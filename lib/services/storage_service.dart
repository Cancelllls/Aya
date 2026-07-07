import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  static DatabaseService? _db;

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
      _db = await DatabaseService.getInstance();
      await _migrateIfNeeded();
    }
    return _instance!;
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
    return preset != 'light' && preset != 'white_monet';
  }

  // Location Cache
  Map<String, dynamic> getLocation() {
    final raw = getString('user_location');
    if (raw.isEmpty) {
      return {
        'city': 'Cairo',
        'country': 'Egypt',
        'latitude': 30.0444,
        'longitude': 31.2357,
        'source': 'default',
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  int determineSmartCalculationMethod(String city, String country) {
    final loc = '$city $country'.toLowerCase();
    if (loc.contains('egypt') ||
        loc.contains('مصر') ||
        loc.contains('alexandria') ||
        loc.contains('الإسكندرية') ||
        loc.contains('cairo') ||
        loc.contains('القاهرة')) {
      return 5; // Egypt (Egyptian General Authority of Survey)
    } else if (loc.contains('saudi') ||
        loc.contains('سعودية') ||
        loc.contains('makkah') ||
        loc.contains('mecca') ||
        loc.contains('مكة') ||
        loc.contains('riyadh') ||
        loc.contains('الرياض') ||
        loc.contains('madinah') ||
        loc.contains('المدينة')) {
      return 4; // Umm Al-Qura
    } else if (loc.contains('turkey') ||
        loc.contains('türkiye') ||
        loc.contains('turk') ||
        loc.contains('تركيا') ||
        loc.contains('istanbul') ||
        loc.contains('إسطنبول') ||
        loc.contains('ankara') ||
        loc.contains('أنقرة')) {
      return 13; // Turkey (Diyanet)
    } else if (loc.contains('united states') ||
        loc.contains('usa') ||
        loc.contains('canada') ||
        loc.contains('america') ||
        loc.contains('أمريكا') ||
        loc.contains('كندا')) {
      return 2; // ISNA
    } else if (loc.contains('singapore') || loc.contains('سنغافورة')) {
      return 11; // Singapore
    } else if (loc.contains('russia') || loc.contains('روسيا')) {
      return 14; // Russia
    } else if (loc.contains('uae') ||
        loc.contains('emirates') ||
        loc.contains('إمارات') ||
        loc.contains('dubai') ||
        loc.contains('دبي') ||
        loc.contains('abu dhabi') ||
        loc.contains('أبوظبي')) {
      return 16; // UAE
    } else if (loc.contains('qatar') || loc.contains('قطر')) {
      return 10; // Qatar
    } else if (loc.contains('france') ||
        loc.contains('فرنسا') ||
        loc.contains('paris') ||
        loc.contains('باريس')) {
      return 12; // France
    } else if (loc.contains('pakistan') ||
        loc.contains('باكستان') ||
        loc.contains('india') ||
        loc.contains('الهند') ||
        loc.contains('bangladesh') ||
        loc.contains('بنجلاديش') ||
        loc.contains('karachi') ||
        loc.contains('كاراتشي')) {
      return 1; // Karachi
    }
    return 3; // Muslim World League (MWL) as general fallback
  }

  Future<bool> setLocation(
    String city,
    String country,
    double lat,
    double lng,
    String source,
  ) async {
    final data = {
      'city': city,
      'country': country,
      'latitude': lat,
      'longitude': lng,
      'source': source,
    };

    // Automatically determine calculation method based on location
    final smartMethod = determineSmartCalculationMethod(city, country);
    await setInt('calc_method', smartMethod);

    return await setString('user_location', jsonEncode(data));
  }

  // Bookmarks
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final list = await _db!.getBookmarks();
    return list
        .map(
          (b) => {
            'surahNumber': b['surah_number'],
            'surahName': b['surah_name'],
            'ayahNumber': b['ayah_number'],
          },
        )
        .toList();
  }

  Future<void> addBookmark(
    int surahNumber,
    String surahName,
    int ayahNumber,
  ) async {
    await _db!.addBookmark(surahNumber, surahName, ayahNumber);
  }

  Future<void> removeBookmark(int surahNumber, {int? ayahNumber}) async {
    await _db!.removeBookmark(surahNumber, ayah: ayahNumber);
  }

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
    return await prefs.remove(key) ?? false;
  }

  // --- Last Read Position ---
  Future<void> saveLastReadPosition(int surahNum, int ayahNum) async {
    await setInt('last_read_surah', surahNum);
    await setInt('last_read_ayah', ayahNum);
    await setInt('last_read_ayah_surah_$surahNum', ayahNum);
  }

  Map<String, int>? getLastReadPosition() {
    final surahNum = prefs.getInt('last_read_surah');
    final ayahNum = prefs.getInt('last_read_ayah');
    if (surahNum != null && ayahNum != null) {
      return {'surah': surahNum, 'ayah': ayahNum};
    }
    return null;
  }

  int? getLastReadAyahForSurah(int surahNum) {
    return prefs.getInt('last_read_ayah_surah_$surahNum');
  }

  // --- Last Audio Position ---
  Future<void> saveLastAudioPosition(int surahNum, int ayahNum, String reciter, String surahName) async {
    await setInt('last_audio_surah', surahNum);
    await setInt('last_audio_ayah', ayahNum);
    await setString('last_audio_reciter', reciter);
    await setString('last_audio_surah_name', surahName);
  }

  Future<void> saveLastAudioTimestamp(int positionMs) async {
    await setInt('last_audio_timestamp_ms', positionMs);
  }

  Map<String, dynamic>? getLastAudioPosition() {
    final surahNum = prefs.getInt('last_audio_surah');
    final ayahNum = prefs.getInt('last_audio_ayah');
    final reciter = prefs.getString('last_audio_reciter');
    final surahName = prefs.getString('last_audio_surah_name') ?? "Surah $surahNum";
    if (surahNum != null && ayahNum != null && reciter != null) {
      return {'surah': surahNum, 'ayah': ayahNum, 'reciter': reciter, 'surahName': surahName};
    }
    return null;
  }

  int? getLastAudioTimestamp() {
    return prefs.getInt('last_audio_timestamp_ms');
  }
}
