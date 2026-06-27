import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../services/translation_service.dart';

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

  const HadithScreen({
    super.key,
    required this.storage,
  });

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  HadithBook _selectedBook = hadithBooks[0];
  List<dynamic> _hadithList = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String _error = '';
  int _currentPage = 1;
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSelectedBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jumpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getLocalPath(String bookId, String lang) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/hadiths/${lang}_$bookId.json';
  }

  Future<bool> isBookDownloaded(String bookId) async {
    final pathAr = await _getLocalPath(bookId, 'ara');
    final pathEn = await _getLocalPath(bookId, 'eng');
    return await File(pathAr).exists() && await File(pathEn).exists();
  }

  Future<void> _loadSelectedBookData() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _hadithList = [];
    });

    final bookId = _selectedBook.id;
    final downloaded = await isBookDownloaded(bookId);

    if (downloaded) {
      try {
        final pathAr = await _getLocalPath(bookId, 'ara');
        final pathEn = await _getLocalPath(bookId, 'eng');
        
        final dataAr = jsonDecode(await File(pathAr).readAsString());
        final dataEn = jsonDecode(await File(pathEn).readAsString());

        final List<dynamic> merged = [];
        final List<dynamic> hadithsAr = dataAr['hadiths'] ?? [];
        final List<dynamic> hadithsEn = dataEn['hadiths'] ?? [];

        for (int i = 0; i < hadithsAr.length; i++) {
          final hAr = hadithsAr[i];
          var textEn = '';
          if (i < hadithsEn.length) {
            textEn = hadithsEn[i]['text'] ?? '';
          }
          final textAr = hAr['text'] ?? '';
          if (textAr.trim().isEmpty && textEn.trim().isEmpty) {
            continue;
          }
          merged.add({
            'number': hAr['hadithnumber'] ?? (i + 1),
            'arabic': textAr,
            'english': textEn,
          });
        }

        if (mounted) {
          setState(() {
            _hadithList = merged;
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
      final lang = TranslationService.isArabic ? 'ara' : 'eng';
      final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$lang-$bookId.min.json';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawHadiths = decoded['hadiths'] ?? [];
        final List<dynamic> list = rawHadiths.map((h) {
          return {
            'number': h['hadithnumber'] ?? 0,
            'arabic': TranslationService.isArabic ? (h['text'] ?? '') : '',
            'english': !TranslationService.isArabic ? (h['text'] ?? '') : '',
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
      final urlAr = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-$bookId.min.json';
      final urlEn = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-$bookId.min.json';

      final resAr = await http.get(Uri.parse(urlAr));
      final resEn = await http.get(Uri.parse(urlEn));

      if (resAr.statusCode == 200 && resEn.statusCode == 200) {
        final pathAr = await _getLocalPath(bookId, 'ara');
        final pathEn = await _getLocalPath(bookId, 'eng');

        await File(pathAr).parent.create(recursive: true);
        await File(pathAr).writeAsString(resAr.body);
        await File(pathEn).writeAsString(resEn.body);

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

  List<dynamic> _getFilteredHadiths() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _hadithList;

    return _hadithList.where((h) {
      final numStr = h['number'].toString();
      final arText = h['arabic'].toString().toLowerCase();
      final enText = h['english'].toString().toLowerCase();
      return numStr == query || arText.contains(query) || enText.contains(query);
    }).toList();
  }

  void _jumpToHadith() {
    final num = int.tryParse(_jumpController.text.trim());
    if (num == null) return;
    
    final idx = _hadithList.indexWhere((element) => element['number'] == num);
    if (idx != -1) {
      setState(() {
        _currentPage = (idx / _pageSize).floor() + 1;
        _jumpController.clear();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.isArabic ? "الرقم غير موجود في هذا الكتاب" : "Number not found in this book"),
        ),
      );
    }
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
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.import_contacts, color: theme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<HadithBook>(
                        dropdownColor: theme.cardColor,
                        value: _selectedBook,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
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
                  if (!_isOffline)
                    IconButton(
                      icon: Icon(Icons.download_for_offline, color: theme.primaryColor),
                      tooltip: TranslationService.isArabic ? "تحميل الكتاب للقراءة بدون إنترنت" : "Download book for offline use",
                      onPressed: _downloadEntireBook,
                    )
                  else
                    Tooltip(
                      message: TranslationService.isArabic ? 'متاح للقراءة بدون إنترنت' : 'Available offline',
                      child: const Icon(Icons.check_circle, color: Colors.green),
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
                        setState(() {
                          _currentPage = 1;
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
                                // unused variable removed
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: theme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: theme.primaryColor.withOpacity(0.15)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor.withOpacity(0.12),
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
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (h['arabic'].toString().isNotEmpty && TranslationService.isArabic)
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
                                        if (h['english'].toString().isNotEmpty && !TranslationService.isArabic)
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
