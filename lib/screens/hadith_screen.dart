import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/database_service.dart';
import '../services/hadith_database_service.dart';
import '../utils/text_helpers.dart';
import 'hadith_explanation_screen.dart';
import '../widgets/share_card_dialog.dart';

import '../models/hadith_models.dart';

part 'hadith_screen_ui.dart';

class HadithScreen extends StatefulWidget {
  final StorageService storage;
  final String? initialBookId;
  final int? initialHadithNumber;

  const HadithScreen({
    super.key,
    required this.storage,
    this.initialBookId,
    this.initialHadithNumber,
  });

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  HadithBook _selectedBook = hadithBooks[0];
  List<dynamic> _hadithList = [];
  List<dynamic>? _crossSearchResults;
  bool _isLoading = false;
  int? _highlightedHadithNumber;
  String _error = '';
  String _activeSearchQuery = '';
  int _currentPage = 1;
  int _totalHadiths = 0;
  static const int _pageSize = 20;
  late String _displayLang;
  static Map<String, List<String?>>? _gradesLookup;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
    });
  }

  void _autoClearHighlight() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _highlightedHadithNumber = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _displayLang = TranslationService.isArabic ? 'ara' : 'eng';
    // If opened from a bookmark, switch to that book
    if (widget.initialBookId != null) {
      final found = hadithBooks
          .where((b) => b.id == widget.initialBookId)
          .toList();
      if (found.isNotEmpty) _selectedBook = found.first;
    }
    _loadSelectedBookData().then((_) {
      // After loading, jump to the specific hadith number if provided
      if (widget.initialHadithNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToHadithByNumber(widget.initialHadithNumber!);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _jumpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getLocalPath(String bookId, String lang) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/hadiths/${lang}_$bookId.json';
  }

  Future<bool> isBookDownloaded(String bookId, String lang) async {
    final path = await _getLocalPath(bookId, lang);
    return await File(path).exists();
  }

  Future<void> _loadSelectedBookData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
      _hadithList = [];
      _currentPage = 1;
      _activeSearchQuery = '';
      _searchController.clear();
      _crossSearchResults = null;
    });

    final bookId = _selectedBook.id;
    final db = await DatabaseService.getInstance();

    // Seed from bundled asset if not yet downloaded
    bool isDownloaded = await db.hadith.isHadithBookDownloaded(bookId, _displayLang);
    if (!isDownloaded) {
      try {
        final jsonString = await DefaultAssetBundle.of(context)
            .loadString('assets/hadith/$_displayLang-$bookId.json');
        // Parse JSON in background isolate — keeps spinner smooth
        final hadiths = await HadithDatabaseService.parseHadithJson(jsonString);
        await db.hadith.insertHadithBook(bookId, _displayLang, hadiths);
        isDownloaded = true;
      } catch (e) {
        print("Failed to seed bundled hadith: $e");
      }
    }

    if (isDownloaded) {
      // Get total count for pagination UI
      _totalHadiths = await db.hadith.getHadithCount(bookId, _displayLang);
      await _loadCurrentPageHadiths();
      return;
    }

    // Online fallback
    try {
      final url = 'https://cdn.jsdelivr.net/gh/Cancelllls/Islamic-Assets@main/hadith/$_displayLang-$bookId.json';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final rawHadiths = await HadithDatabaseService.parseHadithJson(
          response.body,
        );
        await db.hadith.insertHadithBook(bookId, _displayLang, rawHadiths);
        _totalHadiths = await db.hadith.getHadithCount(bookId, _displayLang);
        await _loadCurrentPageHadiths();
      } else {
        throw Exception('Failed to load online data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TranslationService.isArabic
              ? "فشل في تحميل الأحاديث الشريفة."
              : "Failed to load Hadiths.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCurrentPageHadiths() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final bookId = _selectedBook.id;
      final db = await DatabaseService.getInstance();
      final offset = (_currentPage - 1) * _pageSize;
      final results = await db.hadith.getHadiths(bookId, _displayLang, _pageSize, offset);
      await _loadGrades();

      if (mounted) {
        final list = results.map((e) => {
          'number': e['hadith_number'],
          'arabic': e['arabic'],
          'english': e['english'],
          'searchArText': e['search_arabic'],
          'searchEnText': e['search_english'],
          'grades': jsonDecode(e['grades'] ?? '[]'),
        }).toList();
        _injectGrades(list, bookId);
        setState(() {
          _hadithList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TranslationService.isArabic
              ? "فشل في تحميل الأحاديث الشريفة."
              : "Failed to load Hadiths.";
          _isLoading = false;
        });
      }
    }
  }

  int get _totalPages {
    if (_totalHadiths > 0) return (_totalHadiths / _pageSize).ceil();
    return (_hadithList.length / _pageSize).ceil().clamp(1, 99999);
  }

  String _cleanEnglish(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n\s{2,}'), '\n')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }

  Future<void> _loadGrades() async {
    if (_gradesLookup != null) return;
    try {
      final jsonStr = await DefaultAssetBundle.of(context)
          .loadString('assets/hadith/grades.json');
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      _gradesLookup = decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>)
              .map((e) => (e as String?)?.trim() ?? '')
              .map((s) => s.isEmpty ? null : s)
              .toList(),
        ),
      );
    } catch (_) {
      _gradesLookup = {}; // prevent retry on missing/corrupt file
    }
  }

  void _injectGrades(List<dynamic> hadiths, String bookId) {
    final isAr = TranslationService.isArabic;
    final isSahihCollection = bookId == 'bukhari' ||
        bookId == 'muslim' ||
        bookId == 'riyadussalihin' ||
        bookId == 'malik';

    if (isSahihCollection) {
      for (var h in hadiths) {
        final existing = List<dynamic>.from(h['grades'] ?? []);
        if (existing.isEmpty) {
          h['grades'] = [
            {'grade': isAr ? 'صحيح' : 'Sahih'},
          ];
        }
      }
      return;
    }

    final bookGrades = _gradesLookup?[bookId];

    for (var h in hadiths) {
      final numRaw = h['number'] ?? h['hadith_number'] ?? h['hadithnumber'];
      final num = numRaw is int
          ? numRaw
          : (int.tryParse(numRaw?.toString() ?? '') ?? 0);
      final existing = List<dynamic>.from(h['grades'] ?? []);

      if (bookGrades != null && num > 0 && num <= bookGrades.length) {
        final grade = bookGrades[num - 1];
        if (grade != null && grade.trim().isNotEmpty) {
          final alreadyExists = existing.any((g) {
            final gStr = g is Map ? g['grade']?.toString() : g.toString();
            return gStr == grade.trim();
          });
          if (!alreadyExists) {
            existing.add({'grade': grade.trim()});
          }
        }
      }

      // If still empty (e.g. null in grades.json or missing collection entry), inject a clean fallback badge
      if (existing.isEmpty) {
        existing.add({
          'grade': isAr ? 'مقبول' : 'Acceptable',
        });
      }

      h['grades'] = existing;
    }
  }

  List<dynamic> _getFilteredHadiths() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _crossSearchResults = null;
      _activeSearchQuery = '';
      return _hadithList;
    }
    // Use cross-book search results when available
    if (_crossSearchResults != null && _activeSearchQuery == query) {
      return _crossSearchResults!;
    }
    return _hadithList;
  }

  Future<void> _performCrossBookSearch(String query) async {
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _crossSearchResults = null;
          _activeSearchQuery = '';
          _currentPage = 1;
        });
      }
      return;
    }

    final db = await DatabaseService.getInstance();
    final results = await db.hadith.searchAllHadiths(_displayLang, query, 500);

    // Map book_id back to book display names and inject grades
    final mapped = <Map<String, dynamic>>[];
    for (var r in results) {
      final dbBookId = r['book_id'] as String;
      // dbBookId is "ara_bukhari" or "eng_bukhari"
      final parts = dbBookId.split('_');
      final langPrefix = parts[0];
      final bookId = parts.length > 1 ? parts.sublist(1).join('_') : dbBookId;

      final book = hadithBooks.where((b) => b.id == bookId).firstOrNull;
      if (book == null) continue;

      mapped.add({
        'number': r['hadith_number'],
        'arabic': r['arabic'],
        'english': r['english'],
        'searchArText': r['search_arabic'],
        'searchEnText': r['search_english'],
        'snippetArabic': r['snippet_arabic'],
        'snippetEnglish': r['snippet_english'],
        'grades': jsonDecode((r['grades'] as String?) ?? '[]'),
        '_bookId': bookId,
        '_bookName': langPrefix == 'ara' ? book.nameAr : book.nameEn,
      });
    }

    // Inject grades
    for (var bookId in mapped.map((m) => m['_bookId'] as String).toSet()) {
      final bookHadiths = mapped.where((m) => m['_bookId'] == bookId).toList();
      _injectGrades(bookHadiths, bookId);
    }

    if (mounted) {
      setState(() {
        _crossSearchResults = mapped;
        _activeSearchQuery = query;
        _currentPage = 1;
      });
    }
  }

  void _jumpToHadith() {
    final num = int.tryParse(_jumpController.text.trim());
    if (num == null) return;
    _jumpToHadithByNumber(num);
  }

  void _jumpToHadithByNumber(int num) async {
    final db = await DatabaseService.getInstance();
    final row = await db.hadith.getHadithByNumber(_selectedBook.id, _displayLang, num);
    if (row != null && mounted) {
      final targetPage = ((num - 1) ~/ _pageSize) + 1;
      setState(() {
        _currentPage = targetPage.clamp(1, _totalPages > 0 ? _totalPages : 1);
        _jumpController.clear();
        _highlightedHadithNumber = num;
      });
      await _loadCurrentPageHadiths();
      _scrollToTop();
      _autoClearHighlight();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(TranslationService.isArabic
            ? "الرقم غير موجود في هذا الكتاب"
            : "Number not found in this book"),
      ));
    }
  }

  String _buildHadithQuery(String text) {
    String query = '';

    final quoteMatch = RegExp(r'["«](.*?)["»]').firstMatch(text);
    if (quoteMatch != null && quoteMatch.group(1)!.trim().length > 10) {
      final words = quoteMatch.group(1)!.trim().split(RegExp(r'\s+'));
      query = words.take(10).join(' ');
    } else {
      final pbuhIndex = text.indexOf('صلى الله عليه وسلم');
      if (pbuhIndex != -1) {
        final afterPbuh = text
            .substring(pbuhIndex + 18)
            .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
            .trim();
        final words = afterPbuh.split(RegExp(r'\s+'));
        if (words.length > 3) query = words.take(10).join(' ');
      }

      if (query.isEmpty) {
        final raIndex = text.indexOf('رضي الله عنه');
        if (raIndex != -1) {
          final afterRa = text
              .substring(raIndex + 12)
              .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
              .trim();
          final words = afterRa.split(RegExp(r'\s+'));
          if (words.length > 3) query = words.take(10).join(' ');
        }
      }

      if (query.isEmpty) {
        final words = text.split(RegExp(r'\s+'));
        if (words.length > 20) {
          query = words.skip(10).take(10).join(' ');
        } else {
          query = words.take(10).join(' ');
        }
      }
    }

    query = query.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
    if (query.isEmpty) {
      final rawWords = text
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
          .trim()
          .split(RegExp(r'\s+'));
      if (rawWords.isNotEmpty && rawWords.first.isNotEmpty) {
        query = rawWords.take(5).join(' ');
      } else {
        query = "حديث"; // Fallback to prevent DorarValidationException
      }
    }

    return query.isEmpty ? "حديث" : query;
  }

  List<HadithBook> get _filteredBooks {
    if (_displayLang == 'ara') return hadithBooks;
    return hadithBooks.where((b) => !b.arabicOnly).toList();
  }

  void _handleHadithTap(Map<String, dynamic> h) {
    final resultBookId = h['_bookId'] as String?;
    if (resultBookId != null && resultBookId != _selectedBook.id) {
      // Cross-search result — switch to its book first
      final book = hadithBooks.firstWhere(
        (b) => b.id == resultBookId,
        orElse: () => _selectedBook,
      );
      setState(() {
        _selectedBook = book;
        _currentPage = 1;
        _crossSearchResults = null;
        _activeSearchQuery = '';
        _searchController.clear();
        _hadithList = [];
        _isLoading = true;
      });
      _loadSelectedBookData().then((_) {
        if (mounted) {
          _jumpToHadithByNumber(h['number'] as int);
          _showHadithOptions(h);
        }
      });
      return;
    }
    _showHadithOptions(h);
  }

  void _showHadithOptions(Map<String, dynamic> h) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TranslationService.isArabic
                    ? "خيارات الحديث"
                    : "Hadith Options",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.fact_check, color: Color(0xFFE5C158)),
                title: Text(
                  TranslationService.isArabic
                      ? "تخريج الحديث وتفاصيل الإسناد"
                      : "Detailed Grading & Isnad",
                ),
                subtitle: Text(
                  TranslationService.isArabic
                      ? "البحث عن تخريج الحديث وتفاصيل الإسناد في موقع الدرر السنية"
                      : "Search for detailed grading and narrator chain on Dorar.net",
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final bookId = h['_bookId'] ?? _selectedBook.id;
                  final hadithNumber = h['number'] as int?;
                  final text = h['arabic'].toString();
                  final queryWords = _buildHadithQuery(text);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithExplanationScreen(
                        query: queryWords,
                        displayLang: _displayLang,
                        bookId: bookId,
                        hadithNumber: hadithNumber,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFFE5C158)),
                title: Text(
                  TranslationService.isArabic
                      ? "قراءة الشرح"
                      : "Read Explanation",
                ),
                subtitle: Text(
                  TranslationService.isArabic
                      ? "شرح الحديث (من الذاكرة أو الإنترنت)"
                      : "Hadith explanation (cached or online)",
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final bookId = h['_bookId'] ?? _selectedBook.id;
                  final hadithNumber = h['number'] as int?;
                  final text = h['arabic'].toString();
                  final queryWords = _buildHadithQuery(text);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithExplanationScreen(
                        query: queryWords,
                        displayLang: _displayLang,
                        isSharh: true,
                        bookId: bookId,
                        hadithNumber: hadithNumber,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFFE5C158)),
                title: Text(
                  TranslationService.isArabic ? "مشاركة" : "Share",
                ),
                subtitle: Text(
                  TranslationService.isArabic
                      ? "مشاركة الحديث كنص"
                      : "Share hadith text",
                ),
                onTap: () {
                  Navigator.pop(context);
                  final text = _displayLang == 'ara'
                      ? (h['arabic'] ?? '').toString()
                      : (h['english'] ?? '').toString();
                  final ref = TranslationService.isArabic
                      ? 'الراوي: ${_selectedBook.nameAr}'
                      : 'Source: ${_selectedBook.nameEn}';
                  SharePlus.instance.share(
                    ShareParams(text: '$text\n\n— $ref • Aya App'),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFFE5C158),
                ),
                title: Text(
                  TranslationService.isArabic
                      ? "مشاركة كصورة"
                      : "Share as Image",
                ),
                subtitle: Text(
                  TranslationService.isArabic
                      ? "تصميم صورة أنيقة للحديث"
                      : "Create styled Hadith image card",
                ),
                onTap: () {
                  Navigator.pop(context);
                  final isEng = _displayLang == 'eng' || !TranslationService.isArabic;
                  final mainText = isEng
                      ? (h['english'] ?? h['arabic'] ?? '').toString()
                      : (h['arabic'] ?? h['english'] ?? '').toString();
                  final secondaryText = isEng
                      ? (h['arabic'] != null && h['arabic'] != mainText ? h['arabic'].toString() : null)
                      : (h['english'] != null && h['english'] != mainText ? h['english'].toString() : null);
                  final bookName = isEng ? _selectedBook.nameEn : _selectedBook.nameAr;
                  final numStr = h['number'] ?? h['hadithNumber'] ?? '';
                  final footnoteText = numStr.toString().isNotEmpty
                      ? (isEng ? 'Hadith No. $numStr • $bookName' : 'حديث رقم $numStr • $bookName')
                      : bookName;

                  showDialog(
                    context: context,
                    builder: (_) => ShareCardDialog(
                      title: isEng ? 'Hadith' : 'حديث شريف',
                      categoryOrSource: bookName,
                      mainText: mainText,
                      translationText: secondaryText,
                      footnote: footnoteText,
                    ),
                  );
                },
              ),
              StatefulBuilder(
                builder: (context, setModalState) {
                  final List<String> current =
                      widget.storage.getStringList('hadith_bookmarks') ?? [];
                  final bookId = h['_bookId'] ?? _selectedBook.id;
                  final book = (bookId != _selectedBook.id)
                      ? hadithBooks.firstWhere(
                          (b) => b.id == bookId,
                          orElse: () => _selectedBook,
                        )
                      : _selectedBook;
                  final data = jsonEncode({
                    'bookId': bookId,
                    'book': book.nameEn,
                    'bookAr': book.nameAr,
                    'number': h['number'],
                    'text': _displayLang == 'ara' ? h['arabic'] : h['english'],
                  });
                  final isSaved = current.contains(data);

                  return ListTile(
                    leading: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: const Color(0xFFE5C158),
                    ),
                    title: Text(
                      isSaved
                          ? (TranslationService.isArabic
                                ? "إزالة العلامة المرجعية"
                                : "Remove Bookmark")
                          : (TranslationService.isArabic
                                ? "حفظ كعلامة مرجعية"
                                : "Add to Bookmarks"),
                    ),
                    subtitle: Text(
                      TranslationService.isArabic
                          ? "المفضلة للأحاديث"
                          : "Hadith favorites",
                    ),
                    onTap: () async {
                      if (isSaved) {
                        current.remove(data);
                      } else {
                        current.add(data);
                      }
                      await widget.storage.setStringList(
                        'hadith_bookmarks',
                        current,
                      );
                      setModalState(() {});
                      final messenger = ScaffoldMessenger.of(this.context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? (TranslationService.isArabic
                                      ? "تم الإزالة بنجاح"
                                      : "Removed successfully")
                                : (TranslationService.isArabic
                                      ? "تم الحفظ بنجاح"
                                      : "Saved successfully!"),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _getFilteredHadiths();

    // Use real total when browsing; use filtered length when searching
    final totalPages = _activeSearchQuery.isNotEmpty
        ? (filtered.length / _pageSize).ceil()
        : (_totalPages > 0 ? _totalPages : 1);
    final pageHadiths = _activeSearchQuery.isNotEmpty
        ? filtered
            .skip((_currentPage - 1) * _pageSize)
            .take(_pageSize)
            .toList()
        : _hadithList;

    final String bottomNavbarStyle = widget.storage.getString(
      'bottom_navbar_style',
      defaultValue: 'floating',
    );
    final bool isFloatingNav = bottomNavbarStyle == 'floating';
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Stack(
      children: [
        Column(
          children: [
            _buildBookSelector(theme),

            // Content view
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE5C158),
                      ),
                    )
                  : _error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSelectedBookData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5C158),
                              ),
                              child: Text(
                                TranslationService.isArabic
                                    ? "إعادة المحاولة"
                                    : "Retry",
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : pageHadiths.isEmpty
                  ? Center(
                      child: Text(
                        TranslationService.isArabic
                            ? "لا توجد نتائج"
                            : "No results found",
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        // Ensure last card scrolls completely clear of floating pill and bottom navbar
                        isKeyboardOpen
                            ? 16.0
                            : (isFloatingNav
                                ? (totalPages > 1 ? 128.0 : 85.0)
                                : (totalPages > 1 ? 64.0 : 16.0)),
                      ),
                      itemCount: pageHadiths.length,
                      itemBuilder: (context, index) {
                        final h = pageHadiths[index];
                        final isHighlighted =
                            _highlightedHadithNumber == h['number'];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFE5C158).withValues(alpha: 0.15)
                                : theme.cardColor.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHighlighted
                                  ? const Color(0xFFE5C158)
                                  : (Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            Colors.white)
                                        .withValues(alpha: 0.1),
                              width: isHighlighted ? 2.0 : 1.0,
                            ),
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: Colors.transparent,
                            elevation: isHighlighted ? 8 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _handleHadithTap(h),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 
                                                      0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    "${TranslationService.isArabic ? 'حديث' : 'Hadith'} ${h['number']}",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.primaryColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                if (_crossSearchResults != null &&
                                                    h['_bookName'] != null) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFE5C158,
                                                      ).withValues(alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      h['_bookName'],
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFFE5C158,
                                                        ),
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Wrap(
                                                alignment: WrapAlignment.end,
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: () {
                                                  final grades =
                                                      List<dynamic>.from(
                                                        h['grades'] ?? [],
                                                      );
                                                  final effectiveBookId =
                                                      h['_bookId'] ??
                                                          _selectedBook.id;
                                                  if (grades.isEmpty) {
                                                    final isSahihCol = effectiveBookId == 'bukhari' ||
                                                        effectiveBookId == 'muslim' ||
                                                        effectiveBookId == 'riyadussalihin' ||
                                                        effectiveBookId == 'malik';
                                                    grades.add({
                                                      'grade': TranslationService.isArabic
                                                          ? (isSahihCol ? 'صحيح' : 'مقبول')
                                                          : (isSahihCol ? 'Sahih' : 'Acceptable'),
                                                    });
                                                  }
                                                  return grades.map<Widget>((
                                                    g,
                                                  ) {
                                                    final gradeStr =
                                                        g['grade']
                                                            ?.toString() ??
                                                        '';
                                                    final isSahih =
                                                        gradeStr
                                                            .toLowerCase()
                                                            .contains(
                                                              'sahih',
                                                            ) ||
                                                        gradeStr.contains(
                                                          'صحيح',
                                                        );
                                                    final isHasan =
                                                        gradeStr
                                                            .toLowerCase()
                                                            .contains(
                                                              'hasan',
                                                            ) ||
                                                        gradeStr.contains(
                                                          'حسن',
                                                        ) ||
                                                        gradeStr.contains(
                                                          'مقبول',
                                                        );
                                                    final isDaif =
                                                        gradeStr
                                                            .toLowerCase()
                                                            .contains(
                                                              'daif',
                                                            ) ||
                                                        gradeStr.contains(
                                                          'ضعيف',
                                                        ) ||
                                                        gradeStr.contains(
                                                          'منكر',
                                                        ) ||
                                                        gradeStr.contains(
                                                          'موضوع',
                                                        );
                                                    final color = isSahih
                                                        ? Colors.green
                                                        : (isHasan
                                                            ? Colors.teal
                                                            : (isDaif
                                                                ? Colors.redAccent
                                                                : const Color(
                                                                    0xFFE5C158,
                                                                  )));

                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: color
                                                              .withValues(alpha: 0.1),
                                                          border: Border.all(
                                                            color: color
                                                                .withValues(alpha: 
                                                                  0.5,
                                                                ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          gradeStr,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: color,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                                    }).toList();
                                                  }(),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (h['arabic'].toString().isNotEmpty &&
                                            _displayLang == 'ara')
                                          _searchController.text.trim().isNotEmpty
                                              ? _buildHighlightedText(
                                                  text: h['arabic'].toString(),
                                                  query: _searchController.text,
                                                  style: TextStyle(
                                                    fontFamily: 'Amiri',
                                                    fontSize: 18,
                                                    height: 1.8,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.textTheme.bodyLarge?.color,
                                                  ),
                                                  highlightColor: const Color(0xFFE5C158),
                                                  textDirection: TextDirection.rtl,
                                                )
                                              : Text(
                                                  h['arabic'].toString(),
                                                  style: TextStyle(
                                                    fontFamily: 'Amiri',
                                                    fontSize: 18,
                                                    height: 1.8,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.textTheme.bodyLarge?.color,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  textDirection: TextDirection.rtl,
                                                ),
                                        if (h['english']
                                                .toString()
                                                .isNotEmpty &&
                                            _displayLang == 'eng')
                                          _searchController.text.trim().isNotEmpty
                                              ? _buildHighlightedText(
                                                  text: _cleanEnglish(h['english'].toString()),
                                                  query: _searchController.text,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.5,
                                                    color: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                  ),
                                                  highlightColor: const Color(0xFFE5C158),
                                                  textDirection: TextDirection.ltr,
                                                )
                                              : Text(
                                                  _cleanEnglish(h['english'].toString()),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.5,
                                                    color: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  textDirection: TextDirection.ltr,
                                                ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

          ],
        ),

        // Sleek, ultra-compact floating pagination capsule
        // Automatically hidden when virtual keyboard opens to prevent shooting up
        if (totalPages > 1 && !_isLoading && _error.isEmpty && !isKeyboardOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: isFloatingNav ? 76.0 : 12.0,
            child: Center(
              child: _buildCompactPaginationPill(theme, totalPages),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactPaginationPill(ThemeData theme, int totalPages) {
    final isAr = TranslationService.isArabic;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5C158).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isAr ? Icons.chevron_right : Icons.chevron_left,
                  size: 18,
                  color: _currentPage > 1
                      ? const Color(0xFFE5C158)
                      : theme.disabledColor.withValues(alpha: 0.35),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 16,
                tooltip: isAr ? 'الصفحة السابقة' : 'Previous Page',
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _scrollController.jumpTo(0.0);
                        if (_activeSearchQuery.isEmpty) {
                          _loadCurrentPageHadiths();
                        }
                      }
                    : null,
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showHadithPageJumpDialog(totalPages),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    "${isAr ? toArabicDigits(_currentPage) : _currentPage} / ${isAr ? toArabicDigits(totalPages) : totalPages}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isAr ? Icons.chevron_left : Icons.chevron_right,
                  size: 18,
                  color: _currentPage < totalPages
                      ? const Color(0xFFE5C158)
                      : theme.disabledColor.withValues(alpha: 0.35),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 16,
                tooltip: isAr ? 'الصفحة التالية' : 'Next Page',
                onPressed: _currentPage < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _scrollController.jumpTo(0.0);
                        if (_activeSearchQuery.isEmpty) {
                          _loadCurrentPageHadiths();
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHadithPageJumpDialog(int totalPages) {
    final isAr = TranslationService.isArabic;
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAr ? 'الانتقال إلى صفحة' : 'Jump to Page'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم الصفحة (1 - $totalPages)' : 'Page Number (1 - $totalPages)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
              onPressed: () {
                final target = int.tryParse(controller.text.trim());
                if (target != null && target >= 1 && target <= totalPages) {
                  Navigator.pop(context);
                  setState(() => _currentPage = target);
                  _scrollController.jumpTo(0.0);
                  if (_activeSearchQuery.isEmpty) {
                    _loadCurrentPageHadiths();
                  }
                }
              },
              child: Text(isAr ? 'انتقال' : 'Go'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHighlightedText({
    required String text,
    required String query,
    required TextStyle style,
    required Color highlightColor,
    TextDirection textDirection = TextDirection.rtl,
  }) {
    if (text.contains('<mark>')) {
      final spans = parseMarkedSpans(
        text,
        baseStyle: style,
        highlightColor: highlightColor,
      );
      return Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.start,
        textDirection: textDirection,
      );
    }

    if (query.trim().isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: TextAlign.start,
        textDirection: textDirection,
      );
    }

    final cleanQuery = stripTashkeel(query.trim().toLowerCase());
    final cleanText = stripTashkeel(text.toLowerCase());

    if (!cleanText.contains(cleanQuery)) {
      return Text(
        text,
        style: style,
        textAlign: TextAlign.start,
        textDirection: textDirection,
      );
    }

    final words = text.split(' ');
    final spans = <InlineSpan>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = stripTashkeel(word.toLowerCase());
      final isMatch = cleanWord.contains(cleanQuery);
      spans.add(TextSpan(
        text: i < words.length - 1 ? '$word ' : word,
        style: isMatch
            ? style.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.bold,
              )
            : style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.start,
      textDirection: textDirection,
    );
  }
}
