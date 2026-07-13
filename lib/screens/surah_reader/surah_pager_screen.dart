import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/storage_service.dart';
import 'surah_reader_screen.dart';
import '../../models/offline_surahs.dart';

class SurahPagerScreen extends StatefulWidget {
  final Surah initialSurah;
  final StorageService storage;
  final int? initialAyahNumber;

  const SurahPagerScreen({
    Key? key,
    required this.initialSurah,
    required this.storage,
    this.initialAyahNumber,
  }) : super(key: key);

  @override
  _SurahPagerScreenState createState() => _SurahPagerScreenState();
}

class _SurahPagerScreenState extends State<SurahPagerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Surah numbers are 1-indexed, PageView is 0-indexed
    // Note: Arabic reads right to left, but PageView uses Left-to-Right layout by default.
    // If we want Surah 2 to be on the "left" of Surah 1 (swiping right to go to Surah 2),
    // we might need to invert the index or rely on Directionality.
    // Assuming standard LTR index mapping for now: index 0 is Al-Fatihah.
    _pageController = PageController(initialPage: widget.initialSurah.number - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      // In Arabic layout, swiping right goes to lower index natively if Directionality is RTL.
      // But let's let Flutter handle it natively with reverse: false.
      itemCount: 114,
      itemBuilder: (context, index) {
        final surahNum = index + 1;
        final surahData = allOfflineSurahs[index];
        final surah = Surah(
          number: surahNum,
          name: surahData.name,
          englishName: surahData.englishName,
          englishNameTranslation: '',
          numberOfAyahs: surahData.numberOfAyahs,
          revelationType: '',
        );

        return SurahReaderScreen(
          surah: surah,
          storage: widget.storage,
          initialAyahNumber: surahNum == widget.initialSurah.number ? widget.initialAyahNumber : null,
          isInsidePager: true,
          onGoToNext: () {
            if (index < 113) {
              _pageController.animateToPage(index + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          },
          onGoToPrev: () {
            if (index > 0) {
              _pageController.animateToPage(index - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          },
        );
      },
    );
  }
}
