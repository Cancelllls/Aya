import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/prayer_models.dart';

void main() {
  group('PrayerTimeData', () {
    test('toJson and fromLocalJson round-trip accurately', () {
      final original = PrayerTimeData(
        fajr: '05:00',
        sunrise: '06:15',
        dhuhr: '12:00',
        asr: '15:30',
        maghrib: '18:00',
        isha: '19:30',
        sunset: '18:00',
        imsak: '04:50',
        gregorianDate: '19 Aug 2026',
        hijriDate: '06 Safar 1448',
        hijriMonth: 'Safar',
        hijriYear: '1448',
      );

      final json = original.toJson();
      final restored = PrayerTimeData.fromLocalJson(json);

      expect(restored.fajr, equals('05:00'));
      expect(restored.sunrise, equals('06:15'));
      expect(restored.dhuhr, equals('12:00'));
      expect(restored.asr, equals('15:30'));
      expect(restored.maghrib, equals('18:00'));
      expect(restored.isha, equals('19:30'));
      expect(restored.sunset, equals('18:00'));
      expect(restored.imsak, equals('04:50'));
      expect(restored.gregorianDate, equals('19 Aug 2026'));
      expect(restored.hijriDate, equals('06 Safar 1448'));
      expect(restored.hijriMonth, equals('Safar'));
      expect(restored.hijriYear, equals('1448'));
    });

    test('fromJson parses AlAdhan API responses correctly', () {
      final apiResponse = {
        'timings': {
          'Fajr': '04:15',
          'Sunrise': '05:40',
          'Dhuhr': '11:55',
          'Asr': '15:20',
          'Sunset': '18:10',
          'Maghrib': '18:10',
          'Isha': '19:40',
          'Imsak': '04:05',
        },
        'date': {
          'readable': '19 Aug 2026',
          'hijri': {
            'day': '6',
            'year': '1448',
            'month': {'en': 'Safar'},
          },
        },
      };

      final parsed = PrayerTimeData.fromJson(apiResponse);
      expect(parsed.fajr, equals('04:15'));
      expect(parsed.sunrise, equals('05:40'));
      expect(parsed.dhuhr, equals('11:55'));
      expect(parsed.asr, equals('15:20'));
      expect(parsed.maghrib, equals('18:10'));
      expect(parsed.isha, equals('19:40'));
      expect(parsed.gregorianDate, equals('19 Aug 2026'));
      expect(parsed.hijriYear, equals('1448'));
    });

    test('fromPrayZone parses fallback format correctly', () {
      final prayZoneData = {
        'Fajr': '04:20',
        'Sunrise': '05:45',
        'Dhuhr': '12:00',
        'Asr': '15:25',
        'Maghrib': '18:15',
        'Isha': '19:45',
        'Sunset': '18:15',
        'Imsak': '04:10',
      };

      final parsed = PrayerTimeData.fromPrayZone(prayZoneData);
      expect(parsed.fajr, equals('04:20'));
      expect(parsed.dhuhr, equals('12:00'));
      expect(parsed.asr, equals('15:25'));
      expect(parsed.maghrib, equals('18:15'));
      expect(parsed.isha, equals('19:45'));
    });
  });
}
