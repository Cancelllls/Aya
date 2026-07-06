import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static const int _version = 3;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._();
      _database = await _initDatabase();
    }
    return _instance!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'aya_app.db');
    final db = await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _seedQuranData(db);
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Quran Surahs table
    await db.execute('''
      CREATE TABLE surahs (
        number INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        englishName TEXT NOT NULL,
        englishNameTranslation TEXT NOT NULL,
        numberOfAyahs INTEGER NOT NULL,
        revelationType TEXT NOT NULL
      )
    ''');

    // Quran Ayahs table
    await db.execute('''
      CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        global_number INTEGER NOT NULL,
        text_arabic TEXT NOT NULL,
        text_english TEXT NOT NULL,
        tafsir TEXT,
        juz INTEGER,
        hizb INTEGER,
        FOREIGN KEY (surah_number) REFERENCES surahs (number)
      )
    ''');
    await db.execute('CREATE INDEX idx_ayahs_surah ON ayahs(surah_number)');

    // Prayer times cache table
    await db.execute('''
      CREATE TABLE prayer_times_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cache_key TEXT UNIQUE NOT NULL,
        fajr TEXT, sunrise TEXT, dhuhr TEXT, asr TEXT,
        maghrib TEXT, isha TEXT, sunset TEXT, imsak TEXT,
        gregorian_date TEXT, hijri_date TEXT, hijri_month TEXT, hijri_year TEXT,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(surah_number, ayah_number)
      )
    ''');

    // Custom dhikrs table
    await db.execute('''
      CREATE TABLE custom_dhikrs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        arabic TEXT NOT NULL,
        translation TEXT,
        target INTEGER DEFAULT 33,
        current_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Monthly prayer calendar cache
    await db.execute('''
      CREATE TABLE monthly_prayer_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        day INTEGER NOT NULL,
        fajr TEXT, sunrise TEXT, dhuhr TEXT, asr TEXT,
        maghrib TEXT, isha TEXT, sunset TEXT, imsak TEXT,
        hijri_day TEXT, hijri_month TEXT, hijri_year TEXT,
        cached_at INTEGER NOT NULL,
        UNIQUE(year, month, day)
      )
    ''');

    // Audio download status tracking
    await db.execute('''
      CREATE TABLE audio_downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reciter_id TEXT NOT NULL,
        audio_type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        file_size INTEGER,
        downloaded_at INTEGER NOT NULL,
        UNIQUE(reciter_id, audio_type)
      )
    ''');

    // Create indexes for fast lookups
    await db.execute(
      'CREATE INDEX idx_prayer_cache_key ON prayer_times_cache(cache_key)',
    );
    await db.execute(
      'CREATE INDEX idx_bookmarks_surah ON bookmarks(surah_number)',
    );
    await db.execute(
      'CREATE INDEX idx_monthly_date ON monthly_prayer_cache(year, month)',
    );

    // Prayer Tracker
    await db.execute('''
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
    await db.execute(
      'CREATE INDEX idx_prayer_tracker_date ON prayer_tracker(date)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
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
      await db.execute(
        'CREATE INDEX idx_prayer_tracker_date ON prayer_tracker(date)',
      );
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS ayahs');
      await db.execute('DROP TABLE IF EXISTS surahs');
      
      // Quran Surahs table
      await db.execute('''
        CREATE TABLE surahs (
          number INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          englishName TEXT NOT NULL,
          englishNameTranslation TEXT NOT NULL,
          numberOfAyahs INTEGER NOT NULL,
          revelationType TEXT NOT NULL
        )
      ''');

      // Quran Ayahs table
      await db.execute('''
        CREATE TABLE ayahs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          surah_number INTEGER NOT NULL,
          ayah_number INTEGER NOT NULL,
          global_number INTEGER NOT NULL,
          text_arabic TEXT NOT NULL,
          text_english TEXT NOT NULL,
          tafsir TEXT,
          juz INTEGER,
          hizb INTEGER,
          FOREIGN KEY (surah_number) REFERENCES surahs (number)
        )
      ''');
      await db.execute('CREATE INDEX idx_ayahs_surah ON ayahs(surah_number)');
    }
  }

  static Future<void> _seedQuranData(Database db) async {
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM surahs'));
      if (count == 0) {
        final String surahsStr = await rootBundle.loadString('assets/quran/surahs.json');
        final List<dynamic> surahs = jsonDecode(surahsStr);
        Batch batch = db.batch();
        for (var s in surahs) {
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

        final String ayahsStr = await rootBundle.loadString('assets/quran/quran_hafs.json');
        final List<dynamic> quranData = jsonDecode(ayahsStr);
        batch = db.batch();
        for (var editions in quranData) {
          final arabic = editions[0]['ayahs'];
          final english = editions[1]['ayahs'];
          final tafsir = editions.length > 2 ? editions[2]['ayahs'] : null;
          
          for (int i = 0; i < arabic.length; i++) {
            final hizbQuarter = arabic[i]['hizbQuarter'] as int? ?? 1;
            final calculatedHizb = ((hizbQuarter - 1) ~/ 4) + 1;
            batch.insert('ayahs', {
              'surah_number': editions[0]['number'],
              'ayah_number': arabic[i]['numberInSurah'],
              'global_number': arabic[i]['number'],
              'text_arabic': arabic[i]['text'],
              'text_english': english[i]['text'],
              'tafsir': tafsir != null ? tafsir[i]['text'] : null,
              'juz': arabic[i]['juz'],
              'hizb': calculatedHizb,
            });
          }
        }
        await batch.commit(noResult: true);
      }
    } catch (e) {
      print('Failed to seed Quran data: $e');
    }
  }

  // ── Quran Data ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSurahs() async {
    final db = _database!;
    return await db.query('surahs', orderBy: 'number ASC');
  }

  Future<List<Map<String, dynamic>>> getAyahsForSurah(int surahNumber) async {
    final db = _database!;
    return await db.query('ayahs', where: 'surah_number = ?', whereArgs: [surahNumber], orderBy: 'ayah_number ASC');
  }

  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    final db = _database!;
    final queryClean = _stripTashkeel(query).toLowerCase();

    final results = await db.rawQuery('''
      SELECT ayahs.*, surahs.name as surah_name, surahs.englishName as surah_englishName 
      FROM ayahs 
      JOIN surahs ON ayahs.surah_number = surahs.number 
      ORDER BY ayahs.surah_number ASC, ayahs.ayah_number ASC
    ''');

    return results.where((row) {
      final arabicClean = _stripTashkeel((row['text_arabic'] as String?) ?? '');
      final english = (row['text_english'] as String?)?.toLowerCase() ?? '';
      return arabicClean.contains(queryClean) || english.contains(queryClean);
    }).toList();
  }

  String _stripTashkeel(String input) {
    final RegExp tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
    return input.replaceAll(tashkeelRegex, '');
  }

  // ── Prayer Times Cache ──────────────────────────────────────
  Future<void> cachePrayerTimes(String key, Map<String, dynamic> data) async {
    final db = _database!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + const Duration(hours: 12).inMilliseconds;

    await db.insert('prayer_times_cache', {
      'cache_key': key,
      'fajr': data['Fajr'],
      'sunrise': data['Sunrise'],
      'dhuhr': data['Dhuhr'],
      'asr': data['Asr'],
      'maghrib': data['Maghrib'],
      'isha': data['Isha'],
      'sunset': data['Sunset'],
      'imsak': data['Imsak'],
      'gregorian_date': data['gregorian_date'],
      'hijri_date': data['hijri_date'],
      'hijri_month': data['hijri_month'],
      'hijri_year': data['hijri_year'],
      'cached_at': now,
      'expires_at': expires,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedPrayerTimes(String key) async {
    final db = _database!;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times_cache',
      where: 'cache_key = ? AND expires_at > ?',
      whereArgs: [key, now],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return {
      'Fajr': map['fajr'],
      'Sunrise': map['sunrise'],
      'Dhuhr': map['dhuhr'],
      'Asr': map['asr'],
      'Maghrib': map['maghrib'],
      'Isha': map['isha'],
      'Sunset': map['sunset'],
      'Imsak': map['imsak'],
      'gregorian_date': map['gregorian_date'],
      'hijri_date': map['hijri_date'],
      'hijri_month': map['hijri_month'],
      'hijri_year': map['hijri_year'],
    };
  }

  // ── Bookmarks ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = _database!;
    return await db.query('bookmarks', orderBy: 'created_at DESC');
  }

  Future<void> addBookmark(int surah, String name, int ayah) async {
    final db = _database!;

    // Remove any existing bookmark for this surah first so we only keep the last one.
    // This prevents the reciter from flooding the bookmarks list with every ayah played.
    await db.delete('bookmarks', where: 'surah_number = ?', whereArgs: [surah]);

    await db.insert('bookmarks', {
      'surah_number': surah,
      'surah_name': name,
      'ayah_number': ayah,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeBookmark(int surah, {int? ayah}) async {
    final db = _database!;
    if (ayah != null) {
      await db.delete(
        'bookmarks',
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: [surah, ayah],
      );
    } else {
      await db.delete(
        'bookmarks',
        where: 'surah_number = ?',
        whereArgs: [surah],
      );
    }
  }

  Future<void> clearAllBookmarks() async {
    final db = _database!;
    await db.delete('bookmarks');
  }

  // ── Custom Dhikrs ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCustomDhikrs() async {
    final db = _database!;
    return await db.query('custom_dhikrs', orderBy: 'created_at ASC');
  }

  Future<void> addCustomDhikr({
    required String id,
    required String name,
    required String arabic,
    String? translation,
    int target = 33,
    int currentCount = 0,
  }) async {
    final db = _database!;
    await db.insert('custom_dhikrs', {
      'id': id,
      'name': name,
      'arabic': arabic,
      'translation': translation,
      'target': target,
      'current_count': currentCount,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDhikrCount(String id, int count) async {
    final db = _database!;
    await db.update(
      'custom_dhikrs',
      {'current_count': count},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCustomDhikr(String id) async {
    final db = _database!;
    await db.delete('custom_dhikrs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllCustomDhikrs() async {
    final db = _database!;
    await db.delete('custom_dhikrs');
  }

  // ── Audio Downloads ────────────────────────────────────────
  Future<bool> isAudioDownloaded(String reciterId, String type) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'audio_downloads',
      where: 'reciter_id = ? AND audio_type = ?',
      whereArgs: [reciterId, type],
    );
    return maps.isNotEmpty;
  }

  Future<void> markAudioDownloaded(
    String reciterId,
    String type,
    String path,
  ) async {
    final db = _database!;
    await db.insert('audio_downloads', {
      'reciter_id': reciterId,
      'audio_type': type,
      'local_path': path,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Prayer Tracker ────────────────────────────────────────
  Future<Map<String, dynamic>> getPrayerTracker(String date) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_tracker',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return {
      'date': date,
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    };
  }

  Future<void> updatePrayerTracker(
    String date,
    String prayer,
    int status,
  ) async {
    final db = _database!;
    final maps = await db.query(
      'prayer_tracker',
      where: 'date = ?',
      whereArgs: [date],
    );

    Map<String, dynamic> row;
    if (maps.isEmpty) {
      row = {
        'date': date,
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
    } else {
      row = Map<String, dynamic>.from(maps.first);
    }

    row[prayer] = status;
    row.remove('id');

    await db.insert(
      'prayer_tracker',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPrayerTrackerRange(
    String startDate,
    String endDate,
  ) async {
    final db = _database!;
    return await db.query(
      'prayer_tracker',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }
}
