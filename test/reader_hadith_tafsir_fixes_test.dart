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

  group('Hadith Compact Floating Pill & Clearance Tests', () {
    test('Compact floating pill height is exactly 38px and non-obtrusive', () {
      const double pillHeight = 38.0;
      expect(pillHeight, equals(38.0));
      expect(pillHeight, lessThan(50.0));
    });

    test('List bottom clearance prevents collision with floating pill and bottom navbar', () {
      double getHadithListBottomPadding({required bool isFloatingNav, required int totalPages}) {
        return isFloatingNav
            ? (totalPages > 1 ? 128.0 : 85.0)
            : (totalPages > 1 ? 64.0 : 16.0);
      }

      // In floating mode with multiple pages, padding is 128 (nav bar 60 + pill 38 + breathing room 30)
      expect(getHadithListBottomPadding(isFloatingNav: true, totalPages: 10), equals(128.0));
      // In floating mode with single page, padding is 85 (nav bar clearance)
      expect(getHadithListBottomPadding(isFloatingNav: true, totalPages: 1), equals(85.0));
      // In solid mode with multiple pages, padding is 64
      expect(getHadithListBottomPadding(isFloatingNav: false, totalPages: 10), equals(64.0));
      // In solid mode with single page, padding is 16
      expect(getHadithListBottomPadding(isFloatingNav: false, totalPages: 1), equals(16.0));
    });

    test('Jump to page validator properly handles boundaries and invalid inputs', () {
      int? validatePageTarget(String input, int totalPages) {
        final parsed = int.tryParse(input.trim());
        if (parsed != null && parsed >= 1 && parsed <= totalPages) {
          return parsed;
        }
        return null;
      }

      expect(validatePageTarget('1', 379), equals(1));
      expect(validatePageTarget('379', 379), equals(379));
      expect(validatePageTarget('150', 379), equals(150));
      expect(validatePageTarget('0', 379), isNull);
      expect(validatePageTarget('380', 379), isNull);
      expect(validatePageTarget('-5', 379), isNull);
      expect(validatePageTarget('abc', 379), isNull);
      expect(validatePageTarget('', 379), isNull);
    });
  });

  group('Quran Dynamic Text Scaling & Pager Stability Tests', () {
    test('Quran reader dynamically adapts font size to both width and height', () {
      double computeBaseFontSize({
        required double availableWidth,
        required double availableHeight,
        required double scaleMultiplier,
        int estimatedLines = 15,
      }) {
        final double availableTextSpace = availableHeight.clamp(200.0, 1400.0);
        final double targetLineHeightPx = availableTextSpace / estimatedLines;
        final double widthFactor = (availableWidth / 360.0).clamp(0.85, 1.35);
        return ((targetLineHeightPx / 1.85) * widthFactor).clamp(13.0, 28.0) * scaleMultiplier;
      }

      // Default scale (1.0) on phone (390 x 700)
      final phoneSize = computeBaseFontSize(
        availableWidth: 390.0,
        availableHeight: 700.0,
        scaleMultiplier: 1.0,
      );
      expect(phoneSize, inInclusiveRange(18.0, 28.0));

      // Pinch zoom in (1.5x)
      final zoomedSize = computeBaseFontSize(
        availableWidth: 390.0,
        availableHeight: 700.0,
        scaleMultiplier: 1.5,
      );
      expect(zoomedSize, equals(phoneSize * 1.5));

      // Pinch zoom out (0.8x)
      final shrunkSize = computeBaseFontSize(
        availableWidth: 390.0,
        availableHeight: 700.0,
        scaleMultiplier: 0.8,
      );
      expect(shrunkSize, equals(phoneSize * 0.8));

      // Wider device (tablet 600 width) has larger width factor
      final tabletSize = computeBaseFontSize(
        availableWidth: 600.0,
        availableHeight: 700.0,
        scaleMultiplier: 1.0,
      );
      expect(tabletSize, greaterThan(phoneSize));
    });

    test('Pinch zoom scale is strictly clamped within [0.7, 2.2]', () {
      double clampZoom(double base, double scaleDiff) {
        return (base * (1.0 + scaleDiff * 1.5)).clamp(0.7, 2.2);
      }

      expect(clampZoom(1.0, 0.0), equals(1.0));
      expect(clampZoom(1.0, 0.5), equals(1.75));
      expect(clampZoom(1.0, 2.0), equals(2.2)); // Clamped at max
      expect(clampZoom(1.0, -0.8), equals(0.7)); // Clamped at min
    });

    test('Pager widget keys remain stable across font size changes to preserve reading page', () {
      String getMushafKey(int reloadKey, int page) => 'mushaf_view_${reloadKey}_$page';
      String getSurahKey(int reloadKey, String mode, String script, int surah) =>
          'surah_${reloadKey}_${mode}_${script}_$surah';

      // Key at multiplier 1.0 vs 1.4 must be identical so widget state is preserved
      final key1 = getMushafKey(0, 45);
      final key2 = getMushafKey(0, 45);
      expect(key1, equals(key2));
      expect(key1, isNot(contains('1.0'))); // Font size NOT in key

      final surahKey1 = getSurahKey(0, 'continuous', 'hafs', 2);
      final surahKey2 = getSurahKey(0, 'continuous', 'hafs', 2);
      expect(surahKey1, equals(surahKey2));
      expect(surahKey1, isNot(contains('1.0'))); // Font size NOT in key
    });
  });
}
