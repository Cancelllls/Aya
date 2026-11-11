import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPlayState Tests', () {
    test('AudioPlayState defaults are clean and empty', () {
      final state = AudioPlayState();
      expect(state.surahNum, equals(0));
      expect(state.ayahNum, equals(0));
      expect(state.isPlaying, isFalse);
      expect(state.title, isEmpty);
      expect(state.subtitle, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('AudioPlayState holds correct values for active ayah recitation', () {
      final state = AudioPlayState(
        surahNum: 1,
        ayahNum: 5,
        isPlaying: true,
        title: 'Al-Fatihah',
        subtitle: 'Ayah 5',
        isLoading: false,
      );

      expect(state.surahNum, equals(1));
      expect(state.ayahNum, equals(5));
      expect(state.isPlaying, isTrue);
      expect(state.title, equals('Al-Fatihah'));
      expect(state.subtitle, equals('Ayah 5'));
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
}
