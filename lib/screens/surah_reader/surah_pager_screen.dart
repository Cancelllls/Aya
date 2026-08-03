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
  int _speedLevel = 2;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSurah.number - 1;
    _speedLevel = widget.storage.getInt('autoscroll_speed', defaultValue: 2);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSpeedChanged(int speed) {
    widget.storage.setInt('autoscroll_speed', speed);
    setState(() => _speedLevel = speed);
  }

  @override
  Widget build(BuildContext context) {
    final surahData = allOfflineSurahs[_currentPage];
    final theme = Theme.of(context);

    final speedLabels = TranslationService.isArabic
        ? ['بطيء جداً', 'بطيء', 'متوسط', 'سريع', 'سريع جداً']
        : ['Very Slow', 'Slow', 'Medium', 'Fast', 'Very Fast'];

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
                color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Container(
            height: 38,
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.speed, color: Color(0xFFE5C158), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    speedLabels[_speedLevel.clamp(0, 4)],
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => _onSpeedChanged(i),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _speedLevel == i
                            ? const Color(0xFFE5C158)
                            : const Color(0xFFE5C158).withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _speedLevel == i
                              ? Colors.black
                              : const Color(0xFFE5C158),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
            hideAppBar: true,
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
