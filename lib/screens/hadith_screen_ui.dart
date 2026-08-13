part of 'hadith_screen.dart';

extension HadithScreenUi on _HadithScreenState {
  Widget _buildBookSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF042F1A), const Color(0xFF02170D)]
              : [const Color(0xFF0D9488), const Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.import_contacts,
                  color: Color(0xFFE5C158),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<HadithBook>(
                    dropdownColor: theme.cardColor,
                    value: _filteredBooks.contains(_selectedBook)
                        ? _selectedBook
                        : _filteredBooks.first,
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext context) {
                      return _filteredBooks.map((b) {
                        return Container(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            TranslationService.isArabic
                                ? b.nameAr
                                : b.nameEn,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE5C158),
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFE5C158),
                    ),
                    items: _filteredBooks.map((b) {
                      return DropdownMenuItem<HadithBook>(
                        value: b,
                        child: Text(
                          TranslationService.isArabic
                              ? b.nameAr
                              : b.nameEn,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedBook = val;
                          _currentPage = 1;
                        });
                        _loadSelectedBookData();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  final newLang = _displayLang == 'ara' ? 'eng' : 'ara';
                  setState(() {
                    _displayLang = newLang;
                    _currentPage = 1;
                    if (newLang == 'eng' && _selectedBook.arabicOnly) {
                      _selectedBook = hadithBooks[0];
                    }
                  });
                  _loadSelectedBookData();
                },
                style: TextButton.styleFrom(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  _displayLang == 'ara' ? 'EN' : 'عربي',
                  style: const TextStyle(
                    color: Color(0xFFE5C158),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _jumpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: TranslationService.isArabic
                          ? "انتقل إلى رقم الحديث (1 - ${_selectedBook.totalHadiths})"
                          : "Jump to Hadith # (1 - ${_selectedBook.totalHadiths})",
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: (Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.white)
                            .withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white)
                          .withValues(alpha: 0.12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _jumpToHadith(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFFE5C158)),
                onPressed: _jumpToHadith,
                tooltip: TranslationService.isArabic ? "انتقال" : "Go",
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: TranslationService.isArabic
                    ? "بحث شامل في نص الحديث..."
                    : "Full text search across hadiths...",
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white)
                      .withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white)
                    .withValues(alpha: 0.12),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFFE5C158),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _performCrossBookSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (q) {
                if (q.trim().isEmpty) {
                  setState(() {
                    _crossSearchResults = null;
                    _activeSearchQuery = '';
                    _currentPage = 1;
                  });
                } else {
                  _performCrossBookSearch(q.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
