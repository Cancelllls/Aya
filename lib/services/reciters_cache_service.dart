import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../services/translation_service.dart';

/// Fetches the full reciter list from mp3quran.net API v3 once,
/// caches it to disk, and serves filtered results by riwayah.
///
/// On first access the service fetches all riwayat then all reciters
/// for each riwayah with controlled concurrency.  Results are written
/// to `reciters_cache.json` in the app documents directory.
///
/// Callers that currently import the 405 KB `reciters_data.dart` bundle
/// should route through this service instead so the list stays up to date.
class RecitersCacheService {
  RecitersCacheService._();

  static final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);

  static List<Map<String, dynamic>>? _allReciters;

  /// True once the cache has been loaded (from disk or network).
  static bool get isLoaded => _allReciters != null;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Return reciters whose moshaf list includes entries matching [riwayahId],
  /// loading from disk cache or network on first call.
  /// Results are deduplicated by reciter name.
  static Future<List<Map<String, dynamic>>> getRecitersForRiwayah(
    int riwayahId,
  ) async {
    final all = await _ensureLoaded();
    final seen = <String>{};
    final filtered = <Map<String, dynamic>>[];
    for (final r in all) {
      final name = r['name'] as String;
      if (!seen.add(name)) continue; // same reciter from a different riwayah
      final moshafs = (r['moshaf'] as List)
          .where((m) => (m['rewaya_id'] as int) == riwayahId)
          .toList();
      if (moshafs.isNotEmpty) {
        filtered.add({
          'name': name,
          'moshaf': moshafs,
        });
      }
    }
    return filtered;
  }

  /// Return all reciters across all riwayat (for the download picker).
  static Future<List<Map<String, dynamic>>> getAllReciters() async {
    return List<Map<String, dynamic>>.from(await _ensureLoaded());
  }

  /// Re-fetch everything from the API and overwrite the disk cache.
  static Future<void> refresh() async {
    loadingNotifier.value = true;
    _allReciters = null;
    try {
      _allReciters = await _fetchAll();
      await _writeCache(_allReciters!);
    } finally {
      loadingNotifier.value = false;
    }
  }

  // ── Internals ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _ensureLoaded() async {
    if (_allReciters != null) return _allReciters!;

    // 1. Try disk cache
    final cached = await _readCache();
    if (cached != null) {
      _allReciters = List<Map<String, dynamic>>.from(cached);
      return _allReciters!;
    }

    // 2. Fetch from API
    loadingNotifier.value = true;
    try {
      _allReciters = await _fetchAll();
      await _writeCache(_allReciters!);
      return _allReciters!;
    } finally {
      loadingNotifier.value = false;
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAll() async {
    final lang = TranslationService.isArabic ? 'ar' : 'en';
    final client = http.Client();
    final all = <Map<String, dynamic>>[];
    final seen = <String>{}; // dedup by reciter name across riwayat

    try {
      // Fetch list of riwayat
      final riwayatUri = Uri.parse(
        'https://mp3quran.net/api/v3/riwayat?language=$lang',
      );
      final riwayatRes = await client.get(riwayatUri);
      if (riwayatRes.statusCode != 200) {
        throw Exception('Failed to fetch riwayat: HTTP ${riwayatRes.statusCode}');
      }

      final riwayatData = jsonDecode(utf8.decode(riwayatRes.bodyBytes))
          as Map<String, dynamic>;
      final riwayatList = (riwayatData['riwayat'] as List?) ?? [];

      // Fetch reciters for each riwayah, 2 at a time
      for (int i = 0; i < riwayatList.length; i += 2) {
        final batch = <Future<void>>[];
        for (int j = i;
            j < i + 2 && j < riwayatList.length;
            j++) {
          final rw = riwayatList[j] as Map<String, dynamic>;
          final riwayahId = rw['id'] as int;
          batch.add(_fetchRecitersForRiwayah(client, riwayahId, lang, all, seen));
        }
        await Future.wait(batch);
        // Small delay between batches to be kind to the server
        if (i + 2 < riwayatList.length) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
      }
    } finally {
      client.close();
    }

    return all;
  }

  static Future<void> _fetchRecitersForRiwayah(
    http.Client client,
    int riwayahId,
    String lang,
    List<Map<String, dynamic>> sink,
    Set<String> seen,
  ) async {
    try {
      final uri = Uri.parse(
        'https://mp3quran.net/api/v3/reciters?language=$lang&riwayah=$riwayahId',
      );
      final res = await client.get(uri);
      if (res.statusCode != 200) return;

      final data = jsonDecode(utf8.decode(res.bodyBytes))
          as Map<String, dynamic>;
      final reciters = (data['reciters'] as List?) ?? [];

      for (final r in reciters) {
        // Dedup by name across riwayat — the same reciter often records
        // in multiple Qira'at and the API returns them under each riwayah.
        if (seen.add(r['name'] as String)) {
          sink.add(Map<String, dynamic>.from(r as Map));
        }
      }
    } catch (_) {
      // Skip this riwayah — the rest will still be available
    }
  }

  // ── Disk cache ──────────────────────────────────────────────────────────

  static Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/reciters_cache.json');
  }

  static Future<List<Map<String, dynamic>>?> _readCache() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      // Invalidate cache after 7 days or if it's from before the dedup fix
      final cacheVersion = decoded['_v'] as int? ?? 0;
      if (cacheVersion < 2) return null;
      final cachedAt = decoded['_cached_at'] as int? ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - cachedAt >
          const Duration(days: 7).inMilliseconds) {
        return null;
      }
      final list = (decoded['reciters'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(List<Map<String, dynamic>> reciters) async {
    try {
      final file = await _cacheFile();
      final wrapper = {
        '_v': 2,
        '_cached_at': DateTime.now().millisecondsSinceEpoch,
        'reciters': reciters,
      };
      await file.writeAsString(jsonEncode(wrapper));
    } catch (_) {}
  }
}
