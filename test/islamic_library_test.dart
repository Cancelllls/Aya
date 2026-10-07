import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/data/prophets_data.dart';
import 'package:aya_app/data/sirah_data.dart';
import 'package:aya_app/data/fiqh_chapters_data.dart';
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

    test('every chapter has valid read time and summaries', () {
      for (final ch in SirahData.chapters) {
        expect(ch.titleAr, isNotEmpty);
        expect(ch.titleEn, isNotEmpty);
        expect(ch.summaryAr, isNotEmpty);
        expect(ch.summaryEn, isNotEmpty);
        expect(ch.yearAr, isNotEmpty);
        expect(ch.yearEn, isNotEmpty);
        expect(ch.readTimeMinutes, greaterThan(0));
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

    test('cleanText removes redundant footnotes and editorial brackets', () {
      const sample = 'ابْن كثير: (١) هُوَ أَبُو الْفِدَاء عماد الدّين [١] إِسْمَاعِيل [ص: ٤٥] [ ] ( ) (*) بن عمر [وصفته]';
      final cleaned = IslamicBookService.cleanText(sample);
      expect(cleaned, isNot(contains('(١)')));
      expect(cleaned, isNot(contains('[١]')));
      expect(cleaned, isNot(contains('(*)')));
      expect(cleaned, isNot(contains('[ص: ٤٥]')));
      expect(cleaned, isNot(contains('[]')));
      expect(cleaned, isNot(contains('()')));
      expect(cleaned, contains('إِسْمَاعِيل'));
      expect(cleaned, contains('وصفته'));
    });

    test('normalizeDigits accurately converts Eastern Arabic-Indic numerals', () {
      expect(IslamicBookService.normalizeDigits('١٢٣'), equals('123'));
      expect(IslamicBookService.normalizeDigits('٤٥٦'), equals('456'));
      expect(IslamicBookService.normalizeDigits('٧٨٩٠'), equals('7890'));
      expect(IslamicBookService.normalizeDigits('ص ٤٥ من ٨٨٨'), equals('ص 45 من 888'));
    });

    test('getScopedBook creates perfectly bounded sub-book for Adam and Introduction', () async {
      final fullBook = await IslamicBookService.loadBook('qisas_al_anbiya');
      
      // Introduction: pages 1 to 17
      final intro = IslamicBookService.getScopedBook(
        fullBook,
        1,
        17,
        scopeTitleAr: 'مقدمة كتاب قصص الأنبياء (ابن كثير)',
      );
      expect(intro.titleAr, equals('مقدمة كتاب قصص الأنبياء (ابن كثير)'));
      expect(intro.totalPages, equals(17));
      expect(intro.allPages.length, equals(17));
      expect(intro.allPages.first.pageNum, equals(1));
      expect(intro.allPages.last.pageNum, equals(17));

      // Adam: pages 18 to 87
      final adam = IslamicBookService.getScopedBook(
        fullBook,
        18,
        87,
        scopeTitleAr: 'قصة آدم عليه السلام',
      );
      expect(adam.titleAr, equals('قصة آدم عليه السلام'));
      expect(adam.totalPages, equals(70));
      expect(adam.allPages.length, equals(70));
      expect(adam.allPages.first.pageNum, equals(18));
      expect(adam.allPages.last.pageNum, equals(87));
      expect(adam.chapters, isNotEmpty);
      expect(adam.chapters.first.title, contains('آدم'));
    });

    test('getScopedBook creates perfectly bounded sub-book for Raheeq Al-Makhtum Introduction', () async {
      final fullBook = await IslamicBookService.loadBook('raheeq_makhtum');
      final intro = IslamicBookService.getScopedBook(
        fullBook,
        1,
        6,
        scopeTitleAr: 'مقدمة كتاب الرحيق المختوم',
      );
      expect(intro.titleAr, equals('مقدمة كتاب الرحيق المختوم'));
      expect(intro.totalPages, equals(6));
      expect(intro.allPages.length, equals(6));
      expect(intro.allPages.first.pageNum, equals(1));
      expect(intro.allPages.last.pageNum, equals(6));
      expect(SirahData.chapters.first.bookStartPage, equals(7));
    });

    test('all 25 Prophets have valid non-null bookStartPage and bookEndPage', () {
      for (final p in ProphetsData.prophets) {
        expect(p.bookStartPage, isNotNull, reason: '${p.nameAr} missing bookStartPage');
        expect(p.bookEndPage, isNotNull, reason: '${p.nameAr} missing bookEndPage');
        expect(p.bookStartPage!, greaterThan(0));
        expect(p.bookEndPage!, greaterThanOrEqualTo(p.bookStartPage!));
        expect(p.bookStartPageEn, isNotNull, reason: '${p.nameEn} missing bookStartPageEn');
        expect(p.bookEndPageEn, isNotNull, reason: '${p.nameEn} missing bookEndPageEn');
        expect(p.bookStartPageEn!, greaterThan(0));
        expect(p.bookEndPageEn!, greaterThanOrEqualTo(p.bookStartPageEn!));
      }
    });

    test('all 22 Sirah chapters have valid non-null bookStartPage and bookEndPage', () {
      for (final c in SirahData.chapters) {
        expect(c.bookStartPage, isNotNull, reason: '${c.titleAr} missing bookStartPage');
        expect(c.bookEndPage, isNotNull, reason: '${c.titleAr} missing bookEndPage');
        expect(c.bookStartPage!, greaterThan(0));
        expect(c.bookEndPage!, greaterThanOrEqualTo(c.bookStartPage!));
        expect(c.bookStartPageEn, isNotNull, reason: '${c.titleEn} missing bookStartPageEn');
        expect(c.bookEndPageEn, isNotNull, reason: '${c.titleEn} missing bookEndPageEn');
        expect(c.bookStartPageEn!, greaterThan(0));
        expect(c.bookEndPageEn!, greaterThanOrEqualTo(c.bookStartPageEn!));
      }
    });

    test('loads and parses full English Raheeq Al-Makhtum book (256 pages)', () async {
      final book = await IslamicBookService.loadBook('raheeq_makhtum_en');
      expect(book.bookId, equals('raheeq_makhtum_en'));
      expect(book.totalPages, equals(256));
      expect(book.allPages.length, equals(256));
      expect(book.allPages.first.text, contains('Sealed Nectar'));
    });

    test('loads and parses full English Qisas al-Anbiya book (227 pages)', () async {
      final book = await IslamicBookService.loadBook('qisas_al_anbiya_en');
      expect(book.bookId, equals('qisas_al_anbiya_en'));
      expect(book.totalPages, equals(227));
      expect(book.allPages.length, equals(227));
      expect(book.allPages[1].text, contains('Stories of the Prophets'));
    });

    test('loads and parses full Al-Fiqh Al-Muyassar book (439 pages)', () async {
      final book = await IslamicBookService.loadBook('fiqh_muyassar');
      expect(book.titleAr, contains('الفقه الميسر'));
      expect(book.allPages.length, equals(439));
      expect(book.chapters.length, equals(15));

      final searchResults = IslamicBookService.searchBook(book, 'الوضوء');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.pageNum, greaterThan(0));
    });

    test('loads and parses full English Al-Fiqh Al-Muyassar book (439 pages)', () async {
      final book = await IslamicBookService.loadBook('fiqh_muyassar_en');
      expect(book.bookId, equals('fiqh_muyassar_en'));
      expect(book.titleEn, contains('Al-Fiqh Al-Muyassar'));
      expect(book.totalPages, equals(439));
      expect(book.allPages.length, equals(439));
      expect(book.allPages.first.text, contains('Islamic Jurisprudence'));
    });
  });

  group('Al-Fiqh Al-Muyassar Chapters Tests', () {
    test('contains all 15 canonical books and chapters', () {
      expect(FiqhChaptersData.chapters.length, equals(15));
    });

    test('chapter IDs and numbers are sequentially 1 to 15', () {
      for (int i = 0; i < FiqhChaptersData.chapters.length; i++) {
        expect(FiqhChaptersData.chapters[i].id, equals(i + 1));
        expect(FiqhChaptersData.chapters[i].number, equals(i + 1));
      }
    });

    test('all 15 chapters have valid non-empty titles, summaries, and categories', () {
      for (final ch in FiqhChaptersData.chapters) {
        expect(ch.titleAr, isNotEmpty);
        expect(ch.titleEn, isNotEmpty);
        expect(ch.summaryAr, isNotEmpty);
        expect(ch.summaryEn, isNotEmpty);
        expect(ch.categoryAr, isNotEmpty);
        expect(ch.categoryEn, isNotEmpty);
        expect(ch.readTimeMinutes, greaterThan(0));
      }
    });

    test('chapters cover full book from page 1 to page 439 continuously without gaps', () {
      expect(FiqhChaptersData.chapters.first.bookStartPage, equals(1));
      expect(FiqhChaptersData.chapters.last.bookEndPage, equals(439));

      for (int i = 0; i < FiqhChaptersData.chapters.length; i++) {
        final ch = FiqhChaptersData.chapters[i];
        expect(ch.bookStartPage, greaterThan(0));
        expect(ch.bookEndPage, greaterThanOrEqualTo(ch.bookStartPage));

        if (i > 0) {
          final prev = FiqhChaptersData.chapters[i - 1];
          expect(ch.bookStartPage, equals(prev.bookEndPage + 1),
              reason: '${ch.titleAr} should follow ${prev.titleAr}');
        }
      }
    });

    test('getChapterById retrieves correct chapter', () {
      final ch = FiqhChaptersData.getChapterById(2);
      expect(ch, isNotNull);
      expect(ch!.titleAr, contains('الطهارة'));
      expect(FiqhChaptersData.getChapterById(999), isNull);
    });
  });
}
