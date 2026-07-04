import 'dart:io';

void main() async {
  final file = File('lib/screens/quran_screen.dart');
  var content = await file.readAsString();

  final buildAyahSearchResults = '''
  Widget _buildAyahSearchResults(ThemeData theme, bool isDark) {
    if (_isSearchingAyahs) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)));
    }
    if (_ayahSearchError.isNotEmpty) {
      return Center(
        child: Text(
          _ayahSearchError,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    if (_ayahSearchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.disabledColor),
            SizedBox(height: 12),
            Text(
              TranslationService.isArabic ? "لا توجد نتائج" : "No matches found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _ayahSearchResults.length,
      itemBuilder: (context, index) {
        final match = _ayahSearchResults[index];
        final surahInfo = match['surah'];
        final String surahName = surahInfo['name'] ?? '';
        final String englishName = surahInfo['englishName'] ?? '';
        final int numberInSurah = match['numberInSurah'] ?? 0;
        final String text = match['text'] ?? '';
        final int surahNumber = surahInfo['number'] ?? 1;

        return Card(
          color: theme.cardColor,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFFE5C158).withOpacity(0.12),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textDirection: _isArabic(text) ? TextDirection.rtl : TextDirection.ltr,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                TranslationService.isArabic
                    ? "\$surahName - الآية \$numberInSurah"
                    : "\$englishName - Verse \$numberInSurah",
                style: TextStyle(
                  color: const Color(0xFFE5C158),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              // Find the Surah object
              Surah? targetSurah;
              try {
                targetSurah = _surahList.firstWhere((s) => s.number == surahNumber);
              } catch (_) {}
              
              if (targetSurah != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahReaderScreen(
                      surah: targetSurah!,
                      storage: widget.storage,
                      initialAyahNumber: numberInSurah,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
''';

  // Find the last closing brace and replace it
  int lastBraceIndex = content.lastIndexOf('}');
  content = content.substring(0, lastBraceIndex) + buildAyahSearchResults;
  
  await file.writeAsString(content);
}
