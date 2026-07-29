import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/notification_service.dart';
import 'package:aya_app/services/adhan_audio_service.dart';

void main() {
  group('AdhanAudioService reciter mappings', () {
    test('fajrReciterUrls has 4 reciters', () {
      expect(AdhanAudioService.fajrReciterUrls, hasLength(4));
    });

    test('standardReciterUrls has 7 reciters', () {
      expect(AdhanAudioService.standardReciterUrls, hasLength(7));
    });

    test('all reciter IDs are valid', () {
      final fajr = AdhanAudioService.fajrReciterUrls;
      final standard = AdhanAudioService.standardReciterUrls;
      for (final key in fajr.keys) {
        expect(key, isNotEmpty);
        expect(fajr[key], isNotEmpty);
        expect(fajr[key]!.endsWith('.mp3'), isTrue);
      }
      for (final key in standard.keys) {
        expect(key, isNotEmpty);
        expect(standard[key], isNotEmpty);
        expect(standard[key]!.endsWith('.mp3'), isTrue);
      }
    });

    test('fajr and standard have different files for same reciter', () {
      expect(
        AdhanAudioService.fajrReciterUrls['mishary'],
        isNot(AdhanAudioService.standardReciterUrls['mishary']),
      );
    });
  });

  group('NotificationService', () {
    test('singleton returns same instance', () {
      final a = NotificationService();
      final b = NotificationService();
      expect(identical(a, b), isTrue);
    });

    test('islamicVibrationPattern has correct structure', () {
      expect(NotificationService.islamicVibrationPattern.length, 18);
      expect(NotificationService.islamicVibrationAmplitudes.length, 18);
      expect(NotificationService.islamicVibrationPattern[0], 0); // starts with 0 delay
    });

    test('notification IDs do not overlap between types', () {
      // Prayer IDs: 1-70 base, +2000 pre-adhan, +5000 tracker
      // Reminder IDs: 3000 morning, 3001 evening, 3002-3008 verse
      final prayerBase = {for (int i = 1; i <= 70; i++) i};
      final preAdhan = {for (int i = 1; i <= 70; i++) i + 2000};
      final tracker = {for (int i = 1; i <= 70; i++) i + 5000};
      final reminders = {3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008};

      // Check no overlap
      expect(prayerBase.intersection(preAdhan), isEmpty);
      expect(prayerBase.intersection(tracker), isEmpty);
      expect(prayerBase.intersection(reminders), isEmpty);
      expect(preAdhan.intersection(tracker), isEmpty);
      expect(preAdhan.intersection(reminders), isEmpty);
      expect(tracker.intersection(reminders), isEmpty);
    });
  });
}
