import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/text_helpers.dart';
import 'hadith_database_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static const int _version = 12;
  // Keep in sync with android/app/build.gradle.kts applicationId
  static const String _packageName = 'com.quran.aya';

  HadithDatabaseService? _hadith;

  /// Hadith-specific operations. Available after [getInstance].
  HadithDatabaseService get hadith => _hadith!;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._();
      _database = await _initDatabase();
      _instance!._hadith = HadithDatabaseService(_database!);
    }
    return _instance!;
  }

  /// Resolves the databases directory path.
  /// Falls back to known Android locations when platform channels are
  /// unavailable (e.g. background isolate spawned by notification plugin).
  static Future<String> _databasesPath() async {
    try {
      return await getDatabasesPath();
    } catch (_) {
      for (final dir in <String>[
        '/data/data/$_packageName/databases',
        '/data/user/0/$_packageName/databases',
      ]) {
        if (await Directory(dir).exists()) return dir;
      }
      rethrow;
    }
  }

  static Future<Database> _initDatabase() async {
    final path = join(await _databasesPath(), 'aya_app.db');

    // Use bundled SQLite with FTS5 on Android/Linux via FFI.
    // iOS already has FTS5 in its system SQLite.
    if (!Platform.isIOS && !Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Fast-boot pre-seeded DB: If DB does not exist on disk, check if a pre-compiled
    // seed DB is bundled in assets. If present, copy directly for instant 0ms first launch.
    if (!await File(path).exists()) {
      try {
        final byteData = await rootBundle.load('assets/db/aya_seed.db');
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      } catch (_) {
        // Fallback to normal creation if seed DB asset is not bundled
      }
    }

    Database? db;
    try {
      db = await openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      // DB open failed — recreating
      try { await deleteDatabase(path); } catch (_) {}
      db = await openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    // Enable SQLite Write-Ahead Logging (WAL) and High-Performance PRAGMAs
    try {
      await db.execute('PRAGMA journal_mode=WAL;');
      await db.execute('PRAGMA synchronous=NORMAL;');
      await db.execute('PRAGMA cache_size=-64000;');
      await db.execute('PRAGMA temp_store=MEMORY;');
      await db.execute('PRAGMA mmap_size=268435456;');
      await db.execute('PRAGMA threads=4;');
    } catch (_) {}

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
        text_arabic_clean TEXT NOT NULL,
        text_english TEXT NOT NULL,
        tafsir TEXT,
        juz INTEGER,
        hizb INTEGER,
        page INTEGER DEFAULT 1,
        FOREIGN KEY (surah_number) REFERENCES surahs (number)
      )
    ''');
    await db.execute('CREATE INDEX idx_ayahs_surah ON ayahs(surah_number)');
    await db.execute('CREATE INDEX idx_ayahs_page ON ayahs(page)');

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

    // Offline Extra Tafsirs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS extra_tafsirs (
        edition_id TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY(edition_id, surah_number, ayah_number)
      )
    ''');

    // Offline Extra Translations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS extra_translations (
        edition_id TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY(edition_id, surah_number, ayah_number)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_extra_trans_lookup ON extra_translations(edition_id, surah_number)',
    );

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

    // Hadith books table
    await db.execute('''
      CREATE TABLE hadith_books (
        book_id TEXT PRIMARY KEY,
        lang TEXT NOT NULL,
        downloaded_at INTEGER NOT NULL
      )
    ''');

    // Hadiths table
    await db.execute('''
      CREATE TABLE hadiths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        hadith_number INTEGER,
        arabic TEXT NOT NULL,
        english TEXT NOT NULL,
        search_arabic TEXT NOT NULL,
        search_english TEXT NOT NULL,
        grades TEXT NOT NULL,
        FOREIGN KEY(book_id) REFERENCES hadith_books(book_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_hadiths_book ON hadiths(book_id)');

    // ── FTS5 full-text search (guaranteed by bundled SQLite via FFI) ──
    await db.execute('''
      CREATE VIRTUAL TABLE hadiths_fts USING fts5(
        search_arabic, search_english,
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS ayahs_fts USING fts5(
        text_arabic_clean, text_english,
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');

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
    await db.execute('''
      CREATE TABLE hadith_translations (
        text_hash TEXT PRIMARY KEY,
        source_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
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

    if (oldVersion < 4) {
      // Add text_arabic_clean column if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE ayahs ADD COLUMN text_arabic_clean TEXT DEFAULT ""',
        );
        final List<Map<String, dynamic>> allAyahs = await db.query(
          'ayahs',
          columns: ['id', 'text_arabic'],
        );
        Batch batch = db.batch();
        for (var row in allAyahs) {
          batch.update(
            'ayahs',
            {
              'text_arabic_clean': stripTashkeel(
                row['text_arabic'] as String? ?? '',
              ).toLowerCase(),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await batch.commit(noResult: true);
      } catch (e) {
        // v4 upgrade error — non-critical
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE hadith_books (
            book_id TEXT PRIMARY KEY,
            lang TEXT NOT NULL,
            downloaded_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE hadiths (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id TEXT NOT NULL,
            hadith_number INTEGER,
            arabic TEXT NOT NULL,
            english TEXT NOT NULL,
            search_arabic TEXT NOT NULL,
            search_english TEXT NOT NULL,
            grades TEXT NOT NULL,
            FOREIGN KEY(book_id) REFERENCES hadith_books(book_id)
          )
        ''');
        await db.execute('CREATE INDEX idx_hadiths_book ON hadiths(book_id)');
      } catch (_) {
        // Ignore if v5 tables already exist
      }
    }

    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS hadith_translations (
            text_hash TEXT PRIMARY KEY,
            source_text TEXT NOT NULL,
            translated_text TEXT NOT NULL,
            target_lang TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          DELETE FROM hadith_books WHERE book_id NOT IN (
            SELECT DISTINCT book_id FROM hadiths
          )
        ''');
      } catch (_) {
        // Ignore best-effort v6 cleanup
      }
    }

    if (oldVersion < 7) {
      try {
        await db.execute(
          "DELETE FROM hadiths WHERE book_id IN ('ara_muslim', 'eng_muslim')",
        );
        await db.execute(
          "DELETE FROM hadith_books WHERE book_id IN ('ara_muslim', 'eng_muslim')",
        );
      } catch (_) {
        // Ignore best-effort v7 cleanup
      }
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
          search_arabic, search_english,
          tokenize='unicode61 remove_diacritics 2'
        )
      ''');
      await db.execute(
        'INSERT INTO hadiths_fts(search_arabic, search_english) '
        'SELECT search_arabic, search_english FROM hadiths',
      );
    }

    if (oldVersion < 9) {
      final rows = await db.query('ayahs', columns: ['id', 'text_arabic']);
      final batch = db.batch();
      for (final r in rows) {
        batch.update('ayahs', {
          'text_arabic_clean': stripTashkeel(
            (r['text_arabic'] as String?) ?? '',
          ).toLowerCase(),
        }, where: 'id = ?', whereArgs: [r['id']]);
      }
      await batch.commit(noResult: true);
    }

    if (oldVersion < 10) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS extra_tafsirs (
            edition_id TEXT NOT NULL,
            surah_number INTEGER NOT NULL,
            ayah_number INTEGER NOT NULL,
            text TEXT NOT NULL,
            PRIMARY KEY(edition_id, surah_number, ayah_number)
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE ayahs ADD COLUMN page INTEGER DEFAULT 1');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ayahs_page ON ayahs(page)');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS ayahs_fts USING fts5(
            text_arabic_clean, text_english,
            tokenize='unicode61 remove_diacritics 2'
          )
        ''');
        await db.execute(
          'INSERT INTO ayahs_fts(rowid, text_arabic_clean, text_english) '
          'SELECT id, text_arabic_clean, text_english FROM ayahs',
        );
      } catch (_) {}
    }

    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS extra_translations (
            edition_id TEXT NOT NULL,
            surah_number INTEGER NOT NULL,
            ayah_number INTEGER NOT NULL,
            text TEXT NOT NULL,
            PRIMARY KEY(edition_id, surah_number, ayah_number)
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_extra_trans_lookup ON extra_translations(edition_id, surah_number)',
        );
      } catch (_) {}
    }
  }

  // ── Quran Data ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSurahs() async {
    final db = _database!;
    return await db.query('surahs', orderBy: 'number ASC');
  }

  Future<List<Map<String, dynamic>>> getAyahsForSurah(
    int surahNumber, {
    bool includeTafsir = false,
  }) async {
    final db = _database!;
    final columns = includeTafsir
        ? null // all columns
        : <String>[
            'id', 'surah_number', 'ayah_number', 'global_number',
            'text_arabic', 'text_arabic_clean', 'text_english',
            'juz', 'hizb', 'page',
          ];
    return await db.query(
      'ayahs',
      columns: columns,
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number ASC',
    );
  }

  /// Fetch all ayahs for a standard 604-page Madinah Mushaf page.
  Future<List<Map<String, dynamic>>> getAyahsForPage(int pageNumber) async {
    final db = _database!;
    return await db.rawQuery(
      '''
      SELECT ayahs.id, ayahs.surah_number, ayahs.ayah_number, ayahs.global_number,
             ayahs.text_arabic, ayahs.text_arabic_clean, ayahs.text_english,
             ayahs.juz, ayahs.hizb, ayahs.page,
             surahs.name as surah_name, surahs.englishName as surah_englishName 
      FROM ayahs 
      JOIN surahs ON ayahs.surah_number = surahs.number 
      WHERE ayahs.page = ?
      ORDER BY ayahs.surah_number ASC, ayahs.ayah_number ASC
      ''',
      [pageNumber],
    );
  }

  /// Fetch only tafsir text for a surah — used for lazy loading.
  Future<List<Map<String, dynamic>>> getTafsirForSurah(
    int surahNumber,
  ) async {
    final db = _database!;
    return await db.query(
      'ayahs',
      columns: ['ayah_number', 'tafsir'],
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number ASC',
    );
  }

  /// Fetch tafsir text for a single ayah — O(1) via idx_ayahs_surah (fix #2).
  Future<String> getTafsirForAyah(int surahNumber, int ayahNumber) async {
    final db = _database!;
    final rows = await db.query(
      'ayahs',
      columns: ['tafsir'],
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return '';
    return (rows.first['tafsir'] as String?) ?? '';
  }

  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    final db = _database!;
    final queryClean = stripTashkeel(query).toLowerCase().trim();
    if (queryClean.isEmpty) return [];

    // 1. High-speed FTS5 MATCH with snippet highlights (<mark> tags)
    try {
      final ftsResults = await db.rawQuery(
        '''
        SELECT ayahs.id, ayahs.surah_number, ayahs.ayah_number, ayahs.global_number,
               ayahs.text_arabic, ayahs.text_arabic_clean, ayahs.text_english,
               ayahs.juz, ayahs.hizb, ayahs.page,
               surahs.name as surah_name, surahs.englishName as surah_englishName,
               snippet(ayahs_fts, 0, '<mark>', '</mark>', '...', 15) as snippet_arabic,
               snippet(ayahs_fts, 1, '<mark>', '</mark>', '...', 15) as snippet_english
        FROM ayahs 
        JOIN surahs ON ayahs.surah_number = surahs.number 
        INNER JOIN ayahs_fts ON ayahs.id = ayahs_fts.rowid
        WHERE ayahs_fts MATCH ?
        ORDER BY rank
        ''',
        ['"$queryClean"'],
      );
      if (ftsResults.isNotEmpty) return ftsResults;
    } catch (_) {}

    // 2. Fallback: LIKE scan
    final searchPattern = '%$queryClean%';
    final results = await db.rawQuery(
      '''
      SELECT ayahs.id, ayahs.surah_number, ayahs.ayah_number, ayahs.global_number,
             ayahs.text_arabic, ayahs.text_arabic_clean, ayahs.text_english,
             ayahs.juz, ayahs.hizb, ayahs.page,
             surahs.name as surah_name, surahs.englishName as surah_englishName 
      FROM ayahs 
      JOIN surahs ON ayahs.surah_number = surahs.number 
      WHERE ayahs.text_arabic_clean LIKE ? OR LOWER(ayahs.text_english) LIKE ?
      ORDER BY ayahs.surah_number ASC, ayahs.ayah_number ASC
    ''',
      [searchPattern, searchPattern],
    );

    return results;
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
    final batch = db.batch();
    batch.delete('bookmarks', where: 'surah_number = ?', whereArgs: [surah]);
    batch.insert('bookmarks', {
      'surah_number': surah,
      'surah_name': name,
      'ayah_number': ayah,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await batch.commit(noResult: true);
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

  Future<void> deleteCustomDhikr(String id) async {
    final db = _database!;
    await db.delete('custom_dhikrs', where: 'id = ?', whereArgs: [id]);
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

  // ─── Extra Offline Tafsirs ────────────────────────────────────────────────
  Future<void> saveExtraTafsir(
    String editionId,
    int surahNumber,
    int ayahNumber,
    String text,
  ) async {
    final db = _database!;
    await db.insert(
      'extra_tafsirs',
      {
        'edition_id': editionId,
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'text': text,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getExtraTafsir(
    String editionId,
    int surahNumber,
    int ayahNumber,
  ) async {
    final db = _database!;
    final rows = await db.query(
      'extra_tafsirs',
      columns: ['text'],
      where: 'edition_id = ? AND surah_number = ? AND ayah_number = ?',
      whereArgs: [editionId, surahNumber, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['text'] as String?;
  }

  // ─── Extra Translations Methods ───

  Future<void> saveExtraTranslationsBatch(
    String editionId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = _database!;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'extra_translations',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Map<int, String>> getExtraTranslationsForSurah(
    int surahNumber,
    String editionId,
  ) async {
    if (editionId == 'en.sahih') {
      final rows = await getAyahsForSurah(surahNumber);
      return {
        for (var r in rows)
          r['ayah_number'] as int: (r['text_english'] as String?) ?? '',
      };
    }
    final db = _database!;
    final rows = await db.query(
      'extra_translations',
      columns: ['ayah_number', 'text'],
      where: 'edition_id = ? AND surah_number = ?',
      whereArgs: [editionId, surahNumber],
    );
    final map = <int, String>{};
    for (final r in rows) {
      map[r['ayah_number'] as int] = (r['text'] as String?) ?? '';
    }
    return map;
  }

  Future<String?> getExtraTranslation(
    String editionId,
    int surahNumber,
    int ayahNumber,
  ) async {
    if (editionId == 'en.sahih') {
      final db = _database!;
      final rows = await db.query(
        'ayahs',
        columns: ['text_english'],
        where: 'surah_number = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['text_english'] as String?;
    }
    final db = _database!;
    final rows = await db.query(
      'extra_translations',
      columns: ['text'],
      where: 'edition_id = ? AND surah_number = ? AND ayah_number = ?',
      whereArgs: [editionId, surahNumber, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['text'] as String?;
  }

  Future<bool> isTranslationEditionDownloaded(String editionId) async {
    if (editionId == 'en.sahih') return true;
    final db = _database!;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM extra_translations WHERE edition_id = ?',
        [editionId],
      ),
    );
    return (count ?? 0) >= 5000;
  }

  Future<int> getTranslationCountForEdition(String editionId) async {
    if (editionId == 'en.sahih') return 6236;
    final db = _database!;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM extra_translations WHERE edition_id = ?',
        [editionId],
      ),
    );
    return count ?? 0;
  }

  Future<void> deleteTranslationEdition(String editionId) async {
    if (editionId == 'en.sahih') return;
    final db = _database!;
    await db.delete(
      'extra_translations',
      where: 'edition_id = ?',
      whereArgs: [editionId],
    );
  }
}
