import 'package:http/http.dart' as http;
import 'offline_prayer_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/quran_models.dart';
import '../models/prayer_models.dart';
import 'database_service.dart';
import 'translation_service.dart';

/// Service handling network calls for prayer times and Quran data.
/// Uses primary free APIs with graceful fallbacks.
class ApiService {
  /// Flavor detection: 'fdroid' or 'play'.
  /// Defaults to 'fdroid' for 100% open-source privacy compliance.
  static const String appFlavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'fdroid');
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

  static Future<List<Ayah>> fetchSurahDetails(
    int surahNumber, {
    String tafsirEdition = 'ar.muyassar',
  }) async {
    final db = await DatabaseService.getInstance();
    // Exclude tafsir from initial load — it's the single largest column.
    // Tafsir is lazy-loaded when the user switches to tafsir mode.
    final ayahsRaw = await db.getAyahsForSurah(surahNumber);

    final list = <Ayah>[];
    for (var row in ayahsRaw) {
      final ayah = Ayah(
        number: row['global_number'] as int? ?? 0,
        numberInSurah: row['ayah_number'] as int? ?? 0,
        text: Ayah.cleanBasmalah(
          row['text_arabic'] as String? ?? '',
          row['ayah_number'] as int? ?? 0,
          row['global_number'] as int? ?? 0,
        ),
        translation: row['text_english'] as String? ?? '',
        juz: row['juz'] as int? ?? 0,
        hizb: row['hizb'] as int? ?? 0,
        tafseer: '',
      );
      list.add(ayah);
    }

    return list;
  }

  /// Fetch tafsir text for a surah and merge into existing [ayahs] list.
  static Future<void> fetchTafsirForSurah(
    int surahNumber,
    List<Ayah> ayahs,
  ) async {
    final db = await DatabaseService.getInstance();
    final rows = await db.getTafsirForSurah(surahNumber);
    final lookup = <int, String>{};
    for (final r in rows) {
      lookup[r['ayah_number'] as int] = (r['tafsir'] as String?) ?? '';
    }
    for (final a in ayahs) {
      a.tafseer = lookup[a.numberInSurah] ?? '';
    }
  }

  static final Map<String, String> _tafsirMemoryCache = {};
  static final Map<String, Map<String, dynamic>> _bundledTafsirAssetCache = {};
  static const int _maxTafsirCacheEntries = 500;
  static const int _maxBundledTafsirAssetEntries = 3;

  static void _setTafsirCache(String key, String text) {
    if (_tafsirMemoryCache.length >= _maxTafsirCacheEntries) {
      _tafsirMemoryCache.remove(_tafsirMemoryCache.keys.first);
    }
    _tafsirMemoryCache[key] = text;
  }

  static Future<String> _loadFromBundledTafsirAsset(
    String editionId,
    int surahNumber,
    int ayahNumber,
  ) async {
    try {
      if (!_bundledTafsirAssetCache.containsKey(editionId)) {
        if (_bundledTafsirAssetCache.length >= _maxBundledTafsirAssetEntries) {
          _bundledTafsirAssetCache.remove(_bundledTafsirAssetCache.keys.first);
        }
        final jsonStr = await rootBundle.loadString(
          'assets/tafsir/$editionId.json',
        );
        _bundledTafsirAssetCache[editionId] =
            jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      final surahData =
          _bundledTafsirAssetCache[editionId]?[surahNumber.toString()]
              as Map<String, dynamic>?;
      if (surahData != null) {
        return (surahData[ayahNumber.toString()] as String? ?? '').trim();
      }
    } catch (_) {}
    return '';
  }

  /// Returns true if the tafsir for this ayah is already in the memory cache.
  static bool isTafsirCached(String editionId, int surahNumber, int ayahNumber) {
    return _tafsirMemoryCache.containsKey('$editionId:$surahNumber:$ayahNumber');
  }

  /// Fetch specific Tafsir text for a single Ayah given an edition ID.
  static Future<String> fetchTafsirTextForAyah(
    String editionId,
    int surahNumber,
    int ayahNumber,
  ) async {
    final cacheKey = '$editionId:$surahNumber:$ayahNumber';
    if (_tafsirMemoryCache.containsKey(cacheKey)) {
      return _tafsirMemoryCache[cacheKey]!;
    }

    final db = await DatabaseService.getInstance();

    // 1. Check local bundled Tafsir for ar.muyassar
    if (editionId == 'ar.muyassar') {
      final text = await db.getTafsirForAyah(surahNumber, ayahNumber);
      if (text.isNotEmpty) {
        _setTafsirCache(cacheKey, text);
        return text;
      }
    }

    // 2. Check bundled local asset JSON (assets/tafsir/$editionId.json)
    final assetText = await _loadFromBundledTafsirAsset(
      editionId,
      surahNumber,
      ayahNumber,
    );
    if (assetText.isNotEmpty) {
      _setTafsirCache(cacheKey, assetText);
      return assetText;
    }

    // 3. Check offline extra_tafsirs SQLite cache table
    final offlineText = await db.getExtraTafsir(
      editionId,
      surahNumber,
      ayahNumber,
    );
    if (offlineText != null && offlineText.isNotEmpty) {
      _setTafsirCache(cacheKey, offlineText);
      return offlineText;
    }

    final isEnglishEdition = editionId.startsWith('en.');
    final fallbackMsg = isEnglishEdition
        ? 'Tafsir for this verse is unavailable offline.'
        : 'التفسير غير متوفر لهذه الآية في الطبعة الحالية.';
    _setTafsirCache(cacheKey, fallbackMsg);
    return fallbackMsg;
  }

  /// Download an entire Tafsir edition (all 114 surahs) for 100% offline access.
  static Future<void> downloadFullTafsirEdition(
    String editionId, {
    void Function(double progress)? onProgress,
  }) async {
    final db = await DatabaseService.getInstance();
    if (editionId == 'ar.muyassar') {
      if (onProgress != null) onProgress(1.0);
      return; // Already bundled locally!
    }

    final tafsirMap = {
      'ar.jalalayn': 91,
      'ar.qurtubi': 90,
      'ar.miqbas': 93,
      'ar.waseet': 94,
      'ar.baghawi': 94,
      'en.ibnkathir': 169,
      'en.jalalayn': 171,
      'en.maududi': 168,
    };
    final tId = tafsirMap[editionId] ?? 16;
    final List<Map<String, dynamic>> batchItems = [];

    for (int surah = 1; surah <= 114; surah++) {
      try {
        final url = Uri.parse(
          'https://api.quran.com/api/v4/tafsirs/$tId/by_chapter/$surah',
        );
        final res = await http
            .get(url)
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final tafsirsList = data['tafsirs'] as List? ?? [];
          for (final t in tafsirsList) {
            final verseKey = t['verse_key'] as String? ?? '';
            final parts = verseKey.split(':');
            if (parts.length == 2) {
              final sNum = int.tryParse(parts[0]) ?? surah;
              final aNum = int.tryParse(parts[1]) ?? 1;
              final rawText = t['text'] as String? ?? '';
              final cleanText =
                  rawText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
              if (cleanText.isNotEmpty) {
                batchItems.add({
                  'edition_id': editionId,
                  'surah_number': sNum,
                  'ayah_number': aNum,
                  'text': cleanText,
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Tafsir download error surah $surah: $e');
      }

      if (onProgress != null) {
        onProgress(surah / 114.0);
      }
    }

    if (batchItems.isNotEmpty) {
      await db.saveExtraTafsirsBatch(editionId, batchItems);
    }
  }

  // ─── Reverse Geocoding ───────────────────────────────────────────────────
  static Future<Map<String, String>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    // If building for F-Droid flavor (or default), use Photon directly for 100% open-source geocoding
    if (appFlavor == 'fdroid') {
      final photonResult = await _reverseGeocodePhoton(latitude, longitude);
      if (photonResult != null) return photonResult;
    }

    // Otherwise (or if Play flavor), try Google Geocoding first with Photon fallback
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        List<String> parts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        } else if (place.thoroughfare != null &&
            place.thoroughfare!.isNotEmpty) {
          parts.add(place.thoroughfare!);
        } else if (place.name != null &&
            place.name!.isNotEmpty &&
            !place.name!.contains('+')) {
          parts.add(place.name!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          parts.add(place.subAdministrativeArea!);
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        List<String> uniqueParts = [];
        for (var p in parts) {
          bool isSubset = uniqueParts.any(
            (u) => u.contains(p) || p.contains(u),
          );
          if (!uniqueParts.contains(p) && (!isSubset || uniqueParts.isEmpty)) {
            uniqueParts.add(p);
          } else if (isSubset) {
            // Prefer the longer, more descriptive one if they are subsets
            int idx = uniqueParts.indexWhere(
              (u) => u.contains(p) || p.contains(u),
            );
            if (idx != -1 && p.length > uniqueParts[idx].length) {
              uniqueParts[idx] = p;
            }
          }
        }

        String exactLocation = uniqueParts.take(2).join(', ');
        if (exactLocation.isEmpty) exactLocation = 'Unknown Location';

        final country = place.country ?? 'Unknown Country';
        return {'city': exactLocation, 'country': country};
      }
    } catch (_) {
      // Fallback to Photon if Google geocoding fails (e.g. de-googled ROMs / missing backend)
      final fallback = await _reverseGeocodePhoton(latitude, longitude);
      if (fallback != null) return fallback;
    }
    return {'city': 'My Location', 'country': 'GPS'};
  }

  /// Open-source reverse geocoding via Photon (Komoot / OpenStreetMap).
  /// Fast, keyless, and 100% Google Play Services free for F-Droid.
  static Future<Map<String, String>?> _reverseGeocodePhoton(
    double latitude,
    double longitude,
  ) async {
    try {
      final langParam = TranslationService.isArabic ? 'default' : 'en';
      final uri = Uri.parse(
        'https://photon.komoot.io/reverse?lat=$latitude&lon=$longitude&lang=$langParam',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'AyaIslamicApp/1.0 (https://github.com/Cancellls/Aya)',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
            final props = features.first['properties'] as Map<String, dynamic>?;
          if (props != null) {
            final street = (props['street'] as String?)?.trim();
            final name = (props['name'] as String?)?.trim();
            final district = (props['district'] as String?)?.trim() ??
                (props['locality'] as String?)?.trim();
            final city = (props['city'] as String?)?.trim() ??
                (props['town'] as String?)?.trim() ??
                (props['village'] as String?)?.trim() ??
                (props['state'] as String?)?.trim();
            final country = (props['country'] as String?)?.trim() ?? '';

            List<String> parts = [];
            if (street != null && street.isNotEmpty) {
              parts.add(street);
            } else if (name != null && name.isNotEmpty && name != city) {
              parts.add(name);
            }

            if (district != null && district.isNotEmpty && district != city) {
              parts.add(district);
            }

            if (city != null && city.isNotEmpty) {
              parts.add(city);
            }

            String displayLocation = parts.take(2).join(', ');
            if (displayLocation.isEmpty) {
              displayLocation = name ?? city ?? 'Unknown Location';
            }

            return {
              'city': displayLocation,
              'country': country.isNotEmpty ? country : 'GPS',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Photon reverse geocoding error: $e');
    }
    return null;
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
      return server.endsWith('/')
          ? '$server$formattedNumber.mp3'
          : '$server/$formattedNumber.mp3';
    }
    return 'https://cdn.islamic.network/quran/audio/128/$reciter/$surahNumber.mp3';
  }

  static String buildSurahAudioUrlForQiraat(
    int surahNumber, {
    String quranScriptType = 'hafs',
    String reciter = 'ar.alafasy',
  }) {
    return buildSurahAudioUrl(surahNumber, reciter: reciter);
  }
}
