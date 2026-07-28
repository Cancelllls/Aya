part of 'surah_reader_screen.dart';

extension SurahReaderNavigation on _SurahReaderScreenState {
  void _goToNextSurah() {
    if (_allSurahs.isEmpty) return;
    final currentIdx = _allSurahs.indexWhere(
      (s) => s.number == _currentSurah.number,
    );
    if (widget.isInsidePager && widget.onGoToNext != null) {
      widget.onGoToNext!();
      return;
    }
    if (currentIdx != -1 && currentIdx < _allSurahs.length - 1) {
      _slideDirection = 1;
      _navigateToSurahWithAnimation(_allSurahs[currentIdx + 1].number, true);
    }
  }

  void _goToPrevSurah() {
    if (_allSurahs.isEmpty) return;
    final currentIdx = _allSurahs.indexWhere(
      (s) => s.number == _currentSurah.number,
    );
    if (widget.isInsidePager && widget.onGoToPrev != null) {
      widget.onGoToPrev!();
      return;
    }
    if (currentIdx != -1 && currentIdx > 0) {
      _slideDirection = -1;
      _navigateToSurahWithAnimation(_allSurahs[currentIdx - 1].number, false);
    }
  }
}
