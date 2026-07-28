import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quran_models.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'translation_service.dart';
import '../models/offline_surahs.dart';
import 'qdc_audio_service.dart';

class AudioPlayState {
  final int surahNum;
  final int ayahNum;
  final bool isPlaying;
  final String title;
  final String subtitle;
  final bool isLoading;

  AudioPlayState({
    this.surahNum = 0,
    this.ayahNum = 0,
    this.isPlaying = false,
    this.title = '',
    this.subtitle = '',
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
  late StorageService _storage;

  // QDC Timestamps for the current Surah
  Map<int, List<dynamic>>? _currentTimestamps;
  bool isTimestampSyncMode = false;

  void init(StorageService storage) {
    _storage = storage;
    _setupPlayer(_player);

    final lastAudio = _storage.getLastAudioPosition();
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
  }

  void _setupPlayer(AudioPlayer p) {
    p.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );

    p.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;

      int currentAyah = playState.value.ayahNum;

      playState.value = AudioPlayState(
        surahNum: _surahNum,
        ayahNum: currentAyah,
        isPlaying: isPlaying,
        title: _surahName,
        subtitle: isTimestampSyncMode
            ? (TranslationService.isArabic
                  ? "الآية $currentAyah"
                  : "Ayah $currentAyah")
            : "Full Surah Recitation",
        isLoading: false,
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
          playState.value = AudioPlayState(
            surahNum: _surahNum,
            ayahNum: detectedAyah,
            isPlaying: playState.value.isPlaying,
            title: _surahName,
            subtitle: TranslationService.isArabic
                ? "الآية $detectedAyah"
                : "Ayah $detectedAyah",
            isLoading: false,
          );

          final autoBookmark = _storage.getBool(
            'setting_auto_bookmark',
            defaultValue: true,
          );
          if (autoBookmark) {
            _storage.addBookmark(_surahNum, _surahName, detectedAyah);
          }
        }
      }
    });

    p.onPlayerComplete.listen((_) {
      stop();
    });
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
    int initialAyahNum = 1;
    if (index >= 0 && index < ayahs.length) {
      initialAyahNum = ayahs[index].numberInSurah;
    }

    playSurahWithSync(surahNum, surahName, initialAyahNum: initialAyahNum);
  }

  void playSurahWithSync(
    int surahNum,
    String surahName, {
    int initialAyahNum = 0,
  }) async {
    final reciter = _storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );

    // Check if we can sync timestamps
    isTimestampSyncMode = QdcAudioService.getQdcReciterId(reciter) != null;

    if (isTimestampSyncMode) {
      playState.value = AudioPlayState(
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

    final dir = await getApplicationDocumentsDirectory();
    final fileName = isTimestampSyncMode
        ? 'surah_${surahNum}_qdc_v2.mp3'
        : 'surah_$surahNum.mp3';
    final localPath = '${dir.path}/quran_audio/$reciter/$fileName';
    final isOffline = await File(localPath).exists();

    playState.value = AudioPlayState(
      surahNum: surahNum,
      ayahNum: isTimestampSyncMode ? initialAyahNum : 0,
      isPlaying: true,
      title: surahName,
      subtitle: isTimestampSyncMode
          ? "Syncing Ayah..."
          : "Full Surah Recitation",
      isLoading: false,
    );

    try {
      await _player.stop();
      await _player.setVolume(1.0);
      if (isOffline) {
        await _player.play(DeviceFileSource(localPath));
      } else {
        await _player.play(UrlSource(url));
      }

      if (isTimestampSyncMode &&
          initialAyahNum > 1 &&
          _currentTimestamps != null) {
        if (_currentTimestamps!.containsKey(initialAyahNum)) {
          int startMs = _currentTimestamps![initialAyahNum]![0];
          await _player.seek(Duration(milliseconds: startMs));
        }
      }
    } catch (_) {}
  }

  void playSurah(int surahNum, String surahName, List<Ayah> ayahs) async {
    playSurahWithSync(surahNum, surahName);
  }

  void playAdhan(String adhanPath) async {
    try {
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
      await _player.resume();
    } else if (state == PlayerState.completed || state == PlayerState.stopped) {
      if (isTimestampSyncMode && _currentTimestamps != null) {
        int startAyah = playState.value.ayahNum > 0
            ? playState.value.ayahNum
            : 1;
        playSurahWithSync(_surahNum, _surahName, initialAyahNum: startAyah);
      } else {
        final reciter = _storage.getString(
          'default_reciter',
          defaultValue: 'ar.alafasy',
        );
        final url = ApiService.buildSurahAudioUrl(_surahNum, reciter: reciter);
        final dir = await getApplicationDocumentsDirectory();
        final localPath =
            '${dir.path}/quran_audio/$reciter/surah_$_surahNum.mp3';
        if (await File(localPath).exists()) {
          await _player.play(DeviceFileSource(localPath));
        } else {
          await _player.play(UrlSource(url));
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

  void stop() async {
    final pos = await _player.getCurrentPosition();
    if (pos != null) {
      _storage.saveLastAudioTimestamp(pos.inMilliseconds);
    }
    await _player.stop();
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    playState.value = AudioPlayState();
  }
}
