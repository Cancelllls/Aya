import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/quran_models.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'translation_service.dart';

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

  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();
  bool _usingPlayerA = true;
  bool _isTransitioning = false;
  Timer? _crossfadeTimer;
  Duration? _currentDuration;
  int _preloadedIndex = -1;

  void _cancelCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    _isTransitioning = false;
    _currentDuration = null;
  }

  AudioPlayer get activePlayer => _usingPlayerA ? _playerA : _playerB;
  AudioPlayer get inactivePlayer => _usingPlayerA ? _playerB : _playerA;

  AudioPlayer get player => activePlayer;

  final ValueNotifier<AudioPlayState> playState = ValueNotifier(
    AudioPlayState(),
  );

  List<Ayah> _currentPlaylist = [];
  int _currentIndex = -1;
  int _surahNum = 0;
  String _surahName = '';
  late StorageService _storage;

  void init(StorageService storage) {
    _storage = storage;
    _setupPlayer(_playerA);
    _setupPlayer(_playerB);
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
      if (_isTransitioning) return;

      if (p == activePlayer) {
        final isPlaying = state == PlayerState.playing;
        playState.value = AudioPlayState(
          surahNum: _surahNum,
          ayahNum: _currentIndex >= 0 && _currentIndex < _currentPlaylist.length
              ? _currentPlaylist[_currentIndex].numberInSurah
              : 0,
          isPlaying: isPlaying,
          title: _surahName,
          subtitle:
              _currentIndex >= 0 && _currentIndex < _currentPlaylist.length
              ? (TranslationService.isArabic
                    ? "الآية ${_currentPlaylist[_currentIndex].numberInSurah}"
                    : "Ayah ${_currentPlaylist[_currentIndex].numberInSurah}")
              : "Full Surah Recitation",
          isLoading: false,
        );
      }
    });

    p.onDurationChanged.listen((d) {
      if (p == activePlayer) {
        _currentDuration = d;
      }
    });

    p.onPositionChanged.listen((pos) {
      if (p != activePlayer || _isTransitioning) return;

      final dur = _currentDuration;
      if (dur != null && dur.inMilliseconds > 0) {
        final remaining = dur.inMilliseconds - pos.inMilliseconds;
        // Start crossfading 800ms before the end of the ayah
        if (remaining <= 800 &&
            remaining > 0 &&
            _currentIndex < _currentPlaylist.length - 1) {
          final continuous = _storage.getBool(
            'setting_continuous_play',
            defaultValue: true,
          );
          if (continuous) {
            _playNextAyahWithCrossfade();
          }
        }
      }
    });

    p.onPlayerComplete.listen((event) {
      if (p == activePlayer) {
        _handlePlaybackComplete();
      }
    });
  }

  Future<String> _getLocalSurahPath(int surahNum, String reciter) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/quran_audio/$reciter/surah_$surahNum.mp3';
  }

  Future<String> _getLocalAyahPath(int globalAyahNum, String reciter) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/quran_audio/$reciter/ayah_$globalAyahNum.mp3';
  }

  void _cacheAyahBackground(String url, File localFile) async {
    try {
      await localFile.parent.create(recursive: true);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {}
  }

  void _preloadNextAyah() async {
    final nextIndex = _currentIndex + 1;
    if (nextIndex < 0 || nextIndex >= _currentPlaylist.length) return;

    final nextAyah = _currentPlaylist[nextIndex];
    final reciter = _storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    final url = ApiService.buildAyahAudioUrl(nextAyah.number, reciter: reciter);
    final localPath = await _getLocalAyahPath(nextAyah.number, reciter);
    final localFile = File(localPath);
    final isOffline = await localFile.exists();

    final nextPlayer = inactivePlayer;
    try {
      await nextPlayer.setVolume(0.0);
      if (isOffline) {
        await nextPlayer.setSource(DeviceFileSource(localPath));
      } else {
        await nextPlayer.setSource(UrlSource(url));
      }
      _preloadedIndex = nextIndex;
    } catch (_) {}
  }

  void playAyah(
    int surahNum,
    String surahName,
    List<Ayah> ayahs,
    int index,
  ) async {
    _cancelCrossfade();
    _surahNum = surahNum;
    _surahName = surahName;
    _currentPlaylist = ayahs;
    _currentIndex = index;

    if (_currentIndex < 0 || _currentIndex >= _currentPlaylist.length) return;

    _isTransitioning = false;

    final ayah = _currentPlaylist[_currentIndex];

    playState.value = AudioPlayState(
      surahNum: surahNum,
      ayahNum: ayah.numberInSurah,
      isPlaying: false,
      title: surahName,
      subtitle: TranslationService.isArabic
          ? "جاري تحميل التلاوة..."
          : "Loading recitation...",
      isLoading: true,
    );

    final reciter = _storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    final url = ApiService.buildAyahAudioUrl(ayah.number, reciter: reciter);
    final localPath = await _getLocalAyahPath(ayah.number, reciter);
    final localFile = File(localPath);
    final isOffline = await localFile.exists();

    try {
      await _playerA.stop();
      await _playerB.stop();
      await _playerA.setVolume(1.0);
      await _playerB.setVolume(1.0);

      if (isOffline) {
        await activePlayer.play(DeviceFileSource(localPath));
      } else {
        await activePlayer.play(UrlSource(url));
        _cacheAyahBackground(url, localFile);
      }

      _currentDuration = null;
      _preloadNextAyah();

      playState.value = AudioPlayState(
        surahNum: _surahNum,
        ayahNum: ayah.numberInSurah,
        isPlaying: true,
        title: surahName,
        subtitle: TranslationService.isArabic
            ? "الآية ${ayah.numberInSurah} ${isOffline ? '(محملة)' : ''}"
            : "Ayah ${ayah.numberInSurah} ${isOffline ? '(Offline)' : ''}",
        isLoading: false,
      );

      final autoBookmark = _storage.getBool(
        'setting_auto_bookmark',
        defaultValue: true,
      );
      if (autoBookmark) {
        await _storage.addBookmark(surahNum, surahName, ayah.numberInSurah);
      }
    } catch (e) {
      playState.value = AudioPlayState(
        surahNum: _surahNum,
        ayahNum: ayah.numberInSurah,
        isPlaying: false,
        title: surahName,
        subtitle: TranslationService.isArabic
            ? "فشل تشغيل الصوت: $e"
            : "Playback failed: $e",
        isLoading: false,
      );
    }
  }

  void playSurah(int surahNum, String surahName, List<Ayah> ayahs) async {
    _cancelCrossfade();
    _surahNum = surahNum;
    _surahName = surahName;
    _isTransitioning = false;

    final reciter = _storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    final localPath = await _getLocalSurahPath(surahNum, reciter);
    final localFile = File(localPath);
    final isOffline = await localFile.exists();

    if (isOffline) {
      _currentPlaylist = [];
      _currentIndex = -1;

      playState.value = AudioPlayState(
        surahNum: surahNum,
        ayahNum: 0,
        isPlaying: false,
        title: surahName,
        subtitle: TranslationService.isArabic
            ? "جاري تحميل التلاوة..."
            : "Loading recitation...",
        isLoading: true,
      );

      try {
        await _playerA.stop();
        await _playerB.stop();
        await _playerA.setVolume(1.0);
        await _playerB.setVolume(1.0);
        await activePlayer.play(DeviceFileSource(localPath));

        playState.value = AudioPlayState(
          surahNum: surahNum,
          ayahNum: 0,
          isPlaying: true,
          title: surahName,
          subtitle: TranslationService.isArabic
              ? "تلاوة السورة كاملة (محملة)"
              : "Full Surah Recitation (Offline)",
          isLoading: false,
        );
      } catch (e) {
        playState.value = AudioPlayState(
          surahNum: surahNum,
          ayahNum: 0,
          isPlaying: false,
          title: surahName,
          subtitle: TranslationService.isArabic
              ? "فشل تشغيل الصوت: $e"
              : "Playback failed: $e",
          isLoading: false,
        );
      }
    } else {
      // Play consecutive Ayahs starting from 0
      playAyah(surahNum, surahName, ayahs, 0);
    }
  }

  void _handlePlaybackComplete() {
    if (_isTransitioning) return;
    final continuous = _storage.getBool(
      'setting_continuous_play',
      defaultValue: true,
    );
    if (continuous &&
        _currentIndex >= 0 &&
        _currentIndex < _currentPlaylist.length - 1) {
      _playNextAyahWithCrossfade();
    } else {
      stop();
    }
  }

  void _playNextAyahWithCrossfade() async {
    if (_currentIndex < 0 || _currentIndex >= _currentPlaylist.length - 1)
      return;
    if (_isTransitioning) return;

    final nextIndex = _currentIndex + 1;
    final nextAyah = _currentPlaylist[nextIndex];
    final reciter = _storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    final url = ApiService.buildAyahAudioUrl(nextAyah.number, reciter: reciter);
    final localPath = await _getLocalAyahPath(nextAyah.number, reciter);
    final localFile = File(localPath);
    final isOffline = await localFile.exists();

    _isTransitioning = true;

    playState.value = AudioPlayState(
      surahNum: _surahNum,
      ayahNum: nextAyah.numberInSurah,
      isPlaying: true,
      title: _surahName,
      subtitle: TranslationService.isArabic
          ? "الآية ${nextAyah.numberInSurah} ${isOffline ? '(محملة)' : ''}"
          : "Ayah ${nextAyah.numberInSurah} ${isOffline ? '(Offline)' : ''}",
      isLoading: !isOffline,
    );

    final autoBookmark = _storage.getBool(
      'setting_auto_bookmark',
      defaultValue: true,
    );
    if (autoBookmark) {
      await _storage.addBookmark(_surahNum, _surahName, nextAyah.numberInSurah);
    }

    final currentPlay = activePlayer;
    final nextPlay = inactivePlayer;

    try {
      await nextPlay.setVolume(0.0);
      final isPreloaded = _preloadedIndex == nextIndex;
      if (isPreloaded) {
        await nextPlay.resume();
      } else {
        if (isOffline) {
          await nextPlay.play(DeviceFileSource(localPath));
        } else {
          await nextPlay.play(UrlSource(url));
          _cacheAyahBackground(url, localFile);
        }
      }

      _currentDuration = null;
      _preloadNextAyah();

      playState.value = AudioPlayState(
        surahNum: _surahNum,
        ayahNum: nextAyah.numberInSurah,
        isPlaying: true,
        title: _surahName,
        subtitle: TranslationService.isArabic
            ? "الآية ${nextAyah.numberInSurah} ${isOffline ? '(محملة)' : ''}"
            : "Ayah ${nextAyah.numberInSurah} ${isOffline ? '(Offline)' : ''}",
        isLoading: false,
      );

      int step = 0;
      const steps = 30; // 1500ms crossfade
      _crossfadeTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) async {
        if (!_isTransitioning) {
          timer.cancel();
          return;
        }
        step++;
        final double nextVol = step / steps;
        final double currVol = 1.0 - nextVol;

        try {
          await currentPlay.setVolume(currVol);
          await nextPlay.setVolume(nextVol);
        } catch (_) {}

        if (step >= steps) {
          timer.cancel();
          _crossfadeTimer = null;
          if (_isTransitioning) {
            try {
              await currentPlay.stop();
              await currentPlay.setVolume(1.0);
            } catch (_) {}
            _usingPlayerA = !_usingPlayerA;
            _currentIndex = nextIndex;
            _isTransitioning = false;
          }
        }
      });
    } catch (e) {
      _currentIndex = nextIndex;
      try {
        await currentPlay.stop();
        await nextPlay.setVolume(1.0);
      } catch (_) {}
      _usingPlayerA = !_usingPlayerA;
      _isTransitioning = false;

      playState.value = AudioPlayState(
        surahNum: _surahNum,
        ayahNum: nextAyah.numberInSurah,
        isPlaying: false,
        title: _surahName,
        subtitle: TranslationService.isArabic
            ? "فشل الانتقال الصوتي: $e"
            : "Audio transition failed: $e",
        isLoading: false,
      );
    }
  }

  void togglePlayPause() async {
    if (activePlayer.state == PlayerState.playing) {
      await activePlayer.pause();
      if (_isTransitioning) {
        await inactivePlayer.pause();
      }
    } else if (activePlayer.state == PlayerState.paused ||
        activePlayer.state == PlayerState.completed) {
      await activePlayer.resume();
      if (_isTransitioning) {
        await inactivePlayer.resume();
      }
    }
  }

  void stop() async {
    _cancelCrossfade();
    await _playerA.stop();
    await _playerB.stop();
    await _playerA.setVolume(1.0);
    await _playerB.setVolume(1.0);
    playState.value = AudioPlayState();
    _currentPlaylist = [];
    _currentIndex = -1;
  }
}
