part of 'surah_reader_screen.dart';

extension SurahReaderNavigation on _SurahReaderScreenState {

  void _navigateToSurah(Surah newSurah) {
      setState(() {
        _currentSurah = newSurah;
        _isLoading = true;
        _ayahList = [];
        _ayahKeys.clear();
        _pageKeys.clear();
        _pageRecognizers.clear();
      });
      _loadAyahs();
      _fetchDynamicReciters(_quranScriptType);
      _checkBookmarkStatus();
    }

  void _goToNextSurah() {
      if (_allSurahs.isEmpty) return;
      final currentIdx = _allSurahs.indexWhere(
        (s) => s.number == _currentSurah.number,
      );
      if (currentIdx != -1 && currentIdx < _allSurahs.length - 1) {
        _slideDirection = 1;
        _navigateToSurah(_allSurahs[currentIdx + 1]);
      }
    }

  void _goToPrevSurah() {
      if (_allSurahs.isEmpty) return;
      final currentIdx = _allSurahs.indexWhere(
        (s) => s.number == _currentSurah.number,
      );
      if (currentIdx != -1 && currentIdx > 0) {
        _slideDirection = -1;
        _navigateToSurah(_allSurahs[currentIdx - 1]);
      }
    }
}
