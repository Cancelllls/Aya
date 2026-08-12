part of 'surah_reader_screen.dart';

extension SurahReaderActions on _SurahReaderScreenState {
  void _showTafseerDialog(Ayah ayah) async {
    if (ayah.tafseer.isEmpty) {
      await _ensureTafsirLoaded();
    }
    String currentEdition = 'ar.muyassar';
    final Map<String, String> loadedTafsirs = {
      'ar.muyassar': ayah.tafseer,
    };
    bool isLoadingTafsir = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isAr = TranslationService.isArabic;
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_currentSurah.name} - ${isAr ? 'آية' : 'Ayah'} ${ayah.numberInSurah}",
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
                  const SizedBox(height: 10),
                  // Horizontal Tab Bar for ALL available Tafsir books
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableTafsirs.length,
                      itemBuilder: (context, idx) {
                        final edition = availableTafsirs[idx];
                        final isSelected = edition.identifier == currentEdition;
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              isAr ? edition.name : edition.mufassirEn,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFE5C158),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            onSelected: (selected) async {
                              if (!selected) return;
                              setSheetState(() {
                                currentEdition = edition.identifier;
                              });

                              if (!loadedTafsirs.containsKey(edition.identifier)) {
                                setSheetState(() {
                                  isLoadingTafsir = true;
                                });
                                try {
                                  final tempAyahs = _ayahList.map((a) => Ayah(
                                    number: a.number,
                                    numberInSurah: a.numberInSurah,
                                    text: a.text,
                                    translation: a.translation,
                                    juz: a.juz,
                                    hizb: a.hizb,
                                    tafseer: '',
                                  )).toList();
                                  await ApiService.fetchTafsirForSurah(
                                    _currentSurah.number,
                                    tempAyahs,
                                  );
                                  final target = tempAyahs.firstWhere(
                                    (a) => a.numberInSurah == ayah.numberInSurah,
                                    orElse: () => ayah,
                                  );
                                  loadedTafsirs[edition.identifier] = target.tafseer;
                                } catch (_) {}
                                setSheetState(() {
                                  isLoadingTafsir = false;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: isLoadingTafsir
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
                        : SingleChildScrollView(
                            child: Text(
                              (loadedTafsirs[currentEdition]?.isNotEmpty ?? false)
                                  ? loadedTafsirs[currentEdition]!
                                  : (isAr
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
      },
    );
  }

  void _shareAyahAsImage(Ayah ayah) {
    showDialog(
      context: context,
      builder: (ctx) => ShareAyahDialog(
        ayah: ayah,
        surahName: _currentSurah.name,
        surahNumber: _currentSurah.number,
      ),
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
        return;
      }

      if (attempt >= 20) return;

      final totalItemCount = _readingMode == 'continuous'
          ? (_ayahList.length / 5).ceil()
          : _ayahList.length + 1; // +1 for bismillah header
      final targetIndex = _readingMode == 'continuous'
          ? ((ayahNum - 1) ~/ 5)
          : ayahNum; // index 0 is bismillah, ayah 1 is index 1

      if (totalItemCount > 0) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        currentGuess = maxScroll > 0
            ? ((targetIndex / totalItemCount) * maxScroll)
                .clamp(0.0, maxScroll)
            : currentGuess + 600;
        _scrollController.jumpTo(currentGuess);
      }

      Future.delayed(
        const Duration(milliseconds: 50),
        () => performSearch(attempt + 1, currentGuess),
      );
    }

    performSearch(0, 0);
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
                leading: const Icon(Icons.share, color: Color(0xFFE5C158)),
                title: Text(
                  TranslationService.isArabic ? "مشاركة كنص" : "Share Text",
                ),
                onTap: () {
                  Navigator.pop(context);
                  final ref =
                      '${_currentSurah.englishName} ${_currentSurah.number}:${ayah.numberInSurah}';
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${ayah.text}\n\n${ayah.translation}\n\n— $ref • Aya App',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Color(0xFFE5C158)),
                title: Text(
                  TranslationService.isArabic ? "مشاركة كصورة" : "Share as Image",
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareAyahAsImage(ayah);
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
