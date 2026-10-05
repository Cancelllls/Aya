import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'storage/prayer_preferences.dart';
import 'storage/reading_tracker_store.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  static DatabaseService? _db;

  late final PrayerPreferences prayer;
  late final ReadingTrackerStore readingTracker;

  StorageService._();

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'StorageService is not initialized. Call getInstance() first.',
      );
    }
    return _prefs!;
  }

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
      _instance!.prayer = PrayerPreferences(_prefs!);
      try {
        _db = await DatabaseService.getInstance();
        _instance!.readingTracker = ReadingTrackerStore(_prefs!, _db!);
        await _migrateIfNeeded();
      } catch (_) {}
    }
    return _instance!;
  }

  static void resetForTesting() {
    _instance = null;
    _prefs = null;
    _db = null;
  }

  static Future<void> _migrateIfNeeded() async {
    final migrated = _prefs!.getBool('db_migrated_v1') ?? false;
    if (!migrated) {
      final bookmarksJson = _prefs!.getString('quran_bookmarks');
      if (bookmarksJson != null) {
        try {
          final bookmarks = jsonDecode(bookmarksJson) as List;
          for (final b in bookmarks) {
            await _db!.addBookmark(
              b['surahNumber'] ?? b['surah_number'] ?? 1,
              b['surahName'] ?? b['surah_name'] ?? '',
              b['ayahNumber'] ?? b['ayah_number'] ?? 1,
            );
          }
        } catch (_) {}
      }
      final dhikrsJson = _prefs!.getString('custom_dhikrs');
      if (dhikrsJson != null) {
        try {
          final dhikrs = jsonDecode(dhikrsJson) as List;
          for (final d in dhikrs) {
            await _db!.addCustomDhikr(
              id: d['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: d['name'] ?? '',
              arabic: d['arabic'] ?? '',
              translation: d['translation'] ?? '',
              target: d['target'] ?? 33,
            );
          }
        } catch (_) {}
      }
      await _prefs!.setBool('db_migrated_v1', true);
    }

    // Migrate large JSON strings from SharedPreferences to Files
    final migratedFiles = _prefs!.getBool('quran_files_migrated_v1') ?? false;
    if (!migratedFiles) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final keys = _prefs!.getKeys().toList();
        for (final key in keys) {
          if (key.startsWith('cached_surah_') ||
              key.startsWith('cached_tafsir_')) {
            final value = _prefs!.getString(key);
            if (value != null) {
              final file = File('${dir.path}/$key.json');
              await file.writeAsString(value);
              await _prefs!.remove(key);
            }
          }
        }
        await _prefs!.setBool('quran_files_migrated_v1', true);
      } catch (_) {}
    }
  }

  // General set/get
  Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return prefs.getString(key) ?? defaultValue;
  }

  List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  Future<bool> setBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return prefs.getInt(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) async {
    return await prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return prefs.getDouble(key) ?? defaultValue;
  }

  // Specific state helpers

  // Dark/Light Theme
  bool isDarkMode() {
    final preset = getString('theme_preset', defaultValue: 'dark');
    return preset == 'dark' || preset == 'black' || preset == 'dark_monet';
  }

  // Location Cache (Delegated to PrayerPreferences)
  Map<String, dynamic> getLocation() => prayer.getLocation();

  int determineSmartCalculationMethod(String city, String country) =>
      prayer.determineSmartCalculationMethod(city, country);

  Future<bool> setLocation(
    String city,
    String country,
    double lat,
    double lng,
    String source,
  ) => prayer.setLocation(city, country, lat, lng, source);

  // Bookmarks (Delegated to ReadingTrackerStore)
  Future<List<Map<String, dynamic>>> getBookmarks() =>
      readingTracker.getBookmarks();

  Future<void> addBookmark(int surahNumber, String surahName, int ayahNumber) =>
      readingTracker.addBookmark(surahNumber, surahName, ayahNumber);

  Future<void> removeBookmark(int surahNumber, {int? ayahNumber}) =>
      readingTracker.removeBookmark(surahNumber, ayahNumber: ayahNumber);

  // Custom Dhikr list
  Future<List<Map<String, dynamic>>> getCustomDhikrs() async {
    final list = await _db!.getCustomDhikrs();
    return list
        .map(
          (d) => {
            'id': d['id'],
            'name': d['name'],
            'arabic': d['arabic'],
            'translation': d['translation'],
            'target': d['target'],
            'currentCount': d['current_count'],
          },
        )
        .toList();
  }

  Future<void> addCustomDhikr(
    String name,
    String arabic,
    String translation,
    int target,
  ) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db!.addCustomDhikr(
      id: id,
      name: name,
      arabic: arabic,
      translation: translation,
      target: target,
    );
  }

  Future<void> deleteCustomDhikr(String id) async {
    await _db!.deleteCustomDhikr(id);
  }

  Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  // --- Last Read Position (Delegated to ReadingTrackerStore) ---
  Future<void> saveLastReadPosition(int surahNum, int ayahNum) =>
      readingTracker.saveLastReadPosition(surahNum, ayahNum);

  Map<String, int>? getLastReadPosition() =>
      readingTracker.getLastReadPosition();

  int? getLastReadAyahForSurah(int surahNum) =>
      readingTracker.getLastReadAyahForSurah(surahNum);

  // --- Last Audio Position (Delegated to ReadingTrackerStore) ---
  Future<void> saveLastAudioPosition(
    int surahNum,
    int ayahNum,
    String reciter,
    String surahName,
  ) => readingTracker.saveLastAudioPosition(
    surahNum,
    ayahNum,
    reciter,
    surahName,
  );

  Future<void> saveLastAudioTimestamp(int positionMs) =>
      readingTracker.saveLastAudioTimestamp(positionMs);

  Map<String, dynamic>? getLastAudioPosition() =>
      readingTracker.getLastAudioPosition();

  int? getLastAudioTimestamp() => readingTracker.getLastAudioTimestamp();

  Future<void> clearAll() async {
    await prefs.clear();
  }
}
