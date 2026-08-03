#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Generates per-surah ayah timestamp files for all supported reciters
/// by fetching from the QDC API. Run once and commit the output to
/// assets/timestamps/ so the app never needs to call api.qurancdn.com.
///
/// Usage: dart run tools/generate_timestamps.dart

const _baseUrl = 'https://api.qurancdn.com/api/qdc/audio/reciters';

final _reciters = {
  7: 'ar.alafasy',
  2: 'ar.abdulbasitmurattal',
  1: 'ar.abdulbasitmujawwad',
  3: 'ar.sudais',
  4: 'ar.shatri',
  5: 'ar.rifai',
  12: 'ar.husary',
  6: 'ar.husarymujawwad',
};

final _outDir = 'assets/timestamps';

Future<void> main() async {
  final client = HttpClient();
  final dir = Directory(_outDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  for (final entry in _reciters.entries) {
    final qdcId = entry.key;
    final reciterKey = entry.value;
    final reciterDir = Directory('$_outDir/$reciterKey');
    if (!reciterDir.existsSync()) reciterDir.createSync(recursive: true);

    for (int surah = 1; surah <= 114; surah++) {
      final outFile = File('${reciterDir.path}/$surah.json');
      if (outFile.existsSync()) {
        print('[$reciterKey] Surah $surah — already exists, skipping');
        continue;
      }

      print('[$reciterKey] Surah $surah — fetching...');
      try {
        final uri = Uri.parse('$_baseUrl/$qdcId/audio_files?chapter=$surah&segments=true');
        final request = await client.getUrl(uri);
        final response = await request.close().timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          print('  HTTP ${response.statusCode} — skipping');
          continue;
        }

        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final audioFiles = data['audio_files'] as List?;
        if (audioFiles == null || audioFiles.isEmpty) {
          print('  No audio files — skipping');
          continue;
        }

        final timings = audioFiles[0]['verse_timings'] as List?;
        if (timings == null || timings.isEmpty) {
          print('  No verse timings — skipping');
          continue;
        }

        // Format identical to the app's runtime cache
        final out = <String, dynamic>{};
        if (audioFiles[0].containsKey('audio_url')) {
          out['audio_url'] = audioFiles[0]['audio_url'];
        }
        for (final t in timings) {
          final verseKey = t['verse_key'] as String;
          final ayahNum = verseKey.split(':')[1];
          out[ayahNum] = [t['timestamp_from'], t['timestamp_to']];
        }

        await outFile.writeAsString(jsonEncode(out));
        print('  ✓ ${out.length - (out.containsKey('audio_url') ? 1 : 0)} ayahs');
      } catch (e) {
        print('  ✗ $e');
      }

      // Respect rate limits
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  client.close();
  print('\nDone. Files written to $_outDir/');
}
