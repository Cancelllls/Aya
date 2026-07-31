import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

/// Backup & restore bookmarks, settings, azkar, and prayer tracker data.
class BackupService {
  static Future<Map<String, dynamic>> exportData() async {
    final storage = await StorageService.getInstance();
    final db = await DatabaseService.getInstance();

    final bookmarks = storage.getStringList('hadith_bookmarks') ?? [];
    final quranBookmarks = storage.getStringList('quran_bookmarks') ?? [];

    // Collect settings as proper types
    final settings = <String, dynamic>{};
    final strKeys = [
      'prayer_method', 'prayer_school', 'calc_method', 'asr_method',
      'adhan_alert_mode', 'pre_adhan_alert_mode', 'quran_font',
      'theme_preset', 'lang_code', 'reading_mode',
    ];
    for (var key in strKeys) {
      final v = storage.getString(key);
      if (v != null && v.isNotEmpty) settings[key] = v;
    }
    final intKeys = ['first_day_of_week', 'pre_adhan_duration', 'focus_lock_duration'];
    for (var key in intKeys) {
      final v = storage.getInt(key, defaultValue: -1);
      if (v != -1) settings[key] = v;
    }
    final boolKeys = [
      'morning_azkar_reminder', 'evening_azkar_reminder', 'todays_verse_reminder',
      'ramadan_imsak_enabled', 'ramadan_iftar_enabled', 'islamic_events_enabled',
      'swipe_surah_navigation', 'hide_full_surah_disclaimer',
      'use_24h_format', 'continuous_play', 'auto_bookmark',
    ];
    for (var key in boolKeys) {
      final v = storage.getBool(key);
      if (v != null) settings[key] = v;
    }

    final azkar = storage.getStringList('custom_dhikrs') ?? [];

    // Prayer tracker — convert int values to int for safe JSON encoding
    final rawTracker = await db.getPrayerTrackerRange('2020-01-01', '2030-01-01');
    final tracker = rawTracker.map((row) {
      return row.map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0));
    }).toList();

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

    final bookmarks = (data['bookmarks'] as List?)?.cast<String>() ?? [];
    if (bookmarks.isNotEmpty) { await storage.setStringList('hadith_bookmarks', bookmarks); imported++; }

    final qbm = (data['quran_bookmarks'] as List?)?.cast<String>() ?? [];
    if (qbm.isNotEmpty) { await storage.setStringList('quran_bookmarks', qbm); imported++; }

    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    for (var e in settings.entries) {
      if (e.value is String) { await storage.setString(e.key, e.value); }
      else if (e.value is bool) { await storage.setBool(e.key, e.value); }
      else if (e.value is num) { await storage.setInt(e.key, e.value.toInt()); }
    }
    if (settings.isNotEmpty) imported++;

    final azkar = (data['custom_azkar'] as List?)?.cast<String>() ?? [];
    if (azkar.isNotEmpty) { await storage.setStringList('custom_dhikrs', azkar); imported++; }

    final tracker = data['prayer_tracker'] as List? ?? [];
    for (var item in tracker) {
      if (item is! Map) continue;
      final date = (item['date'] ?? '').toString();
      if (date.isEmpty) continue;
      for (var prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final v = item[prayer];
        if (v == null) continue;
        final status = v is int ? v : int.tryParse(v.toString()) ?? 0;
        if (status > 0) await db.updatePrayerTracker(date, prayer, status);
      }
    }
    if (tracker.isNotEmpty) imported++;
    return imported;
  }

  static Future<String> exportToFile() async {
    final data = await exportData();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aya_backup.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file.path;
  }

  static Future<void> shareBackup() async {
    final path = await exportToFile();
    final file = XFile(path, mimeType: 'application/json');
    await SharePlus.instance.share(ShareParams(files: [file], text: 'Aya Backup'));
  }

  /// Read backup from a user-specified file path.
  /// On Android, users can export to Downloads and reference it there.
  static Future<String?> readBackupFromPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Read from the default backup location (app documents).
  static Future<String?> readDefaultBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aya_backup.json');
    if (!await file.exists()) {
      // Also check Downloads
      final dlDir = Directory('/storage/emulated/0/Download');
      if (await dlDir.exists()) {
        final dlFile = File('${dlDir.path}/aya_backup.json');
        if (await dlFile.exists()) {
          return await dlFile.readAsString();
        }
      }
      return null;
    }
    return await file.readAsString();
  }
}
