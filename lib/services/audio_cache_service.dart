import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Transparent LRU disk cache for streamed Quran recitations.
///
/// Ensures recitations played via URL are automatically stored locally
/// without blocking initial playback, capping disk footprint at 250 MB.
class AudioCacheService {
  static final AudioCacheService instance = AudioCacheService._();
  AudioCacheService._();

  Directory? _cacheDir;
  final Set<String> _inFlightDownloads = {};

  /// Maximum cache limit: 250 MB
  static const int maxCacheBytes = 250 * 1024 * 1024;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/audio_stream_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return _cacheDir!;
  }

  /// Returns cached [File] if it exists and has non-zero size.
  /// Updates file modification timestamp for LRU tracking.
  Future<File?> getCachedAudio(String cacheKey) async {
    try {
      final dir = await _getCacheDirectory();
      final file = File('${dir.path}/$cacheKey');
      if (await file.exists()) {
        final len = await file.length();
        if (len > 0) {
          try {
            await file.setLastModified(DateTime.now());
          } catch (_) {}
          return file;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Downloads and caches streamed recitation in background.
  /// Uses an atomic `.tmp` rename pattern to prevent corrupt partial reads.
  Future<void> cacheStreamUrl(String url, String cacheKey) async {
    if (_inFlightDownloads.contains(cacheKey)) return;
    _inFlightDownloads.add(cacheKey);

    try {
      final dir = await _getCacheDirectory();
      final targetFile = File('${dir.path}/$cacheKey');
      if (await targetFile.exists() && await targetFile.length() > 0) {
        return;
      }

      final tempFile = File('${dir.path}/$cacheKey.tmp');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(minutes: 5),
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await tempFile.writeAsBytes(response.bodyBytes);
        if (await tempFile.exists()) {
          await tempFile.rename(targetFile.path);
        }
        await pruneLru();
      }
    } catch (_) {
      // Non-fatal stream caching failure
    } finally {
      _inFlightDownloads.remove(cacheKey);
    }
  }

  /// Prunes least recently accessed files if cache size exceeds [maxBytes].
  Future<void> pruneLru({int maxBytes = maxCacheBytes}) async {
    try {
      final dir = await _getCacheDirectory();
      final entities = dir.listSync().whereType<File>().toList();
      int totalBytes = 0;
      final fileStats = <Map<String, dynamic>>[];

      for (final file in entities) {
        if (file.path.endsWith('.tmp')) {
          try {
            file.deleteSync();
          } catch (_) {}
          continue;
        }
        final stat = file.statSync();
        totalBytes += stat.size;
        fileStats.add({
          'file': file,
          'size': stat.size,
          'modified': stat.modified,
        });
      }

      if (totalBytes > maxBytes) {
        fileStats.sort(
          (a, b) =>
              (a['modified'] as DateTime).compareTo(b['modified'] as DateTime),
        );
        final targetBudget = (maxBytes * 0.8).toInt();

        for (final entry in fileStats) {
          if (totalBytes <= targetBudget) break;
          final file = entry['file'] as File;
          final size = entry['size'] as int;
          try {
            file.deleteSync();
            totalBytes -= size;
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Clears entire stream cache.
  Future<void> clearCache() async {
    try {
      final dir = await _getCacheDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _cacheDir = null;
      }
    } catch (_) {}
  }
}
