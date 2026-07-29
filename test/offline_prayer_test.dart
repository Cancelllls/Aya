import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/offline_prayer_service.dart';
import 'package:aya_app/models/prayer_models.dart';

void main() {
  group('OfflinePrayerService', () {
    test('calculates prayer times for Cairo', () async {
      final data = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0444,
        longitude: 31.2357,
        method: 5,
        school: 0,
      );
      expect(data, isA<PrayerTimeData>());
      expect(data.fajr, isNotEmpty);
      expect(data.dhuhr, isNotEmpty);
      expect(data.asr, isNotEmpty);
      expect(data.maghrib, isNotEmpty);
      expect(data.isha, isNotEmpty);
    });

    test('calculates prayer times for Mecca', () async {
      final data = await OfflinePrayerService.getPrayerTimes(
        latitude: 21.4225,
        longitude: 39.8262,
        method: 4,
        school: 0,
      );
      expect(data, isA<PrayerTimeData>());
      expect(data.fajr, isNotEmpty);
    });

    test('calculates with Hanafi asr method', () async {
      final data = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0444,
        longitude: 31.2357,
        method: 5,
        school: 1,
      );
      expect(data.asr, isNotEmpty);
    });

    test('calculates for high-latitude location (Oslo)', () async {
      final data = await OfflinePrayerService.getPrayerTimes(
        latitude: 59.9139,
        longitude: 10.7522,
        method: 2,
        school: 0,
      );
      expect(data.fajr, isNotEmpty);
    });

    test('times are formatted as HH:MM', () async {
      final data = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0,
        longitude: 31.0,
        method: 5, school: 0,
      );
      final timePattern = RegExp(r'^\d{2}:\d{2}');
      expect(timePattern.hasMatch(data.fajr.trim().split(' ')[0]), isTrue);
      expect(timePattern.hasMatch(data.isha.trim().split(' ')[0]), isTrue);
    });

    test('different calculation methods produce different times', () async {
      final dataIsna = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0, longitude: 31.0, method: 2, school: 0,
      );
      final dataMakkah = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0, longitude: 31.0, method: 4, school: 0,
      );
      // Fajr times should differ between ISNA (15°) and Umm Al-Qura (18.5°)
      expect(dataIsna.fajr, isNot(dataMakkah.fajr));
    });

    test('monthly calendar generates 28-31 days', () async {
      final month = await OfflinePrayerService.getMonthlyCalendar(
        month: 7, year: 2026,
        latitude: 30.0, longitude: 31.0, method: 5, school: 0,
      );
      expect(month.length, greaterThanOrEqualTo(28));
      expect(month.length, lessThanOrEqualTo(31));
      for (final day in month) {
        expect(day['Fajr'], isNotEmpty);
        expect(day['Isha'], isNotEmpty);
      }
    });
  });
}
