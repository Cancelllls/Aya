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
import 'translation_cache_service.dart';
import '../utils/text_helpers.dart';

/// Service handling network calls for prayer times and Quran data.
/// Uses primary free APIs with graceful fallbacks.
class ApiService {
  /// Flavor detection: 'fdroid' or 'play'.
  /// Defaults to 'fdroid' for 100% open-source privacy compliance.
  static const String appFlavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'fdroid',
  );

  // ─── Prayer Times ────────────────────────────────────────────────────────
  static Future<PrayerTimeData> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    int latitudeAdjustmentMethod = 3,
    int midnightMode = 0,
    int adjustment = 0,
    double? customFajr,
    double? customIsha,
  }) async {
    return OfflinePrayerService.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      method: method,
      school: school,
      customFajr: customFajr,
      customIsha: customIsha,
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

  static Future<List<Surah>> fetchSurahList() async {
    final db = await DatabaseService.getInstance();
    final data = await db.getSurahs();
    return data.map((e) => Surah.fromJson(e)).toList();
  }

  static Future<List<Ayah>> fetchSurahDetails(
    int surahNumber, {
    String tafsirEdition = 'ar.muyassar',
    String? translationEdition,
  }) async {
    final db = await DatabaseService.getInstance();
    // Exclude tafsir from initial load — it's the single largest column.
    // Tafsir is lazy-loaded when the user switches to tafsir mode.
    final ayahsRaw = await db.getAyahsForSurah(surahNumber);

    Map<int, String>? extraTranslations;
    if (translationEdition != null && translationEdition != 'en.sahih') {
      extraTranslations = await db.getExtraTranslationsForSurah(
        surahNumber,
        translationEdition,
      );
      if (extraTranslations.isEmpty) {
        try {
          await TranslationCacheService.instance.downloadFromCdn(
            translationEdition,
          );
          extraTranslations = await db.getExtraTranslationsForSurah(
            surahNumber,
            translationEdition,
          );
        } catch (_) {}
      }
    }

    final list = <Ayah>[];
    for (var row in ayahsRaw) {
      final ayahNum = row['ayah_number'] as int? ?? 0;
      final transText =
          (extraTranslations != null &&
              extraTranslations.containsKey(ayahNum) &&
              extraTranslations[ayahNum]!.isNotEmpty)
          ? extraTranslations[ayahNum]!
          : (row['text_english'] as String? ?? '');
      final ayah = Ayah(
        number: row['global_number'] as int? ?? 0,
        numberInSurah: ayahNum,
        text: Ayah.cleanBasmalah(
          row['text_arabic'] as String? ?? '',
          ayahNum,
          row['global_number'] as int? ?? 0,
        ),
        translation: cleanTranslationText(transText),
        juz: row['juz'] as int? ?? 0,
        hizb: row['hizb'] as int? ?? 0,
        tafseer: '',
      );
      list.add(ayah);
    }

    return list;
  }

  /// Fetch a single Ayah's text and translation

  /// Clean HTML tags and common entities from Tafsir text.
  static String _cleanTafsirHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Fetch tafsir text for a surah and merge into existing [ayahs] list.
  static Future<void> fetchTafsirForSurah(
    int surahNumber,
    List<Ayah> ayahs, {
    String tafsirEdition = 'ar.muyassar',
  }) async {
    final db = await DatabaseService.getInstance();
    if (tafsirEdition == 'ar.muyassar') {
      final rows = await db.getTafsirForSurah(surahNumber);
      final lookup = <int, String>{};
      for (final r in rows) {
        lookup[r['ayah_number'] as int] = (r['tafsir'] as String?) ?? '';
      }
      for (final a in ayahs) {
        a.tafseer = lookup[a.numberInSurah] ?? '';
      }
      return;
    }

    // For other editions (e.g. en.ibnkathir, en.maududi):
    for (final a in ayahs) {
      final text = await fetchTafsirTextForAyah(
        tafsirEdition,
        surahNumber,
        a.numberInSurah,
      );
      a.tafseer = text;
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

  /// Resolves bundled tafsir asset IDs where equivalent editions share a JSON file.
  static String resolveBundledTafsirAssetId(String editionId) =>
      editionId == 'ar.miqbas' ? 'ar.waseet' : editionId;

  static Future<String> _loadFromBundledTafsirAsset(
    String editionId,
    int surahNumber,
    int ayahNumber,
  ) async {
    try {
      final effectiveId = resolveBundledTafsirAssetId(editionId);
      if (!_bundledTafsirAssetCache.containsKey(effectiveId)) {
        if (_bundledTafsirAssetCache.length >= _maxBundledTafsirAssetEntries) {
          _bundledTafsirAssetCache.remove(_bundledTafsirAssetCache.keys.first);
        }
        final jsonStr = await rootBundle.loadString(
          'assets/tafsir/$effectiveId.json',
        );
        _bundledTafsirAssetCache[effectiveId] =
            jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      final surahData =
          _bundledTafsirAssetCache[effectiveId]?[surahNumber.toString()]
              as Map<String, dynamic>?;
      if (surahData != null) {
        return (surahData[ayahNumber.toString()] as String? ?? '').trim();
      }
    } catch (_) {}
    return '';
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

    // 4. Fetch on-demand from Quran.com API with auto-caching into SQLite
    final tafsirMap = {
      'ar.muyassar': 16,
      'ar.jalalayn': 91,
      'ar.qurtubi': 90,
      'ar.miqbas': 93,
      'ar.waseet': 94,
      'ar.baghawi': 94,
      'en.ibnkathir': 169,
      'en.jalalayn': 171,
      'en.maududi': 168,
    };
    final isEnglishEdition = editionId.startsWith('en.');
    final tId = tafsirMap[editionId] ?? (isEnglishEdition ? 169 : 16);

    try {
      final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/$tId/by_ayah/$surahNumber:$ayahNumber',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawText = data['tafsir']?['text'] as String? ?? '';
        final cleanText = _cleanTafsirHtml(rawText);
        if (cleanText.isNotEmpty) {
          _setTafsirCache(cacheKey, cleanText);
          await db.saveExtraTafsir(
            editionId,
            surahNumber,
            ayahNumber,
            cleanText,
          );
          return cleanText;
        }
      }
    } catch (_) {}

    final fallbackMsg = isEnglishEdition
        ? 'Tafsir for this verse is unavailable offline. Connect to the internet once to load it.'
        : 'التفسير غير متوفر لهذه الآية دون إنترنت. يرجى الاتصال بالإنترنت لتحميله.';
    return fallbackMsg;
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
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'AyaIslamicApp/1.0 (https://github.com/Cancellls/Aya)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final props = features.first['properties'] as Map<String, dynamic>?;
          if (props != null) {
            final street = (props['street'] as String?)?.trim();
            final name = (props['name'] as String?)?.trim();
            final district =
                (props['district'] as String?)?.trim() ??
                (props['locality'] as String?)?.trim();
            final city =
                (props['city'] as String?)?.trim() ??
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
}
