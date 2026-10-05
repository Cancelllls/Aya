import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aya_app/services/offline_prayer_service.dart';
import 'package:aya_app/services/storage/prayer_preferences.dart';
import 'package:aya_app/services/storage_service.dart';
import 'package:aya_app/models/prayer_models.dart';

void main() {
  group('OfflinePrayerService', () {
    setUp(() {
      StorageService.resetForTesting();
    });
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
        method: 5,
        school: 0,
      );
      final timePattern = RegExp(r'^\d{2}:\d{2}');
      expect(timePattern.hasMatch(data.fajr.trim().split(' ')[0]), isTrue);
      expect(timePattern.hasMatch(data.isha.trim().split(' ')[0]), isTrue);
    });

    test('different calculation methods produce different times', () async {
      final dataIsna = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0,
        longitude: 31.0,
        method: 2,
        school: 0,
      );
      final dataMakkah = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0,
        longitude: 31.0,
        method: 4,
        school: 0,
      );
      // Fajr times should differ between ISNA (15°) and Umm Al-Qura (18.5°)
      expect(dataIsna.fajr, isNot(dataMakkah.fajr));
    });

    test(
      'calculates prayer times for Baghdad using Sunni Endowment Iraq (method 6)',
      () async {
        final dataIraq = await OfflinePrayerService.getPrayerTimes(
          latitude: 33.3152,
          longitude: 44.3661,
          method: 6,
          school: 0,
        );
        expect(dataIraq, isA<PrayerTimeData>());
        expect(dataIraq.fajr, isNotEmpty);
        expect(dataIraq.dhuhr, isNotEmpty);
        expect(dataIraq.asr, isNotEmpty);
        expect(dataIraq.maghrib, isNotEmpty);
        expect(dataIraq.isha, isNotEmpty);

        // Method 6 (Sunni Endowment Iraq 19.5°/17.5°) should match Method 5 (Egyptian 19.5°/17.5°)
        final dataEgypt = await OfflinePrayerService.getPrayerTimes(
          latitude: 33.3152,
          longitude: 44.3661,
          method: 5,
          school: 0,
        );
        expect(dataIraq.fajr, equals(dataEgypt.fajr));
        expect(dataIraq.isha, equals(dataEgypt.isha));
      },
    );

    test('monthly calendar generates 28-31 days', () async {
      final month = await OfflinePrayerService.getMonthlyCalendar(
        month: 7,
        year: 2026,
        latitude: 30.0,
        longitude: 31.0,
        method: 5,
        school: 0,
      );
      expect(month.length, greaterThanOrEqualTo(28));
      expect(month.length, lessThanOrEqualTo(31));
      for (final day in month) {
        expect(day['timings']['Fajr'], isNotEmpty);
        expect(day['timings']['Isha'], isNotEmpty);
      }
    });

    test(
      'PrayerPreferences determineSmartCalculationMethod detects Iraq cities',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final prayerPrefs = PrayerPreferences(prefs);

        expect(
          prayerPrefs.determineSmartCalculationMethod('Baghdad', 'Iraq'),
          6,
        );
        expect(
          prayerPrefs.determineSmartCalculationMethod('بغداد', 'العراق'),
          6,
        );
        expect(prayerPrefs.determineSmartCalculationMethod('Mosul', 'Iraq'), 6);
        expect(prayerPrefs.determineSmartCalculationMethod('Erbil', 'Iraq'), 6);
        expect(prayerPrefs.determineSmartCalculationMethod('Basra', 'Iraq'), 6);
      },
    );

    test('Auto method (0) resolves to Egyptian Survey for Cairo', () async {
      SharedPreferences.setMockInitialValues({
        'user_location':
            '{"city":"Cairo","country":"Egypt","latitude":30.0444,"longitude":31.2357,"source":"default"}',
      });

      final autoData = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0444,
        longitude: 31.2357,
        method: 0,
        school: 0,
      );
      final egyptData = await OfflinePrayerService.getPrayerTimes(
        latitude: 30.0444,
        longitude: 31.2357,
        method: 5,
        school: 0,
      );

      expect(autoData.fajr, equals(egyptData.fajr));
      expect(autoData.isha, equals(egyptData.isha));
    });

    test('Custom method (-1) calculates accurately with custom angles', () async {
      SharedPreferences.setMockInitialValues({});

      final customData = await OfflinePrayerService.getPrayerTimes(
        latitude: 51.5074,
        longitude: -0.1278,
        method: -1,
        school: 0,
        customFajr: 16.0,
        customIsha: 14.5,
      );

      expect(customData, isA<PrayerTimeData>());
      expect(customData.fajr, isNotEmpty);
      expect(customData.isha, isNotEmpty);

      // A 19.5° Fajr angle should trigger earlier in the morning than a 12.0° Fajr angle
      final earlyFajr = await OfflinePrayerService.getPrayerTimes(
        latitude: 51.5074,
        longitude: -0.1278,
        method: -1,
        school: 0,
        customFajr: 19.5,
        customIsha: 15.0,
      );
      final lateFajr = await OfflinePrayerService.getPrayerTimes(
        latitude: 51.5074,
        longitude: -0.1278,
        method: -1,
        school: 0,
        customFajr: 12.0,
        customIsha: 15.0,
      );
      expect(earlyFajr.fajr, isNot(equals(lateFajr.fajr)));
    });

    test(
      'Custom method (-1) reads angles from SharedPreferences fallback',
      () async {
        SharedPreferences.setMockInitialValues({
          'custom_fajr_angle': 16.0,
          'custom_isha_angle': 14.0,
        });

        final customData = await OfflinePrayerService.getPrayerTimes(
          latitude: 30.0444,
          longitude: 31.2357,
          method: -1,
          school: 0,
        );
        expect(customData.fajr, isNotEmpty);
        expect(customData.isha, isNotEmpty);
      },
    );

    test('get30DaysScheduleJson supports Auto (0) and Custom (-1)', () async {
      SharedPreferences.setMockInitialValues({
        'user_location':
            '{"city":"Cairo","country":"Egypt","latitude":30.0444,"longitude":31.2357}',
        'custom_fajr_angle': 16.0,
        'custom_isha_angle': 14.0,
      });

      final autoSchedule = await OfflinePrayerService.get30DaysScheduleJson(
        latitude: 30.0444,
        longitude: 31.2357,
        method: 0,
        school: 0,
      );
      expect(autoSchedule, contains('f_ms'));

      final customSchedule = await OfflinePrayerService.get30DaysScheduleJson(
        latitude: 30.0444,
        longitude: 31.2357,
        method: -1,
        school: 0,
        customFajr: 16.0,
        customIsha: 14.0,
      );
      expect(customSchedule, contains('f_ms'));
    });
  });
}
