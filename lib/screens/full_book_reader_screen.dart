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

  const FullBookReaderScreen({
    super.key,
    required this.bookKey,
    required this.defaultTitleAr,
    required this.defaultTitleEn,
    required this.storage,
    this.initialPage,
  });

  @override
  State<FullBookReaderScreen> createState() => _FullBookReaderScreenState();
}

class _FullBookReaderScreenState extends State<FullBookReaderScreen> {
  FullIslamicBook? _book;
  bool _isLoading = true;
  String? _error;

  late PageController _pageController;
  int _currentPageIndex = 0;
  double _fontSize = 19.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fontSize = widget.storage.getDouble('book_reader_font_size', defaultValue: 19.0);
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final book = await IslamicBookService.loadBook(widget.bookKey);
      if (!mounted) return;

      int startPage = widget.initialPage ??
          IslamicBookService.getLastReadPage(widget.bookKey, widget.storage);

      if (startPage < 1) startPage = 1;
      if (startPage > book.allPages.length) startPage = book.allPages.length;

      _currentPageIndex = startPage - 1;
      _pageController = PageController(initialPage: _currentPageIndex);

      setState(() {
        _book = book;
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

  @override
  void dispose() {
    if (_book != null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    if (_book != null && index < _book!.allPages.length) {
      final pageNum = _book!.allPages[index].pageNum;
      IslamicBookService.saveLastReadPage(widget.bookKey, pageNum, widget.storage);
    }
  }

  void _jumpToPage(int pageNum) {
    if (_book == null) return;
    final index = (_book!.allPages.indexWhere((p) => p.pageNum == pageNum));
    final targetIndex = index != -1 ? index : (pageNum - 1).clamp(0, _book!.allPages.length - 1);

    _pageController.jumpToPage(targetIndex);
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
      builder: (ctx) => _BookSearchSheet(
        book: _book!,
        onSelectPage: (pageNum) {
          Navigator.pop(ctx);
          _jumpToPage(pageNum);
        },
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
      builder: (ctx) => _TableOfContentsSheet(
        book: _book!,
        currentPage: _currentPageIndex + 1,
        onSelectPage: (pageNum) {
          Navigator.pop(ctx);
          _jumpToPage(pageNum);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            TranslationService.isArabic ? widget.defaultTitleAr : widget.defaultTitleEn,
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري فتح الكتاب...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            TranslationService.isArabic ? widget.defaultTitleAr : widget.defaultTitleEn,
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
                Text('تعذر فتح الكتاب: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadBook();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentPage = _currentPageIndex < _book!.allPages.length
        ? _book!.allPages[_currentPageIndex]
        : null;

    final isBookmarked = currentPage != null &&
        IslamicBookService.getBookmarks(widget.bookKey, widget.storage)
            .contains(currentPage.pageNum);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.isArabic ? _book!.titleAr : _book!.titleEn,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (currentPage != null && currentPage.title.isNotEmpty)
              Text(
                currentPage.title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
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
                  widget.bookKey,
                  currentPage.pageNum,
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
            // Page navigation
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      TranslationService.isArabic
                          ? 'ص ${_currentPageIndex + 1} / ${_book!.allPages.length}'
                          : 'P. ${_currentPageIndex + 1} / ${_book!.allPages.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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
                  onPressed: _fontSize > 14
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: _book!.allPages.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final page = _book!.allPages[index];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (page.title.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(
                        right: BorderSide(color: AppColors.teal, width: 4),
                      ),
                    ),
                    child: Text(
                      page.title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SelectableText(
                  page.text,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.8,
                    letterSpacing: 0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showJumpToPageDialog(BuildContext context) {
    final textController = TextEditingController(text: '${_currentPageIndex + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(TranslationService.isArabic ? 'انتقال إلى صفحة' : 'Jump to Page'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - ${_book!.allPages.length}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(TranslationService.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(textController.text.trim());
              if (val != null) {
                Navigator.pop(ctx);
                _jumpToPage(val);
              }
            },
            child: Text(TranslationService.isArabic ? 'انتقال' : 'Go'),
          ),
        ],
      ),
    );
  }
}

class _TableOfContentsSheet extends StatelessWidget {
  final FullIslamicBook book;
  final int currentPage;
  final Function(int) onSelectPage;

  const _TableOfContentsSheet({
    required this.book,
    required this.currentPage,
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
                  TranslationService.isArabic ? 'فهرس الكتاب' : 'Table of Contents',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Text(
                  '${book.chapters.length} فصلاً',
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
                    textDirection: TextDirection.rtl,
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
                      'ص ${ch.startPage}',
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
  final Function(int) onSelectPage;

  const _BookSearchSheet({
    required this.book,
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
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: TranslationService.isArabic
                    ? 'ابحث في كامل نصوص الكتاب...'
                    : 'Search inside book...',
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
                    'تم العثور على ${_results.length} نتيجة',
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
                          ? (TranslationService.isArabic
                              ? 'لم يتم العثور على نتائج'
                              : 'No matches found')
                          : (TranslationService.isArabic
                              ? 'اكتب كلمة للبحث في الكتاب'
                              : 'Type a word to search'),
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
                          textDirection: TextDirection.rtl,
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
                            textDirection: TextDirection.rtl,
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
                            'ص ${item.pageNum}',
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
