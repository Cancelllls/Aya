import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/storage_service.dart';
import '../../models/offline_surahs.dart';
import '../../services/translation_service.dart';
import 'surah_reader_screen.dart';

class SurahPagerScreen extends StatefulWidget {
  final Surah initialSurah;
  final StorageService storage;
  final int? initialAyahNumber;

  const SurahPagerScreen({
    super.key,
    required this.initialSurah,
    required this.storage,
    this.initialAyahNumber,
  });

  @override
  _SurahPagerScreenState createState() => _SurahPagerScreenState();
}

class _SurahPagerScreenState extends State<SurahPagerScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSurah.number - 1;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahData = allOfflineSurahs[_currentPage];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surahData.englishName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              surahData.name,
              style: TextStyle(
                fontSize: 11,
                color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: 114,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemBuilder: (context, index) {
          final surahNum = index + 1;
          final data = allOfflineSurahs[index];
          final surah = Surah(
            number: surahNum,
            name: data.name,
            englishName: data.englishName,
            englishNameTranslation: '',
            numberOfAyahs: data.numberOfAyahs,
            revelationType: '',
          );

          return SurahReaderScreen(
            surah: surah,
            storage: widget.storage,
            initialAyahNumber: surahNum == widget.initialSurah.number
                ? widget.initialAyahNumber
                : null,
            isInsidePager: true,
            hideAppBar: true, // app bar is handled by the pager
            onGoToNext: () {
              if (index < 113) {
                _pageController.animateToPage(
                  index + 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            onGoToPrev: () {
              if (index > 0) {
                _pageController.animateToPage(
                  index - 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          );
        },
      ),
    );
  }
}
