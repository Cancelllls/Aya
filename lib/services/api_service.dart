import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_models.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';

/// Service handling network calls for prayer times and Quran data.
/// Uses primary free APIs with graceful fallbacks.
class ApiService {
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
        final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        // Invalidate cache after 24 hours
        if (decoded.containsKey('timestamp')) {
          final int timestamp = decoded['timestamp'] as int;
          final int ageMs = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (ageMs > 24 * 3600 * 1000) {
            // ignore: avoid_print
            print('Cached prayer times expired for key: $key');
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

  static Future<PrayerTimeData> _fetchPrayerTimesHelper({
    required String cacheKey,
    required String aladhanPath,
    required Map<String, String> aladhanQuery,
    required Uri prayZoneUri,
  }) async {
    // 1. Primary: AlAdhan
    try {
      final response = await http.get(Uri.https('api.aladhan.com', aladhanPath, aladhanQuery))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = PrayerTimeData.fromJson(jsonDecode(response.body)['data']);
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

    // 2. Fallback: pray.zone
    try {
      final resp = await http.get(prayZoneUri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final timings = data['results']['datetime'][0]['times'] as Map<String, dynamic>;
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
    final globalLatest = await getCachedPrayerTimes('cached_latest_prayer_times');
    if (globalLatest != null) return globalLatest;

    throw Exception('Failed to fetch prayer times and no cached data available');
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
    final cacheKey = 'cached_prayer_times_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_m${method}_s$school';
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
    final cacheKey = 'cached_prayer_times_city_${city.toLowerCase()}_${country.toLowerCase()}_m${method}_s$school';
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

    final prayZoneUri = Uri.https('api.pray.zone', '/v2/times/today.json', {'city': city});

    return _fetchPrayerTimesHelper(
      cacheKey: cacheKey,
      aladhanPath: '/v1/timingsByCity/$date',
      aladhanQuery: aladhanQuery,
      prayZoneUri: prayZoneUri,
    );
  }

  // ─── Quran Data & Caching ────────────────────────────────────────────────
  static Future<void> _cacheString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<String?> _getCachedString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Surah>> fetchSurahList() async {
    // Primary: AlQuran Cloud
    try {
      final response = await http.get(Uri.parse('$_quranBaseUrl/surah')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = response.body;
        await _cacheString('cached_surah_list', body);
        return (jsonDecode(body)['data'] as List)
            .map((e) => Surah.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback: Quran.com API (v4)
    try {
      final fallback = await http.get(Uri.https('api.quran.com', '/api/v4/chapters')).timeout(const Duration(seconds: 5));
      if (fallback.statusCode == 200) {
        final body = fallback.body;
        await _cacheString('cached_surah_list_qurancom', body);
        final data = jsonDecode(body) as Map<String, dynamic>;
        return (data['chapters'] as List)
            .map((e) => Surah.fromQuranCom(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback to local cache
    final cached = await _getCachedString('cached_surah_list');
    if (cached != null) {
      return (jsonDecode(cached)['data'] as List)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final cachedQC = await _getCachedString('cached_surah_list_qurancom');
    if (cachedQC != null) {
      final data = jsonDecode(cachedQC) as Map<String, dynamic>;
      return (data['chapters'] as List)
          .map((e) => Surah.fromQuranCom(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to fetch Surah list. No internet and no cached data.');
  }

  static Future<void> _injectTafsirIfCached(int surahNumber, List<Ayah> ayahs) async {
    try {
      final storage = await StorageService.getInstance();
      final tafsirRaw = storage.getString('cached_tafsir_$surahNumber');
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

  static Future<List<Ayah>> fetchSurahDetails(int surahNumber) async {
    List<Ayah>? ayahs;

    // Primary: AlQuran Cloud (full edition with Tafseer)
    try {
      final response = await http.get(Uri.parse('$_quranBaseUrl/surah/$surahNumber/editions/quran-uthmani,en.sahih,ar.muyassar')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = response.body;
        await _cacheString('cached_surah_${surahNumber}_details', body);
        final data = jsonDecode(body) as Map<String, dynamic>;
        final editions = data['data'] as List<dynamic>;
        final arabic = editions[0]['ayahs'] as List<dynamic>;
        final english = editions[1]['ayahs'] as List<dynamic>;
        final tafseer = editions.length > 2 ? editions[2]['ayahs'] as List<dynamic>? : null;
        final list = <Ayah>[];
        for (int i = 0; i < arabic.length; i++) {
          list.add(Ayah.fromEditions(
            arabic[i] as Map<String, dynamic>,
            english[i] as Map<String, dynamic>,
            tafseer != null ? tafseer[i] as Map<String, dynamic> : null,
          ));
        }
        ayahs = list;
      }
    } catch (_) {}

    if (ayahs == null) {
      // Fallback: Quran.com API (v4)
      try {
        final uri = Uri.https('api.quran.com', '/api/v4/verses/by_chapter/$surahNumber', {
          'translations': '20',
          'fields': 'text_uthmani',
          'per_page': '500',
        });
        final response = await http.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final body = response.body;
          await _cacheString('cached_surah_${surahNumber}_details_qurancom', body);
          final data = jsonDecode(body) as Map<String, dynamic>;
          final verses = data['verses'] as List<dynamic>;
          ayahs = verses.map((v) => Ayah.fromQuranCom(v as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    if (ayahs == null) {
      // Fallback to local cache
      final cached = await _getCachedString('cached_surah_${surahNumber}_details');
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final editions = data['data'] as List<dynamic>;
        final arabic = editions[0]['ayahs'] as List<dynamic>;
        final english = editions[1]['ayahs'] as List<dynamic>;
        final tafseer = editions.length > 2 ? editions[2]['ayahs'] as List<dynamic>? : null;
        final list = <Ayah>[];
        for (int i = 0; i < arabic.length; i++) {
          list.add(Ayah.fromEditions(
            arabic[i] as Map<String, dynamic>,
            english[i] as Map<String, dynamic>,
            tafseer != null ? tafseer[i] as Map<String, dynamic> : null,
          ));
        }
        ayahs = list;
      }
    }

    if (ayahs == null) {
      final cachedQC = await _getCachedString('cached_surah_${surahNumber}_details_qurancom');
      if (cachedQC != null) {
        final data = jsonDecode(cachedQC) as Map<String, dynamic>;
        final verses = data['verses'] as List<dynamic>;
        ayahs = verses.map((v) => Ayah.fromQuranCom(v as Map<String, dynamic>)).toList();
      }
    }

    if (ayahs != null) {
      await _injectTafsirIfCached(surahNumber, ayahs);
      return ayahs;
    }

    throw Exception('Failed to load verses for Surah $surahNumber. No internet and no cached data.');
  }

  // ─── Reverse Geocoding ───────────────────────────────────────────────────
  static Future<Map<String, String>> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'accept-language': 'en',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'AyaApp/1.0',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final neighbourhood = address['neighbourhood'] ?? address['suburb'] ?? address['city_district'];
          final cityOrTown = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['state'];
          
          String exactLocation = '';
          if (neighbourhood != null && cityOrTown != null) {
            if (neighbourhood.toString().toLowerCase() != cityOrTown.toString().toLowerCase()) {
              exactLocation = '${neighbourhood.toString()}, ${cityOrTown.toString()}';
            } else {
              exactLocation = cityOrTown.toString();
            }
          } else {
            exactLocation = (neighbourhood ?? cityOrTown ?? 'Current Location').toString();
          }

          final country = address['country'] ?? 'Unknown Country';
          return {'city': exactLocation, 'country': country.toString()};
        }
      }
    } catch (_) {}
    return {'city': 'My Location', 'country': 'GPS'};
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
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
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
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  // ─── Audio URLs ────────────────────────────────────────────────────────
  static String buildAyahAudioUrl(int globalAyahNumber, {String reciter = 'ar.alafasy'}) {
    return 'https://cdn.islamic.network/quran/audio/64/$reciter/$globalAyahNumber.mp3';
  }

  static String buildSurahAudioUrl(int surahNumber, {String reciter = 'ar.alafasy'}) {
    return 'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$surahNumber.mp3';
  }
}
