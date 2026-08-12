import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QdcAudioService {
  // Map of AlQuran.cloud / Mp3Quran string IDs to QDC integer IDs.
  // Includes aliases so both AlQuran.cloud and QDC ID formats map correctly.
  static final Map<String, int> _qdcReciterMap = {
    'ar.alafasy': 7,
    'ar.abdulbasitmurattal': 2,
    'ar.abdulsamad': 2,
    'ar.abdulbasitmujawwad': 1,
    'ar.sudais': 3,
    'ar.abdurrahmaansudais': 3,
    'ar.shatri': 4,
    'ar.shaatree': 4,
    'ar.rifai': 5,
    'ar.hanirifai': 5,
    'ar.husary': 12,
    'ar.husarymujawwad': 6,
    'ar.minshawimujawwad': 8,
    'ar.hudhaify': 11,
    'ar.ayyoub': 10,
    'ar.muhammadayyoub': 10,
    'ar.minshawi': 9,
  };

  static int? getQdcReciterId(String reciter) {
    return _qdcReciterMap[reciter];
  }

  static String getCanonicalReciterId(String reciter) {
    switch (reciter) {
      case 'ar.abdurrahmaansudais':
        return 'ar.sudais';
      case 'ar.abdulsamad':
        return 'ar.abdulbasitmurattal';
      case 'ar.shaatree':
        return 'ar.shatri';
      case 'ar.hanirifai':
        return 'ar.rifai';
      case 'ar.muhammadayyoub':
        return 'ar.ayyoub';
      default:
        return reciter;
    }
  }

  /// Load timestamp JSON from the best available source.
  /// Priority: bundled asset → local file cache → QDC API.
  static Future<Map<String, dynamic>?> _loadTimestampJson(
    String reciter,
    int surahNum,
  ) async {
    final canonical = getCanonicalReciterId(reciter);
    // 1. Try bundled asset (pre-packaged with the APK)
    try {
      final assetPath = 'assets/timestamps/$canonical/$surahNum.json';
      final content = await rootBundle.loadString(assetPath);
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      // Not bundled — fall through to local cache
    }

    // 2. Try local file cache (written by a previous API fetch)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File(
        '${dir.path}/quran_audio/$canonical/timestamps_$surahNum.json',
      );
      if (await cacheFile.exists()) {
        final content = await cacheFile.readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        if (!decoded.containsKey('audio_url')) {
          await cacheFile.delete();
          return null;
        }
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  /// Save fetched timestamps to the local file cache.
  static Future<void> _saveToCache(
    String reciter,
    int surahNum,
    Map<String, dynamic> data,
  ) async {
    try {
      final canonical = getCanonicalReciterId(reciter);
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File(
        '${dir.path}/quran_audio/$canonical/timestamps_$surahNum.json',
      );
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static Future<String?> getAudioUrl(int surahNum, String reciter) async {
    final json = await _loadTimestampJson(reciter, surahNum);
    if (json != null && json.containsKey('audio_url')) {
      return json['audio_url'] as String;
    }
    return null;
  }

  static Future<Map<int, List<dynamic>>?> fetchSurahTimestamps(
    int surahNum,
    String reciter,
  ) async {
    final qdcId = getQdcReciterId(reciter);
    if (qdcId == null) return null;

    // Try bundled asset or local cache first
    final cached = await _loadTimestampJson(reciter, surahNum);
    if (cached != null) {
      Map<int, List<dynamic>> ayahTimestamps = {};
      cached.forEach((key, value) {
        if (key != 'audio_url') {
          ayahTimestamps[int.parse(key)] = value;
        }
      });
      return ayahTimestamps;
    }

    // 3. Fetch from QDC API (last resort)
    final url = Uri.parse(
      'https://api.qurancdn.com/api/qdc/audio/reciters/$qdcId/audio_files?chapter=$surahNum&segments=true',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioFiles = data['audio_files'] as List;
        if (audioFiles.isEmpty) return null;

        final timings = audioFiles[0]['verse_timings'] as List;
        Map<int, List<dynamic>> ayahTimestamps = {};
        Map<String, dynamic> toCache = {};

        for (var t in timings) {
          final verseKey = t['verse_key'] as String;
          final ayahNum = int.parse(verseKey.split(':')[1]);
          final times = [t['timestamp_from'], t['timestamp_to']];
          ayahTimestamps[ayahNum] = times;
          toCache[ayahNum.toString()] = times;
        }

        if (audioFiles[0].containsKey('audio_url')) {
          toCache['audio_url'] = audioFiles[0]['audio_url'];
        }

        await _saveToCache(reciter, surahNum, toCache);
        return ayahTimestamps;
      }
    } catch (e) {
      print('Error fetching QDC timestamps: $e');
    }
    return null;
  }
}
