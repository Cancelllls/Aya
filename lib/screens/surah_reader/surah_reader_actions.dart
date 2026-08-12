part of 'surah_reader_screen.dart';

extension SurahReaderActions on _SurahReaderScreenState {
  void _showTafseerDialog(Ayah ayah) async {
    if (ayah.tafseer.isEmpty) {
      await _ensureTafsirLoaded();
    }

    // Fix #3: Pre-fetch all editions concurrently BEFORE opening the sheet.
    // This avoids firing HTTP requests inside itemBuilder (side-effect in build)
    // and ensures all 6 tafsirs load in parallel with a single loading indicator.
    final Map<String, String> loadedTafsirs = {
      'ar.muyassar': ayah.tafseer,
    };

    // Show a transient loading snack while fetching non-cached editions.
    final needsFetch = availableTafsirs
        .where((e) => !ApiService.isTafsirCached(e.identifier, _currentSurah.number, ayah.numberInSurah))
        .toList();

    if (needsFetch.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic ? 'جاري تحميل التفاسير...' : 'Loading tafsirs…',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFE5C158),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Fetch all editions concurrently, bounded by availableTafsirs count (6).
    final results = await Future.wait(
      availableTafsirs.map((e) async {
        if (loadedTafsirs.containsKey(e.identifier) &&
            loadedTafsirs[e.identifier]!.isNotEmpty) {
          return MapEntry(e.identifier, loadedTafsirs[e.identifier]!);
        }
        final text = await ApiService.fetchTafsirTextForAyah(
          e.identifier,
          _currentSurah.number,
          ayah.numberInSurah,
        );
        return MapEntry(e.identifier, text);
      }),
    );
    for (final entry in results) {
      loadedTafsirs[entry.key] = entry.value;
    }

    if (!mounted) return;

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

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                        "${_currentSurah.name} - ${isAr ? 'آية' : 'Ayah'} ${ayah.numberInSurah}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        isAr ? 'جميع التفاسير المتاحة' : 'All Available Tafsirs',
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
              const SizedBox(height: 14),

              // Stacked Vertical List — all data is pre-loaded (fix #3).
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableTafsirs.length,
                  itemBuilder: (context, idx) {
                    final edition = availableTafsirs[idx];
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
                                    isAr ? edition.name : edition.mufassirEn,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE5C158),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAr ? edition.mufassir : edition.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            // Edition Content Body — pre-loaded, no spinner needed.
                            Text(
                              tafsirText.isNotEmpty
                                  ? tafsirText
                                  : (isAr ? 'لا يوجد تفسير متاح' : 'No tafsir available'),
                              textDirection: TextDirection.rtl,
                              style: _getArabicTextStyle(16, height: 1.8),
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

  void _toggleAyahSelection(int num) {
    setState(() {
      if (_selectedAyahs.contains(num)) {
        _selectedAyahs.remove(num);
      } else {
        _selectedAyahs.add(num);
      }
    });
  }

  void _clearAyahSelection() {
    setState(() {
      _selectedAyahs.clear();
    });
  }

  void _copySelectedAyahsText() {
    if (_selectedAyahs.isEmpty) return;
    final sorted = _selectedAyahs.toList()..sort();
    final selectedTextList = _ayahList
        .where((a) => sorted.contains(a.numberInSurah))
        .map((a) => "${a.text} ﴿${a.numberInSurah}﴾")
        .join("\n");
    final ref = "${_currentSurah.name} (${sorted.first}-${sorted.last})";
    Clipboard.setData(ClipboardData(text: "$selectedTextList\n\n— $ref"));
    _clearAyahSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationService.isArabic
              ? "تم نسخ الآيات المحددة"
              : "Selected verses copied",
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareSelectedAyahsText() {
    if (_selectedAyahs.isEmpty) return;
    final sorted = _selectedAyahs.toList()..sort();
    final selectedTextList = _ayahList
        .where((a) => sorted.contains(a.numberInSurah))
        .map((a) => "${a.text} ﴿${a.numberInSurah}﴾")
        .join("\n");
    final ref = "${_currentSurah.name} (${sorted.first}-${sorted.last})";
    SharePlus.instance.share(
      ShareParams(text: "$selectedTextList\n\n— $ref • Aya"),
    );
    _clearAyahSelection();
  }
}
