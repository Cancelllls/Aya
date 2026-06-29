import re

with open('lib/services/database_service.dart', 'r') as f:
    content = f.read()

old_func = """  Future<void> updatePrayerTracker(
    String date,
    String prayer,
    int status,
  ) async {
    // ponytail: single raw SQL upsert instead of select-then-replace
    await _database!.execute(
      'INSERT INTO prayer_tracker (date, $prayer) VALUES (?, ?) '
      'ON CONFLICT(date) DO UPDATE SET $prayer = excluded.$prayer',
      [date, status],
    );
  }"""

new_func = """  Future<void> updatePrayerTracker(
    String date,
    String prayer,
    int status,
  ) async {
    final maps = await _database!.query('prayer_tracker', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) {
      await _database!.insert('prayer_tracker', {'date': date, prayer: status});
    } else {
      await _database!.update('prayer_tracker', {prayer: status}, where: 'date = ?', whereArgs: [date]);
    }
  }"""

if old_func in content:
    content = content.replace(old_func, new_func)
    with open('lib/services/database_service.dart', 'w') as f:
        f.write(content)
else:
    print("Function not found!")
