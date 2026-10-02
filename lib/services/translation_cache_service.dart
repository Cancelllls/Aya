import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/quran_models.dart';
import 'database_service.dart';

class TranslationCacheService {
  static final TranslationCacheService instance = TranslationCacheService._();
  TranslationCacheService._();

  static const String _cdnBase =
      'https://cdn.jsdelivr.net/gh/Cancelllls/Islamic-Assets@main/translations';
  static const String _fallbackBase =
      'https://raw.githubusercontent.com/Cancelllls/Islamic-Assets/main/translations';

  final Map<String, String> _memCache = {};
  static const int _maxCacheEntries = 600;

  void cacheAyah(String editionId, int surah, int ayah, String text) {
    if (_memCache.length >= _maxCacheEntries) {
      _memCache.remove(_memCache.keys.first);
    }
    _memCache['$editionId:$surah:$ayah'] = text;
  }

  String? getFromMemory(String editionId, int surah, int ayah) {
    return _memCache['$editionId:$surah:$ayah'];
  }

  /// Download a full translation edition from CDN and store in SQLite extra_translations table.
  /// Returns the number of ayahs saved.
  Future<int> downloadFromCdn(
    String editionId, {
    Function(double progress)? onProgress,
    Function(String log)? onLog,
  }) async {
    final edition = availableTranslations
        .where((e) => e.identifier == editionId)
        .firstOrNull;
    if (edition == null) {
      throw Exception('Unknown translation edition: $editionId');
    }

    if (edition.isBundled) {
      onProgress?.call(1.0);
      return 6236;
    }

    final cdnUrl = '$_cdnBase/${edition.cdnFile}';
    final fallbackUrl = '$_fallbackBase/${edition.cdnFile}';
    final isGzip = edition.cdnFile.endsWith('.gz');

    onLog?.call('Downloading ${edition.name} from CDN...');
    onProgress?.call(0.1);

    http.Response response;
    try {
      response = await http
          .get(Uri.parse(cdnUrl))
          .timeout(const Duration(minutes: 3));
    } catch (_) {
      onLog?.call('CDN primary timed out. Trying fallback repository...');
      response = await http
          .get(Uri.parse(fallbackUrl))
          .timeout(const Duration(minutes: 3));
    }

    if (response.statusCode != 200) {
      response = await http
          .get(Uri.parse(fallbackUrl))
          .timeout(const Duration(minutes: 3));
    }

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    onProgress?.call(0.5);
    var bytes = response.bodyBytes;
    if (isGzip) {
      onLog?.call('Decompressing translation pack...');
      bytes = Uint8List.fromList(gzip.decode(bytes));
    }

    onProgress?.call(0.7);
    final jsonStr = utf8.decode(bytes);
    final rawMap = jsonDecode(jsonStr) as Map<String, dynamic>;

    final items = <Map<String, dynamic>>[];
    for (final entry in rawMap.entries) {
      final parts = entry.key.split(':');
      if (parts.length == 2) {
        final s = int.tryParse(parts[0]);
        final a = int.tryParse(parts[1]);
        if (s != null && a != null) {
          final text = (entry.value as String?) ?? '';
          items.add({
            'edition_id': editionId,
            'surah_number': s,
            'ayah_number': a,
            'text': text,
          });
          cacheAyah(editionId, s, a, text);
        }
      }
    }

    onProgress?.call(0.85);
    final db = await DatabaseService.getInstance();
    await db.saveExtraTranslationsBatch(editionId, items);

    onProgress?.call(1.0);
    onLog?.call('Saved ${items.length} verses locally.');
    return items.length;
  }

  /// Get translation for a single ayah. Checks memory cache -> SQLite -> null.
  Future<String?> getAyahTranslation(
    int surahNumber,
    int ayahNumber, {
    String? editionId,
  }) async {
    final edition = editionId ?? 'en.sahih';
    final cached = getFromMemory(edition, surahNumber, ayahNumber);
    if (cached != null) return cached;

    final db = await DatabaseService.getInstance();
    final text = await db.getExtraTranslation(edition, surahNumber, ayahNumber);
    if (text != null) {
      cacheAyah(edition, surahNumber, ayahNumber, text);
      return text;
    }
    return null;
  }
}
