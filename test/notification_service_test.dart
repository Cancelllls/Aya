import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/notification_service.dart';
import 'package:aya_app/services/adhan_audio_service.dart';
import 'package:aya_app/services/translation_service.dart';

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
      // Prayer IDs: 1-70 base, +2000 pre-adhan, +2500 early, +2800 iqamah, +4000 jumuah, +5000 tracker, +6000/+7000/+8000 escalating
      // Reminder IDs: 3000 morning, 3001 evening, 3002-3008 verse
      final prayerBase = {for (int i = 1; i <= 70; i++) i};
      final preAdhan = {for (int i = 1; i <= 70; i++) i + 2000};
      final earlyPreAdhan = {for (int i = 1; i <= 70; i++) i + 2500};
      final iqamahReminders = {for (int i = 1; i <= 70; i++) i + 2800};
      final reminders = {3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008};
      final jumuah = {for (int i = 1; i <= 70; i++) i + 4000};
      final tracker = {for (int i = 1; i <= 70; i++) i + 5000};
      final escalating = {
        for (int i = 1; i <= 70; i++) ...[i + 6000, i + 7000, i + 8000],
      };
      final media = {8888};
      final events = {for (int i = 9000; i <= 9050; i++) i};

      final allGroups = [
        prayerBase,
        preAdhan,
        earlyPreAdhan,
        iqamahReminders,
        reminders,
        jumuah,
        tracker,
        escalating,
        media,
        events,
      ];

      for (int i = 0; i < allGroups.length; i++) {
        for (int j = i + 1; j < allGroups.length; j++) {
          expect(
            allGroups[i].intersection(allGroups[j]),
            isEmpty,
            reason: 'Group $i and Group $j have overlapping notification IDs',
          );
        }
      }
    });

    test('resolveIsArabic correctly prioritizes notification_lang over app language', () {
      TranslationService.setLanguage('en');
      expect(NotificationService.resolveIsArabic('ar'), isTrue);
      expect(NotificationService.resolveIsArabic('en'), isFalse);
      expect(NotificationService.resolveIsArabic('follow_app'), isFalse);

      TranslationService.setLanguage('ar');
      expect(NotificationService.resolveIsArabic('ar'), isTrue);
      expect(NotificationService.resolveIsArabic('en'), isFalse);
      expect(NotificationService.resolveIsArabic('follow_app'), isTrue);
    });

    test('arabicPrayerName returns canonical clean Arabic names without duplicate prefixes', () {
      expect(NotificationService.arabicPrayerName('Fajr'), 'الفجر');
      expect(NotificationService.arabicPrayerName('Dhuhr'), 'الظهر');
      expect(NotificationService.arabicPrayerName('Asr'), 'العصر');
      expect(NotificationService.arabicPrayerName('Maghrib'), 'المغرب');
      expect(NotificationService.arabicPrayerName('Isha'), 'العشاء');
      expect(NotificationService.arabicPrayerName('Sunrise'), 'الشروق');
    });

    test('formatMinutesGrammar adheres to strict Arabic dual, plural, and accusative rules', () {
      expect(NotificationService.formatMinutesGrammar(1, true), 'دقيقة واحدة');
      expect(NotificationService.formatMinutesGrammar(2, true), 'دقيقتين');
      expect(NotificationService.formatMinutesGrammar(5, true), '5 دقائق');
      expect(NotificationService.formatMinutesGrammar(10, true), '10 دقائق');
      expect(NotificationService.formatMinutesGrammar(15, true), '15 دقيقة');
      expect(NotificationService.formatMinutesGrammar(30, true), '30 دقيقة');
      expect(NotificationService.formatMinutesGrammar(45, true), '45 دقيقة');

      expect(NotificationService.formatMinutesGrammar(1, false), '1 minute');
      expect(NotificationService.formatMinutesGrammar(5, false), '5 minutes');
      expect(NotificationService.formatMinutesGrammar(15, false), '15 minutes');
    });
  });
}
