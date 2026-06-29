import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var factory = databaseFactoryFfi;
  var db = await factory.openDatabase(inMemoryDatabasePath);
  await db.execute('''
      CREATE TABLE prayer_tracker (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL,
        fajr INTEGER DEFAULT 0
      )
  ''');
  
  try {
    await db.insert('prayer_tracker', {'date': '2023-01-01', 'Fajr': 1});
    print("Insert success");
  } catch(e) {
    print("Insert failed: $e");
  }
}
