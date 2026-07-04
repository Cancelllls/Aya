import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show compute;

import '../models/quran_models.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';

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

  static Future<PrayerTimeData> _fetchPrayerTimesHelper({
    required String cacheKey,
    required String aladhanPath,
    required Map<String, String> aladhanQuery,
    required Uri prayZoneUri,
  }) async {
    // 1. Primary: AlAdhan
    try {
      final response = await _client
          .get(Uri.https('api.aladhan.com', aladhanPath, aladhanQuery))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded =
            await compute(_parseJson, response.body) as Map<String, dynamic>;
        final data = PrayerTimeData.fromJson(decoded['data']);
        await cachePrayerTimes(cacheKey, data);
        await cachePrayerTimes('cached_latest_prayer_times', data);
        return data;
      } else {
        // ignore: avoid_print
        print('AlAdhan API returned status code ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching from AlAdhan API: $e');
    }

    // 2. Fallback 2: pray.zone
    try {
      final resp = await _client
          .get(prayZoneUri)
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final decoded =
            await compute(_parseJson, resp.body) as Map<String, dynamic>;
        final timings =
            decoded['results']['datetime'][0]['times'] as Map<String, dynamic>;
        final prayerData = PrayerTimeData.fromPrayZone(timings);
        await cachePrayerTimes(cacheKey, prayerData);
        await cachePrayerTimes('cached_latest_prayer_times', prayerData);
        return prayerData;
      } else {
        // ignore: avoid_print
        print('PrayZone API returned status code ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching from PrayZone API: $e');
    }

    // 3. Fallback to local cache for this specific location
    final cached = await getCachedPrayerTimes(cacheKey);
    if (cached != null) return cached;

    // 4. Fallback to latest successfully fetched prayer times anywhere
    final globalLatest = await getCachedPrayerTimes(
      'cached_latest_prayer_times',
    );
    if (globalLatest != null) return globalLatest;

    throw Exception(
      'Failed to fetch prayer times and no cached data available',
    );
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
    final cacheKey =
        'cached_prayer_times_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_m${method}_s$school';
    final now = DateTime.now();
    final date = "${now.day}-${now.month}-${now.year}";

    final aladhanQuery = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': method.toString(),
      'latitudeAdjustmentMethod': latitudeAdjustmentMethod.toString(),
      'school': school.toString(),
      'midnightMode': midnightMode.toString(),
      'adjustment': adjustment.toString(),
    };

    final prayZoneUri = Uri.https('api.pray.zone', '/v2/times/today.json', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    });

    return _fetchPrayerTimesHelper(
      cacheKey: cacheKey,
      aladhanPath: '/v1/timings/$date',
      aladhanQuery: aladhanQuery,
      prayZoneUri: prayZoneUri,
    );
  }

  static Future<PrayerTimeData> fetchPrayerTimesByCity({
    required String city,
    required String country,
    required int method,
    required int school,
    int latitudeAdjustmentMethod = 3,
    int midnightMode = 0,
    int adjustment = 0,
  }) async {
    final cacheKey =
        'cached_prayer_times_city_${city.toLowerCase()}_${country.toLowerCase()}_m${method}_s$school';
    final now = DateTime.now();
    final date = "${now.day}-${now.month}-${now.year}";

    final aladhanQuery = {
      'city': city,
      'country': country,
      'method': method.toString(),
      'latitudeAdjustmentMethod': latitudeAdjustmentMethod.toString(),
      'school': school.toString(),
      'midnightMode': midnightMode.toString(),
      'adjustment': adjustment.toString(),
    };

    final prayZoneUri = Uri.https('api.pray.zone', '/v2/times/today.json', {
      'city': city,
    });

    return _fetchPrayerTimesHelper(
      cacheKey: cacheKey,
      aladhanPath: '/v1/timingsByCity/$date',
      aladhanQuery: aladhanQuery,
      prayZoneUri: prayZoneUri,
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
        if (key.startsWith('cached_surah_') || key.startsWith('cached_tafsir_')) {
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
        print("Migrated large JSONs from SharedPreferences to Files.");
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
      final storage = await StorageService.getInstance();
      var tafsirRaw = storage.getString(
        'cached_tafsir_${tafsirEdition}_$surahNumber',
      );
      if (tafsirRaw.isEmpty && tafsirEdition == 'ar.muyassar') {
        // Fallback for old cache key
        tafsirRaw = storage.getString('cached_tafsir_$surahNumber');
      }
      if (tafsirRaw.isNotEmpty) {
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
}
