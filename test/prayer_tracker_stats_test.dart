import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/prayer_tracker_stats_service.dart';

void main() {
  group('PrayerTrackerStatsCalculator Tests', () {
    final today = DateTime(2026, 9, 29); // Tuesday

    test('Empty tracker data returns zero stats', () {
      final stats = PrayerTrackerStatsCalculator.calculateStats(
        start: DateTime(2026, 9, 28),
        end: DateTime(2026, 10, 4),
        today: today,
        trackerData: {},
        isPrayerPassedToday: (_) => true,
      );

      expect(stats['prayed'], 0);
      expect(stats['missed'], 0);
      expect(stats['total'], 0);
    });

    test('User tracking only today at 07:00 AM (only Fajr passed and prayed)', () {
      // User prayed Fajr today; other prayers not yet due
      final trackerData = {
        '2026-09-29': {
          'date': '2026-09-29',
          'fajr': 1,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        },
      };

      // Only fajr has passed
      bool isPrayerPassedToday(String p) => p == 'fajr';

      final stats = PrayerTrackerStatsCalculator.calculateStats(
        start: DateTime(2026, 9, 28), // Monday
        end: DateTime(2026, 10, 4), // Sunday
        today: today,
        trackerData: trackerData,
        isPrayerPassedToday: isPrayerPassedToday,
      );

      // Should be 1 prayed, 0 missed, 1 total (100%), NOT 1 prayed, 4 missed!
      expect(stats['prayed'], 1);
      expect(stats['missed'], 0);
      expect(stats['total'], 1);
    });

    test('User missed Fajr today at 14:00 PM (Fajr and Dhuhr passed, user only prayed Dhuhr)', () {
      final trackerData = {
        '2026-09-29': {
          'date': '2026-09-29',
          'fajr': 0,
          'dhuhr': 1,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        },
      };

      // Fajr and Dhuhr have passed, Asr/Maghrib/Isha have not
      bool isPrayerPassedToday(String p) => p == 'fajr' || p == 'dhuhr';

      final stats = PrayerTrackerStatsCalculator.calculateStats(
        start: DateTime(2026, 9, 28),
        end: DateTime(2026, 10, 4),
        today: today,
        trackerData: trackerData,
        isPrayerPassedToday: isPrayerPassedToday,
      );

      // 1 prayed (Dhuhr), 1 missed (Fajr), 2 total (50%)
      expect(stats['prayed'], 1);
      expect(stats['missed'], 1);
      expect(stats['total'], 2);
    });

    test('User tracking multiple days this week', () {
      // Monday: 5/5 prayed
      // Tuesday (today at night): all 5 passed, user prayed 4, missed 1 (Asr)
      final trackerData = {
        '2026-09-28': {
          'date': '2026-09-28',
          'fajr': 1,
          'dhuhr': 1,
          'asr': 1,
          'maghrib': 1,
          'isha': 1,
        },
        '2026-09-29': {
          'date': '2026-09-29',
          'fajr': 1,
          'dhuhr': 1,
          'asr': 0,
          'maghrib': 1,
          'isha': 1,
        },
      };

      bool isPrayerPassedToday(String p) => true; // All passed at night

      final stats = PrayerTrackerStatsCalculator.calculateStats(
        start: DateTime(2026, 9, 28),
        end: DateTime(2026, 10, 4),
        today: today,
        trackerData: trackerData,
        isPrayerPassedToday: isPrayerPassedToday,
      );

      // Monday: 5 prayed, 0 missed
      // Tuesday: 4 prayed, 1 missed
      // Total: 9 prayed, 1 missed, 10 total
      expect(stats['prayed'], 9);
      expect(stats['missed'], 1);
      expect(stats['total'], 10);
    });

    test('Days before user began tracking are not counted as missed', () {
      // Today is Tuesday. User only started tracking on Tuesday.
      // Monday had no tracking record and was before user started.
      final trackerData = {
        '2026-09-29': {
          'date': '2026-09-29',
          'fajr': 1,
          'dhuhr': 1,
          'asr': 1,
          'maghrib': 1,
          'isha': 1,
        },
      };

      final stats = PrayerTrackerStatsCalculator.calculateStats(
        start: DateTime(2026, 9, 1), // Month started Sep 1
        end: DateTime(2026, 9, 30),
        today: today,
        trackerData: trackerData,
        isPrayerPassedToday: (_) => true,
      );

      // Should only count from Sep 29 onwards: 5 prayed, 0 missed, 5 total
      // NOT 140 missed prayers from Sep 1 to Sep 28!
      expect(stats['prayed'], 5);
      expect(stats['missed'], 0);
      expect(stats['total'], 5);
    });
  });
}
