import re

with open('lib/screens/prayer_tracker_screen.dart', 'r') as f:
    content = f.read()

old_toggle = """  Future<void> _togglePrayerForDate(
    DateTime date,
    String prayer,
    int currentStatus,
  ) async {
    final db = await DatabaseService.getInstance();
    int nextStatus = currentStatus > 0 ? 0 : 1;
    final dateStr = _formatDate(date);

    // ponytail: Optimistic UI update, no heavy DB reload
    setState(() {
      if (_trackerData[dateStr] == null) _trackerData[dateStr] = {};
      _trackerData[dateStr]![prayer] = nextStatus;
    });

    await db.updatePrayerTracker(dateStr, prayer, nextStatus);

    // Silently reload stats in background
    _loadData(showLoading: false);
  }"""

new_toggle = """  Future<void> _togglePrayerForDate(
    DateTime date,
    String prayer,
    int currentStatus,
  ) async {
    final db = await DatabaseService.getInstance();
    int nextStatus = currentStatus > 0 ? 0 : 1;
    final dateStr = _formatDate(date);

    setState(() {
      if (_trackerData[dateStr] == null) {
        _trackerData[dateStr] = {
          'date': dateStr,
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        };
      }
      _trackerData[dateStr]![prayer] = nextStatus;
      _updateStatsLocally();
    });

    await db.updatePrayerTracker(dateStr, prayer, nextStatus);
  }

  void _updateStatsLocally() {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

    final list = _trackerData.values.toList();
    _calculateStats('yearly', yearStart, yearEnd, list);
    _calculateStats(
      'monthly',
      monthStart,
      monthEnd,
      list.where((e) {
        if (e['date'] == null) return false;
        final d = DateTime.parse(e['date'] as String);
        return d.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            d.isBefore(monthEnd.add(const Duration(days: 1)));
      }),
    );
    _calculateStats(
      'weekly',
      currentWeekStart,
      currentWeekEnd,
      list.where((e) {
        if (e['date'] == null) return false;
        final d = DateTime.parse(e['date'] as String);
        return d.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
            d.isBefore(currentWeekEnd.add(const Duration(days: 1)));
      }),
    );
  }"""

if old_toggle in content:
    content = content.replace(old_toggle, new_toggle)
    with open('lib/screens/prayer_tracker_screen.dart', 'w') as f:
        f.write(content)
else:
    print("Code not found")
