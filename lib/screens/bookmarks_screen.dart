import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import 'surah_reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  final StorageService storage;

  const BookmarksScreen({super.key, required this.storage});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final b = await widget.storage.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = b;
        _isLoading = false;
      });
    }
  }

  void _removeBookmark(int surahNum, int ayahNum) async {
    await widget.storage.removeBookmark(surahNum, ayahNumber: ayahNum);
    await _loadBookmarks();
  }

  void _navigateToBookmark(int surahNum, int ayahNum) async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.isArabic ? "العلامات المرجعية" : "Bookmarks", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(child: Text(TranslationService.isArabic ? "لا توجد علامات مرجعية" : "No bookmarks found", style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final b = _bookmarks[index];
                    final sName = b['surahName'] ?? '';
                    final sNum = b['surahNumber'] ?? 1;
                    final aNum = b['ayahNumber'] ?? 1;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
                      child: ListTile(
                        onTap: () => _navigateToBookmark(sNum, aNum),
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.2),
                          child: Icon(Icons.bookmark, color: theme.primaryColor, size: 20),
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
                          onPressed: () => _removeBookmark(sNum, aNum),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
