part of 'surah_reader_screen.dart';

extension SurahReaderUi on _SurahReaderScreenState {
  Widget _buildHizbDivider(int hizb, int juz) {
    if (hizb == 0 && juz == 0) return const SizedBox.shrink();

    final text = hizb == 0
        ? "${TranslationService.t('juz')} $juz"
        : "${TranslationService.t('hizb')} $hizb";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          // ignore: deprecated_member_use
          Expanded(
            child: Divider(
              color: const Color(0xFFE5C158).withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: const Color(0xFFE5C158).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                // ignore: deprecated_member_use
                border: Border.all(
                  color: const Color(0xFFE5C158).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFE5C158),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // ignore: deprecated_member_use
          Expanded(
            child: Divider(
              color: const Color(0xFFE5C158).withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeaderBanner(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
        border: Border.all(
          color: const Color(0xFFE5C158).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'surah_name_${_currentSurah.number}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                _currentSurah.name,
                style: const TextStyle(fontFamily: 'Amiri',
                  color: const Color(0xFFE5C158),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentSurah.englishName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          Text(
            "${_currentSurah.englishNameTranslation} • ${_currentSurah.numberOfAyahs} ${TranslationService.t('verses')}",
            style: TextStyle(
              fontSize: 11,
              // ignore: deprecated_member_use
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard(Ayah ayah, ThemeData theme, AudioPlayState playState) {
    final isDark = theme.brightness == Brightness.dark;
    final key = _ayahKeys.putIfAbsent(ayah.numberInSurah, () => GlobalKey());
    final isBookmarked = _bookmarkedAyahNumber == ayah.numberInSurah;
    final isPlaying =
        playState.isPlaying &&
        playState.surahNum == _currentSurah.number &&
        playState.ayahNum == ayah.numberInSurah;
    final isHighlighted = isBookmarked || isPlaying;

    return VisibilityDetector(
      key: Key('ayah_${ayah.numberInSurah}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          _debouncedSavePosition(
            _currentSurah.number,
            ayah.numberInSurah,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        key: key,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isPlaying
              // ignore: deprecated_member_use
              ? const Color(0xFFE5C158).withValues(alpha: isDark ? 0.18 : 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFE5C158)
                // ignore: deprecated_member_use
                : const Color(0xFFE5C158).withValues(alpha: 0.12),
            width: isHighlighted ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  // ignore: deprecated_member_use
                  ? const Color(0xFFE5C158).withValues(alpha: 0.08)
                  // ignore: deprecated_member_use
                  : Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: isHighlighted
                      ? const Color(0xFFE5C158)
                      : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isBookmarked
                            // ignore: deprecated_member_use
                            ? const Color(0xFFE5C158).withValues(alpha: 0.15)
                            : theme.dividerColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${_currentSurah.number}:${ayah.numberInSurah}",
                        style: TextStyle(
                          color: const Color(0xFFE5C158),
                          fontSize: 11,
                          fontWeight: isBookmarked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.menu_book_outlined,
                            size: 20,
                            color: Color(0xFFE5C158),
                          ),
                          onPressed: () {
                            _showTafseerDialog(ayah);
                          },
                          tooltip: 'Read Tafseer',
                        ),
                        IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 20,
                            color: const Color(0xFFE5C158),
                          ),
                          onPressed: () {
                            _bookmarkAyah(ayah.numberInSurah);
                          },
                          tooltip: 'Bookmark this Verse',
                        ),
                        IconButton(
                          icon:
                              (playState.isLoading &&
                                  playState.surahNum == _currentSurah.number &&
                                  playState.ayahNum == ayah.numberInSurah)
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark
                                        ? const Color(0xFFE5C158)
                                        : theme.primaryColor,
                                  ),
                                )
                              : Icon(
                                  Icons.play_circle_outline,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFFE5C158)
                                      : theme.primaryColor,
                                ),
                          onPressed: () {
                            _playAudioWithDisclaimer(
                              ayahIndex: _ayahList.indexOf(ayah),
                            );
                          },
                          tooltip: 'Play Verse Audio',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _toggleAyahMasking(ayah.numberInSurah),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: (_isHifzMode && !_unmaskedAyahs.contains(ayah.numberInSurah))
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5C158).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5C158).withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.visibility_off_outlined,
                                  color: Color(0xFFE5C158),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  TranslationService.isArabic
                                      ? "انقر لكشف الآية (وضع الحفظ والتسميع)"
                                      : "Tap to reveal verse (Hifz Mode)",
                                  style: const TextStyle(
                                    color: Color(0xFFE5C158),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            ayah.text,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.justify,
                            style: _getArabicTextStyle(
                              22 * _fontSizeMultiplier,
                              height: 2.1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (_readingMode == 'translation') ...[
                  const SizedBox(height: 12),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    ayah.translation,
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: 14 * _fontSizeMultiplier,
                      // ignore: deprecated_member_use
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
                        0.85,
                      ),
                      height: 1.5,
                    ),
                  ),
                ] else if (_readingMode == 'tafseer') ...[
                  const SizedBox(height: 12),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    ayah.tafseer.isNotEmpty
                        ? ayah.tafseer
                        : (TranslationService.isArabic
                              ? 'التفسير غير متوفر حالياً لهذه الآية.'
                              : 'Tafseer is not available for this verse.'),
                    textDirection: TextDirection.rtl,
                    style: _getArabicTextStyle(
                      16 * _fontSizeMultiplier,
                      height: 1.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinuousLayout(AudioPlayState playState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const int chunkSize = 5;
    final int pageCount = (_ayahList.length / chunkSize).ceil();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _pauseAutoScrollTemporarily();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: 16,
          bottom: 16.0 + MediaQuery.of(context).padding.bottom + 58.0 + 16.0,
        ),
        itemCount: pageCount + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _buildSurahHeaderBanner(theme, isDark),
                if (_currentSurah.number != 9 && _currentSurah.number != 1)
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                      style: _getArabicTextStyle(
                        30,
                        color: const Color(0xFFE5C158),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          }

          final int pageIndex = index - 1;
          final int startIdx = pageIndex * chunkSize;
          final int endIdx = (startIdx + chunkSize).clamp(0, _ayahList.length);
          final List<Ayah> chunk = _ayahList.sublist(startIdx, endIdx);

          final key = _pageKeys.putIfAbsent(pageIndex, () => GlobalKey());

          final oldRecs = _pageRecognizers[pageIndex];
          if (oldRecs != null) {
            for (var r in oldRecs) {
              r.dispose();
            }
            oldRecs.clear();
          }
          final List<TapGestureRecognizer> pageRecs = [];
          _pageRecognizers[pageIndex] = pageRecs;

          final List<InlineSpan> spans = [];
          for (var ayah in chunk) {
            final isBookmarked = _bookmarkedAyahNumber == ayah.numberInSurah;
            final isPlaying =
                playState.isPlaying &&
                playState.surahNum == _currentSurah.number &&
                playState.ayahNum == ayah.numberInSurah;
            final isHighlighted = isBookmarked || isPlaying;

            final recognizer = TapGestureRecognizer()
              ..onTap = () => _showAyahActionSheet(ayah);
            pageRecs.add(recognizer);

            spans.add(
              TextSpan(
                text: "${ayah.text} ",
                recognizer: recognizer,
                style: _getArabicTextStyle(
                  22 * _fontSizeMultiplier,
                  height: 2.1,
                  color: isHighlighted
                      ? const Color(0xFFE5C158)
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                  backgroundColor: isPlaying
                      // ignore: deprecated_member_use
                      ? const Color(0xFFE5C158).withValues(alpha: 0.3)
                      : isBookmarked
                      // ignore: deprecated_member_use
                      ? const Color(0xFFE5C158).withValues(alpha: 0.15)
                      : null,
                ),
              ),
            );

            spans.add(
              TextSpan(
                text: " ﴿${ayah.numberInSurah}﴾ ",
                style: _getArabicTextStyle(
                  20,
                  color: const Color(0xFFE5C158),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final int firstHizb = chunk.isNotEmpty ? chunk.first.hizb : 0;
          final int firstJuz = chunk.isNotEmpty ? chunk.first.juz : 0;

          final bool showHizbHeader =
              pageIndex == 0 ||
              (pageIndex > 0 &&
                  firstHizb != 0 &&
                  firstHizb != _ayahList[(pageIndex * chunkSize) - 1].hizb) ||
              (pageIndex > 0 &&
                  firstHizb == 0 &&
                  firstJuz != _ayahList[(pageIndex * chunkSize) - 1].juz);

          return Column(
            children: [
              if (showHizbHeader && (firstHizb > 0 || firstJuz > 0))
                _buildHizbDivider(firstHizb, firstJuz),
              VisibilityDetector(
                key: Key('chunk_$pageIndex'),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0.5 && chunk.isNotEmpty) {
                    _debouncedSavePosition(
                      _currentSurah.number,
                      chunk.first.numberInSurah,
                    );
                  }
                },
                child: Container(
                  key: key,
                  margin: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: _hideContinuousBorders ? 2 : 8,
                  ),
                  decoration: _hideContinuousBorders
                      ? BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        )
                      : BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          // ignore: deprecated_member_use
                          border: Border.all(
                            color: const Color(0xFFE5C158).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withValues(alpha: 
                                isDark ? 0.3 : 0.04,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                  child: Container(
                    margin: _hideContinuousBorders
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(4),
                    decoration: _hideContinuousBorders
                        ? null
                        : BoxDecoration(
                            // ignore: deprecated_member_use
                            border: Border.all(
                              color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Text.rich(
                      TextSpan(children: spans),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopMiniPlayer(
    ThemeData theme,
    bool isDark,
    AudioPlayState playState,
  ) {
    return Container(
      height: 40.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5C158).withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              playState.isPlaying ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFFE5C158),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => AudioManager.instance.togglePlayPause(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ValueListenableBuilder<Duration>(
              valueListenable: AudioManager.instance.durationNotifier,
              builder: (context, duration, child) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: AudioManager.instance.positionNotifier,
                  builder: (context, position, child) {
                    final isSplit =
                        playState.ayahNum > 0 &&
                        !AudioManager.instance.isTimestampSyncMode;
                    final currentAyahIndex = isSplit
                        ? playState.ayahNum - 1
                        : 0;
                    final totalAyahs = _currentSurah.numberOfAyahs;

                    double posVal;
                    double maxVal;

                    if (isSplit) {
                      maxVal = totalAyahs.toDouble();
                      posVal = currentAyahIndex.toDouble();
                      if (duration.inMilliseconds > 0) {
                        posVal +=
                            position.inMilliseconds / duration.inMilliseconds;
                      }
                      if (posVal > maxVal) posVal = maxVal;
                      if (posVal < 0) posVal = 0;
                    } else {
                      maxVal = duration.inMilliseconds.toDouble();
                      maxVal = maxVal > 0 ? maxVal : 1.0;
                      posVal = position.inMilliseconds.toDouble();
                      if (posVal > maxVal) posVal = maxVal;
                      if (posVal < 0) posVal = 0;
                    }

                    return SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14.0,
                        ),
                      ),
                      child: Slider(
                        value: posVal,
                        min: 0,
                        max: maxVal,
                        activeColor: const Color(0xFFE5C158),
                        inactiveColor: const Color(0xFFE5C158).withValues(alpha: 0.3),
                        onChanged: (val) {
                          if (!isSplit) {
                            AudioManager.instance.positionNotifier.value =
                                Duration(milliseconds: val.toInt());
                          }
                        },
                        onChangeStart: (val) {
                          if (!isSplit) AudioManager.instance.isSeeking = true;
                        },
                        onChangeEnd: (val) async {
                          if (isSplit) {
                            int targetAyah = val.floor() + 1;
                            if (targetAyah > totalAyahs)
                              targetAyah = totalAyahs;
                            if (targetAyah < 1) targetAyah = 1;
                            AudioManager.instance.seekToAyahInSplitMode(
                              targetAyah,
                            );
                          } else {
                            await AudioManager.instance.seekTo(
                              Duration(milliseconds: val.toInt()),
                            );
                            Future.delayed(
                              const Duration(milliseconds: 800),
                              () {
                                AudioManager.instance.isSeeking = false;
                              },
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
