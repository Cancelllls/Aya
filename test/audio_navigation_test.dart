import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/audio_manager.dart';
import 'package:aya_app/services/reciters_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
  });

  group('AudioPlayState Tests', () {
    test('AudioPlayState defaults are clean and empty', () {
      final state = AudioPlayState();
      expect(state.surahNum, equals(0));
      expect(state.ayahNum, equals(0));
      expect(state.isPlaying, isFalse);
      expect(state.title, isEmpty);
      expect(state.subtitle, isEmpty);
      expect(state.reciterName, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('AudioPlayState holds correct values for active ayah recitation', () {
      final state = AudioPlayState(
        surahNum: 1,
        ayahNum: 5,
        isPlaying: true,
        title: 'Al-Fatihah',
        subtitle: 'Ayah 5',
        reciterName: 'Mishary Alafasy',
        isLoading: false,
      );

      expect(state.surahNum, equals(1));
      expect(state.ayahNum, equals(5));
      expect(state.isPlaying, isTrue);
      expect(state.title, equals('Al-Fatihah'));
      expect(state.subtitle, equals('Ayah 5'));
      expect(state.reciterName, equals('Mishary Alafasy'));
      expect(state.isLoading, isFalse);
    });

    test('AudioManager singleton exposes valid playState notifier', () {
      final manager = AudioManager.instance;
      expect(manager, isNotNull);
      expect(manager.playState.value.isPlaying, isFalse);
      expect(manager.durationNotifier.value, equals(Duration.zero));
      expect(manager.positionNotifier.value, equals(Duration.zero));
    });
  });

  group('Native Media Player Metadata Tests', () {
    tearDown(() {
      RecitersCacheService.setCachedRecitersForTest(null);
    });

    test('resolveNativeTrackTitle resolves Surah name for Arabic and English', () {
      expect(
        AudioManager.resolveNativeTrackTitle(
          surahNum: 2,
          fallbackTitle: 'Al-Baqara',
          isArabic: true,
        ),
        equals('سُورَةُ البَقَرَةِ'),
      );
      expect(
        AudioManager.resolveNativeTrackTitle(
          surahNum: 2,
          fallbackTitle: 'Al-Baqara',
          isArabic: false,
        ),
        equals('Al-Baqara'),
      );
      expect(
        AudioManager.resolveNativeTrackTitle(
          surahNum: 1,
          fallbackTitle: '',
          isArabic: false,
        ),
        equals('Al-Faatiha'),
      );
    });

    test('resolveNativeArtistName resolves reciter name and non-Quran fallback', () {
      expect(
        AudioManager.resolveNativeArtistName(
          reciterName: 'Mishary Alafasy',
          surahNum: 1,
          fallbackSubtitle: 'Ayah 5',
          isArabic: false,
        ),
        equals('Mishary Alafasy'),
      );
      expect(
        AudioManager.resolveNativeArtistName(
          reciterName: '',
          surahNum: 1,
          fallbackSubtitle: 'Ayah 5',
          isArabic: true,
        ),
        equals('القرآن الكريم'),
      );
      expect(
        AudioManager.resolveNativeArtistName(
          reciterName: 'Ignored',
          surahNum: 0,
          fallbackSubtitle: 'Prayer Time',
          isArabic: false,
        ),
        equals('Prayer Time'),
      );
    });

    test('RecitersCacheService resolves static and dynamic reciters', () {
      expect(
        RecitersCacheService.resolveCachedReciterName(
          'ar.alafasy',
          isArabic: true,
        ),
        equals('مشاري العفاسي'),
      );
      expect(
        RecitersCacheService.resolveCachedReciterName(
          'ar.alafasy',
          isArabic: false,
        ),
        equals('Mishary Alafasy'),
      );

      RecitersCacheService.setCachedRecitersForTest([
        {
          'name': 'محمود خليل الحصري',
          'moshaf': [
            {'server': 'https://cdn.mp3quran.net/audio/husary/warsh/'},
          ],
        },
      ]);

      expect(
        RecitersCacheService.resolveCachedReciterName(
          'mp3quran_server_https://cdn.mp3quran.net/audio/husary/warsh',
          isArabic: true,
        ),
        equals('محمود خليل الحصري'),
      );
    });
  });
}
