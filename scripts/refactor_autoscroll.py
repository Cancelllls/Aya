with open('lib/screens/surah_reader_screen.dart', 'r') as f:
    text = f.read()

# Refactor the ListView.builder for non-continuous mode
old_item_builder_non_continuous = """                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        if (_currentSurah.number == 9 ||
                                            _currentSurah.number == 1) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Text(
                                            "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                            style: GoogleFonts.amiri(
                                              fontSize: 30,
                                              color: const Color(0xFFE5C158),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      final ayah = _ayahList[index - 1];
                                      final showHizbHeader = index == 1 ||
                                          (index > 1 &&
                                              ayah.hizb !=
                                                  _ayahList[index - 2].hizb);
                                      return Column(
                                        children: [
                                          if (showHizbHeader)
                                            _buildHizbDivider(ayah.hizb),
                                          _buildAyahCard(
                                              ayah, theme, playState),
                                        ],
                                      );
                                    },"""

new_item_builder_non_continuous = """                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        if (_currentSurah.number == 9 ||
                                            _currentSurah.number == 1) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Text(
                                            "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                            style: GoogleFonts.amiri(
                                              fontSize: 30,
                                              color: const Color(0xFFE5C158),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      final ayah = _ayahList[index - 1];
                                      final showHizbHeader = index == 1 ||
                                          (index > 1 &&
                                              ayah.hizb !=
                                                  _ayahList[index - 2].hizb);
                                      return AutoScrollTag(
                                        key: ValueKey(index),
                                        controller: _scrollController,
                                        index: index,
                                        child: Column(
                                          children: [
                                            if (showHizbHeader)
                                              _buildHizbDivider(ayah.hizb),
                                            _buildAyahCard(
                                                ayah, theme, playState),
                                          ],
                                        ),
                                      );
                                    },"""

text = text.replace(old_item_builder_non_continuous, new_item_builder_non_continuous)

# Refactor the continuous mode
old_return_column_continuous = """        return Column(
          children: [
            if (showHizbHeader && firstHizb > 0)
              _buildHizbDivider(firstHizb),
            Container(
              key: key,
              margin: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: _hideContinuousBorders ? 2 : 8,
              ),
              decoration: _hideContinuousBorders
                  ? BoxDecoration(
                      color: isDark ? const Color(0xFF0F1E1B) : const Color(0xFFFDFBF7),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : BoxDecoration(
                      color: isDark ? const Color(0xFF0F1E1B) : const Color(0xFFFDFBF7),
                      borderRadius: BorderRadius.circular(16),
                      // ignore: deprecated_member_use
border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
              padding: EdgeInsets.all(_hideContinuousBorders ? 12 : 24),
              child: RichText(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                text: TextSpan(children: spans),
              ),
            ),
          ],
        );"""

new_return_column_continuous = """        return AutoScrollTag(
          key: ValueKey(pageIndex),
          controller: _scrollController,
          index: pageIndex,
          child: Column(
            children: [
              if (showHizbHeader && firstHizb > 0)
                _buildHizbDivider(firstHizb),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: _hideContinuousBorders ? 2 : 8,
                ),
                decoration: _hideContinuousBorders
                    ? BoxDecoration(
                        color: isDark ? const Color(0xFF0F1E1B) : const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : BoxDecoration(
                        color: isDark ? const Color(0xFF0F1E1B) : const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(16),
                        // ignore: deprecated_member_use
border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                padding: EdgeInsets.all(_hideContinuousBorders ? 12 : 24),
                child: RichText(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  text: TextSpan(children: spans),
                ),
              ),
            ],
          ),
        );"""

text = text.replace(old_return_column_continuous, new_return_column_continuous)

with open('lib/screens/surah_reader_screen.dart', 'w') as f:
    f.write(text)

