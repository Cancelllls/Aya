import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.openInMemory();
  db.execute('''
        CREATE TABLE prayer_tracker (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT UNIQUE NOT NULL,
          fajr INTEGER DEFAULT 0,
          dhuhr INTEGER DEFAULT 0,
          asr INTEGER DEFAULT 0,
          maghrib INTEGER DEFAULT 0,
          isha INTEGER DEFAULT 0
        )
  ''');

  // simulate insert
  db.execute("INSERT INTO prayer_tracker (date, fajr) VALUES ('2023-01-01', 1)");
  
  // simulate update
  db.execute("UPDATE prayer_tracker SET dhuhr = 1 WHERE date = '2023-01-01'");

  final result = db.select("SELECT * FROM prayer_tracker");
  print(result);
}
