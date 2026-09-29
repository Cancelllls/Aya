class PrayerTrackerStatsCalculator {
  static const List<String> prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// Computes accurate prayer statistics for a period [start, end].
  ///
  /// - Unpassed prayers today are not counted as missed.
  /// - Only counts from the earliest date the user actually began tracking prayers.
  /// - Returns {'prayed': int, 'missed': int, 'total': int}.
  static Map<String, int> calculateStats({
    required DateTime start,
    required DateTime end,
    required DateTime today,
    required Map<String, Map<String, dynamic>> trackerData,
    required bool Function(String prayerKey) isPrayerPassedToday,
  }) {
    // 1. Find earliest date where user tracked prayers
    DateTime? earliestDate;
    for (final entry in trackerData.entries) {
      final data = entry.value;
      bool hasAnyMarked = false;
      for (final p in prayers) {
        if ((data[p] as int? ?? 0) > 0) {
          hasAnyMarked = true;
          break;
        }
      }
      if (hasAnyMarked) {
        try {
          final d = DateTime.parse(entry.key);
          final cleanD = DateTime(d.year, d.month, d.day);
          if (earliestDate == null || cleanD.isBefore(earliestDate)) {
            earliestDate = cleanD;
          }
        } catch (_) {}
      }
    }

    if (earliestDate == null) {
      return {'prayed': 0, 'missed': 0, 'total': 0};
    }

    final cleanStart = DateTime(start.year, start.month, start.day);
    final cleanEnd = DateTime(end.year, end.month, end.day);
    final cleanToday = DateTime(today.year, today.month, today.day);

    // Only count from the day the user actually began tracking prayers
    final effectiveStart = earliestDate.isAfter(cleanStart) ? earliestDate : cleanStart;

    int prayed = 0;
    int missed = 0;

    DateTime curr = effectiveStart;
    while (!curr.isAfter(cleanEnd) && !curr.isAfter(cleanToday)) {
      final dateStr =
          "${curr.year.toString().padLeft(4, '0')}-${curr.month.toString().padLeft(2, '0')}-${curr.day.toString().padLeft(2, '0')}";
      final dayData = trackerData[dateStr] ?? {};

      final isCurrentDay = curr.year == cleanToday.year &&
          curr.month == cleanToday.month &&
          curr.day == cleanToday.day;

      for (final p in prayers) {
        final val = dayData[p] as int? ?? 0;
        if (val > 0) {
          prayed++;
        } else {
          if (isCurrentDay) {
            // For today, only count as missed if prayer time has already passed
            if (isPrayerPassedToday(p)) {
              missed++;
            }
          } else {
            // For past days since tracking began, unprayed prayers are missed
            missed++;
          }
        }
      }

      curr = curr.add(const Duration(days: 1));
    }

    // Also count any future days in the period that might have been explicitly pre-marked
    DateTime futureCurr = cleanToday.add(const Duration(days: 1));
    while (!futureCurr.isAfter(cleanEnd)) {
      final dateStr =
          "${futureCurr.year.toString().padLeft(4, '0')}-${futureCurr.month.toString().padLeft(2, '0')}-${futureCurr.day.toString().padLeft(2, '0')}";
      final dayData = trackerData[dateStr];
      if (dayData != null) {
        for (final p in prayers) {
          if ((dayData[p] as int? ?? 0) > 0) {
            prayed++;
          }
        }
      }
      futureCurr = futureCurr.add(const Duration(days: 1));
    }

    final total = prayed + missed;
    return {'prayed': prayed, 'missed': missed, 'total': total};
  }
}
