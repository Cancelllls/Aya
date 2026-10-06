import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class BookPage {
  final int pageId;
  final int pageNum;
  final String title;
  final String text;

  const BookPage({
    required this.pageId,
    required this.pageNum,
    required this.title,
    required this.text,
  });

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      pageId: json['pageId'] as int? ?? 1,
      pageNum: json['pageNum'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class BookChapter {
  final int chapterIndex;
  final String title;
  final int startPage;
  final int endPage;
  final List<BookPage> pages;

  const BookChapter({
    required this.chapterIndex,
    required this.title,
    required this.startPage,
    required this.endPage,
    required this.pages,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    final rawPages = (json['pages'] as List<dynamic>?) ?? [];
    return BookChapter(
      chapterIndex: json['chapterIndex'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      startPage: json['startPage'] as int? ?? 1,
      endPage: json['endPage'] as int? ?? 1,
      pages: rawPages
          .map((p) => BookPage.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FullIslamicBook {
  final String bookId;
  final String titleAr;
  final String titleEn;
  final String authorAr;
  final String authorEn;
  final int totalPages;
  final int totalChapters;
  final List<BookChapter> chapters;
  final List<BookPage> allPages;

  FullIslamicBook({
    required this.bookId,
    required this.titleAr,
    required this.titleEn,
    required this.authorAr,
    required this.authorEn,
    required this.totalPages,
    required this.totalChapters,
    required this.chapters,
    required this.allPages,
  });

  factory FullIslamicBook.fromJson(Map<String, dynamic> json) {
    final rawChapters = (json['chapters'] as List<dynamic>?) ?? [];
    final chaptersList = rawChapters
        .map((c) => BookChapter.fromJson(c as Map<String, dynamic>))
        .toList();

    final allPagesList = <BookPage>[];
    for (final ch in chaptersList) {
      allPagesList.addAll(ch.pages);
    }

    return FullIslamicBook(
      bookId: json['bookId'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      authorAr: json['authorAr'] as String? ?? '',
      authorEn: json['authorEn'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? allPagesList.length,
      totalChapters: json['totalChapters'] as int? ?? chaptersList.length,
      chapters: chaptersList,
      allPages: allPagesList,
    );
  }
}

class BookSearchResult {
  final int pageNum;
  final String chapterTitle;
  final String snippet;

  const BookSearchResult({
    required this.pageNum,
    required this.chapterTitle,
    required this.snippet,
  });
}

class IslamicBookService {
  static final Map<String, FullIslamicBook> _cache = {};

  static Future<FullIslamicBook> loadBook(String bookKey) async {
    if (_cache.containsKey(bookKey)) {
      return _cache[bookKey]!;
    }

    String jsonString = '';

    // 1. Try loading compressed json.gz
    try {
      final byteData = await rootBundle.load('assets/books/$bookKey.json.gz');
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final decompressed = gzip.decode(bytes);
      jsonString = utf8.decode(decompressed);
    } catch (_) {
      // 2. Fallback to uncompressed json
      try {
        jsonString = await rootBundle.loadString('assets/books/$bookKey.json');
      } catch (e) {
        throw Exception('Could not load book asset $bookKey: $e');
      }
    }

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final book = FullIslamicBook.fromJson(data);
    _cache[bookKey] = book;
    return book;
  }

  static String normalizeDigits(String input) {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < eastern.length; i++) {
      input = input.replaceAll(eastern[i], '$i');
    }
    return input;
  }

  static String cleanText(String text) {
    if (text.isEmpty) return text;
    var t = text.replaceAll(RegExp(r'\[\s*(?:ص|جـ|ج)\s*:[^\]]*\]'), '');
    t = t.replaceAll(RegExp(r'\([٠-٩\d]+\)'), '');
    t = t.replaceAll(RegExp(r'\[[٠-٩\d]+\]'), '');
    t = t.replaceAll(RegExp(r'\(\s*\*\s*\)'), '');
    t = t.replaceAllMapped(RegExp(r'\[\s*([^\]]*?)\s*\]'), (m) => m[1] ?? '');
    t = t.replaceAll(RegExp(r'\[\s*\]'), '');
    t = t.replaceAll(RegExp(r'\(\s*\)'), '');
    t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
    return t.trim();
  }

  static FullIslamicBook getScopedBook(
    FullIslamicBook book,
    int startPage,
    int endPage, {
    String? scopeTitleAr,
    String? scopeTitleEn,
  }) {
    if (startPage < 1) startPage = 1;
    if (endPage > book.allPages.length) endPage = book.allPages.length;
    if (startPage > endPage) startPage = endPage;

    final slicedPages = book.allPages
        .sublist(startPage - 1, endPage)
        .map((p) => BookPage(
              pageId: p.pageId,
              pageNum: p.pageNum,
              title: cleanText(p.title),
              text: cleanText(p.text),
            ))
        .toList();

    // Collect overlapping chapters
    final relevantChapters = <BookChapter>[];
    for (final ch in book.chapters) {
      if (ch.endPage >= startPage && ch.startPage <= endPage) {
        final chPages = ch.pages
            .where((p) => p.pageNum >= startPage && p.pageNum <= endPage)
            .map((p) => BookPage(
                  pageId: p.pageId,
                  pageNum: p.pageNum,
                  title: cleanText(p.title),
                  text: cleanText(p.text),
                ))
            .toList();

        relevantChapters.add(BookChapter(
          chapterIndex: relevantChapters.length + 1,
          title: cleanText(ch.title),
          startPage: ch.startPage.clamp(startPage, endPage),
          endPage: ch.endPage.clamp(startPage, endPage),
          pages: chPages,
        ));
      }
    }

    return FullIslamicBook(
      bookId: '${book.bookId}_scoped_${startPage}_$endPage',
      titleAr: scopeTitleAr ?? book.titleAr,
      titleEn: scopeTitleEn ?? book.titleEn,
      authorAr: book.authorAr,
      authorEn: book.authorEn,
      totalPages: slicedPages.length,
      totalChapters: relevantChapters.length,
      chapters: relevantChapters,
      allPages: slicedPages,
    );
  }

  static List<BookSearchResult> searchBook(
    FullIslamicBook book,
    String query, {
    List<BookPage>? pagesToSearch,
  }) {
    if (query.trim().isEmpty) return [];
    final cleanQuery = query.trim().toLowerCase();
    final results = <BookSearchResult>[];
    final pages = pagesToSearch ?? book.allPages;

    for (final page in pages) {
      final textLower = page.text.toLowerCase();
      final titleLower = page.title.toLowerCase();

      final idx = textLower.indexOf(cleanQuery);
      if (idx != -1 || titleLower.contains(cleanQuery)) {
        String snippet = '';
        if (idx != -1) {
          final start = (idx - 40).clamp(0, page.text.length);
          final end = (idx + cleanQuery.length + 60).clamp(0, page.text.length);
          snippet = '...${page.text.substring(start, end).replaceAll('\n', ' ')}...';
        } else {
          snippet = page.text.length > 100
              ? '${page.text.substring(0, 100).replaceAll('\n', ' ')}...'
              : page.text;
        }

        results.add(BookSearchResult(
          pageNum: page.pageNum,
          chapterTitle: page.title.isNotEmpty ? page.title : 'صفحة ${page.pageNum}',
          snippet: snippet,
        ));

        if (results.length >= 100) break; // Limit search results for speed
      }
    }

    return results;
  }

  static int getLastReadPage(String bookKey, StorageService storage) {
    return storage.getInt('book_last_page_$bookKey', defaultValue: 1);
  }

  static void saveLastReadPage(String bookKey, int pageNum, StorageService storage) {
    storage.setInt('book_last_page_$bookKey', pageNum);
  }

  static List<int> getBookmarks(String bookKey, StorageService storage) {
    final raw = storage.getString('book_bookmarks_$bookKey', defaultValue: '[]');
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }

  static void toggleBookmark(String bookKey, int pageNum, StorageService storage) {
    final bookmarks = getBookmarks(bookKey, storage);
    if (bookmarks.contains(pageNum)) {
      bookmarks.remove(pageNum);
    } else {
      bookmarks.add(pageNum);
    }
    bookmarks.sort();
    storage.setString('book_bookmarks_$bookKey', jsonEncode(bookmarks));
  }
}
