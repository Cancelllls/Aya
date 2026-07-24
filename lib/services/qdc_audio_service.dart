import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QdcAudioService {
  // Map of AlQuran.cloud / Mp3Quran string IDs to QDC integer IDs
  static final Map<String, int> _qdcReciterMap = {
    'ar.alafasy': 7, // Mishary Rashid Alafasy
    'ar.abdulbasitmurattal': 2, // AbdulBaset AbdulSamad
    'ar.abdulbasitmujawwad': 1,
    'ar.sudais': 3, // Abdur-Rahman as-Sudais
    'ar.shatri': 4, // Abu Bakr al-Shatri
    'ar.rifai': 5, // Hani ar-Rifai
    'ar.husary': 12, // Mahmoud Khalil Al-Husary
    'ar.husarymujawwad': 6,
    'ar.minshawi': 9, // Mohamed Siddiq al-Minshawi
    'ar.minshawimujawwad': 8,
    'ar.hudhaify': 11, // Ali Jaber
    'ar.ayyoub': 10, // Muhammad Ayyub
  };

  static int? getQdcReciterId(String reciter) {
    return _qdcReciterMap[reciter];
  }

  static Future<String?> getAudioUrl(int surahNum, String reciter) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheFile = File(
      '${dir.path}/quran_audio/$reciter/timestamps_$surahNum.json',
    );
    if (await cacheFile.exists()) {
      try {
        final content = await cacheFile.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(content);
        if (decoded.containsKey('audio_url')) {
          return decoded['audio_url'] as String;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<Map<int, List<dynamic>>?> fetchSurahTimestamps(
    int surahNum,
    String reciter,
  ) async {
    final qdcId = getQdcReciterId(reciter);
    if (qdcId == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final cacheFile = File(
      '${dir.path}/quran_audio/$reciter/timestamps_$surahNum.json',
    );

    if (await cacheFile.exists()) {
      try {
        final content = await cacheFile.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(content);
        if (!decoded.containsKey('audio_url')) {
          await cacheFile.delete();
        } else {
          Map<int, List<dynamic>> ayahTimestamps = {};
          decoded.forEach((key, value) {
            if (key != 'audio_url') {
              ayahTimestamps[int.parse(key)] = value;
            }
          });
          return ayahTimestamps;
        }
      } catch (_) {}
    }

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

        try {
          await cacheFile.parent.create(recursive: true);
          await cacheFile.writeAsString(jsonEncode(toCache));
        } catch (_) {}

        return ayahTimestamps;
      }
    } catch (e) {
      print('Error fetching QDC timestamps: $e');
    }
    return null;
  }
}
