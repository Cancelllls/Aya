import 'dart:convert';
import 'dart:io';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

/// Background service for batch-caching Dorar sharh explanations.
///
/// Called from the UI (settings/dev screen). Runs on the main isolate
/// with controlled delays to respect Dorar rate limits (~2-3 sec/request).
///
/// Progress is saved incrementally so it's safe to stop/resume at any time.
class SharhCacheService {
  static const _requestDelay = Duration(seconds: 3);

  final void Function(String message) onLog;
  final void Function(int done, int total) onProgress;

  String _status = 'idle'; // idle | running | paused | done
  bool _cancelRequested = false;

  SharhCacheService({this.onLog = _defaultLog, this.onProgress = _defaultProgress});

  static void _defaultLog(String msg) {}
  static void _defaultProgress(int done, int total) {}

  String get status => _status;

  void cancel() {
    _cancelRequested = true;
    _status = 'paused';
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sharh_cache.json');
  }

  Future<Map<String, dynamic>> _loadCache() async {
    final file = await _cacheFile();
    if (await file.exists()) {
      try {
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  Future<void> _saveCache(Map<String, dynamic> cache) async {
    final file = await _cacheFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(cache));
    await tmp.rename(file.path);
  }

  /// Scrape sharh for one book. Returns number of new entries fetched.
  Future<int> cacheBook(String bookId, String displayLang) async {
    final db = await DatabaseService.getInstance();
    final cache = await _loadCache();
    final prefix = '$bookId:';
    int newCount = 0;

    // Count total hadiths
    final hadiths = await db.getHadiths(bookId, displayLang, 100000, 0);
    final total = hadiths.length;

    onLog('📖 $bookId: $total hadiths');

    int done = 0;
    for (var h in hadiths) {
      if (_cancelRequested) {
        onLog('⏸  Cancelled after $done/$total');
        return newCount;
      }

      final num = h['hadith_number'] as int;
      final key = '$prefix$num';

      // Skip already cached
      if (cache.containsKey(key) && cache[key] is Map && cache[key]['_ok'] == true) {
        done++;
        onProgress(done, total);
        continue;
      }

      final arabic = (h['arabic'] as String?) ?? '';
      if (arabic.isEmpty) {
        done++;
        onProgress(done, total);
        continue;
      }

      // Extract query from hadith text
      final query = _extractQuery(arabic);
      if (query.isEmpty) {
        done++;
        onProgress(done, total);
        continue;
      }

      onLog('  [$bookId #$num] "$query"...');

      try {
        final client = DorarClient();

        // Step 1: Always hit the reliable JSON API first (grading + rawi + book info).
        // This works for virtually every hadith.
        final hadithResults = await client.searchHadith(
          HadithSearchParams(value: query, page: 1),
        );

        String? sharhExplanation;
        String? foundText;
        String? foundGrading;

        if (hadithResults.data.isNotEmpty) {
          final hh = hadithResults.data.first;
          foundText = hh.hadith.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          foundGrading = 'الراوي: ${hh.rawi}\n'
              'المحدث: ${hh.mohdith}\n'
              'المصدر: ${hh.book}\n'
              'خلاصة حكم المحدث: ${hh.grade}'
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
        }

        // Step 2: Also try sharh search for explanation text.
        // Only a subset of hadiths have dedicated sharh entries — that's normal.
        try {
          final sharhResults = await client.searchSharh(
            HadithSearchParams(value: query, page: 1),
          );
          if (sharhResults.data.isNotEmpty) {
            final s = sharhResults.data.first;
            final sharhFull = (s.sharhText ?? '')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();
            if (sharhFull.isNotEmpty) {
              // Parse out the explanation portion (after the grading header)
              final takhreejIdx = sharhFull.indexOf('التخريج');
              if (takhreejIdx != -1) {
                final afterTakhreej = sharhFull.indexOf('\n', takhreejIdx);
                if (afterTakhreej != -1) {
                  sharhExplanation =
                      sharhFull.substring(afterTakhreej).trim();
                }
              }
              if (sharhExplanation == null || sharhExplanation.isEmpty) {
                sharhExplanation = sharhFull;
              }
              // Use sharh grading as override (more detailed) if available
              final rawiIdx = sharhFull.indexOf('الراوي');
              if (rawiIdx != -1) {
                final endOfHdr = sharhFull.indexOf('\n\n', rawiIdx);
                if (endOfHdr != -1) {
                  foundGrading = sharhFull.substring(rawiIdx, endOfHdr).trim();
                }
              }
            }
          }
        } catch (_) {
          // Sharh is a bonus — ignore failures
        }

        await client.dispose();

        if (foundText != null) {
          cache[key] = {
            'q': query,
            't': foundText,
            'e': sharhExplanation ?? '',
            'g': foundGrading ?? '',
            '_ok': true,
          };
          newCount++;
          final extra = sharhExplanation != null && sharhExplanation.isNotEmpty
              ? ' +sharh'
              : '';
          onLog('    ✓$extra');
        } else {
          cache[key] = {'_ok': false, '_reason': 'no results'};
          onLog('    ✗ no results');
        }
      } catch (e) {
        cache[key] = {'_ok': false, '_reason': e.toString()};
        onLog('    ✗ $e');
      }

      done++;
      onProgress(done, total);

      // Save incrementally every 10 hadiths
      if (done % 10 == 0) {
        await _saveCache(cache);
      }

      await Future<void>.delayed(_requestDelay);
    }

    await _saveCache(cache);
    onLog('✅ $bookId done: $newCount new entries');
    return newCount;
  }

  /// Get path to cache file for manual export
  Future<String> getCachePath() async {
    final file = await _cacheFile();
    return file.path;
  }

  /// Copy cache to a user-accessible Downloads directory if possible
  Future<String> exportToDownloads() async {
    final file = await _cacheFile();
    if (!await file.exists()) {
      throw Exception('No cache file to export');
    }
    // Try to copy to Downloads
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final dest = File('${downloadsDir.path}/aya_sharh_cache.json');
        await file.copy(dest.path);
        return dest.path;
      }
    } catch (_) {}
    return file.path; // fallback: just return the app-internal path
  }

  /// Export cache to Downloads folder on Android
  Future<String> exportCache() async {
    final cache = await _loadCache();
    if (cache.isEmpty) {
      throw Exception('No cache to export');
    }
    return exportToDownloads();
  }

  /// Get cache file size in KB
  Future<int> getCacheSize() async {
    final file = await _cacheFile();
    if (await file.exists()) {
      return (await file.length()) ~/ 1024;
    }
    return 0;
  }

  /// How many books' entries are cached
  Future<Map<String, int>> getCacheStats() async {
    final cache = await _loadCache();
    final stats = <String, int>{};
    for (var key in cache.keys) {
      final parts = key.split(':');
      if (parts.length == 2) {
        stats[parts[0]] = (stats[parts[0]] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// Extract a good search query from a hadith text.
  String _extractQuery(String text) {
    String clean = text.replaceAll(RegExp(r'[ً-ٰ]'), '').trim();
    final words = clean.split(RegExp(r'\s+'));

    // Find the actual hadith content (after the isnad)
    for (int i = 0; i < words.length; i++) {
      if (RegExp(r'سَمِعْتُ|يَقُولُ|أَنَّ.*رَسُول|عَنِ.*النَّبِيّ|قَالَ.*رَسُول|إِنَّ')
          .hasMatch(words.sublist(i).join(' '))) {
        return words.sublist(i).take(10).join(' ');
      }
    }

    // Skip first few words (isnad), take next for content
    if (words.length > 8) {
      return words.skip(5).take(10).join(' ');
    }
    return words.take(10).join(' ');
  }
}
