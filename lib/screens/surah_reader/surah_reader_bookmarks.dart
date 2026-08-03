part of 'surah_reader_screen.dart';

extension SurahReaderBookmarks on _SurahReaderScreenState {
  void _checkBookmarkStatus() async {
    final bookmarks = await widget.storage.getBookmarks();
    final b = bookmarks.firstWhere(
      (element) => element['surahNumber'] == _currentSurah.number,
      orElse: () => {},
    );
    if (mounted) {
      setState(() {
        _isBookmarked = b.isNotEmpty;
        _bookmarkedAyahNumber = b.isNotEmpty ? b['ayahNumber'] as int? : null;
      });
    }
  }

  void _bookmarkAyah(int ayahNum) async {
    if (_isBookmarked && _bookmarkedAyahNumber == ayahNum) {
      await widget.storage.removeBookmark(
        _currentSurah.number,
        ayahNumber: ayahNum,
      );
      if (!mounted) return;
      setState(() {
        _isBookmarked = false;
        _bookmarkedAyahNumber = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${TranslationService.isArabic ? 'تم إزالة العلامة من الآية' : 'Removed Bookmark from Ayah'} $ayahNum',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    await widget.storage.addBookmark(
      _currentSurah.number,
      _currentSurah.englishName,
      ayahNum,
    );
    if (!mounted) return;
    setState(() {
      _isBookmarked = true;
      _bookmarkedAyahNumber = ayahNum;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${TranslationService.isArabic ? 'تم حفظ علامة الآية' : 'Bookmarked Ayah'} $ayahNum',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Debounce last-read-position writes — fires at most once every 5 seconds
  /// and immediately on explicit save/exit.
  void _debouncedSavePosition(int surahNum, int ayahNum) {
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer(const Duration(seconds: 5), () {
      widget.storage.saveLastReadPosition(surahNum, ayahNum);
    });
  }

  void _flushPositionSave() {
    _savePositionTimer?.cancel();
  }

  void _toggleBookmark() async {
    if (_isBookmarked) {
      await widget.storage.removeBookmark(_currentSurah.number);
      if (!mounted) return;
      setState(() {
        _isBookmarked = false;
        _bookmarkedAyahNumber = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.t('bookmark_removed')),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      final targetAyah = _bookmarkedAyahNumber ?? 1;
      await widget.storage.addBookmark(
        _currentSurah.number,
        _currentSurah.englishName,
        targetAyah,
      );
      if (!mounted) return;
      setState(() {
        _isBookmarked = true;
        _bookmarkedAyahNumber = targetAyah;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.t('bookmark_saved')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
