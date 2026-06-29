import re

with open('lib/services/database_service.dart', 'r') as f:
    content = f.read()

old_code = """  Future<void> updatePrayerTracker(
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

new_code = """  Future<void> updatePrayerTracker(
    String date,
    String prayer,
    int status,
  ) async {
    final maps = await _database!.query('prayer_tracker', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) {
      await _database!.execute('INSERT INTO prayer_tracker (date, $prayer) VALUES (?, ?)', [date, status]);
    } else {
      await _database!.execute('UPDATE prayer_tracker SET $prayer = ? WHERE date = ?', [status, date]);
    }
  }"""

if old_code in content:
    content = content.replace(old_code, new_code)
    with open('lib/services/database_service.dart', 'w') as f:
        f.write(content)
else:
    print("Code not found")
