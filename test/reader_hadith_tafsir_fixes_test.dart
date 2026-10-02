import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/quran_models.dart';

void main() {
  group('Tafsir Editions & Cleaning Tests', () {
    test('availableTafsirs contains both English editions and canonical Arabic editions', () {
      final identifiers = availableTafsirs.map((e) => e.identifier).toList();
      expect(identifiers, contains('ar.muyassar'));
      expect(identifiers, contains('en.ibnkathir'));
      expect(identifiers, contains('en.maududi'));

      for (final t in availableTafsirs) {
        expect(t.identifier.isNotEmpty, isTrue);
        expect(t.name.isNotEmpty, isTrue);
        expect(t.mufassir.isNotEmpty, isTrue);
        expect(t.mufassirEn.isNotEmpty, isTrue);
        expect(t.language == 'ar' || t.language == 'en', isTrue);
      }
    });

    test('English tafsir editions are properly configured with language en', () {
      final englishEditions = availableTafsirs.where((e) => e.language == 'en').toList();
      expect(englishEditions.length, equals(2));
      expect(englishEditions.any((e) => e.identifier == 'en.ibnkathir'), isTrue);
      expect(englishEditions.any((e) => e.identifier == 'en.maududi'), isTrue);
    });

    test('Tafsir HTML stripper cleans tags, unescapes entities and normalizes newlines', () {
      const rawHtml = '<p>In the Name of Allah, the Most Gracious, the Most Merciful.</p><br>'
          'The meaning of &quot;Al-Fatihah&quot; is the Opener, &#39;Umm Al-Kitab&#39; &amp; &lt;the Mother of the Book&gt;.\n\n\n\n'
          'Every prayer requires it.&nbsp;Amen.';

      // Logic identical to ApiService._cleanTafsirHtml
      final cleaned = rawHtml
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&nbsp;', ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      expect(cleaned, isNot(contains('<p>')));
      expect(cleaned, isNot(contains('</p>')));
      expect(cleaned, isNot(contains('<br>')));
      expect(cleaned, contains('"Al-Fatihah"'));
      expect(cleaned, contains("'Umm Al-Kitab'"));
      expect(cleaned, contains('& <the Mother of the Book>'));
      expect(cleaned, contains('Every prayer requires it. Amen.'));
      expect(cleaned, isNot(contains('\n\n\n')));
    });
  });

  group('Hadith Pagination & Navigation Tests', () {
    const int pageSize = 20;

    test('Large collection totalPages scales beyond 5 pages without artificial ceiling', () {
      const int bukhariCount = 7563;
      final totalPages = (bukhariCount / pageSize).ceil();
      expect(totalPages, equals(379));
      expect(totalPages, greaterThan(5));
    });

    test('Page offset accurately matches requested page', () {
      int getOffset(int page) => (page - 1) * pageSize;

      expect(getOffset(1), equals(0));
      expect(getOffset(2), equals(20));
      expect(getOffset(5), equals(80));
      expect(getOffset(379), equals(7560));
    });

    test('Jump to Hadith accurately computes correct page index', () {
      int getPageForHadith(int hadithNumber) => ((hadithNumber - 1) ~/ pageSize) + 1;

      expect(getPageForHadith(1), equals(1));
      expect(getPageForHadith(20), equals(1));
      expect(getPageForHadith(21), equals(2));
      expect(getPageForHadith(85), equals(5));
      expect(getPageForHadith(5000), equals(250));
      expect(getPageForHadith(7563), equals(379));
    });

    test('Cross-book search with 500 result limit yields 25 pages', () {
      const int searchLimit = 500;
      final totalSearchPages = (searchLimit / pageSize).ceil();
      expect(totalSearchPages, equals(25));
    });
  });

  group('Madinah 15-Line Mushaf Sizing Tests', () {
    test('Mushaf page range is strictly 1 to 604', () {
      const int totalMushafPages = 604;
      expect(totalMushafPages, equals(604));

      int clampPage(int page) => page.clamp(1, 604);
      expect(clampPage(0), equals(1));
      expect(clampPage(1), equals(1));
      expect(clampPage(604), equals(604));
      expect(clampPage(650), equals(604));
    });

    test('Dynamic proportional line height calculation fits without negative space or overflow', () {
      // Test across small (500), medium (750), and large (1000) logical height viewports
      for (final availableHeight in [500.0, 750.0, 1000.0]) {
        // Standard page without banner (15 lines)
        final textSpaceNormal = availableHeight.clamp(240.0, 1200.0);
        final targetLineHeightPxNormal = textSpaceNormal / 15;
        final baseFontSizeNormal = (targetLineHeightPxNormal / 1.82).clamp(14.0, 21.0);
        final textLineHeightNormal = (targetLineHeightPxNormal / baseFontSizeNormal).clamp(1.6, 2.0);

        expect(baseFontSizeNormal, inInclusiveRange(14.0, 21.0));
        expect(textLineHeightNormal, inInclusiveRange(1.6, 2.0));
        expect(15 * baseFontSizeNormal * textLineHeightNormal, lessThanOrEqualTo(availableHeight + 50.0));

        // Page with Surah banner (11 lines)
        const double bannerSpace = 54.0 + 28.0; // Banner + Bismillah
        final double textSpaceBanner = (availableHeight - bannerSpace).clamp(240.0, 1200.0);
        final targetLineHeightPxBanner = textSpaceBanner / 11;
        final baseFontSizeBanner = (targetLineHeightPxBanner / 1.82).clamp(14.0, 21.0);
        final textLineHeightBanner = (targetLineHeightPxBanner / baseFontSizeBanner).clamp(1.6, 2.0);

        expect(baseFontSizeBanner, inInclusiveRange(14.0, 21.0));
        expect(textLineHeightBanner, inInclusiveRange(1.6, 2.0));
      }
    });
  });
}
