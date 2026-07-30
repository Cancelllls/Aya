import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/database_service.dart';
import 'hadith_explanation_screen.dart';

class HadithBook {
  final String id;
  final String nameEn;
  final String nameAr;
  final int totalHadiths;
  final bool arabicOnly;

  const HadithBook({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.totalHadiths,
    this.arabicOnly = false,
  });
}

const List<HadithBook> hadithBooks = [
  HadithBook(
    id: 'bukhari',
    nameEn: 'Sahih al-Bukhari',
    nameAr: 'صحيح البخاري',
    totalHadiths: 7563,
  ),
  HadithBook(
    id: 'muslim',
    nameEn: 'Sahih Muslim',
    nameAr: 'صحيح مسلم',
    totalHadiths: 3033,
  ),
  HadithBook(
    id: 'abudawud',
    nameEn: 'Sunan Abu Dawud',
    nameAr: 'سنن أبي داود',
    totalHadiths: 5274,
  ),
  HadithBook(
    id: 'tirmidhi',
    nameEn: 'Jami` at-Tirmidhi',
    nameAr: 'جامع الترمذي',
    totalHadiths: 3956,
  ),
  HadithBook(
    id: 'nasai',
    nameEn: 'Sunan an-Nasa\'i',
    nameAr: 'سنن النسائي',
    totalHadiths: 5758,
  ),
  HadithBook(
    id: 'ibnmajah',
    nameEn: 'Sunan Ibn Majah',
    nameAr: 'سنن ابن ماجه',
    totalHadiths: 4341,
  ),
  HadithBook(
    id: 'malik',
    nameEn: 'Muwatta Malik',
    nameAr: 'موطأ مالك',
    totalHadiths: 1985,
  ),
  HadithBook(
    id: 'riyadussalihin',
    nameEn: 'Riyad as-Salihin',
    nameAr: 'رياض الصالحين',
    totalHadiths: 1896,
  ),

  HadithBook(
    id: 'adabalmufrad',
    nameEn: 'Al-Adab Al-Mufrad',
    nameAr: 'الأدب المفرد',
    totalHadiths: 1326,
  ),
  HadithBook(
    id: 'bulughalmaram',
    nameEn: 'Bulugh al-Maram',
    nameAr: 'بلوغ المرام',
    totalHadiths: 1767,
  ),
  HadithBook(
    id: 'mishkat',
    nameEn: 'Mishkat al-Masabih',
    nameAr: 'مشكاة المصابيح',
    totalHadiths: 4428,
  ),
  HadithBook(
    id: 'shamail',
    nameEn: 'Shama\'il Muhammadiyah',
    nameAr: 'الشمائل المحمدية',
    totalHadiths: 402,
  ),
  HadithBook(
    id: 'ahmed',
    nameEn: 'Musnad Ahmad (Arabic)',
    nameAr: 'مسند الإمام أحمد',
    totalHadiths: 26363,
    arabicOnly: true,
  ),
];

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
  bool _isOffline = false;
  String _error = '';
  String? _activeSearchQuery;
  int _currentPage = 1;
  static const int _pageSize = 20;
  late String _displayLang;
  static Map<String, List<String?>>? _gradesLookup;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

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
    });

    final bookId = _selectedBook.id;
    final db = await DatabaseService.getInstance();

    // Check if downloaded
    bool isDownloaded = await db.isHadithBookDownloaded(bookId, _displayLang);

    if (!isDownloaded) {
      try {
        final jsonString = await DefaultAssetBundle.of(
          context,
        ).loadString('assets/hadith/$_displayLang-$bookId.json');
        final data = jsonDecode(jsonString);
        List<dynamic> hadiths = data['hadiths'] ?? [];
        if (hadiths.isEmpty && data['hadith'] != null) {
          hadiths = data['hadith'] as List<dynamic>;
        }
        await db.insertHadithBook(bookId, _displayLang, hadiths);
        isDownloaded = true;
      } catch (e) {
        print("Failed to seed bundled hadith: $e");
      }
    }

    if (isDownloaded) {
      final results = await db.getHadiths(
        bookId,
        _displayLang,
        7500,
        0,
      ); // Load all for now to keep pagination logic intact
      await _loadGrades();
      if (mounted) {
        final list = results
            .map(
              (e) => {
                'number': e['hadith_number'],
                'arabic': e['arabic'],
                'english': e['english'],
                'searchArText': e['search_arabic'],
                'searchEnText': e['search_english'],
                'grades': jsonDecode(e['grades'] ?? '[]'),
              },
            )
            .toList();
        _injectGrades(list, bookId);
        setState(() {
          _hadithList = list;
          _isOffline = true;
          _isLoading = false;
        });
      }
      return;
    }

    // Online Fetch API
    try {
      final url =
          'https://cdn.jsdelivr.net/gh/Cancelllls/Islamic-Assets@main/hadith/$_displayLang-$bookId.json';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawHadiths = decoded['hadiths'] ?? [];
        final List<dynamic> list = rawHadiths
            .map((h) {
              return {
                'number': h['hadithnumber'] ?? 0,
                'arabic': _displayLang == 'ara' ? (h['text'] ?? '') : '',
                'searchArText': _displayLang == 'ara'
                    ? _normalizeArabic(
                        (h['text'] ?? '').toString(),
                      ).toLowerCase()
                    : '',
                'searchEnText': _displayLang == 'eng'
                    ? (h['text'] ?? '').toString().toLowerCase()
                    : '',
                'english': _displayLang == 'eng' ? (h['text'] ?? '') : '',
                'grades': h['grades'] ?? [],
              };
            })
            .where(
              (h) =>
                  (h['arabic'] as String).trim().isNotEmpty ||
                  (h['english'] as String).trim().isNotEmpty,
            )
            .toList();

        await _loadGrades();
        _injectGrades(list, bookId);

        if (mounted) {
          setState(() {
            _hadithList = list;
            _isOffline = false;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load online data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TranslationService.isArabic
              ? "فشل في تحميل الأحاديث الشريفة. الرجاء التحقق من الاتصال بالإنترنت."
              : "Failed to load Hadiths. Please check your internet connection.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadEntireBook() async {
    setState(() => _isLoading = true);
    final bookId = _selectedBook.id;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url =
          'https://cdn.jsdelivr.net/gh/Cancelllls/Islamic-Assets@main/hadith/$_displayLang-$bookId.json';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final hadiths = decoded['hadiths'] as List<dynamic>;
        final db = await DatabaseService.getInstance();
        await db.insertHadithBook(bookId, _displayLang, hadiths);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? "تم تحميل الكتاب كاملاً بنجاح!"
                  : "Book downloaded successfully!",
            ),
            backgroundColor: const Color(0xFFE5C158),
          ),
        );
        await _loadSelectedBookData();
      } else {
        throw Exception('Failed to download');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? "فشل تحميل الكتاب. حاول مجدداً."
                : "Download failed. Try again.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove Tashkeel
        .replaceAll(RegExp(r'[إأآا]'), 'ا') // Normalize Alef
        .replaceAll('ة', 'ه') // Normalize Teh Marbuta
        .replaceAll('ى', 'ي'); // Normalize Alef Maksura
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
    // Bukhari and Muslim: entire collection is Sahih
    if (bookId == 'bukhari' || bookId == 'muslim') {
      for (var h in hadiths) {
        final existing = List<dynamic>.from(h['grades'] ?? []);
        if (existing.isEmpty) {
          h['grades'] = [
            {'grade': TranslationService.isArabic ? 'صحيح' : 'Sahih'},
          ];
        }
      }
      return;
    }

    final bookGrades = _gradesLookup?[bookId];
    if (bookGrades == null) return;

    for (var h in hadiths) {
      final num = h['number'] as int;
      if (num > 0 && num <= bookGrades.length) {
        final grade = bookGrades[num - 1];
        if (grade != null && grade.isNotEmpty) {
          final existing = List<dynamic>.from(h['grades'] ?? []);
          final alreadyExists = existing.any((g) {
            final gStr = g is Map ? g['grade']?.toString() : g.toString();
            return gStr == grade;
          });
          if (!alreadyExists) {
            existing.add({'grade': grade});
            h['grades'] = existing;
          }
        }
      }
    }
  }

  bool _isSahihBook(dynamic h) {
    final bookId = h['_bookId'] as String? ?? _selectedBook.id;
    return bookId == 'bukhari' || bookId == 'muslim';
  }

  List<dynamic> _getFilteredHadiths() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _crossSearchResults = null;
      _activeSearchQuery = null;
      return _hadithList;
    }
    // Use the cross-book search results when available
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
          _activeSearchQuery = null;
          _currentPage = 1;
        });
      }
      return;
    }

    final db = await DatabaseService.getInstance();
    final results = await db.searchAllHadiths(_displayLang, query, 100);

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

  void _jumpToHadithByNumber(int num) {
    final idx = _hadithList.indexWhere((element) => element['number'] == num);
    if (idx != -1) {
      setState(() {
        _currentPage = (idx / _pageSize).floor() + 1;
        _jumpController.clear();
        _highlightedHadithNumber = num;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _highlightedHadithNumber = null;
          });
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? "الرقم غير موجود في هذا الكتاب"
                : "Number not found in this book",
          ),
        ),
      );
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
        _activeSearchQuery = null;
        _searchController.clear();
        _hadithList = [];
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
                  final text = h['arabic'].toString();
                  final queryWords = _buildHadithQuery(text);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithExplanationScreen(
                        query: queryWords,
                        displayLang: _displayLang,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFFE5C158)),
                title: Text(
                  TranslationService.isArabic
                      ? "قراءة الشرح (إنترنت)"
                      : "Read Explanation (Online)",
                ),
                subtitle: Text(
                  TranslationService.isArabic
                      ? "البحث عن شروحات الحديث في الموسوعة الحديثية"
                      : "Search for scholarly explanations on Dorar.net",
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final text = h['arabic'].toString();
                  final queryWords = _buildHadithQuery(text);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithExplanationScreen(
                        query: queryWords,
                        displayLang: _displayLang,
                        isSharh: true,
                      ),
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

    final totalPages = (filtered.length / _pageSize).ceil();
    final pageHadiths = filtered
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Book Selector Widget
            Container(
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
                    color: Theme.of(context).shadowColor.withOpacity(0.15),
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
                                  .withOpacity(0.15),
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
                            value: _selectedBook,
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
                          });
                          _loadSelectedBookData();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: theme.primaryColor.withOpacity(0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'En | ع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFE5C158),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!_isOffline)
                        IconButton(
                          icon: const Icon(
                            Icons.download_for_offline,
                            color: Color(0xFFE5C158),
                          ),
                          tooltip: TranslationService.isArabic
                              ? "تحميل لـ $_displayLang"
                              : "Download $_displayLang",
                          onPressed: _downloadEntireBook,
                        )
                      else
                        Tooltip(
                          message: TranslationService.isArabic
                              ? 'متاح للقراءة بدون إنترنت'
                              : 'Available offline',
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Jump bar
            Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: TranslationService.isArabic
                            ? "بحث في كل كتب الحديث..."
                            : "Search across all books...",
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      onChanged: (q) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 400),
                          () {
                            if (mounted) {
                              if (q.trim().isEmpty) {
                                setState(() {
                                  _crossSearchResults = null;
                                  _activeSearchQuery = null;
                                  _currentPage = 1;
                                });
                              } else {
                                _performCrossBookSearch(q.trim());
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _jumpController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: TranslationService.isArabic
                            ? "الذهاب لـ..."
                            : "Go to...",
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          onPressed: _jumpToHadith,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                      padding: const EdgeInsets.all(12),
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
                                ? const Color(0xFFE5C158).withOpacity(0.15)
                                : theme.cardColor.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHighlighted
                                  ? const Color(0xFFE5C158)
                                  : (Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            Colors.white)
                                        .withOpacity(0.1),
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
                                                    color: Colors.white.withOpacity(
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
                                                      ).withOpacity(0.15),
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
                                            if ((h['grades'] != null &&
                                                    (h['grades'] as List)
                                                        .isNotEmpty) ||
                                                _isSahihBook(h) ||
                                                _selectedBook.id == 'bukhari' ||
                                                _selectedBook.id == 'muslim')
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
                                                    if (grades.isEmpty &&
                                                        (effectiveBookId ==
                                                                'bukhari' ||
                                                            effectiveBookId ==
                                                                'muslim')) {
                                                      grades.add({
                                                        'grade':
                                                            TranslationService
                                                                .isArabic
                                                            ? 'صحيح'
                                                            : 'Sahih',
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
                                                      final isDaif =
                                                          gradeStr
                                                              .toLowerCase()
                                                              .contains(
                                                                'daif',
                                                              ) ||
                                                          gradeStr.contains(
                                                            'ضعيف',
                                                          );
                                                      final color = isSahih
                                                          ? Colors.green
                                                          : (isDaif
                                                                ? Colors
                                                                      .redAccent
                                                                : const Color(
                                                                    0xFFE5C158,
                                                                  ));

                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: color
                                                              .withOpacity(0.1),
                                                          border: Border.all(
                                                            color: color
                                                                .withOpacity(
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
                                          Text(
                                            h['arabic'],
                                            style: GoogleFonts.amiri(
                                              fontSize: 18,
                                              height: 1.8,
                                              fontWeight: FontWeight.w500,
                                              color: theme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                            textAlign: TextAlign.start,
                                            textDirection: TextDirection.rtl,
                                          ),
                                        if (h['english']
                                                .toString()
                                                .isNotEmpty &&
                                            _displayLang == 'eng')
                                          Text(
                                            h['english'],
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

            // Pagination Controls
            if (totalPages > 1 && !_isLoading && _error.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                  color: theme.scaffoldBackgroundColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              _scrollController.jumpTo(0.0);
                            }
                          : null,
                    ),
                    Text(
                      "${TranslationService.isArabic ? 'صفحة' : 'Page'} $_currentPage / $totalPages",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      onPressed: _currentPage < totalPages
                          ? () {
                              setState(() => _currentPage++);
                              _scrollController.jumpTo(0.0);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
