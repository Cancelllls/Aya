import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

/// Backup & restore for bookmarks, settings, azkar, and prayer tracker data.
class BackupService {
  static Future<Map<String, dynamic>> exportData() async {
    final storage = await StorageService.getInstance();
    final db = await DatabaseService.getInstance();

    // Bookmarks
    final bookmarks = storage.getStringList('hadith_bookmarks') ?? [];
    final quranBookmarks = storage.getStringList('quran_bookmarks') ?? [];

    // Settings
    final settings = <String, dynamic>{};
    for (var key in [
      'prayer_method', 'prayer_school', 'calc_method', 'asr_method',
      'adhan_alert_mode', 'pre_adhan_alert_mode', 'quran_font',
      'theme_preset', 'morning_azkar_reminder', 'evening_azkar_reminder',
      'todays_verse_reminder', 'ramadan_imsak_enabled',
      'ramadan_iftar_enabled', 'islamic_events_enabled',
      'swipe_surah_navigation', 'use_24h_format',
    ]) {
      final val = storage.getString(key, defaultValue: '');
      if (val.isNotEmpty) settings[key] = val;
      final intVal = storage.getInt(key, defaultValue: -1);
      if (intVal != -1) settings[key] = intVal;
      final boolVal = storage.getBool(key);
      if (boolVal != null) settings[key] = boolVal;
    }

    // Custom Azkar
    final azkar = storage.getStringList('custom_dhikrs') ?? [];

    // Prayer tracker
    final tracker = await db.getPrayerTrackerRange(
      DateTime(2020, 1, 1), DateTime(2030, 1, 1),
    );

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'bookmarks': bookmarks,
      'quran_bookmarks': quranBookmarks,
      'settings': settings,
      'custom_azkar': azkar,
      'prayer_tracker': tracker,
    };
  }

  static Future<int> importData(Map<String, dynamic> data) async {
    final storage = await StorageService.getInstance();
    final db = await DatabaseService.getInstance();
    int imported = 0;

    // Bookmarks
    final bookmarks = (data['bookmarks'] as List?)?.cast<String>() ?? [];
    if (bookmarks.isNotEmpty) {
      await storage.setStringList('hadith_bookmarks', bookmarks);
      imported++;
    }
    final qBookmarks =
        (data['quran_bookmarks'] as List?)?.cast<String>() ?? [];
    if (qBookmarks.isNotEmpty) {
      await storage.setStringList('quran_bookmarks', qBookmarks);
      imported++;
    }

    // Settings
    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    for (var entry in settings.entries) {
      final val = entry.value;
      if (val is String) {
        await storage.setString(entry.key, val);
      } else if (val is int) {
        await storage.setInt(entry.key, val);
      } else if (val is bool) {
        await storage.setBool(entry.key, val);
      }
    }
    if (settings.isNotEmpty) imported++;

    // Custom Azkar
    final azkar = (data['custom_azkar'] as List?)?.cast<String>() ?? [];
    if (azkar.isNotEmpty) {
      await storage.setStringList('custom_dhikrs', azkar);
      imported++;
    }

    // Prayer tracker
    final tracker = data['prayer_tracker'] as List? ?? [];
    for (var item in tracker) {
      if (item is Map) {
        await db.savePrayerTrackerDay(
          item['date']?.toString() ?? '',
          item['fajr'] as int? ?? 0,
          item['dhuhr'] as int? ?? 0,
          item['asr'] as int? ?? 0,
          item['maghrib'] as int? ?? 0,
          item['isha'] as int? ?? 0,
        );
      }
    }
    if (tracker.isNotEmpty) imported++;

    return imported;
  }

  static Future<String> exportToFile() async {
    final data = await exportData();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aya_backup.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    return file.path;
  }

  static Future<void> shareBackup() async {
    final path = await exportToFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Aya Backup'),
    );
  }

  static Future<Map<String, dynamic>?> importFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
