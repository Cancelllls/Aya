import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quran_models.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'translation_service.dart';
import '../models/offline_surahs.dart';
import 'qdc_audio_service.dart';
import 'notification_service.dart';
import 'audio_cache_service.dart';
import 'quran_download_service.dart';
import 'reciters_cache_service.dart';

class AudioPlayState {
  final int surahNum;
  final int ayahNum;
  final bool isPlaying;
  final String title;
  final String subtitle;
  final String reciterName;
  final bool isLoading;

  AudioPlayState({
    this.surahNum = 0,
    this.ayahNum = 0,
    this.isPlaying = false,
    this.title = '',
    this.subtitle = '',
    this.reciterName = '',
    this.isLoading = false,
  });
}

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;
  AudioPlayer get activePlayer => _player;

  final ValueNotifier<AudioPlayState> playState = ValueNotifier(
    AudioPlayState(),
  );

  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  bool isSeeking = false;

  int _surahNum = 0;
  String _surahName = '';
  String _activeReciterId = '';
  String _activeReciterName = '';
  StorageService? _storage;
  final NotificationService _notificationService = NotificationService();
  Timer? _autoBookmarkTimer;

  String? _lastNativeTitle;
  String? _lastNativeArtist;
  String? _lastNativeSubtitle;
  bool? _lastNativeIsPlaying;

  // Playlist & sequence state for non-QDC per-ayah reciters
  List<Ayah> _currentPlaylist = [];
  int _currentIndex = 0;
  bool _isPerAyahSequenceMode = false;

  // QDC Timestamps for the current Surah
  Map<int, List<dynamic>>? _currentTimestamps;
  bool isTimestampSyncMode = false;
  static const MethodChannel _systemChannel = MethodChannel('com.quran.aya/system');

  /// Format the Track Name (Surah) shown by native OS media controls.
  static String resolveNativeTrackTitle({
    required int surahNum,
    required String fallbackTitle,
    required bool isArabic,
  }) {
    if (surahNum >= 1 && surahNum <= allOfflineSurahs.length) {
      final surah = allOfflineSurahs[surahNum - 1];
      if (isArabic) return surah.name;
      return fallbackTitle.isNotEmpty ? fallbackTitle : surah.englishName;
    }
    if (fallbackTitle.isNotEmpty) return fallbackTitle;
    return isArabic ? 'القرآن الكريم' : 'Aya Quran Recitation';
  }

  /// Format the Artist Name (Reciter) shown by native OS media controls.
  static String resolveNativeArtistName({
    required String reciterName,
    required int surahNum,
    required String fallbackSubtitle,
    required bool isArabic,
  }) {
    if (surahNum <= 0) {
      return fallbackSubtitle;
    }
    if (reciterName.isNotEmpty) {
      return reciterName;
    }
    return isArabic ? 'القرآن الكريم' : 'Holy Quran';
  }

  void init(StorageService storage) {
    _storage = storage;
    _setupPlayer(_player);
    _setupMethodChannel();

    final lastAudio = storage.getLastAudioPosition();
    if (lastAudio != null) {
      _surahNum = lastAudio['surah'];
      _surahName = lastAudio['surahName'];
      if (_surahName.startsWith("Surah ") || _surahName.trim().isEmpty) {
        try {
          _surahName = TranslationService.isArabic
              ? allOfflineSurahs[_surahNum - 1].name
              : allOfflineSurahs[_surahNum - 1].englishName;
        } catch (_) {}
      }
    }

    playState.addListener(() {
      final state = playState.value;
      if (state.isPlaying || state.isLoading || state.title.isNotEmpty) {
        _syncNativeMediaService(state);
        if (!Platform.isAndroid) {
          _notificationService.showAudioMediaNotification(
            title: resolveNativeTrackTitle(
              surahNum: state.surahNum,
              fallbackTitle: state.title,
              isArabic: TranslationService.isArabic,
            ),
            subtitle: resolveNativeArtistName(
              reciterName: state.reciterName,
              surahNum: state.surahNum,
              fallbackSubtitle: state.subtitle,
              isArabic: TranslationService.isArabic,
            ),
            isPlaying: state.isPlaying,
          );
        }
      } else {
        _stopNativeMediaService();
        if (!Platform.isAndroid) {
          _notificationService.cancelAudioMediaNotification();
        }
      }
    });
  }

  void _setupMethodChannel() {
    _systemChannel.setMethodCallHandler((call) async {
      if (call.method == 'onMediaAction') {
        final action = call.arguments as String?;
        if (action == 'toggle') {
          await togglePlayPause();
        } else if (action == 'play') {
          if (_player.state != PlayerState.playing) {
            await togglePlayPause();
          }
        } else if (action == 'pause') {
          if (_player.state == PlayerState.playing) {
            await _player.pause();
          }
        } else if (action == 'stop') {
          stop();
        } else if (action == 'next') {
          await nextAyah();
        } else if (action == 'previous') {
          await previousAyah();
        }
      }
    });
  }

  void _refreshActiveReciter() {
    final id =
        _storage?.getString('default_reciter', defaultValue: 'ar.alafasy') ??
        'ar.alafasy';
    _activeReciterId = id;
    final resolved = RecitersCacheService.resolveCachedReciterName(
      id,
      isArabic: TranslationService.isArabic,
    );
    if (resolved != null && resolved.isNotEmpty) {
      _activeReciterName = resolved;
      return;
    }
    _activeReciterName = '';
    if (id.startsWith('mp3quran_server_')) {
      unawaited(_resolveDynamicReciterAndSync(id));
    }
  }

  Future<void> _resolveDynamicReciterAndSync(String reciterId) async {
    final resolved = await RecitersCacheService.resolveReciterName(
      reciterId,
      isArabic: TranslationService.isArabic,
    );
    if (resolved == null || resolved.isEmpty) return;
    if (_activeReciterId != reciterId || playState.value.surahNum <= 0) return;
    _activeReciterName = resolved;
    final current = playState.value;
    playState.value = AudioPlayState(
      surahNum: current.surahNum,
      ayahNum: current.ayahNum,
      isPlaying: current.isPlaying,
      title: current.title,
      subtitle: current.subtitle,
      reciterName: resolved,
      isLoading: current.isLoading,
    );
  }

  void _setSurahPlayState({
    required int surahNum,
    required int ayahNum,
    required bool isPlaying,
    required String title,
    required String subtitle,
    bool isLoading = false,
  }) {
    playState.value = AudioPlayState(
      surahNum: surahNum,
      ayahNum: ayahNum,
      isPlaying: isPlaying,
      title: title,
      subtitle: subtitle,
      reciterName: _activeReciterName,
      isLoading: isLoading,
    );
  }

  void _syncNativeMediaService(AudioPlayState state) {
    if (!Platform.isAndroid) return;
    final isAr = TranslationService.isArabic;
    final trackTitle = resolveNativeTrackTitle(
      surahNum: state.surahNum,
      fallbackTitle: state.title,
      isArabic: isAr,
    );
    final reciterName = state.reciterName.isNotEmpty
        ? state.reciterName
        : (_activeReciterId.isNotEmpty
              ? (RecitersCacheService.resolveCachedReciterName(
                      _activeReciterId,
                      isArabic: isAr,
                    ) ??
                    '')
              : '');
    final artistName = resolveNativeArtistName(
      reciterName: reciterName,
      surahNum: state.surahNum,
      fallbackSubtitle: state.subtitle,
      isArabic: isAr,
    );
    final subtitle = state.surahNum > 0 ? state.subtitle : '';

    if (_lastNativeTitle == trackTitle &&
        _lastNativeArtist == artistName &&
        _lastNativeSubtitle == subtitle &&
        _lastNativeIsPlaying == state.isPlaying) {
      return;
    }
    _lastNativeTitle = trackTitle;
    _lastNativeArtist = artistName;
    _lastNativeSubtitle = subtitle;
    _lastNativeIsPlaying = state.isPlaying;

    try {
      _systemChannel.invokeMethod('startMediaService', {
        'title': trackTitle,
        'artist': artistName,
        'subtitle': subtitle,
        'isPlaying': state.isPlaying,
      });
    } catch (_) {}
  }

  void _stopNativeMediaService() {
    _lastNativeTitle = null;
    _lastNativeArtist = null;
    _lastNativeSubtitle = null;
    _lastNativeIsPlaying = null;
    if (Platform.isAndroid) {
      try {
        _systemChannel.invokeMethod('stopMediaService');
      } catch (_) {}
    }
  }

  void _setupPlayer(AudioPlayer p) {
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );

    AudioPlayer.global.setAudioContext(audioContext);
    p.setAudioContext(audioContext);
    p.setReleaseMode(ReleaseMode.stop);

    p.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped) {
        return;
      }
      if (_surahName.isEmpty) {
        return;
      }
      final isPlaying = state == PlayerState.playing;

      int currentAyah = playState.value.ayahNum;

      _setSurahPlayState(
        surahNum: _surahNum,
        ayahNum: currentAyah,
        isPlaying: isPlaying,
        title: _surahName,
        subtitle: isTimestampSyncMode
            ? (TranslationService.isArabic
                  ? "الآية $currentAyah"
                  : "Ayah $currentAyah")
            : "Full Surah Recitation",
      );
    });

    p.onDurationChanged.listen((d) {
      durationNotifier.value = d;
    });

    p.onPositionChanged.listen((pos) {
      if (isSeeking) return;
      positionNotifier.value = pos;

      // Handle timestamp syncing
      if (isTimestampSyncMode && _currentTimestamps != null) {
        int posMs = pos.inMilliseconds;

        // Find which ayah we are in
        int detectedAyah = 0;
        for (var entry in _currentTimestamps!.entries) {
          int start = entry.value[0];
          int end = entry.value[1];
          if (posMs >= start && posMs <= end) {
            detectedAyah = entry.key;
            break;
          }
        }

        if (detectedAyah > 0 && detectedAyah != playState.value.ayahNum) {
          _setSurahPlayState(
            surahNum: _surahNum,
            ayahNum: detectedAyah,
            isPlaying: playState.value.isPlaying,
            title: _surahName,
            subtitle: TranslationService.isArabic
                ? "الآية $detectedAyah"
                : "Ayah $detectedAyah",
          );

          _handleAutoBookmark(detectedAyah);
        }
      }
    });

    p.onPlayerComplete.listen((_) {
      if (_isPerAyahSequenceMode && _currentIndex + 1 < _currentPlaylist.length) {
        _currentIndex++;
        _playNextAyahInSequence();
      } else {
        _isPerAyahSequenceMode = false;
        stop();
      }
    });
  }

  Future<void> _playNextAyahInSequence() async {
    if (_currentIndex < 0 || _currentIndex >= _currentPlaylist.length) {
      _isPerAyahSequenceMode = false;
      stop();
      return;
    }

    final ayah = _currentPlaylist[_currentIndex];
    _refreshActiveReciter();
    final reciter = _activeReciterId;
    final quranScriptType =
        _storage?.getString('quran_script_type', defaultValue: 'hafs') ??
        'hafs';

    final url = ApiService.buildAyahAudioUrl(
      ayah.number,
      _surahNum,
      ayah.numberInSurah,
      reciter: reciter,
      quranScriptType: quranScriptType,
    );

    _setSurahPlayState(
      surahNum: _surahNum,
      ayahNum: ayah.numberInSurah,
      isPlaying: true,
      title: _surahName,
      subtitle: TranslationService.isArabic
          ? "الآية ${ayah.numberInSurah}"
          : "Ayah ${ayah.numberInSurah}",
    );

    final ayahCacheKey = 'ayah_${_surahNum}_${ayah.numberInSurah}_${reciter}_$quranScriptType.mp3';
    final cachedAyahFile = await AudioCacheService.instance.getCachedAudio(ayahCacheKey);

    try {
      await _player.stop();
      await _player.setVolume(1.0);
      if (cachedAyahFile != null) {
        await _player.play(DeviceFileSource(cachedAyahFile.path));
      } else {
        await _player.play(UrlSource(url));
        unawaited(AudioCacheService.instance.cacheStreamUrl(url, ayahCacheKey));
      }
    } catch (_) {
      _isPerAyahSequenceMode = false;
      stop();
    }
  }

  void seekToAyahInSplitMode(int targetAyahNum) {
    if (isTimestampSyncMode && _currentTimestamps != null) {
      if (_currentTimestamps!.containsKey(targetAyahNum)) {
        int startMs = _currentTimestamps![targetAyahNum]![0];
        seekTo(Duration(milliseconds: startMs));
      }
    }
  }

  void playAyah(
    int surahNum,
    String surahName,
    List<Ayah> ayahs,
    int index,
  ) async {
    _surahNum = surahNum;
    _surahName = surahName;
    _currentPlaylist = ayahs;
    _currentIndex = (index >= 0 && index < ayahs.length) ? index : 0;

    _refreshActiveReciter();
    final reciter = _activeReciterId;

    isTimestampSyncMode = QdcAudioService.getQdcReciterId(reciter) != null;

    if (!isTimestampSyncMode && !reciter.startsWith('mp3quran_server_')) {
      _isPerAyahSequenceMode = true;
      _playNextAyahInSequence();
    } else {
      _isPerAyahSequenceMode = false;
      int initialAyahNum = ayahs[_currentIndex].numberInSurah;
      playSurahWithSync(surahNum, surahName, initialAyahNum: initialAyahNum);
    }
  }

  void playSurahWithSync(
    int surahNum,
    String surahName, {
    int initialAyahNum = 0,
  }) async {
    _isPerAyahSequenceMode = false;
    _refreshActiveReciter();
    final reciter = _activeReciterId;

    // Check if we can sync timestamps
    isTimestampSyncMode = QdcAudioService.getQdcReciterId(reciter) != null;

    if (isTimestampSyncMode) {
      _setSurahPlayState(
        surahNum: surahNum,
        ayahNum: initialAyahNum,
        isPlaying: false,
        title: surahName,
        subtitle: 'Loading Timestamps...',
        isLoading: true,
      );

      _currentTimestamps = await QdcAudioService.fetchSurahTimestamps(
        surahNum,
        reciter,
      );

      if (_currentTimestamps == null) {
        isTimestampSyncMode = false; // fallback
      }
    }

    _surahNum = surahNum;
    _surahName = surahName;

    String url = ApiService.buildSurahAudioUrl(surahNum, reciter: reciter);
    if (isTimestampSyncMode) {
      final qdcUrl = await QdcAudioService.getAudioUrl(surahNum, reciter);
      if (qdcUrl != null) {
        url = qdcUrl;
      }
    }

    final localPath = await QuranDownloadService.instance.getLocalSurahPath(surahNum, reciter);
    final isOffline = await File(localPath).exists();

    final streamCacheKey = 'surah_${surahNum}_${reciter}_${isTimestampSyncMode ? "qdc" : "std"}.mp3';
    final cachedStreamFile = await AudioCacheService.instance.getCachedAudio(streamCacheKey);

    _setSurahPlayState(
      surahNum: surahNum,
      ayahNum: isTimestampSyncMode ? initialAyahNum : 0,
      isPlaying: true,
      title: surahName,
      subtitle: isTimestampSyncMode
          ? "Syncing Ayah..."
          : "Full Surah Recitation",
    );

    try {
      await _player.stop();
      await _player.setVolume(1.0);
      if (isOffline) {
        try {
          await _player.play(DeviceFileSource(localPath));
        } catch (e) {
          debugPrint('AudioManager: error playing local file, falling back to stream: $e');
          await _player.play(UrlSource(url));
        }
      } else if (cachedStreamFile != null) {
        try {
          await _player.play(DeviceFileSource(cachedStreamFile.path));
        } catch (e) {
          debugPrint('AudioManager: error playing cached stream, falling back to stream: $e');
          await _player.play(UrlSource(url));
        }
      } else {
        await _player.play(UrlSource(url));
        unawaited(AudioCacheService.instance.cacheStreamUrl(url, streamCacheKey));
      }

      if (isTimestampSyncMode &&
          initialAyahNum > 1 &&
          _currentTimestamps != null) {
        if (_currentTimestamps!.containsKey(initialAyahNum)) {
          int startMs = _currentTimestamps![initialAyahNum]![0];
          await _player.seek(Duration(milliseconds: startMs));
        }
      }
    } catch (e) {
      debugPrint('AudioManager.playSurahWithSync error: $e');
      _setSurahPlayState(
        surahNum: surahNum,
        ayahNum: 0,
        isPlaying: false,
        title: surahName,
        subtitle: "Playback error",
      );
    }
  }

  void playSurah(int surahNum, String surahName, List<Ayah> ayahs) async {
    _currentPlaylist = ayahs;
    _currentIndex = 0;
    _refreshActiveReciter();
    final reciter = _activeReciterId;

    isTimestampSyncMode = QdcAudioService.getQdcReciterId(reciter) != null;

    if (!isTimestampSyncMode && !reciter.startsWith('mp3quran_server_')) {
      _surahNum = surahNum;
      _surahName = surahName;
      _isPerAyahSequenceMode = true;
      _playNextAyahInSequence();
    } else {
      playSurahWithSync(surahNum, surahName);
    }
  }

  void playAdhan(String adhanPath) async {
    try {
      _activeReciterId = '';
      _activeReciterName = '';
      await _player.stop();
      playState.value = AudioPlayState(
        surahNum: 0,
        ayahNum: 0,
        isPlaying: true,
        title: TranslationService.isArabic ? "أذان" : "Adhan",
        subtitle: TranslationService.isArabic ? "وقت الصلاة" : "Prayer Time",
        isLoading: false,
      );

      if (adhanPath.startsWith('assets/')) {
        await _player.play(AssetSource(adhanPath.substring(7)));
      } else {
        final file = File(adhanPath);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(adhanPath));
        }
      }
    } catch (e) {
      print('Error playing Adhan: $e');
    }
  }

  Future<void> togglePlayPause() async {
    final state = _player.state;
    if (state == PlayerState.playing) {
      await _player.pause();
    } else if (state == PlayerState.paused) {
      _refreshActiveReciter();
      await _player.resume();
    } else if (state == PlayerState.completed || state == PlayerState.stopped) {
      if (isTimestampSyncMode && _currentTimestamps != null) {
        int startAyah = playState.value.ayahNum > 0
            ? playState.value.ayahNum
            : 1;
        playSurahWithSync(_surahNum, _surahName, initialAyahNum: startAyah);
      } else {
        _refreshActiveReciter();
        final reciter = _activeReciterId;
        final url = ApiService.buildSurahAudioUrl(_surahNum, reciter: reciter);
        final localPath = await QuranDownloadService.instance.getLocalSurahPath(_surahNum, reciter);
        final streamCacheKey = 'surah_${_surahNum}_${reciter}_std.mp3';
        final cachedStreamFile = await AudioCacheService.instance.getCachedAudio(streamCacheKey);

        if (await File(localPath).exists()) {
          try {
            await _player.play(DeviceFileSource(localPath));
          } catch (_) {
            await _player.play(UrlSource(url));
          }
        } else if (cachedStreamFile != null) {
          try {
            await _player.play(DeviceFileSource(cachedStreamFile.path));
          } catch (_) {
            await _player.play(UrlSource(url));
          }
        } else {
          await _player.play(UrlSource(url));
          unawaited(AudioCacheService.instance.cacheStreamUrl(url, streamCacheKey));
        }
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekBy(Duration offset) async {
    final currentPos = await _player.getCurrentPosition();
    if (currentPos != null) {
      var newPos = currentPos + offset;
      if (newPos < Duration.zero) newPos = Duration.zero;

      final maxDur = await _player.getDuration();
      if (maxDur != null && newPos > maxDur) {
        newPos = maxDur;
      }

      await _player.seek(newPos);
    }
  }

  Future<void> nextAyah() async {
    if (playState.value.surahNum <= 0) return;

    if (isTimestampSyncMode && _currentTimestamps != null) {
      int currentAyah = playState.value.ayahNum;
      if (currentAyah <= 0) {
        final pos = await _player.getCurrentPosition();
        if (pos != null) {
          int posMs = pos.inMilliseconds;
          for (var entry in _currentTimestamps!.entries) {
            if (posMs >= entry.value[0] && posMs <= entry.value[1]) {
              currentAyah = entry.key;
              break;
            }
          }
        }
      }
      int targetAyah = currentAyah + 1;
      if (_currentTimestamps!.containsKey(targetAyah)) {
        int startMs = _currentTimestamps![targetAyah]![0];
        await seekTo(Duration(milliseconds: startMs));
        _setSurahPlayState(
          surahNum: _surahNum,
          ayahNum: targetAyah,
          isPlaying: playState.value.isPlaying,
          title: _surahName,
          subtitle: TranslationService.isArabic
              ? "الآية $targetAyah"
              : "Ayah $targetAyah",
        );
        _handleAutoBookmark(targetAyah);
      }
    } else if (_isPerAyahSequenceMode && _currentPlaylist.isNotEmpty) {
      if (_currentIndex + 1 < _currentPlaylist.length) {
        _currentIndex++;
        await _playNextAyahInSequence();
      }
    } else {
      await seekBy(const Duration(seconds: 10));
    }
  }

  Future<void> previousAyah() async {
    if (playState.value.surahNum <= 0) return;

    if (isTimestampSyncMode && _currentTimestamps != null) {
      int currentAyah = playState.value.ayahNum;
      if (currentAyah <= 0) {
        final pos = await _player.getCurrentPosition();
        if (pos != null) {
          int posMs = pos.inMilliseconds;
          for (var entry in _currentTimestamps!.entries) {
            if (posMs >= entry.value[0] && posMs <= entry.value[1]) {
              currentAyah = entry.key;
              break;
            }
          }
        }
      }
      if (currentAyah > 1) {
        int targetAyah = currentAyah - 1;
        if (_currentTimestamps!.containsKey(targetAyah)) {
          int startMs = _currentTimestamps![targetAyah]![0];
          await seekTo(Duration(milliseconds: startMs));
          _setSurahPlayState(
            surahNum: _surahNum,
            ayahNum: targetAyah,
            isPlaying: playState.value.isPlaying,
            title: _surahName,
            subtitle: TranslationService.isArabic
                ? "الآية $targetAyah"
                : "Ayah $targetAyah",
          );
          _handleAutoBookmark(targetAyah);
        }
      } else {
        await seekTo(Duration.zero);
      }
    } else if (_isPerAyahSequenceMode && _currentPlaylist.isNotEmpty) {
      if (_currentIndex > 0) {
        _currentIndex--;
        await _playNextAyahInSequence();
      } else {
        _currentIndex = 0;
        await _playNextAyahInSequence();
      }
    } else {
      await seekBy(const Duration(seconds: -10));
    }
  }

  void _handleAutoBookmark(int ayahNum) {
    final autoBookmark =
        _storage?.getBool('setting_auto_bookmark', defaultValue: true) ?? true;
    if (autoBookmark) {
      _autoBookmarkTimer?.cancel();
      final sNum = _surahNum;
      final sName = _surahName;
      _autoBookmarkTimer = Timer(const Duration(milliseconds: 1500), () {
        _storage?.addBookmark(sNum, sName, ayahNum);
      });
    }
  }

  void stop() async {
    _isPerAyahSequenceMode = false;
    _surahNum = 0;
    _surahName = '';
    _activeReciterId = '';
    _activeReciterName = '';
    _currentPlaylist = [];
    _currentIndex = 0;
    isTimestampSyncMode = false;
    _currentTimestamps = null;
    final pos = await _player.getCurrentPosition();
    if (pos != null) {
      await _storage?.saveLastAudioTimestamp(pos.inMilliseconds);
    }
    await _player.stop();
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    playState.value = AudioPlayState();
    _stopNativeMediaService();
    if (!Platform.isAndroid) {
      _notificationService.cancelAudioMediaNotification();
    }
  }
}
