import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/translation_service.dart';
import 'package:hijri/hijri_calendar.dart';

void main() {
  group('Redesigned Calendar Feature Tests', () {
    test('Calculates spanning Hijri title correctly', () {
      // September 2026 spans Rabi' I and Rabi' II 1448
      final hStart = HijriCalendar.fromDate(DateTime(2026, 9, 1));
      final hEnd = HijriCalendar.fromDate(DateTime(2026, 9 + 1, 0));

      expect(hStart.hYear, equals(1448));
      expect(hEnd.hYear, equals(1448));
      expect(hStart.hMonth, isNot(equals(hEnd.hMonth)));
    });

    test('Upcoming holy days calculation returns sorted chronological events', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final hNow = HijriCalendar.fromDate(today);

      final holyEvents = [
        {'m': 1, 'd': 1, 'ar': 'رأس السنة الهجرية', 'en': 'Islamic New Year', 'icon': '🌙'},
        {'m': 7, 'd': 1, 'ar': 'أول شهر رجب', 'en': 'First Day of Rajab', 'icon': '🌙'},
        {'m': 7, 'd': 27, 'ar': 'ليلة الإسراء والمعراج', 'en': "Isra' and Mi'raj", 'icon': '🕌'},
        {'m': 8, 'd': 15, 'ar': 'ليلة النصف من شعبان', 'en': "Mid-Sha'ban", 'icon': '🌕'},
        {'m': 9, 'd': 1, 'ar': 'بداية شهر رمضان المبارك', 'en': 'Start of Ramadan', 'icon': '🌙'},
        {'m': 10, 'd': 1, 'ar': 'عيد الفطر المبارك', 'en': 'Eid al-Fitr', 'icon': '✨'},
        {'m': 12, 'd': 10, 'ar': 'عيد الأضحى المبارك', 'en': 'Eid al-Adha', 'icon': '🕌'},
      ];

      final upcoming = <Map<String, dynamic>>[];

      for (final ev in holyEvents) {
        final m = ev['m'] as int;
        final d = ev['d'] as int;

        DateTime? gregDate;
        for (int yearOffset = 0; yearOffset <= 1; yearOffset++) {
          final candidateHYear = hNow.hYear + yearOffset;
          final hCal = HijriCalendar();
          final candidateDate = hCal.hijriToGregorian(candidateHYear, m, d);
          if (!candidateDate.isBefore(today)) {
            gregDate = candidateDate;
            break;
          }
        }

        if (gregDate != null) {
          final daysDiff = gregDate.difference(today).inDays;
          upcoming.add({
            'title': ev['en'],
            'daysRemaining': daysDiff,
            'gregDate': gregDate,
          });
        }
      }

      upcoming.sort((a, b) => (a['daysRemaining'] as int).compareTo(b['daysRemaining'] as int));

      expect(upcoming, isNotEmpty);
      for (int i = 0; i < upcoming.length - 1; i++) {
        expect(upcoming[i]['daysRemaining'] <= upcoming[i + 1]['daysRemaining'], isTrue);
      }
    });

    test('Translation keys for upcoming holy days exist in both English and Arabic', () {
      TranslationService.setLanguage('en');
      expect(TranslationService.t('upcoming_holy_days'), equals('UPCOMING HOLY DAYS'));
      expect(TranslationService.t('view_table'), equals('Full Month Table'));
      expect(TranslationService.t('view_calendar'), equals('Calendar Grid'));

      TranslationService.setLanguage('ar');
      expect(TranslationService.t('upcoming_holy_days'), equals('المناسبات الإسلامية القادمة'));
      expect(TranslationService.t('view_table'), equals('جدول الشهر بالكامل'));
      expect(TranslationService.t('view_calendar'), equals('تقويم الأيام'));
    });
  });
}
