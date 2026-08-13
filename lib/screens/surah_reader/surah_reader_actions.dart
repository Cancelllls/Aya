part of 'surah_reader_screen.dart';

extension SurahReaderActions on _SurahReaderScreenState {
  void _showTafseerDialog(Ayah ayah) {
    final Map<String, String> loadedTafsirs = {};
    if (ayah.tafseer.trim().isNotEmpty) {
      loadedTafsirs['ar.muyassar'] = ayah.tafseer;
    }

    String selectedLang = 'all'; // 'all', 'ar', 'en'

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
                            "${_currentSurah.name} - ${isAr ? 'آية' : 'Ayah'} ${ayah.numberInSurah}",
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
                          // Fetch in background & trigger rebuild on load
                          ApiService.fetchTafsirTextForAyah(
                            edition.identifier,
                            _currentSurah.number,
                            ayah.numberInSurah,
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
                                      child: Text(
                                        edition.language == 'en'
                                            ? edition.name
                                            : (isAr ? edition.name : edition.mufassirEn),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  edition.language == 'en'
                                      ? edition.mufassirEn
                                      : (isAr ? edition.mufassir : edition.mufassirEn),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                  ),
                                ),
                                const Divider(height: 16),
                                if (!hasLoaded)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFE5C158),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    tafsirText.isNotEmpty ? tafsirText : (isAr ? 'التفسير غير متوفر لهذه الآية' : 'Tafsir not available'),
                                    textDirection: edition.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: edition.language == 'en' ? null : 'Amiri',
                                      fontSize: 14,
                                      height: 1.8,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
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

  void _shareSelectedAyahsAsImage() {
    if (_selectedAyahs.isEmpty) return;
    final sorted = _selectedAyahs.toList()..sort();
    final selectedAyahsList = _ayahList
        .where((a) => sorted.contains(a.numberInSurah))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => ShareAyahDialog(
        ayahs: selectedAyahsList,
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
        if (_selectedAyahs.length == 1) {
          _selectedAyahs.clear();
        } else {
          final sorted = _selectedAyahs.toList()..sort();
          final min = sorted.first;
          final max = sorted.last;
          if (num == min) {
            _selectedAyahs.remove(min);
          } else if (num == max) {
            _selectedAyahs.remove(max);
          } else {
            // Internal ayah tapped: compare left chunk [min..num-1] vs right chunk [num+1..max].
            // Remove the smaller chunk (and num) so the larger contiguous chunk stays selected.
            final leftLen = num - min;
            final rightLen = max - num;
            if (leftLen < rightLen) {
              // Left chunk is smaller -> remove [min..num]
              for (int i = min; i <= num; i++) {
                _selectedAyahs.remove(i);
              }
            } else {
              // Right chunk is smaller or equal -> remove [num..max]
              for (int i = num; i <= max; i++) {
                _selectedAyahs.remove(i);
              }
            }
          }
        }
      } else if (_selectedAyahs.isEmpty) {
        _selectedAyahs.add(num);
      } else {
        // Fill the gap: select all ayahs between current min/max and new ayah
        final currentMin = _selectedAyahs.reduce((a, b) => a < b ? a : b);
        final currentMax = _selectedAyahs.reduce((a, b) => a > b ? a : b);
        final newMin = num < currentMin ? num : currentMin;
        final newMax = num > currentMax ? num : currentMax;
        for (int i = newMin; i <= newMax; i++) {
          _selectedAyahs.add(i);
        }
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
    final isAr = TranslationService.isArabic;
    final sorted = _selectedAyahs.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "مشاركة كصورة" : "Share as Image"),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareSelectedAyahsAsImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "مشاركة كنص" : "Share as Text"),
                onTap: () {
                  Navigator.pop(ctx);
                  final selectedTextList = _ayahList
                      .where((a) => sorted.contains(a.numberInSurah))
                      .map((a) => "${a.text} ﴿${a.numberInSurah}﴾")
                      .join("\n");
                  final ref = "${_currentSurah.name} (${sorted.first}-${sorted.last})";
                  SharePlus.instance.share(
                    ShareParams(text: "$selectedTextList\n\n— $ref • Aya"),
                  );
                  _clearAyahSelection();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
