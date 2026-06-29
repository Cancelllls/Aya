import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../services/translation_service.dart';
import 'hadith_explanation_screen.dart';

class HadithBook {
  final String id;
  final String nameEn;
  final String nameAr;
  final int totalHadiths;

  const HadithBook({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.totalHadiths,
  });
}

const List<HadithBook> hadithBooks = [
  HadithBook(id: 'bukhari', nameEn: 'Sahih al-Bukhari', nameAr: 'صحيح البخاري', totalHadiths: 7563),
  HadithBook(id: 'muslim', nameEn: 'Sahih Muslim', nameAr: 'صحيح مسلم', totalHadiths: 3033),
  HadithBook(id: 'abudawud', nameEn: 'Sunan Abu Dawud', nameAr: 'سنن أبي داود', totalHadiths: 5274),
  HadithBook(id: 'tirmidhi', nameEn: 'Jami` at-Tirmidhi', nameAr: 'جامع الترمذي', totalHadiths: 3956),
  HadithBook(id: 'nasai', nameEn: 'Sunan an-Nasa\'i', nameAr: 'سنن النسائي', totalHadiths: 5758),
  HadithBook(id: 'ibnmajah', nameEn: 'Sunan Ibn Majah', nameAr: 'سنن ابن ماجه', totalHadiths: 4341),
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
  bool _isLoading = false;
  int? _highlightedHadithNumber;
  bool _isOffline = false;
  String _error = '';
  int _currentPage = 1;
  static const int _pageSize = 20;
  late String _displayLang;

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
      final found = hadithBooks.where((b) => b.id == widget.initialBookId).toList();
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
    setState(() {
      _isLoading = true;
      _error = '';
      _hadithList = [];
    });

    final bookId = _selectedBook.id;
    final downloaded = await isBookDownloaded(bookId, _displayLang);

    if (downloaded) {
      try {
        final path = await _getLocalPath(bookId, _displayLang);
        final data = jsonDecode(await File(path).readAsString());
        final List<dynamic> hadiths = data['hadiths'] ?? [];

        final List<dynamic> list = [];
        for (int i = 0; i < hadiths.length; i++) {
          final h = hadiths[i];
          final text = h['text'] ?? '';
          if (text.toString().trim().isEmpty) continue;
          list.add({
            'number': h['hadithnumber'] ?? (i + 1),
            'arabic': _displayLang == 'ara' ? text : '',
            'searchArText': _displayLang == 'ara' ? _normalizeArabic(text.toString()).toLowerCase() : '',
            'searchEnText': _displayLang == 'eng' ? text.toString().toLowerCase() : '',
            'english': _displayLang == 'eng' ? text : '',
            'grades': h['grades'] ?? [],
          });
        }

        if (mounted) {
          setState(() {
            _hadithList = list;
            _isOffline = true;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        // Fallback to online if reading files fails
      }
    }

    // Online Fetch API
    try {
      final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$_displayLang-$bookId.min.json';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawHadiths = decoded['hadiths'] ?? [];
        final List<dynamic> list = rawHadiths.map((h) {
          return {
            'number': h['hadithnumber'] ?? 0,
            'arabic': _displayLang == 'ara' ? (h['text'] ?? '') : '',
            'searchArText': _displayLang == 'ara' ? _normalizeArabic((h['text'] ?? '').toString()).toLowerCase() : '',
            'searchEnText': _displayLang == 'eng' ? (h['text'] ?? '').toString().toLowerCase() : '',
            'english': _displayLang == 'eng' ? (h['text'] ?? '') : '',
            'grades': h['grades'] ?? [],
          };
        }).where((h) => (h['arabic'] as String).trim().isNotEmpty || (h['english'] as String).trim().isNotEmpty).toList();

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
    setState(() {
      _isLoading = true;
    });

    final bookId = _selectedBook.id;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$_displayLang-$bookId.min.json';

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final path = await _getLocalPath(bookId, _displayLang);

        await File(path).parent.create(recursive: true);
        await File(path).writeAsString(res.body);

        messenger.showSnackBar(
          SnackBar(
            content: Text(TranslationService.isArabic ? "تم تحميل الكتاب كاملاً بنجاح!" : "Book downloaded successfully!"),
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
          content: Text(TranslationService.isArabic ? "فشل تحميل الكتاب. حاول مجدداً." : "Download failed. Try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove Tashkeel
        .replaceAll(RegExp(r'[إأآا]'), 'ا')             // Normalize Alef
        .replaceAll('ة', 'ه')                           // Normalize Teh Marbuta
        .replaceAll('ى', 'ي');                          // Normalize Alef Maksura
  }

  List<dynamic> _getFilteredHadiths() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _hadithList;

    final normQuery = _normalizeArabic(query);

    return _hadithList.where((h) {
      final numStr = h['number'].toString();
      final arText = h['searchArText'];
      final enText = h['searchEnText'];
      return numStr == query || arText.contains(normQuery) || enText.contains(query);
    }).toList();
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
          content: Text(TranslationService.isArabic ? "الرقم غير موجود في هذا الكتاب" : "Number not found in this book"),
        ),
      );
    }
  }

  String _buildHadithQuery(String text) {
    // 1. Try to extract text inside quotes (usually the core hadith matn)
    final quoteMatch = RegExp(r'["«](.*?)["»]').firstMatch(text);
    if (quoteMatch != null && quoteMatch.group(1)!.trim().length > 10) {
      final words = quoteMatch.group(1)!.trim().split(RegExp(r'\s+'));
      return words.take(10).join(' ');
    }

    // 2. Look for the Prophet's blessing and take what comes after it
    final pbuhIndex = text.indexOf('صلى الله عليه وسلم');
    if (pbuhIndex != -1) {
      final afterPbuh = text.substring(pbuhIndex + 18).replaceAll(RegExp(r'قال|يقول|:|["«»]'), '').trim();
      final words = afterPbuh.split(RegExp(r'\s+'));
      if (words.length > 3) return words.take(10).join(' ');
    }

    // 3. Look for "رضي الله عنه" and take what comes after
    final raIndex = text.indexOf('رضي الله عنه');
    if (raIndex != -1) {
      final afterRa = text.substring(raIndex + 12).replaceAll(RegExp(r'قال|يقول|:|["«»]'), '').trim();
      final words = afterRa.split(RegExp(r'\s+'));
      if (words.length > 3) return words.take(10).join(' ');
    }

    // 4. Fallback: skip the first chunk of words assuming it's a long narrator chain
    final words = text.split(RegExp(r'\s+'));
    if (words.length > 20) {
      return words.skip(10).take(10).join(' ');
    }
    
    return words.take(10).join(' ');
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
                TranslationService.isArabic ? "خيارات الحديث" : "Hadith Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.fact_check, color: Color(0xFFE5C158)),
                title: Text(TranslationService.isArabic ? "تخريج الحديث (إنترنت)" : "Hadith Grading (Online)"),
                subtitle: Text(TranslationService.isArabic ? "البحث عن تخريج الحديث وحكمه في موقع الدرر السنية" : "Search for authenticity grading on Dorar.net"),
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
                title: Text(TranslationService.isArabic ? "قراءة الشرح (إنترنت)" : "Read Explanation (Online)"),
                subtitle: Text(TranslationService.isArabic ? "البحث عن شروحات الحديث في الموسوعة الحديثية" : "Search for scholarly explanations on Dorar.net"),
                onTap: () async {
                  Navigator.pop(context);
                  final text = h['arabic'].toString();
                  final queryWords = _buildHadithQuery(text);
                  final encoded = Uri.encodeComponent(queryWords);
                  final url = Uri.parse('https://dorar.net/hadith/search?q=$encoded&st=p2');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              StatefulBuilder(
                builder: (context, setModalState) {
                  final List<String> current = widget.storage.getStringList('hadith_bookmarks') ?? [];
                  final data = jsonEncode({
                    'bookId': _selectedBook.id,
                    'book': _selectedBook.nameEn,
                    'bookAr': _selectedBook.nameAr,
                    'number': h['number'],
                    'text': _displayLang == 'ara' ? h['arabic'] : h['english']
                  });
                  final isSaved = current.contains(data);

                  return ListTile(
                    leading: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFE5C158)),
                    title: Text(isSaved 
                        ? (TranslationService.isArabic ? "إزالة العلامة المرجعية" : "Remove Bookmark")
                        : (TranslationService.isArabic ? "حفظ كعلامة مرجعية" : "Add to Bookmarks")),
                    subtitle: Text(TranslationService.isArabic ? "المفضلة للأحاديث" : "Hadith favorites"),
                    onTap: () async {
                      if (isSaved) {
                        current.remove(data);
                      } else {
                        current.add(data);
                      }
                      await widget.storage.setStringList('hadith_bookmarks', current);
                      setModalState(() {});
                      final messenger = ScaffoldMessenger.of(this.context);
                      messenger.showSnackBar(SnackBar(
                        content: Text(isSaved 
                            ? (TranslationService.isArabic ? "تم الإزالة بنجاح" : "Removed successfully") 
                            : (TranslationService.isArabic ? "تم الحفظ بنجاح" : "Saved successfully!")),
                        duration: const Duration(seconds: 1),
                      ));
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
    final pageHadiths = filtered.skip((_currentPage - 1) * _pageSize).take(_pageSize).toList();

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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.import_contacts, color: const Color(0xFFE5C158), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<HadithBook>(
                            dropdownColor: theme.cardColor,
                            value: _selectedBook,
                            isExpanded: true,
                            selectedItemBuilder: (BuildContext context) {
                              return hadithBooks.map((b) {
                                return Container(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    TranslationService.isArabic ? b.nameAr : b.nameEn,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5C158), fontSize: 15),
                                  ),
                                );
                              }).toList();
                            },
                            icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFFE5C158)),
                            items: hadithBooks.map((b) {
                              return DropdownMenuItem<HadithBook>(
                                value: b,
                                child: Text(
                                  TranslationService.isArabic ? b.nameAr : b.nameEn,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'En | ع',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE5C158)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!_isOffline)
                        IconButton(
                          icon: const Icon(Icons.download_for_offline, color: Color(0xFFE5C158)),
                          tooltip: TranslationService.isArabic ? "تحميل لـ $_displayLang" : "Download $_displayLang",
                          onPressed: _downloadEntireBook,
                        )
                      else
                        Tooltip(
                          message: TranslationService.isArabic ? 'متاح للقراءة بدون إنترنت' : 'Available offline',
                          child: const Icon(Icons.check_circle, color: Colors.green),
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
                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: TranslationService.isArabic ? "بحث في هذا الكتاب..." : "Search in this book...",
                        prefixIcon: Icon(Icons.search, size: 18, color: theme.textTheme.bodyMedium?.color),
                      ),
                      onChanged: (q) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _currentPage = 1;
                            });
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _jumpController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: TranslationService.isArabic ? "الذهاب لـ..." : "Go to...",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_forward, size: 18, color: theme.primaryColor),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
                  : _error.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadSelectedBookData,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
                                  child: Text(TranslationService.isArabic ? "إعادة المحاولة" : "Retry"),
                                )
                              ],
                            ),
                          ),
                        )
                      : pageHadiths.isEmpty
                          ? Center(child: Text(TranslationService.isArabic ? "لا توجد نتائج" : "No results found"))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: pageHadiths.length,
                                  itemBuilder: (context, index) {
                                    final h = pageHadiths[index];
                                    final isHighlighted = _highlightedHadithNumber == h['number'];
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: isHighlighted ? const Color(0xFFE5C158).withOpacity(0.15) : theme.cardColor.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isHighlighted ? const Color(0xFFE5C158) : Colors.white.withOpacity(0.1),
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
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showHadithOptions(h),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
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
                                            const SizedBox(width: 8),
                                            if ((h['grades'] != null && (h['grades'] as List).isNotEmpty) || _selectedBook.id == 'bukhari' || _selectedBook.id == 'muslim')
                                              Expanded(
                                                child: Wrap(
                                                  alignment: WrapAlignment.end,
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: () {
                                                    final grades = List<dynamic>.from(h['grades'] ?? []);
                                                    if (grades.isEmpty && (_selectedBook.id == 'bukhari' || _selectedBook.id == 'muslim')) {
                                                      grades.add({'grade': TranslationService.isArabic ? 'صحيح' : 'Sahih'});
                                                    }
                                                    return grades.map<Widget>((g) {
                                                      final gradeStr = g['grade']?.toString() ?? '';
                                                      final isSahih = gradeStr.toLowerCase().contains('sahih') || gradeStr.contains('صحيح');
                                                      final isDaif = gradeStr.toLowerCase().contains('daif') || gradeStr.contains('ضعيف');
                                                      final color = isSahih ? Colors.green : (isDaif ? Colors.redAccent : const Color(0xFFE5C158));
                                                      
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: color.withOpacity(0.1),
                                                          border: Border.all(color: color.withOpacity(0.5)),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          gradeStr,
                                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      );
                                                    }).toList();
                                                  }(),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (h['arabic'].toString().isNotEmpty && _displayLang == 'ara')
                                          Text(
                                            h['arabic'],
                                            style: GoogleFonts.amiri(
                                              fontSize: 18,
                                              height: 1.8,
                                              fontWeight: FontWeight.w500,
                                              color: theme.textTheme.bodyLarge?.color,
                                            ),
                                            textAlign: TextAlign.start,
                                            textDirection: TextDirection.rtl,
                                          ),
                                          if (h['english'].toString().isNotEmpty && _displayLang == 'eng')
                                            Text(
                                              h['english'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                                color: theme.textTheme.bodyMedium?.color,
                                              ),
                                              textAlign: TextAlign.start,
                                              textDirection: TextDirection.ltr,
                                            ),

                                        ],
                                      ),
                                    ),
                                  ),
                                  ))));
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
                      icon: Icon(Icons.arrow_back_ios, size: 16, color: theme.primaryColor),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              _scrollController.jumpTo(0.0);
                            }
                          : null,
                    ),
                    Text(
                      "${TranslationService.isArabic ? 'صفحة' : 'Page'} $_currentPage / $totalPages",
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 16, color: theme.primaryColor),
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
