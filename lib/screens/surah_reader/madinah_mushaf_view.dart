import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/offline_surahs.dart';
import '../../models/quran_models.dart';
import '../../services/api_service.dart';
import '../../services/audio_manager.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../utils/text_helpers.dart';
import '../../widgets/share_ayah_dialog.dart';

/// Authentic 604-page 15-line Madinah Mushaf reader.
///
/// Mimics physical King Fahd Complex Mushaf pages with exact ayah pagination,
/// ornate surah title banners, proportional page fitting, gold ayah markers,
/// interactive ayah tap actions (Tafsir, recitation audio, bookmarks, copy/share),
/// audio sync highlighting, and auto-page turns.
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
  Set<String> _bookmarkedAyahs = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadBookmarks();
    AudioManager.instance.playState.addListener(_onAudioPlayStateChanged);
  }

  @override
  void dispose() {
    AudioManager.instance.playState.removeListener(_onAudioPlayStateChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onAudioPlayStateChanged() async {
    if (!mounted) return;
    final playState = AudioManager.instance.playState.value;
    if (playState.isPlaying && playState.surahNum > 0 && playState.ayahNum > 0) {
      try {
        final db = await DatabaseService.getInstance();
        final targetPage = await db.getPageForAyah(playState.surahNum, playState.ayahNum);
        if (mounted && targetPage != _currentPage && targetPage >= 1 && targetPage <= 604) {
          _pageController.animateToPage(
            targetPage - 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await widget.storage.getBookmarks();
      if (mounted) {
        setState(() {
          _bookmarkedAyahs = bookmarks
              .map((b) => "${b['surahNumber']}:${b['ayahNumber']}")
              .toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark(int surahNum, String surahName, int ayahNum) async {
    final key = '$surahNum:$ayahNum';
    final isCurrently = _bookmarkedAyahs.contains(key);
    if (isCurrently) {
      await widget.storage.removeBookmark(surahNum, ayahNumber: ayahNum);
      setState(() {
        _bookmarkedAyahs.remove(key);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'تمت إزالة الإشارة المرجعية للآية $ayahNum'
                  : 'Removed bookmark for Ayah $ayahNum',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      await widget.storage.addBookmark(surahNum, surahName, ayahNum);
      setState(() {
        _bookmarkedAyahs.add(key);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'تم حفظ الإشارة المرجعية للآية $ayahNum'
                  : 'Bookmarked Ayah $ayahNum',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _playRecitation(int surahNum, String surahName, int ayahNum) async {
    final surahData = (surahNum >= 1 && surahNum <= 114)
        ? allOfflineSurahs[surahNum - 1]
        : null;
    final englishName = surahData?.englishName ?? surahName;
    try {
      final ayahs = await ApiService.fetchSurahDetails(surahNum);
      final index = ayahs.indexWhere((a) => a.numberInSurah == ayahNum);
      if (index != -1) {
        AudioManager.instance.playAyah(
          surahNum,
          englishName,
          ayahs,
          index,
        );
      } else {
        AudioManager.instance.playSurah(
          surahNum,
          englishName,
          ayahs,
        );
      }
    } catch (_) {}
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
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5C158).withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Page Top Header Bar
              _buildPageHeader(surahDisplayName, juzNumber),
              const Divider(height: 1, color: Color(0x22E5C158)),

              // Main Page Verses Content with dynamic sizing
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ValueListenableBuilder<AudioPlayState>(
                        valueListenable: AudioManager.instance.playState,
                        builder: (context, playState, _) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: _buildMushafPageBody(
                                ayahs,
                                constraints.maxHeight,
                                playState,
                              ),
                            ),
                          );
                        },
                      );
                    },
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
    final isAr = TranslationService.isArabic;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPageJumpDialog(pageNum),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE5C158).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5C158).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz, size: 14, color: Color(0xFFE5C158)),
                const SizedBox(width: 4),
                Text(
                  isAr ? toArabicDigits(pageNum) : pageNum.toString(),
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5C158),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPageJumpDialog(int currentPage) {
    final isAr = TranslationService.isArabic;
    final controller = TextEditingController(text: currentPage.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAr ? 'الانتقال إلى صفحة' : 'Jump to Page'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم الصفحة (1 - 604)' : 'Page Number (1 - 604)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
              onPressed: () {
                final target = int.tryParse(controller.text.trim());
                if (target != null && target >= 1 && target <= 604) {
                  Navigator.pop(context);
                  _pageController.jumpToPage(target - 1);
                }
              },
              child: Text(isAr ? 'انتقال' : 'Go'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMushafPageBody(
    List<Map<String, dynamic>> ayahs,
    double availableHeight,
    AudioPlayState playState,
  ) {
    final theme = Theme.of(context);

    // Group ayahs by surah on this page
    final surahGroups = <int, List<Map<String, dynamic>>>{};
    for (final a in ayahs) {
      final s = a['surah_number'] as int? ?? 1;
      surahGroups.putIfAbsent(s, () => []).add(a);
    }

    // Count banners to calculate proportional font size
    int bannersCount = 0;
    int bismillahCount = 0;
    for (final entry in surahGroups.entries) {
      final sNum = entry.key;
      final group = entry.value;
      final hasAyahOne = group.any((a) => (a['ayah_number'] as int? ?? 0) == 1);
      if (hasAyahOne) {
        bannersCount++;
        if (sNum != 1 && sNum != 9) {
          bismillahCount++;
        }
      }
    }

    final double bannerSpace = (bannersCount * 54.0) + (bismillahCount * 28.0);
    final double availableTextSpace = (availableHeight - bannerSpace).clamp(240.0, 1200.0);
    final int estimatedLines = (15 - (bannersCount * 3) - (bismillahCount * 1)).clamp(8, 15);
    final double targetLineHeightPx = availableTextSpace / estimatedLines;
    final double baseFontSize = (targetLineHeightPx / 1.82).clamp(14.0, 21.0) * widget.fontSizeMultiplier;
    final double textLineHeight = (targetLineHeightPx / (baseFontSize / widget.fontSizeMultiplier)).clamp(1.6, 2.0);

    final children = <Widget>[];

    for (final entry in surahGroups.entries) {
      final surahNum = entry.key;
      final groupAyahs = entry.value;
      final surahData = (surahNum >= 1 && surahNum <= 114)
          ? allOfflineSurahs[surahNum - 1]
          : null;

      final containsAyahOne = groupAyahs.any((a) => (a['ayah_number'] as int? ?? 0) == 1);
      if (containsAyahOne && surahData != null) {
        children.add(_buildSurahTitleBanner(surahData));
        if (surahNum != 1 && surahNum != 9) {
          children.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Center(
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
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

      // Build continuous page text with interactive ayah spans and gold ayah end badges
      final spans = <InlineSpan>[];
      for (final ayah in groupAyahs) {
        final ayahNum = ayah['ayah_number'] as int? ?? 1;
        String ayahText = (ayah['text_arabic'] as String? ?? '').trim();

        if (ayahNum == 1 && surahNum != 1) {
          ayahText = Ayah.cleanBasmalah(ayahText, ayahNum, ayah['global_number'] as int? ?? 1);
        }

        final isReciting = playState.isPlaying &&
            playState.surahNum == surahNum &&
            playState.ayahNum == ayahNum;
        final isBookmarked = _bookmarkedAyahs.contains('$surahNum:$ayahNum');

        spans.add(
          TextSpan(
            text: '$ayahText ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: baseFontSize,
              height: textLineHeight,
              fontWeight: isReciting ? FontWeight.bold : FontWeight.w500,
              backgroundColor: isReciting
                  ? const Color(0xFFE5C158).withValues(alpha: 0.28)
                  : null,
              color: isReciting
                  ? const Color(0xFFE5C158)
                  : theme.textTheme.bodyLarge?.color,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _showAyahActionSheet(ayah, surahData?.name ?? ''),
          ),
        );

        spans.add(
          TextSpan(
            text: ' ﴿${toArabicDigits(ayahNum)}﴾ ',
            style: TextStyle(
              fontFamily: 'Amiri',
              color: isBookmarked
                  ? const Color(0xFFE5C158)
                  : (isReciting
                      ? const Color(0xFFE5C158)
                      : const Color(0xFFE5C158).withValues(alpha: 0.85)),
              fontWeight: FontWeight.bold,
              fontSize: (baseFontSize * 0.92).clamp(13.0, 19.0),
              backgroundColor: isReciting
                  ? const Color(0xFFE5C158).withValues(alpha: 0.28)
                  : null,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _showAyahActionSheet(ayah, surahData?.name ?? ''),
          ),
        );
      }

      children.add(
        Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    );
  }

  Widget _buildSurahTitleBanner(Surah surah) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
              fontSize: 18,
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

  void _showAyahActionSheet(Map<String, dynamic> ayah, String surahName) {
    final theme = Theme.of(context);
    final isAr = TranslationService.isArabic;
    final surahNum = ayah['surah_number'] as int? ?? 1;
    final ayahNum = ayah['ayah_number'] as int? ?? 1;
    final textArabic = (ayah['text_arabic'] as String? ?? '').trim();
    final textEnglish = (ayah['text_english'] as String? ?? '').trim();
    final isBookmarked = _bookmarkedAyahs.contains('$surahNum:$ayahNum');

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title Header
                Text(
                  isAr
                      ? "$surahName - الآية ${toArabicDigits(ayahNum)}"
                      : "$surahName - Ayah $ayahNum",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFE5C158),
                  ),
                ),
                const SizedBox(height: 10),

                // Verse Preview Box
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        textArabic,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      if (textEnglish.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          textEnglish,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions List
                ListTile(
                  leading: const Icon(Icons.play_circle_outline, color: Color(0xFFE5C158)),
                  title: Text(TranslationService.t('play_recitation')),
                  onTap: () {
                    Navigator.pop(context);
                    _playRecitation(surahNum, surahName, ayahNum);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book, color: Color(0xFFE5C158)),
                  title: Text(isAr ? "التفسير" : "Tafsir"),
                  onTap: () {
                    Navigator.pop(context);
                    _showTafseerDialog(ayah, surahName);
                  },
                ),
                ListTile(
                  leading: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: const Color(0xFFE5C158),
                  ),
                  title: Text(
                    isBookmarked
                        ? (isAr ? "إزالة الإشارة المرجعية" : "Remove Bookmark")
                        : TranslationService.t('bookmark_verse'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleBookmark(surahNum, surahName, ayahNum);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFFE5C158)),
                  title: Text(TranslationService.t('copy_verse')),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: textArabic));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(TranslationService.t('verse_copied')),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Color(0xFFE5C158)),
                  title: Text(isAr ? "مشاركة كنص" : "Share Text"),
                  onTap: () {
                    Navigator.pop(context);
                    final ref = '$surahName $surahNum:$ayahNum';
                    SharePlus.instance.share(
                      ShareParams(
                        text: '$textArabic\n\n$textEnglish\n\n— $ref • Aya App',
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined, color: Color(0xFFE5C158)),
                  title: Text(isAr ? "مشاركة كصورة" : "Share as Image"),
                  onTap: () {
                    Navigator.pop(context);
                    final ayahObj = Ayah(
                      number: ayah['global_number'] as int? ?? 1,
                      numberInSurah: ayahNum,
                      text: textArabic,
                      translation: textEnglish,
                      juz: ayah['juz'] as int? ?? 1,
                      hizb: ayah['hizb'] as int? ?? 1,
                      tafseer: (ayah['tafsir'] as String?) ?? '',
                    );
                    showDialog(
                      context: context,
                      builder: (ctx) => ShareAyahDialog(
                        ayah: ayahObj,
                        surahName: surahName,
                        surahNumber: surahNum,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTafseerDialog(Map<String, dynamic> ayah, String surahName) {
    final Map<String, String> loadedTafsirs = {};
    final rawTafsir = (ayah['tafsir'] as String? ?? '').trim();
    if (rawTafsir.isNotEmpty) {
      loadedTafsirs['ar.muyassar'] = rawTafsir;
    }

    String selectedLang = 'all';
    final surahNum = ayah['surah_number'] as int? ?? 1;
    final ayahNum = ayah['ayah_number'] as int? ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isAr = TranslationService.isArabic;
        final theme = Theme.of(context);

        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final filteredTafsirs = availableTafsirs.where((e) {
              if (selectedLang == 'ar') return e.language == 'ar';
              if (selectedLang == 'en') return e.language == 'en';
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$surahName - ${isAr ? 'آية' : 'Ayah'} ${toArabicDigits(ayahNum)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Text(
                            isAr ? 'جميع التفاسير المتاحة' : 'Available Tafsirs',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Language Filter Bar (ALL | AR | EN)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text(isAr ? 'الكل' : 'All'),
                        selected: selectedLang == 'all',
                        selectedColor: const Color(0xFFE5C158),
                        onSelected: (val) {
                          if (val) sheetSetState(() => selectedLang = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(isAr ? 'عربي فقط' : 'Arabic Only'),
                        selected: selectedLang == 'ar',
                        selectedColor: const Color(0xFFE5C158),
                        onSelected: (val) {
                          if (val) sheetSetState(() => selectedLang = 'ar');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(isAr ? 'English فقط' : 'English Only'),
                        selected: selectedLang == 'en',
                        selectedColor: const Color(0xFFE5C158),
                        onSelected: (val) {
                          if (val) sheetSetState(() => selectedLang = 'en');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Vertical List of Editions
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredTafsirs.length,
                      itemBuilder: (context, idx) {
                        final edition = filteredTafsirs[idx];
                        final hasLoaded = loadedTafsirs.containsKey(edition.identifier);

                        if (!hasLoaded) {
                          ApiService.fetchTafsirTextForAyah(
                            edition.identifier,
                            surahNum,
                            ayahNum,
                          ).then((text) {
                            if (context.mounted) {
                              sheetSetState(() {
                                loadedTafsirs[edition.identifier] = text;
                              });
                            }
                          });
                        }

                        final tafsirText = loadedTafsirs[edition.identifier] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE5C158).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Edition Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5C158).withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        edition.language.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFFE5C158),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            edition.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            isAr ? edition.mufassir : edition.mufassirEn,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                // Tafsir Content Text
                                if (!hasLoaded)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFE5C158),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    tafsirText.isNotEmpty
                                        ? tafsirText
                                        : (isAr ? 'التفسير غير متوفر لهذه الآية' : 'Tafsir not available'),
                                    style: TextStyle(
                                      fontFamily: edition.language == 'ar' ? 'Amiri' : null,
                                      fontSize: 15,
                                      height: 1.7,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    textDirection: edition.language == 'ar'
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
