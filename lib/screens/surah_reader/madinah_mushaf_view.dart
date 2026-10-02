import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../utils/text_helpers.dart';
import '../../models/quran_models.dart';
import '../../models/offline_surahs.dart';

/// Authentic 604-page 15-line Madinah Mushaf reader.
///
/// Mimics physical King Fahd Complex Mushaf pages with exact ayah pagination,
/// ornate surah title banners, justified continuous text, and gold ayah markers.
class MadinahMushafView extends StatefulWidget {
  final int initialPage;
  final StorageService storage;
  final double fontSizeMultiplier;
  final Function(int page)? onPageChanged;

  const MadinahMushafView({
    super.key,
    required this.initialPage,
    required this.storage,
    this.fontSizeMultiplier = 1.0,
    this.onPageChanged,
  });

  @override
  State<MadinahMushafView> createState() => _MadinahMushafViewState();
}

class _MadinahMushafViewState extends State<MadinahMushafView> {
  late PageController _pageController;
  late int _currentPage;
  final Map<int, List<Map<String, dynamic>>> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }
    final db = await DatabaseService.getInstance();
    final results = await db.getAyahsForPage(pageNumber);
    _pageCache[pageNumber] = results;
    return results;
  }

  void _onPageSwiped(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);
    widget.onPageChanged?.call(page);

    // Save reading progress
    final cached = _pageCache[page];
    if (cached != null && cached.isNotEmpty) {
      final first = cached.first;
      final surah = first['surah_number'] as int? ?? 1;
      final ayah = first['ayah_number'] as int? ?? 1;
      widget.storage.saveLastReadPosition(surah, ayah);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: 604,
      reverse: true, // Physical Arabic Mushaf pages read Right-to-Left
      onPageChanged: _onPageSwiped,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        return _buildSinglePage(pageNum);
      },
    );
  }

  Widget _buildSinglePage(int pageNum) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadPage(pageNum),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE5C158)),
          );
        }

        final ayahs = snapshot.data!;
        if (ayahs.isEmpty) {
          return Center(
            child: Text(
              TranslationService.isArabic ? 'صفحة فارغة' : 'Empty Page',
              style: TextStyle(color: theme.disabledColor),
            ),
          );
        }

        // Determine top header metadata
        final firstAyah = ayahs.first;
        final surahNumber = firstAyah['surah_number'] as int? ?? 1;
        final juzNumber = firstAyah['juz'] as int? ?? 1;
        final surahData = (surahNumber >= 1 && surahNumber <= 114)
            ? allOfflineSurahs[surahNumber - 1]
            : null;
        final surahDisplayName = surahData?.name ?? firstAyah['surah_name'] ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5C158).withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Page Top Header Bar
              _buildPageHeader(surahDisplayName, juzNumber),
              const Divider(height: 1, color: Color(0x22E5C158)),

              // Main Page Verses Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildMushafPageBody(ayahs),
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0x22E5C158)),
              // Page Bottom Footer Bar
              _buildPageFooter(pageNum),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(String surahName, int juz) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            surahName,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE5C158).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              TranslationService.isArabic
                  ? 'الجزء ${toArabicDigits(juz)}'
                  : 'Juz $juz',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageFooter(int pageNum) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5C158).withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Text(
            TranslationService.isArabic
                ? toArabicDigits(pageNum)
                : pageNum.toString(),
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMushafPageBody(List<Map<String, dynamic>> ayahs) {
    final theme = Theme.of(context);
    final double baseFontSize = 20.0 * widget.fontSizeMultiplier;

    // Group ayahs by surah on this page
    final surahGroups = <int, List<Map<String, dynamic>>>{};
    for (final a in ayahs) {
      final s = a['surah_number'] as int? ?? 1;
      surahGroups.putIfAbsent(s, () => []).add(a);
    }

    final children = <Widget>[];

    for (final entry in surahGroups.entries) {
      final surahNum = entry.key;
      final groupAyahs = entry.value;
      final surahData = (surahNum >= 1 && surahNum <= 114)
          ? allOfflineSurahs[surahNum - 1]
          : null;

      // If page contains verse 1, display authentic decorative Surah Banner
      final containsAyahOne = groupAyahs.any((a) => (a['ayah_number'] as int? ?? 0) == 1);
      if (containsAyahOne && surahData != null) {
        children.add(_buildSurahTitleBanner(surahData));
        if (surahNum != 1 && surahNum != 9) {
          children.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5C158),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          );
        }
      }

      // Build continuous page text with gold ayah end badges
      final spans = <InlineSpan>[];
      for (final ayah in groupAyahs) {
        final ayahNum = ayah['ayah_number'] as int? ?? 1;
        String ayahText = (ayah['text_arabic'] as String? ?? '').trim();

        // Strip Basmalah prefix if already handled by Surah Banner
        if (ayahNum == 1 && surahNum != 1) {
          ayahText = Ayah.cleanBasmalah(ayahText, ayahNum, ayah['global_number'] as int? ?? 1);
        }

        spans.add(
          TextSpan(
            text: '$ayahText ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: baseFontSize,
              height: 2.05,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        );

        // Ornate Ayah end symbol with Arabic numeral
        spans.add(
          TextSpan(
            text: ' ﴿${toArabicDigits(ayahNum)}﴾ ',
            style: const TextStyle(
              fontFamily: 'Amiri',
              color: Color(0xFFE5C158),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        );
      }

      children.add(
        SelectableText.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildSurahTitleBanner(Surah surah) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5C158).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5C158).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            TranslationService.isArabic
                ? (surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية')
                : surah.revelationType,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
          Text(
            surah.name,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
          Text(
            TranslationService.isArabic
                ? '${toArabicDigits(surah.numberOfAyahs)} آية'
                : '${surah.numberOfAyahs} v.',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
        ],
      ),
    );
  }
}
