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

    // Collect settings including both String and bool values
    final settings = <String, dynamic>{};
    for (var key in [
      'prayer_method', 'prayer_school', 'calc_method', 'asr_method',
      'adhan_alert_mode', 'pre_adhan_alert_mode', 'quran_font',
      'theme_preset', 'morning_azkar_reminder', 'evening_azkar_reminder',
      'todays_verse_reminder', 'use_24h_format',
    ]) {
      final val = storage.getString(key, defaultValue: '');
      if (val.isNotEmpty) settings[key] = val;
    }
    for (var key in [
      'morning_azkar_reminder', 'evening_azkar_reminder', 'todays_verse_reminder',
      'ramadan_imsak_enabled', 'ramadan_iftar_enabled', 'islamic_events_enabled',
      'swipe_surah_navigation', 'hide_full_surah_disclaimer',
    ]) {
      final val = storage.getBool(key);
      if (val != null) settings[key] = val;
    }

    final azkar = storage.getStringList('custom_dhikrs') ?? [];
    final tracker = await db.getPrayerTrackerRange('2020-01-01', '2030-01-01');

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

  static Future<String?> importBackupFile() async {
    // FilePicker would be ideal, but we use share_plus receive intent on mobile.
    // For now, this reads a file from a known path or share intent.
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aya_backup.json');
    if (!await file.exists()) return null;
    return await file.readAsString();
  }
}
