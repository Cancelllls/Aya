import 'offline_prayer_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;

import '../models/quran_models.dart';
import '../models/prayer_models.dart';

/// Service handling network calls for prayer times and Quran data.
/// Uses primary free APIs with graceful fallbacks.
class ApiService {
  static final http.Client _client = http.Client();

  // Base URLs
  static const String _quranBaseUrl = 'https://api.alquran.cloud/v1';

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

  static Future<Map<String, double>?> fetchCoordinatesByCity({
    required String city,
    required String country,
  }) async {
    try {
      final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
        'city': city,
        'country': country,
        'method': '2',
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded =
            await compute(_parseJson, response.body) as Map<String, dynamic>;
        final meta = decoded['data']['meta'] as Map<String, dynamic>;
        return {
          'latitude': (meta['latitude'] as num).toDouble(),
          'longitude': (meta['longitude'] as num).toDouble(),
        };
      }
    } catch (_) {}
    return null;
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
    // Primary: AlQuran Cloud
    try {
      final response = await _client
          .get(Uri.parse('$_quranBaseUrl/surah'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = response.body;
        await _cacheString('cached_surah_list', body);
        final decoded = await compute(_parseJson, body) as Map<String, dynamic>;
        return (decoded['data'] as List)
            .map((e) => Surah.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback: Quran.com API (v4)
    try {
      final fallback = await _client
          .get(Uri.https('api.quran.com', '/api/v4/chapters'))
          .timeout(const Duration(seconds: 5));
      if (fallback.statusCode == 200) {
        final body = fallback.body;
        await _cacheString('cached_surah_list_qurancom', body);
        final decoded = await compute(_parseJson, body) as Map<String, dynamic>;
        return (decoded['chapters'] as List)
            .map((e) => Surah.fromQuranCom(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback to local cache
    final cached = await _getCachedString('cached_surah_list');
    if (cached != null) {
      final decoded = await compute(_parseJson, cached) as Map<String, dynamic>;
      return (decoded['data'] as List)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final cachedQC = await _getCachedString('cached_surah_list_qurancom');
    if (cachedQC != null) {
      final decoded =
          await compute(_parseJson, cachedQC) as Map<String, dynamic>;
      return (decoded['chapters'] as List)
          .map((e) => Surah.fromQuranCom(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Failed to fetch Surah list. No internet and no cached data.',
    );
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
    List<Ayah>? ayahs;

    // 1. Offline first: Try to get from local cache for specific Tafsir edition
    try {
      final cached = await _getCachedString(
        'cached_surah_${surahNumber}_details_$tafsirEdition',
      );
      if (cached != null) {
        final data = await compute(_parseJson, cached) as Map<String, dynamic>;
        final editions = data['data'] as List<dynamic>;
        final arabic = editions[0]['ayahs'] as List<dynamic>;
        final english = editions[1]['ayahs'] as List<dynamic>;
        final tafseer = editions.length > 2
            ? editions[2]['ayahs'] as List<dynamic>?
            : null;
        final list = <Ayah>[];
        for (int i = 0; i < arabic.length; i++) {
          list.add(
            Ayah.fromEditions(
              arabic[i] as Map<String, dynamic>,
              english[i] as Map<String, dynamic>,
              tafseer != null ? tafseer[i] as Map<String, dynamic> : null,
            ),
          );
        }
        ayahs = list;
      }
    } catch (_) {}

    if (ayahs == null) {
      try {
        final cachedQC = await _getCachedString(
          'cached_surah_${surahNumber}_details_qurancom',
        );
        if (cachedQC != null) {
          final data =
              await compute(_parseJson, cachedQC) as Map<String, dynamic>;
          final verses = data['verses'] as List<dynamic>;
          ayahs = verses
              .map((v) => Ayah.fromQuranCom(v as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    if (ayahs != null) {
      await _injectTafsirIfCached(surahNumber, ayahs, tafsirEdition);
      return ayahs;
    }

    // 2. Online fallback: Fetch from AlQuran Cloud
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_quranBaseUrl/surah/$surahNumber/editions/quran-uthmani,en.sahih,$tafsirEdition',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = response.body;
        await _cacheString(
          'cached_surah_${surahNumber}_details_$tafsirEdition',
          body,
        );
        final data = await compute(_parseJson, body) as Map<String, dynamic>;
        final editions = data['data'] as List<dynamic>;
        final arabic = editions[0]['ayahs'] as List<dynamic>;
        final english = editions[1]['ayahs'] as List<dynamic>;
        final tafseer = editions.length > 2
            ? editions[2]['ayahs'] as List<dynamic>?
            : null;
        final list = <Ayah>[];
        for (int i = 0; i < arabic.length; i++) {
          list.add(
            Ayah.fromEditions(
              arabic[i] as Map<String, dynamic>,
              english[i] as Map<String, dynamic>,
              tafseer != null ? tafseer[i] as Map<String, dynamic> : null,
            ),
          );
        }
        ayahs = list;
      }
    } catch (_) {}

    if (ayahs == null) {
      // 3. Fallback: Fetch from Quran.com
      try {
        final uri = Uri.https(
          'api.quran.com',
          '/api/v4/verses/by_chapter/$surahNumber',
          {'translations': '20', 'fields': 'text_uthmani', 'per_page': '500'},
        );
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final body = response.body;
          await _cacheString(
            'cached_surah_${surahNumber}_details_qurancom',
            body,
          );
          final data = await compute(_parseJson, body) as Map<String, dynamic>;
          final verses = data['verses'] as List<dynamic>;
          ayahs = verses
              .map((v) => Ayah.fromQuranCom(v as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    if (ayahs != null) {
      await _injectTafsirIfCached(surahNumber, ayahs, tafsirEdition);
      return ayahs;
    }

    throw Exception(
      'Failed to load verses for Surah $surahNumber. No internet and no cached data.',
    );
  }

  // ─── Reverse Geocoding ───────────────────────────────────────────────────
  static Future<Map<String, String>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'accept-language': 'en',
      });
      final response = await _client.get(
        uri,
        headers: {'User-Agent': 'AyaApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final neighbourhood =
              address['neighbourhood'] ??
              address['suburb'] ??
              address['city_district'];
          final cityOrTown =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'];

          String exactLocation = '';
          if (neighbourhood != null && cityOrTown != null) {
            if (neighbourhood.toString().toLowerCase() !=
                cityOrTown.toString().toLowerCase()) {
              exactLocation =
                  '${neighbourhood.toString()}, ${cityOrTown.toString()}';
            } else {
              exactLocation = cityOrTown.toString();
            }
          } else {
            exactLocation = (neighbourhood ?? cityOrTown ?? 'Current Location')
                .toString();
          }

          final country = address['country'] ?? 'Unknown Country';
          return {'city': exactLocation, 'country': country.toString()};
        }
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

  static Future<Map<String, String>> fetchLocationByIP() async {
    try {
      final response = await _client
          .get(Uri.parse('https://ipapi.co/json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city'] as String? ?? 'Cairo';
        final country = data['country_name'] as String? ?? 'Egypt';
        final lat = double.parse((data['latitude'] ?? 30.0444).toString());
        final lon = double.parse((data['longitude'] ?? 31.2357).toString());
        return {
          'city': city,
          'country': country,
          'latitude': lat.toString(),
          'longitude': lon.toString(),
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print('IP-based location failed: $e');
    }
    return {
      'city': 'Cairo',
      'country': 'Egypt',
      'latitude': '30.0444',
      'longitude': '31.2357',
    };
  }

  // ─── Monthly Calendar ─────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchMonthlyCalendar({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.https('api.aladhan.com', '/v1/calendar', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'method': method.toString(),
        'school': school.toString(),
        'month': month.toString(),
        'year': year.toString(),
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded =
            await compute(_parseJson, response.body) as Map<String, dynamic>;
        return decoded['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> fetchMonthlyCalendarByCity({
    required String city,
    required String country,
    required int method,
    required int school,
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.https('api.aladhan.com', '/v1/calendarByCity', {
        'city': city,
        'country': country,
        'method': method.toString(),
        'school': school.toString(),
        'month': month.toString(),
        'year': year.toString(),
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded =
            await compute(_parseJson, response.body) as Map<String, dynamic>;
        return decoded['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  // ─── Audio URLs ────────────────────────────────────────────────────────
  static String buildAyahAudioUrl(
    int globalAyahNumber, {
    String reciter = 'ar.alafasy',
  }) {
    return 'https://cdn.islamic.network/quran/audio/64/$reciter/$globalAyahNumber.mp3';
  }

  static String buildSurahAudioUrl(
    int surahNumber, {
    String reciter = 'ar.alafasy',
  }) {
    return 'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$surahNumber.mp3';
  }

  static String buildSurahAudioUrlForQiraat(
    int surahNumber, {
    String quranScriptType = 'hafs',
    String reciter = 'ar.alafasy',
  }) {
    String surahPadded = surahNumber.toString().padLeft(3, '0');
    switch (quranScriptType) {
      case 'warsh':
        return 'https://server11.mp3quran.net/warsh/yassin/$surahPadded.mp3';
      case 'qaloon':
        return 'https://server11.mp3quran.net/qalon/trabulsi/$surahPadded.mp3';
      case 'shuba':
        return 'https://server13.mp3quran.net/husr/Rewayat-Sho-bah-A-n-Asim/$surahPadded.mp3';
      case 'duri':
        return 'https://server13.mp3quran.net/husr/Rewayat-Ad-Duri-A-n-Abi-Amr/$surahPadded.mp3';
      case 'susi':
        return 'https://server11.mp3quran.net/sosi/$surahPadded.mp3';
      case 'bazzi':
        return 'https://server14.mp3quran.net/bazzi/$surahPadded.mp3';
      case 'qunbul':
        return 'https://server14.mp3quran.net/qonbol/$surahPadded.mp3';
      case 'hisham':
        return 'https://server14.mp3quran.net/hisham/$surahPadded.mp3';
      case 'ibn-dhakwan':
        return 'https://server14.mp3quran.net/ibn_thakwan/$surahPadded.mp3';
      default:
        return buildSurahAudioUrl(surahNumber, reciter: reciter);
    }
  }
}
