import 'dart:io';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String stripTashkeel(String input) {
  var result = input
      .replaceAll(RegExp(r'[ً-ٰٟۖ-ۭ]'), '')
      .replaceAll(RegExp(r'[أإآٱء]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '')
      .replaceAll('﻿', '');
  while (result.contains('اا')) {
    result = result.replaceAll('اا', 'ا');
  }
  return result;
}

Future<void> main() async {
  print('=== Generating Aya Pre-Seeded SQLite Database (aya_seed.db) ===');
  final stopwatch = Stopwatch()..start();

  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;

  final outputDir = Directory('assets/db');
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  final dbFile = File('assets/db/aya_seed.db');
  final dbPath = dbFile.absolute.path;
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('Removed existing $dbPath');
  }

  final db = await dbFactory.openDatabase(dbPath);

  try {
    print('Enabling WAL and memory PRAGMAs...');
    await db.execute('PRAGMA journal_mode=WAL;');
    await db.execute('PRAGMA synchronous=NORMAL;');

    print('Creating tables...');
    await db.execute('''
      CREATE TABLE surahs (
        number INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        englishName TEXT NOT NULL,
        englishNameTranslation TEXT NOT NULL,
        numberOfAyahs INTEGER NOT NULL,
        revelationType TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        global_number INTEGER NOT NULL,
        text_arabic TEXT NOT NULL,
        text_arabic_clean TEXT NOT NULL,
        text_english TEXT NOT NULL,
        tafsir TEXT,
        juz INTEGER,
        hizb INTEGER,
        page INTEGER DEFAULT 1,
        FOREIGN KEY (surah_number) REFERENCES surahs (number)
      );
    ''');
    await db.execute('CREATE INDEX idx_ayahs_surah ON ayahs(surah_number);');
    await db.execute('CREATE INDEX idx_ayahs_page ON ayahs(page);');

    // FTS5 Virtual Tables
    await db.execute('''
      CREATE VIRTUAL TABLE ayahs_fts USING fts5(
        text_arabic_clean, text_english,
        tokenize='unicode61 remove_diacritics 2'
      );
    ''');

    await db.execute('''
      CREATE VIRTUAL TABLE hadiths_fts USING fts5(
        search_arabic, search_english,
        tokenize='unicode61 remove_diacritics 2'
      );
    ''');

    // Auxiliary tables for full schema readiness
    await db.execute('''
      CREATE TABLE prayer_times_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cache_key TEXT UNIQUE NOT NULL,
        fajr TEXT, sunrise TEXT, dhuhr TEXT, asr TEXT,
        maghrib TEXT, isha TEXT, sunset TEXT, imsak TEXT,
        gregorian_date TEXT, hijri_date TEXT, hijri_month TEXT, hijri_year TEXT,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(surah_number, ayah_number)
      );
    ''');

    await db.execute('''
      CREATE TABLE prayer_tracker (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL,
        fajr INTEGER DEFAULT 0,
        dhuhr INTEGER DEFAULT 0,
        asr INTEGER DEFAULT 0,
        maghrib INTEGER DEFAULT 0,
        isha INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE custom_dhikrs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        arabic TEXT NOT NULL,
        translation TEXT,
        target INTEGER DEFAULT 33,
        current_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');

    print('Reading Surahs asset...');
    final surahsFile = File('assets/quran/surahs.json');
    final List<dynamic> surahs = jsonDecode(await surahsFile.readAsString());
    var batch = db.batch();
    for (final s in surahs) {
      batch.insert('surahs', {
        'number': s['number'],
        'name': s['name'],
        'englishName': s['englishName'],
        'englishNameTranslation': s['englishNameTranslation'],
        'numberOfAyahs': s['numberOfAyahs'],
        'revelationType': s['revelationType'],
      });
    }
    await batch.commit(noResult: true);
    print('Inserted ${surahs.length} surahs.');

    print('Reading Hafs Quran asset (14MB)...');
    final hafsFile = File('assets/quran/quran_hafs.json');
    final List<dynamic> quranData = jsonDecode(await hafsFile.readAsString());

    print('Populating ayahs...');
    batch = db.batch();
    int count = 0;
    for (final editions in quranData) {
      final arabic = editions[0]['ayahs'] as List<dynamic>;
      final english = editions[1]['ayahs'] as List<dynamic>;
      final tafsir = editions.length > 2 ? editions[2]['ayahs'] as List<dynamic>? : null;

      for (int i = 0; i < arabic.length; i++) {
        final hizbQuarter = arabic[i]['hizbQuarter'] as int? ?? 1;
        final calculatedHizb = ((hizbQuarter - 1) ~/ 4) + 1;
        final page = arabic[i]['page'] as int? ?? 1;
        final textAr = arabic[i]['text'] as String? ?? '';
        final textEn = english[i]['text'] as String? ?? '';

        batch.insert('ayahs', {
          'surah_number': editions[0]['number'],
          'ayah_number': arabic[i]['numberInSurah'],
          'global_number': arabic[i]['number'],
          'text_arabic': textAr,
          'text_arabic_clean': stripTashkeel(textAr).toLowerCase(),
          'text_english': textEn,
          'tafsir': tafsir != null ? tafsir[i]['text'] : null,
          'juz': arabic[i]['juz'],
          'hizb': calculatedHizb,
          'page': page,
        });
        count++;
      }
    }
    await batch.commit(noResult: true);
    print('Inserted $count ayahs.');

    print('Indexing into ayahs_fts virtual table...');
    await db.execute('''
      INSERT INTO ayahs_fts(rowid, text_arabic_clean, text_english)
      SELECT id, text_arabic_clean, text_english FROM ayahs;
    ''');

    print('Optimizing SQLite storage...');
    await db.execute('PRAGMA optimize;');
    await db.execute('VACUUM;');

    final fileStat = await File(dbPath).stat();
    final mb = (fileStat.size / (1024 * 1024)).toStringAsFixed(2);
    stopwatch.stop();

    print('SUCCESS: Generated $dbPath ($mb MB) in ${stopwatch.elapsedMilliseconds}ms.');
  } finally {
    await db.close();
  }
}
