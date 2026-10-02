import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/quran_models.dart';
import 'package:aya_app/services/translation_cache_service.dart';

void main() {
  group('TranslationEdition model', () {
    test('contains all 8 expected editions', () {
      final ids = availableTranslations.map((e) => e.identifier).toList();
      expect(ids, contains('en.sahih'));
      expect(ids, contains('en.khattab'));
      expect(ids, contains('id.kemenag'));
      expect(ids, contains('ur.jalandhry'));
      expect(ids, contains('fr.hamidullah'));
      expect(ids, contains('tr.diyanet'));
      expect(ids, contains('ru.kuliev'));
      expect(ids, contains('es.cortes'));
    });

    test('en.sahih is marked as bundled', () {
      final sahih = availableTranslations.firstWhere((e) => e.identifier == 'en.sahih');
      expect(sahih.isBundled, isTrue);
      expect(sahih.language, 'en');
      expect(sahih.isRtl, isFalse);
    });

    test('en.khattab has proper CDN filename and LTR direction', () {
      final khattab = availableTranslations.firstWhere((e) => e.identifier == 'en.khattab');
      expect(khattab.isBundled, isFalse);
      expect(khattab.cdnFile, 'en.khattab.json.gz');
      expect(khattab.translator, 'Dr. Mustafa Khattab');
      expect(khattab.isRtl, isFalse);
    });

    test('ur.jalandhry is marked RTL', () {
      final urdu = availableTranslations.firstWhere((e) => e.identifier == 'ur.jalandhry');
      expect(urdu.language, 'ur');
      expect(urdu.isRtl, isTrue);
    });

    test('custom TranslationEdition instantiation', () {
      const edition = TranslationEdition(
        'test.id',
        'Test Name',
        'اسم تجريبي',
        'Test Translator',
        'مترجم تجريبي',
        language: 'tl',
        cdnFile: 'test.json.gz',
      );

      expect(edition.identifier, 'test.id');
      expect(edition.name, 'Test Name');
      expect(edition.nameAr, 'اسم تجريبي');
      expect(edition.translator, 'Test Translator');
      expect(edition.translatorAr, 'مترجم تجريبي');
      expect(edition.language, 'tl');
      expect(edition.isRtl, isFalse);
      expect(edition.cdnFile, 'test.json.gz');
      expect(edition.isBundled, isFalse);
    });
  });

  group('TranslationCacheService memory caching', () {
    test('cacheAyah and getFromMemory store and retrieve correctly', () {
      final service = TranslationCacheService.instance;
      service.cacheAyah('en.khattab', 1, 1, 'In the Name of Allah—the Most Compassionate, Most Merciful.');

      final cached = service.getFromMemory('en.khattab', 1, 1);
      expect(cached, 'In the Name of Allah—the Most Compassionate, Most Merciful.');

      final notFound = service.getFromMemory('en.khattab', 1, 2);
      expect(notFound, isNull);
    });

    test('gzip decode process correctly parses translation JSON structure', () {
      final originalMap = {
        '1:1': 'In the Name of Allah—the Most Compassionate, Most Merciful.',
        '1:2': 'All praise is for Allah—Lord of all worlds,',
      };
      final jsonString = jsonEncode(originalMap);
      final uncompressedBytes = utf8.encode(jsonString);
      final compressedBytes = gzip.encode(uncompressedBytes);

      // Verify decompression
      final decompressed = gzip.decode(compressedBytes);
      final decodedString = utf8.decode(decompressed);
      final parsed = jsonDecode(decodedString) as Map<String, dynamic>;

      expect(parsed.length, 2);
      expect(parsed['1:1'], originalMap['1:1']);
      expect(parsed['1:2'], originalMap['1:2']);
    });
  });
}
