part of 'surah_reader_screen.dart';

extension SurahReaderActions on _SurahReaderScreenState {
  void _showTafseerDialog(Ayah ayah) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_currentSurah.name} - ${TranslationService.isArabic ? 'آية' : 'Ayah'} ${ayah.numberInSurah}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                TranslationService.isArabic ? 'التفسير:' : 'Tafseer:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5C158),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    ayah.tafseer.isNotEmpty
                        ? ayah.tafseer
                        : (TranslationService.isArabic
                              ? 'التفسير غير متوفر حالياً لهذه الآية.'
                              : 'Tafseer is not available for this verse.'),
                    textDirection: TextDirection.rtl,
                    style: _getArabicTextStyle(18, height: 1.8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToAyah(int ayahNum) {
    if (!mounted) return;

    final currentSequence = ++_scrollToAyahSequence;

    void performSearch(int attempt, double currentGuess) {
      if (!mounted || _scrollToAyahSequence != currentSequence) return;

      if (!_scrollController.hasClients) {
        if (attempt < 20) {
          Future.delayed(
            const Duration(milliseconds: 100),
            () => performSearch(attempt + 1, currentGuess),
          );
        }
        return;
      }

      final key = _readingMode == 'continuous'
          ? _pageKeys[(ayahNum - 1) ~/ 5]
          : _ayahKeys[ayahNum];

      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration.zero,
          alignment: 0.0,
        );
      } else if (attempt < 20) {
        int maxRendered = -1;
        int minRendered = 99999;

        final keysToCheck = _readingMode == 'continuous'
            ? _pageKeys
            : _ayahKeys;
        for (final k in keysToCheck.keys) {
          if (keysToCheck[k]?.currentContext != null) {
            if (k > maxRendered) maxRendered = k;
            if (k < minRendered) minRendered = k;
          }
        }

        final targetIndex = _readingMode == 'continuous'
            ? ((ayahNum - 1) ~/ 5)
            : ayahNum;

        if (maxRendered != -1 && targetIndex > maxRendered) {
          currentGuess += 800;
          if (currentGuess > _scrollController.position.maxScrollExtent) {
            currentGuess = _scrollController.position.maxScrollExtent;
          }
          _scrollController.jumpTo(currentGuess);
        } else if (minRendered != 99999 && targetIndex < minRendered) {
          currentGuess -= 800;
          if (currentGuess < 0) currentGuess = 0;
          _scrollController.jumpTo(currentGuess);
        } else {
          currentGuess += 500;
          _scrollController.jumpTo(currentGuess);
        }

        Future.delayed(
          const Duration(milliseconds: 50),
          () => performSearch(attempt + 1, currentGuess),
        );
      }
    }

    void startSearch(int attempt) {
      if (!mounted || _scrollToAyahSequence != currentSequence) return;
      if (!_scrollController.hasClients) {
        if (attempt < 20) {
          Future.delayed(
            const Duration(milliseconds: 100),
            () => startSearch(attempt + 1),
          );
        }
        return;
      }

      double initialGuess = 0;
      if (_readingMode == 'continuous') {
        initialGuess = ((ayahNum - 1) ~/ 5) * 400.0 * _fontSizeMultiplier;
      } else {
        initialGuess =
            (ayahNum - 1) *
            (_readingMode == 'translation' ? 400.0 : 200.0) *
            _fontSizeMultiplier;
      }

      _scrollController.jumpTo(initialGuess);
      Future.delayed(
        const Duration(milliseconds: 50),
        () => performSearch(0, initialGuess),
      );
    }

    startSearch(0);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSizeMultiplier = (_fontSizeMultiplier + delta).clamp(0.8, 1.8);
    });
  }

  void _showAyahActionSheet(Ayah ayah) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TranslationService.isArabic
                    ? "${_currentSurah.name} : الآية ${ayah.numberInSurah}"
                    : "${_currentSurah.englishName} : Verse ${ayah.numberInSurah}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: Color(0xFFE5C158),
                ),
                title: Text(TranslationService.t('play_recitation')),
                onTap: () {
                  Navigator.pop(context);
                  final idx = _ayahList.indexOf(ayah);
                  _playAudioWithDisclaimer(ayahIndex: idx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFFE5C158)),
                title: Text(TranslationService.isArabic ? "التفسير" : "Tafsir"),
                onTap: () {
                  Navigator.pop(context);
                  _showTafseerDialog(ayah);
                },
              ),
              ListTile(
                leading: Icon(
                  _isBookmarked && _bookmarkedAyahNumber == ayah.numberInSurah
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  color: const Color(0xFFE5C158),
                ),
                title: Text(
                  _isBookmarked && _bookmarkedAyahNumber == ayah.numberInSurah
                      ? (TranslationService.isArabic
                            ? "إزالة العلامة"
                            : "Remove Bookmark")
                      : TranslationService.t('bookmark_verse'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _bookmarkAyah(ayah.numberInSurah);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFFE5C158)),
                title: Text(TranslationService.t('copy_verse')),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: ayah.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(TranslationService.t('verse_copied')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
