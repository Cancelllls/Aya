import 'offline_prayer_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;

import '../models/quran_models.dart';
import '../models/prayer_models.dart';
import 'database_service.dart';

/// Service handling network calls for prayer times and Quran data.
/// Uses primary free APIs with graceful fallbacks.
class ApiService {
  static final http.Client _client = http.Client();

  // Base URLs
  static const String _quranBaseUrl = 'https://raw.githubusercontent.com/Cancelllls/Islamic-App/main/database';

  // ─── Prayer Times ────────────────────────────────────────────────────────
  static Future<void> cachePrayerTimes(String key, PrayerTimeData data) async {
    try {
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data.toJson(),
      };
      final jsonStr = jsonEncode(wrapper);
      await _cacheString(key, jsonStr);
    } catch (e) {
      // ignore: avoid_print
      print('Error caching prayer times: $e');
    }
  }

  static Future<PrayerTimeData?> getCachedPrayerTimes(String key) async {
    try {
      final jsonStr = await _getCachedString(key);
      if (jsonStr != null) {
        final Map<String, dynamic> decoded =
            jsonDecode(jsonStr) as Map<String, dynamic>;

        // Invalidate cache if it was created before the most recent 7:00 AM
        if (decoded.containsKey('timestamp')) {
          final int timestamp = decoded['timestamp'] as int;
          final DateTime cachedTime = DateTime.fromMillisecondsSinceEpoch(
            timestamp,
          );
          final DateTime now = DateTime.now();

          // Calculate the most recent 7:00 AM
          DateTime mostRecent7am = DateTime(
            now.year,
            now.month,
            now.day,
            7,
            0,
            0,
          );
          if (now.isBefore(mostRecent7am)) {
            // If it is currently before 7 AM today, the most recent 7 AM was yesterday
            mostRecent7am = mostRecent7am.subtract(const Duration(days: 1));
          }

          if (cachedTime.isBefore(mostRecent7am)) {
            // ignore: avoid_print
            print('Cached prayer times expired at 7:00 AM for key: $key');
            return null;
          }
        }

        final dataMap = decoded.containsKey('data')
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        return PrayerTimeData.fromLocalJson(dataMap);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error reading cached prayer times: $e');
    }
    return null;
  }

  static dynamic _parseJson(String body) {
    return jsonDecode(body);
  }

  static Future<PrayerTimeData> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    int latitudeAdjustmentMethod = 3,
    int midnightMode = 0,
    int adjustment = 0,
  }) async {
    return OfflinePrayerService.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      method: method,
      school: school,
    );
  }

  // ─── Quran Data & Caching ────────────────────────────────────────────────
  static Future<void> migrateCacheToFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      final dir = await getApplicationDocumentsDirectory();
      bool migrated = false;
      for (final key in keys) {
        if (key.startsWith('cached_surah_') ||
            key.startsWith('cached_tafsir_')) {
          final value = prefs.getString(key);
          if (value != null) {
            final file = File('${dir.path}/$key.json');
            await file.writeAsString(value);
          }
          await prefs.remove(key);
          migrated = true;
        }
      }
      if (migrated) {
        debugPrint("Migrated large JSONs from SharedPreferences to Files.");
      }
    } catch (_) {}
  }

  static Future<void> _cacheString(String key, String value) async {
    try {
      if (key.startsWith('cached_surah_') || key.startsWith('cached_tafsir_')) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$key.json');
        await file.writeAsString(value);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<String?> _getCachedString(String key) async {
    try {
      if (key.startsWith('cached_surah_') || key.startsWith('cached_tafsir_')) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$key.json');
        if (await file.exists()) {
          return await file.readAsString();
        }
        return null; // Don't fallback to prefs to avoid memory spikes, they should be migrated
      }
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Surah>> fetchSurahList() async {
    final db = await DatabaseService.getInstance();
    final data = await db.getSurahs();
    return data.map((e) => Surah.fromJson(e)).toList();
  }

  static Future<void> _injectTafsirIfCached(
    int surahNumber,
    List<Ayah> ayahs,
    String tafsirEdition,
  ) async {
    try {
      var tafsirRaw = await _getCachedString(
        'cached_tafsir_${tafsirEdition}_$surahNumber',
      );
      if (tafsirRaw == null && tafsirEdition == 'ar.muyassar') {
        // Fallback for old cache key
        tafsirRaw = await _getCachedString('cached_tafsir_$surahNumber');
      }
      if (tafsirRaw != null && tafsirRaw.isNotEmpty) {
        final decoded = jsonDecode(tafsirRaw);
        final tafsirAyahs = decoded['data']['ayahs'] as List<dynamic>;
        for (int i = 0; i < ayahs.length; i++) {
          if (i < tafsirAyahs.length) {
            ayahs[i].tafseer = tafsirAyahs[i]['text'] as String? ?? '';
          }
        }
      }
    } catch (_) {}
  }

  static Future<List<Ayah>> fetchSurahDetails(
    int surahNumber, {
    String tafsirEdition = 'ar.muyassar',
  }) async {
    final db = await DatabaseService.getInstance();
    final ayahsRaw = await db.getAyahsForSurah(surahNumber);
    
    final list = <Ayah>[];
    for (var row in ayahsRaw) {
      final ayah = Ayah(
        number: row['global_number'] as int? ?? 0,
        numberInSurah: row['ayah_number'] as int? ?? 0,
        text: Ayah.cleanBasmalah(row['text_arabic'] as String? ?? '', row['ayah_number'] as int? ?? 0, row['global_number'] as int? ?? 0),
        translation: row['text_english'] as String? ?? '',
        juz: row['juz'] as int? ?? 0,
        hizb: row['hizb'] as int? ?? 0,
        tafseer: row['tafsir'] as String? ?? '',
      );
      list.add(ayah);
    }
    
    return list;
  }

  // ─── Reverse Geocoding ───────────────────────────────────────────────────
  static Future<Map<String, String>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final neighbourhood = place.subLocality ?? place.subAdministrativeArea;
        final cityOrTown = place.locality ?? place.administrativeArea ?? 'Unknown City';

        String exactLocation = '';
        if (neighbourhood != null && neighbourhood.isNotEmpty && cityOrTown.isNotEmpty) {
          if (neighbourhood.toLowerCase() != cityOrTown.toLowerCase()) {
            exactLocation = '$neighbourhood, $cityOrTown';
          } else {
            exactLocation = cityOrTown;
          }
        } else {
          exactLocation = neighbourhood ?? cityOrTown;
        }

        final country = place.country ?? 'Unknown Country';
        return {'city': exactLocation, 'country': country};
      }
    } catch (_) {}
    return {'city': 'My Location', 'country': 'GPS'};
  }

  static Future<Position?> getBestLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );
      return position;
    } catch (e) {
      // ignore: avoid_print
      print('getCurrentPosition failed: $e. Trying last known position...');
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
    } catch (e) {
      // ignore: avoid_print
      print('getLastKnownPosition failed: $e');
    }

    return null;
  }

  // ─── Audio URLs ────────────────────────────────────────────────────────
  static String buildAyahAudioUrl(
    int globalAyahNumber,
    int surahNumber,
    int ayahNumberInSurah, {
    String reciter = 'ar.alafasy',
    String quranScriptType = 'hafs',
  }) {
    if (reciter.startsWith('mp3quran_server_')) {
      return ''; // Not supported
    }
    return 'https://cdn.islamic.network/quran/audio/128/$reciter/$globalAyahNumber.mp3';
  }

  static String buildSurahAudioUrl(
    int surahNumber, {
    String reciter = 'ar.alafasy',
  }) {
    if (reciter.startsWith('mp3quran_server_')) {
      final server = reciter.substring(16);
      final formattedNumber = surahNumber.toString().padLeft(3, '0');
      return server.endsWith('/') ? '$server$formattedNumber.mp3' : '$server/$formattedNumber.mp3';
    }
    return 'https://quran-audio-proxy.abdalraman-samir2001.workers.dev/audio/$reciter/$surahNumber.mp3';
  }

  static String buildSurahAudioUrlForQiraat(
    int surahNumber, {
    String quranScriptType = 'hafs',
    String reciter = 'ar.alafasy',
  }) {
    return buildSurahAudioUrl(surahNumber, reciter: reciter);
  }
}
