import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/quran_models.dart';
import 'package:aya_app/models/offline_surahs.dart';
import 'package:aya_app/services/translation_cache_service.dart';
import 'package:aya_app/services/quran_download_service.dart';
import 'package:aya_app/utils/text_helpers.dart';

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

  group('TafsirEdition bundled & download service tests', () {
    test('all availableTafsirs are marked as bundled offline', () {
      expect(availableTafsirs.length, 8);
      for (final edition in availableTafsirs) {
        expect(edition.isBundled, isTrue,
            reason: '${edition.identifier} must be bundled');
      }
    });

    test('getTafsirCountForEdition returns 114 for bundled editions', () async {
      final service = QuranDownloadService.instance;
      for (final edition in availableTafsirs) {
        final count = await service.getTafsirCountForEdition(edition.identifier);
        expect(count, 114,
            reason: '${edition.identifier} should return 114 surahs');
      }
    });

    test('cancelTafsirDownload resets downloading state', () {
      final service = QuranDownloadService.instance;
      service.cancelTafsirDownload();
      expect(service.isDownloadingTafsir, isFalse);
      expect(service.downloadingTafsirEdition, isNull);
      expect(service.tafsirDownloadProgress, 0.0);
    });

    test('cancelTranslationDownload resets downloading state', () {
      final service = QuranDownloadService.instance;
      service.cancelTranslationDownload();
      expect(service.isDownloadingTranslation, isFalse);
      expect(service.downloadingTranslationEdition, isNull);
      expect(service.translationDownloadProgress, 0.0);
    });

    test('binary Tafsir language selection strictly filters by ar or en', () {
      final arOnly = availableTafsirs.where((e) => e.language == 'ar').toList();
      final enOnly = availableTafsirs.where((e) => e.language == 'en').toList();

      expect(arOnly.isNotEmpty, isTrue);
      expect(enOnly.isNotEmpty, isTrue);
      expect(arOnly.every((e) => e.language == 'ar'), isTrue);
      expect(enOnly.every((e) => e.language == 'en'), isTrue);

      // Verify no overlap and all editions belong to either ar or en
      expect(arOnly.length + enOnly.length, availableTafsirs.length);
      for (final t in arOnly) {
        expect(enOnly.contains(t), isFalse);
      }
    });

    test('allOfflineSurahs provides valid Arabic and English names for 114 Surahs', () {
      expect(allOfflineSurahs.length, 114);
      for (int i = 0; i < 114; i++) {
        final surah = allOfflineSurahs[i];
        expect(surah.number, i + 1);
        expect(surah.name.isNotEmpty, isTrue);
        expect(surah.englishName.isNotEmpty, isTrue);
      }
    });

    test('cleanTranslationText removes HTML tags and entities', () {
      // Clear Quran format check
      expect(cleanTranslationText('<i>Alif-Lãm-Mĩm.</i>'), 'Alif-Lãm-Mĩm.');
      expect(
        cleanTranslationText('<b>Indeed</b>, Allah is with the <i>patient</i>.'),
        'Indeed, Allah is with the patient.',
      );
      expect(
        cleanTranslationText('Text with &quot;quotes&quot; and &#39;apostrophe&#39; and &amp; ampersand'),
        'Text with "quotes" and \'apostrophe\' and & ampersand',
      );
      expect(
        cleanTranslationText('<footnote id="1">Note</footnote><sup>1</sup> Guidance for the God-fearing.'),
        'Guidance for the God-fearing.',
      );
      expect(cleanTranslationText(''), '');
    });
  });
}


