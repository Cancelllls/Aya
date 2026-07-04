import 'dart:io';

void main() async {
  final file = File('lib/screens/quran_screen.dart');
  var content = await file.readAsString();

  content = content.replaceFirst("import '../services/translation_service.dart';", "import '../services/translation_service.dart';\nimport 'dart:async';\nimport 'dart:convert';\nimport 'package:http/http.dart' as http;");

  final stateRegex = RegExp(r"final TextEditingController _searchController = TextEditingController\(\);");
  content = content.replaceFirst(stateRegex, "final TextEditingController _searchController = TextEditingController();\n\n  int _activeSearchTab = 0;\n  List<Map<String, dynamic>> _ayahSearchResults = [];\n  bool _isSearchingAyahs = false;\n  String _ayahSearchError = '';\n  Timer? _debounce;");

  final disposeRegex = RegExp(r"_searchController\.dispose\(\);\n    super\.dispose\(\);");
  content = content.replaceFirst(disposeRegex, "_debounce?.cancel();\n    _searchController.dispose();\n    super.dispose();");

  final stripRegex = RegExp(r"String _stripTashkeel\(String input\) \{");
  final ayahSearchMethod = '''
  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\\u0600-\\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  Future<void> _searchAyahs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearchingAyahs = true;
      _ayahSearchError = '';
    });

    try {
      final edition = _isArabic(query) ? 'quran-simple-clean' : 'en.asad';
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'http://api.alquran.cloud/v1/search/\$encodedQuery/all/\$edition';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _ayahSearchResults = List<Map<String, dynamic>>.from(data['data']['matches'] ?? []);
            _isSearchingAyahs = false;
          });
        }
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingAyahs = false;
          _ayahSearchError = TranslationService.isArabic ? "حدث خطأ أثناء البحث" : "Error occurred while searching";
        });
      }
    }
  }

  String _stripTashkeel(String input) {''';
  content = content.replaceFirst(stripRegex, ayahSearchMethod);

  final filterSurahsRegex = RegExp(r"void _filterSurahs\(String query\) \{\s*if \(query\.isEmpty\) \{\s*setState\(\(\) \{\s*_filteredSurahList = _surahList;\s*\}\);\s*return;\s*\}");
  final newFilterSurahs = '''void _filterSurahs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSurahList = _surahList;
        _activeSearchTab = 0;
        _ayahSearchResults.clear();
      });
      return;
    }''';
  content = content.replaceFirst(filterSurahsRegex, newFilterSurahs);
  
  final endFilterSurahsRegex = RegExp(r"\}\)\.toList\(\);\s*\}\);");
  final newEndFilterSurahs = '''}).toList();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchAyahs(query);
    });''';
  content = content.replaceFirst(endFilterSurahsRegex, newEndFilterSurahs);

  // Now the UI
  // Replace the search bar to Surah List Builder
  final searchBarToBuilderRegex = RegExp(r"// Surah List Builder\s*Expanded\(");
  final newSegmentedControls = '''// Segmented Controls for Search Results
        if (_searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSearchTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeSearchTab == 0 ? const Color(0xFFE5C158) : theme.cardColor,
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                        border: Border.all(color: const Color(0xFFE5C158)),
                      ),
                      child: Center(
                        child: Text(
                          TranslationService.isArabic ? "السور" : "Surahs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeSearchTab == 0 ? Colors.black : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSearchTab = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeSearchTab == 1 ? const Color(0xFFE5C158) : theme.cardColor,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                        border: Border.all(color: const Color(0xFFE5C158)),
                      ),
                      child: Center(
                        child: Text(
                          TranslationService.isArabic ? "الآيات" : "Verses",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeSearchTab == 1 ? Colors.black : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Surah List Builder
        Expanded(''';
  content = content.replaceFirst(searchBarToBuilderRegex, newSegmentedControls);

  // Replace ListView.builder for Surah List
  final emptyListRegex = RegExp(r": _filteredSurahList\.isEmpty");
  final newEmptyList = ''': _activeSearchTab == 1
              ? _buildAyahSearchResults(theme, isDark)
              : _filteredSurahList.isEmpty''';
  content = content.replaceFirst(emptyListRegex, newEmptyList);
  
  await file.writeAsString(content);
}
