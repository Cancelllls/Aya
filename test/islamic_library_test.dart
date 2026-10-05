import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/data/prophets_data.dart';
import 'package:aya_app/data/sirah_data.dart';
import 'package:aya_app/services/translation_service.dart';
import 'package:aya_app/services/islamic_book_service.dart';

void main() {
  group('Stories of the Prophets (Qisas al-Anbiya) Tests', () {
    test('contains all 25 canonical Quranic prophets', () {
      expect(ProphetsData.prophets.length, equals(25));
    });

    test('prophet IDs are sequentially numbered 1 to 25', () {
      for (int i = 0; i < ProphetsData.prophets.length; i++) {
        expect(ProphetsData.prophets[i].id, equals(i + 1));
      }
    });

    test('every prophet has complete bilingual names and content', () {
      for (final p in ProphetsData.prophets) {
        expect(p.nameAr, isNotEmpty);
        expect(p.nameEn, isNotEmpty);
        expect(p.titleAr, isNotEmpty);
        expect(p.titleEn, isNotEmpty);
        expect(p.summaryAr, isNotEmpty);
        expect(p.summaryEn, isNotEmpty);
        expect(p.periodAr, isNotEmpty);
        expect(p.periodEn, isNotEmpty);
        expect(p.quranMentions, greaterThan(0));
        expect(p.keySurahs, isNotEmpty);
        expect(p.sections, isNotEmpty);

        for (final sec in p.sections) {
          expect(sec.titleAr, isNotEmpty);
          expect(sec.titleEn, isNotEmpty);
          expect(sec.contentAr, isNotEmpty);
          expect(sec.contentEn, isNotEmpty);
        }
      }
    });

    test('first prophet is Adam and final prophet is Muhammad ﷺ', () {
      expect(ProphetsData.prophets.first.nameAr, contains('آدم'));
      expect(ProphetsData.prophets.first.nameEn, contains('Adam'));
      expect(ProphetsData.prophets.last.nameAr, contains('محمد'));
      expect(ProphetsData.prophets.last.nameEn, contains('Muhammad'));
    });
  });

  group('Prophetic Biography (Al-Sirah al-Nabawiyyah) Tests', () {
    test('contains all 22 chronological epochs/chapters', () {
      expect(SirahData.chapters.length, equals(22));
    });

    test('chapters are sequentially numbered 1 to 22', () {
      for (int i = 0; i < SirahData.chapters.length; i++) {
        expect(SirahData.chapters[i].id, equals(i + 1));
        expect(SirahData.chapters[i].number, equals(i + 1));
      }
    });

    test('period categorization splits into Makkan and Madinan phases', () {
      final makkanChapters = SirahData.chapters
          .where((c) => c.periodEn.contains('Makkan'))
          .toList();
      final madinanChapters = SirahData.chapters
          .where((c) => c.periodEn.contains('Madinan'))
          .toList();

      expect(makkanChapters.length, equals(11));
      expect(madinanChapters.length, equals(11));
      expect(makkanChapters.first.number, equals(1));
      expect(madinanChapters.first.number, equals(12));
    });

    test('every chapter has valid read time, summaries, and sections', () {
      for (final ch in SirahData.chapters) {
        expect(ch.titleAr, isNotEmpty);
        expect(ch.titleEn, isNotEmpty);
        expect(ch.summaryAr, isNotEmpty);
        expect(ch.summaryEn, isNotEmpty);
        expect(ch.yearAr, isNotEmpty);
        expect(ch.yearEn, isNotEmpty);
        expect(ch.readTimeMinutes, greaterThan(0));
        expect(ch.sections, isNotEmpty);

        for (final sec in ch.sections) {
          expect(sec.titleAr, isNotEmpty);
          expect(sec.titleEn, isNotEmpty);
          expect(sec.contentAr, isNotEmpty);
          expect(sec.contentEn, isNotEmpty);
        }
      }
    });
  });

  group('Islamic Library Translation Keys', () {
    setUp(() {
      TranslationService.setLanguage('en');
    });

    test('translation keys exist for both English and Arabic', () {
      const keys = [
        'stories_of_prophets',
        'stories_of_prophets_sub',
        'prophetic_sirah',
        'prophetic_sirah_sub',
      ];

      for (final key in keys) {
        TranslationService.setLanguage('en');
        final enText = TranslationService.t(key);
        expect(enText, isNot(key), reason: 'EN missing key $key');

        TranslationService.setLanguage('ar');
        final arText = TranslationService.t(key);
        expect(arText, isNot(key), reason: 'AR missing key $key');
        expect(
          arText,
          isNot(enText),
          reason: 'AR and EN should differ for $key',
        );
      }
    });
  });

  group('Full Islamic Books Service Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('loads and parses full Raheeq Al-Makhtum book (452 pages)', () async {
      final book = await IslamicBookService.loadBook('raheeq_makhtum');
      expect(book.titleAr, contains('الرحيق المختوم'));
      expect(book.allPages.length, equals(452));
      expect(book.chapters.length, greaterThan(50));

      final searchResults = IslamicBookService.searchBook(book, 'الحديبية');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.pageNum, greaterThan(0));
    });

    test('loads and parses full Qisas al-Anbiya book (888 pages)', () async {
      final book = await IslamicBookService.loadBook('qisas_al_anbiya');
      expect(book.titleAr, contains('قصص الأنبياء'));
      expect(book.allPages.length, equals(888));
      expect(book.chapters.length, greaterThan(20));

      final searchResults = IslamicBookService.searchBook(book, 'إبراهيم');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.pageNum, greaterThan(0));
    });
  });
}
