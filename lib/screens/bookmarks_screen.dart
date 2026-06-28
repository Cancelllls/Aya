import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import 'surah_reader_screen.dart';
import 'hadith_screen.dart';

class BookmarksScreen extends StatefulWidget {
  final StorageService storage;

  const BookmarksScreen({super.key, required this.storage});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _quranBookmarks = [];
  List<Map<String, dynamic>> _hadithBookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final quran = await widget.storage.getBookmarks();
    final List<String> hadithStrings = widget.storage.getStringList('hadith_bookmarks') ?? [];
    
    final hadith = hadithStrings.map((str) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((element) => element.isNotEmpty).toList();

    if (mounted) {
      setState(() {
        _quranBookmarks = quran;
        _hadithBookmarks = hadith;
        _isLoading = false;
      });
    }
  }

  void _removeQuranBookmark(int surahNum, int ayahNum) async {
    await widget.storage.removeBookmark(surahNum, ayahNumber: ayahNum);
    await _loadBookmarks();
  }

  void _removeHadithBookmark(Map<String, dynamic> b) async {
    final List<String> current = widget.storage.getStringList('hadith_bookmarks') ?? [];
    final data = jsonEncode(b);
    current.remove(data);
    await widget.storage.setStringList('hadith_bookmarks', current);
    await _loadBookmarks();
  }

  void _navigateToQuranBookmark(int surahNum, int ayahNum) async {
    try {
      final surahs = await ApiService.fetchSurahList();
      final surah = surahs.firstWhere((s) => s.number == surahNum);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahReaderScreen(
              surah: surah,
              storage: widget.storage,
              initialAyahNumber: ayahNum,
            ),
          ),
        );
        await _loadBookmarks();
      }
    } catch (_) {}
  }

  void _navigateToHadithBookmark(Map<String, dynamic> b) {
    final bookId = b['bookId']?.toString() ?? '';
    final number = b['number'];
    final hadithNum = number is int ? number : int.tryParse(number.toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithScreen(
          storage: widget.storage,
          initialBookId: bookId.isNotEmpty ? bookId : null,
          initialHadithNumber: hadithNum,
        ),
      ),
    );
  }

  Widget _buildQuranList(ThemeData theme) {
    if (_quranBookmarks.isEmpty) {
      return Center(child: Text(TranslationService.isArabic ? "لا توجد علامات مرجعية" : "No Quran bookmarks", style: TextStyle(color: theme.textTheme.bodyMedium?.color)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quranBookmarks.length,
      itemBuilder: (context, index) {
        final b = _quranBookmarks[index];
        final sName = b['surahName'] ?? '';
        final sNum = b['surahNumber'] ?? 1;
        final aNum = b['ayahNumber'] ?? 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
          child: ListTile(
            onTap: () => _navigateToQuranBookmark(sNum, aNum),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.2),
              child: Icon(Icons.menu_book, color: theme.primaryColor, size: 20),
            ),
            title: Text(
              sName,
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            subtitle: Text(
              TranslationService.isArabic ? "الآية $aNum" : "Ayah $aNum",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeQuranBookmark(sNum, aNum),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHadithList(ThemeData theme) {
    if (_hadithBookmarks.isEmpty) {
      return Center(child: Text(TranslationService.isArabic ? "لا توجد علامات مرجعية" : "No Hadith bookmarks", style: TextStyle(color: theme.textTheme.bodyMedium?.color)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hadithBookmarks.length,
      itemBuilder: (context, index) {
        final b = _hadithBookmarks[index];
        final book = b['book'] ?? '';
        final number = b['number'] ?? 1;
        final text = b['text'] ?? '';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToHadithBookmark(b),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          TranslationService.isArabic
                              ? '${b['bookAr'] ?? book} · ${TranslationService.isArabic ? 'حديث' : 'Hadith'} $number'
                              : '$book · Hadith $number',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _removeHadithBookmark(b),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 15),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.open_in_new, size: 12, color: theme.primaryColor.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        TranslationService.isArabic ? 'اضغط للانتقال للحديث' : 'Tap to go to hadith',
                        style: TextStyle(fontSize: 11, color: theme.primaryColor.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.isArabic ? "العلامات المرجعية" : "Bookmarks", style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5C158),
            labelColor: const Color(0xFFE5C158),
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            tabs: [
              Tab(text: TranslationService.isArabic ? "القرآن الكريم" : "Quran"),
              Tab(text: TranslationService.isArabic ? "الحديث الشريف" : "Hadith"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildQuranList(theme),
                  _buildHadithList(theme),
                ],
              ),
      ),
    );
  }
}

