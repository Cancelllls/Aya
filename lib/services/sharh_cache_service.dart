import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Offline cache service for Dorar hadith sharh explanations fetched from CDN.
class SharhCacheService {
  final void Function(String message) onLog;

  SharhCacheService({this.onLog = _defaultLog});

  static void _defaultLog(String msg) {}

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

  static const _cdnBase = 'https://cdn.jsdelivr.net/gh/Cancelllls/Islamic-Assets@main/sharh';

  static const _books = {
    'bukhari': {'file': 'sharh_bukhari.json.gz', 'gzip': true},
    'muslim': {'file': 'sharh_muslim.json', 'gzip': false},
    'abudawud': {'file': 'sharh_abudawud.json', 'gzip': false},
    'tirmidhi': {'file': 'sharh_tirmidhi.json', 'gzip': false},
    'nasai': {'file': 'sharh_nasai.json', 'gzip': false},
  };

  /// List available books on CDN with their sizes
  static Map<String, Map<String, dynamic>> get availableBooks => _books;

  /// Download one book's sharh from jsDelivr CDN and merge into local cache.
  ///
  /// Returns the number of new entries added.
  Future<int> downloadFromCdn(String bookId) async {
    final info = _books[bookId];
    if (info == null) throw Exception('Unknown book: $bookId');

    final url = '$_cdnBase/${info['file']}';
    final isGzip = info['gzip'] == true;

    onLog('Downloading $bookId from CDN...');
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(minutes: 5));

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    var bytes = response.bodyBytes;
    onLog('  ${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB');

    if (isGzip) {
      onLog('  Decompressing...');
      bytes = Uint8List.fromList(gzip.decode(bytes));
      onLog('  ${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB decompressed');
    }

    final cdnData = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    onLog('  ${cdnData.length} entries');

    // Merge with existing cache
    final cache = await _loadCache();
    int added = 0;
    for (final entry in cdnData.entries) {
      if (!cache.containsKey(entry.key) || cache[entry.key]?['_ok'] != true) {
        cache[entry.key] = entry.value;
        added++;
      }
    }
    onLog('  $added new, ${cache.length} total');
    await _saveCache(cache);
    return added;
  }

  /// Look up a cached explanation for a specific hadith.
  Future<Map<String, dynamic>?> cachedExplanation(
      String bookId, int hadithNumber) async {
    final cache = await _loadCache();
    final entry = cache['$bookId:$hadithNumber'];
    if (entry is Map && entry['_ok'] == true) {
      return Map<String, dynamic>.from(entry);
    }
    return null;
  }
}
