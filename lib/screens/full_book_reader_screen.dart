import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/islamic_book_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../theme/app_colors.dart';

class FullBookReaderScreen extends StatefulWidget {
  final String bookKey; // 'raheeq_makhtum' or 'qisas_al_anbiya'
  final String defaultTitleAr;
  final String defaultTitleEn;
  final StorageService storage;
  final int? initialPage;
  final int? startPage;
  final int? endPage;
  final int? startPageEn;
  final int? endPageEn;
  final String? scopeTitleAr;
  final String? scopeTitleEn;

  const FullBookReaderScreen({
    super.key,
    required this.bookKey,
    required this.defaultTitleAr,
    required this.defaultTitleEn,
    required this.storage,
    this.initialPage,
    this.startPage,
    this.endPage,
    this.startPageEn,
    this.endPageEn,
    this.scopeTitleAr,
    this.scopeTitleEn,
  });

  @override
  State<FullBookReaderScreen> createState() => _FullBookReaderScreenState();
}

class _FullBookReaderScreenState extends State<FullBookReaderScreen> {
  FullIslamicBook? _rawFullBook;
  FullIslamicBook? _book;
  bool _isLoading = true;
  String? _error;
  bool _isScopedMode = false;
  bool _isEnglish = false;

  late PageController _pageController;
  int _currentPageIndex = 0;
  double _fontSize = 15.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _isEnglish = widget.storage.getBool('book_reader_is_english', defaultValue: !TranslationService.isArabic);
    _fontSize = widget.storage.getDouble('book_reader_font_size', defaultValue: 15.0);
    _isScopedMode = widget.startPage != null && widget.endPage != null;
    _pageController = PageController(initialPage: 0);
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final activeKey = _isEnglish ? '${widget.bookKey}_en' : widget.bookKey;
      final fullBook = await IslamicBookService.loadBook(activeKey);
      if (!mounted) return;

      FullIslamicBook activeBook;
      final currentStart = _isEnglish ? (widget.startPageEn ?? widget.startPage) : widget.startPage;
      final currentEnd = _isEnglish ? (widget.endPageEn ?? widget.endPage) : widget.endPage;

      if (_isScopedMode && currentStart != null && currentEnd != null) {
        activeBook = IslamicBookService.getScopedBook(
          fullBook,
          currentStart,
          currentEnd,
          scopeTitleAr: widget.scopeTitleAr,
          scopeTitleEn: widget.scopeTitleEn,
        );
      } else {
        activeBook = fullBook;
      }

      int targetIndex = 0;
      if (widget.initialPage != null) {
        if (_isScopedMode && currentStart != null) {
          if (widget.initialPage! >= currentStart) {
            targetIndex = (widget.initialPage! - currentStart).clamp(0, activeBook.allPages.length - 1);
          } else {
            targetIndex = (widget.initialPage! - 1).clamp(0, activeBook.allPages.length - 1);
          }
        } else {
          targetIndex = (widget.initialPage! - 1).clamp(0, activeBook.allPages.length - 1);
        }
      } else {
        final langSuffix = _isEnglish ? '_en' : '';
        final savedPage = IslamicBookService.getLastReadPage(
          _isScopedMode ? '${widget.bookKey}_scoped_$currentStart$langSuffix' : '${widget.bookKey}$langSuffix',
          widget.storage,
        );
        targetIndex = (savedPage - 1).clamp(0, activeBook.allPages.length - 1);
      }

      _currentPageIndex = targetIndex;
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPageIndex);

      setState(() {
        _rawFullBook = fullBook;
        _book = activeBook;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
      _isLoading = true;
    });
    widget.storage.setBool('book_reader_is_english', _isEnglish);
    _loadBook();
  }

  void _toggleFullBookMode() {
    if (_rawFullBook == null) return;
    setState(() {
      _isLoading = true;
      _isScopedMode = !_isScopedMode;
    });

    FullIslamicBook nextBook;
    final currentStart = _isEnglish ? (widget.startPageEn ?? widget.startPage) : widget.startPage;
    final currentEnd = _isEnglish ? (widget.endPageEn ?? widget.endPage) : widget.endPage;

    if (_isScopedMode && currentStart != null && currentEnd != null) {
      nextBook = IslamicBookService.getScopedBook(
        _rawFullBook!,
        currentStart,
        currentEnd,
        scopeTitleAr: widget.scopeTitleAr,
        scopeTitleEn: widget.scopeTitleEn,
      );
    } else {
      nextBook = _rawFullBook!;
    }

    _currentPageIndex = 0;
    _pageController.dispose();
    _pageController = PageController(initialPage: 0);

    setState(() {
      _book = nextBook;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    final currentStart = _isEnglish ? (widget.startPageEn ?? widget.startPage) : widget.startPage;
    final langSuffix = _isEnglish ? '_en' : '';
    final saveKey = _isScopedMode
        ? '${widget.bookKey}_scoped_$currentStart$langSuffix'
        : '${widget.bookKey}$langSuffix';
    IslamicBookService.saveLastReadPage(saveKey, index + 1, widget.storage);
  }

  void _jumpToPage(int pageNum) {
    if (_book == null || _book!.allPages.isEmpty) return;
    final targetIndex = (pageNum - 1).clamp(0, _book!.allPages.length - 1);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(targetIndex);
    }
    setState(() {
      _currentPageIndex = targetIndex;
    });
    final currentStart = _isEnglish ? (widget.startPageEn ?? widget.startPage) : widget.startPage;
    final langSuffix = _isEnglish ? '_en' : '';
    final saveKey = _isScopedMode
        ? '${widget.bookKey}_scoped_$currentStart$langSuffix'
        : '${widget.bookKey}$langSuffix';
    IslamicBookService.saveLastReadPage(saveKey, targetIndex + 1, widget.storage);
  }

  void _openSearchDialog() {
    if (_book == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: _BookSearchSheet(
          book: _book!,
          isEnglish: _isEnglish,
          onSelectPage: (pageNum) {
            Navigator.pop(ctx);
            // pageNum in search result is 1-based pageNum or index
            final index = _book!.allPages.indexWhere((p) => p.pageNum == pageNum);
            final target = index != -1 ? index + 1 : pageNum;
            _jumpToPage(target);
          },
        ),
      ),
    );
  }

  void _openTableOfContents() {
    if (_book == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: _TableOfContentsSheet(
          book: _book!,
          currentPage: _currentPageIndex + 1,
          isScoped: _isScopedMode,
          isEnglish: _isEnglish,
          onToggleFullBook: _rawFullBook != null ? () {
            Navigator.pop(ctx);
            _toggleFullBookMode();
          } : null,
          onSelectPage: (pageNum) {
            Navigator.pop(ctx);
            final index = _book!.allPages.indexWhere((p) => p.pageNum >= pageNum);
            final target = index != -1 ? index + 1 : pageNum;
            _jumpToPage(target);
          },
        ),
      ),
    );
  }

  String get _currentHeadline {
    if (_book == null || _book!.allPages.isEmpty) return '';
    final page = _currentPageIndex < _book!.allPages.length ? _book!.allPages[_currentPageIndex] : null;
    if (page != null && page.title.isNotEmpty) {
      return IslamicBookService.cleanText(page.title);
    }
    // Search matching chapter
    if (page != null) {
      for (final ch in _book!.chapters) {
        if (page.pageNum >= ch.startPage && page.pageNum <= ch.endPage) {
          return IslamicBookService.cleanText(ch.title);
        }
      }
    }
    return TranslationService.isArabic ? _book!.titleAr : _book!.titleEn;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Directionality(
        textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _isEnglish ? widget.defaultTitleEn : widget.defaultTitleAr,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_isEnglish ? 'Opening book...' : 'جاري فتح الكتاب...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Directionality(
        textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _isEnglish ? widget.defaultTitleEn : widget.defaultTitleAr,
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    _isEnglish ? 'Failed to open book: $_error' : 'تعذر فتح الكتاب: $_error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadBook();
                    },
                    child: Text(_isEnglish ? 'Retry' : 'إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentPage = _currentPageIndex < _book!.allPages.length
        ? _book!.allPages[_currentPageIndex]
        : null;

    final bookmarkKey = _isScopedMode
        ? '${widget.bookKey}_scoped_${widget.startPage}'
        : widget.bookKey;
    final isBookmarked = currentPage != null &&
        IslamicBookService.getBookmarks(bookmarkKey, widget.storage)
            .contains(_currentPageIndex + 1);

    return Directionality(
      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEnglish ? _book!.titleEn : _book!.titleAr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _isScopedMode
                  ? (TranslationService.isArabic ? 'قسم مخصص من الكتاب' : 'Dedicated Section')
                  : (TranslationService.isArabic ? 'الكتاب كاملاً' : 'Full Book'),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.teal.withAlpha(120)),
              ),
              child: Text(
                _isEnglish ? 'EN' : 'عربي',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal,
                ),
              ),
            ),
            tooltip: _isEnglish ? 'Switch to Arabic (عربي)' : 'Switch to English (EN)',
            onPressed: _toggleLanguage,
          ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.gold : null,
            ),
            tooltip: TranslationService.isArabic ? 'إشارة مرجعية' : 'Bookmark',
            onPressed: () {
              if (currentPage != null) {
                HapticFeedback.lightImpact();
                IslamicBookService.toggleBookmark(
                  bookmarkKey,
                  _currentPageIndex + 1,
                  widget.storage,
                );
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: TranslationService.isArabic ? 'بحث في الكتاب' : 'Search in Book',
            onPressed: _openSearchDialog,
          ),
          if (widget.startPage != null && widget.endPage != null)
            IconButton(
              icon: Icon(
                _isScopedMode ? Icons.filter_alt_outlined : Icons.menu_book,
                color: _isScopedMode ? AppColors.gold : null,
              ),
              tooltip: _isScopedMode
                  ? (_isEnglish ? 'View Full Book' : 'عرض الكتاب كاملاً')
                  : (_isEnglish ? 'View Chapter Only' : 'عرض الباب المخصص'),
              onPressed: _toggleFullBookMode,
            ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: TranslationService.isArabic ? 'الفهرس' : 'Table of Contents',
            onPressed: _openTableOfContents,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(40))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page navigation with RTL/LTR awareness
            Row(
              children: [
                IconButton(
                  icon: Icon(_isEnglish ? Icons.chevron_left : Icons.chevron_right),
                  tooltip: _isEnglish ? 'Previous Page' : 'الصفحة السابقة',
                  onPressed: _currentPageIndex > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
                InkWell(
                  onTap: () => _showJumpToPageDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isEnglish
                          ? 'P. ${_currentPageIndex + 1} / ${_book!.allPages.length}'
                          : 'ص ${_currentPageIndex + 1} / ${_book!.allPages.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isEnglish ? Icons.chevron_right : Icons.chevron_left),
                  tooltip: _isEnglish ? 'Next Page' : 'الصفحة التالية',
                  onPressed: _currentPageIndex < _book!.allPages.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
              ],
            ),
            // Font controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: _fontSize > 10
                      ? () {
                          setState(() => _fontSize -= 2);
                          widget.storage.setDouble('book_reader_font_size', _fontSize);
                        }
                      : null,
                ),
                Text(
                  '${_fontSize.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: _fontSize < 32
                      ? () {
                          setState(() => _fontSize += 2);
                          widget.storage.setDouble('book_reader_font_size', _fontSize);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // FIXED HEADLINE: Pinned permanently at the top, does NOT move or scroll with pages
          if (_currentHeadline.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 120),
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor.withAlpha(40)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 18, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentHeadline,
                      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Scrollable and swipeable text body
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              reverse: false, // Natural page movement governed by Directionality (Arabic: RTL; English: LTR)
              itemCount: _book!.allPages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final page = _book!.allPages[index];
                final cleanText = IslamicBookService.cleanText(page.text);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: SelectableText(
                    cleanText,
                    textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: _isEnglish ? 'Inter' : 'Amiri',
                      fontSize: _fontSize,
                      height: _isEnglish ? 1.65 : 1.85,
                      letterSpacing: _isEnglish ? 0.3 : 0.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showJumpToPageDialog(BuildContext context) {
    final textController = TextEditingController(text: '${_currentPageIndex + 1}');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: AlertDialog(
          title: Text(_isEnglish ? 'Jump to Page' : 'انتقال إلى صفحة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEnglish
                    ? 'Enter page number between 1 and ${_book!.allPages.length}'
                    : 'أدخل رقم الصفحة بين ١ و ${_book!.allPages.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '1 - ${_book!.allPages.length}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_isEnglish ? 'Cancel' : 'إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = textController.text.trim();
                final normalized = IslamicBookService.normalizeDigits(raw);
                final val = int.tryParse(normalized);
                if (val != null && val >= 1 && val <= _book!.allPages.length) {
                  Navigator.pop(ctx);
                  _jumpToPage(val);
                }
              },
              child: Text(_isEnglish ? 'Go' : 'انتقال'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableOfContentsSheet extends StatelessWidget {
  final FullIslamicBook book;
  final int currentPage;
  final bool isScoped;
  final bool isEnglish;
  final VoidCallback? onToggleFullBook;
  final Function(int) onSelectPage;

  const _TableOfContentsSheet({
    required this.book,
    required this.currentPage,
    required this.isScoped,
    required this.isEnglish,
    this.onToggleFullBook,
    required this.onSelectPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(40))),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(
                  isEnglish ? 'Table of Contents' : 'فهرس الكتاب',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                if (onToggleFullBook != null)
                  TextButton.icon(
                    onPressed: onToggleFullBook,
                    icon: Icon(
                      isScoped ? Icons.menu_book : Icons.filter_alt_outlined,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    label: Text(
                      isScoped
                          ? (isEnglish ? 'Full Book' : 'عرض الكتاب كاملاً')
                          : (isEnglish ? 'Scoped' : 'عرض القسم المخصص'),
                      style: const TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    isEnglish ? '${book.chapters.length} chapters' : '${book.chapters.length} فصلاً',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: book.chapters.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: theme.dividerColor.withAlpha(30),
              ),
              itemBuilder: (context, index) {
                final ch = book.chapters[index];
                final isCurrent = currentPage >= ch.startPage && currentPage <= ch.endPage;

                return ListTile(
                  title: Text(
                    ch.title,
                    textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? AppColors.teal : null,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.teal.withAlpha(40)
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEnglish ? 'P. ${ch.startPage}' : 'ص ${ch.startPage}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrent ? AppColors.teal : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => onSelectPage(ch.startPage),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookSearchSheet extends StatefulWidget {
  final FullIslamicBook book;
  final bool isEnglish;
  final Function(int) onSelectPage;

  const _BookSearchSheet({
    required this.book,
    this.isEnglish = false,
    required this.onSelectPage,
  });

  @override
  State<_BookSearchSheet> createState() => _BookSearchSheetState();
}

class _BookSearchSheetState extends State<_BookSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<BookSearchResult> _results = [];
  bool _hasSearched = false;

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    final res = IslamicBookService.searchBook(widget.book, query);
    setState(() {
      _results = res;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              textDirection: widget.isEnglish ? TextDirection.ltr : TextDirection.rtl,
              decoration: InputDecoration(
                hintText: widget.isEnglish
                    ? 'Search inside book...'
                    : 'ابحث في نصوص الكتاب...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withAlpha(100)
                    : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _search,
              onChanged: (val) {
                if (val.length >= 2) _search(val);
              },
            ),
          ),
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    widget.isEnglish
                        ? 'Found ${_results.length} result${_results.length == 1 ? '' : 's'}'
                        : 'تم العثور على ${_results.length} نتيجة',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _hasSearched
                          ? (widget.isEnglish
                              ? 'No matches found'
                              : 'لم يتم العثور على نتائج')
                          : (widget.isEnglish
                              ? 'Type a word to search'
                              : 'اكتب كلمة للبحث في الكتاب'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: theme.dividerColor.withAlpha(30),
                    ),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        title: Text(
                          item.chapterTitle,
                          textDirection: widget.isEnglish ? TextDirection.ltr : TextDirection.rtl,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.teal,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.snippet,
                            textDirection: widget.isEnglish ? TextDirection.ltr : TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withAlpha(180),
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.isEnglish ? 'P. ${item.pageNum}' : 'ص ${item.pageNum}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => widget.onSelectPage(item.pageNum),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
