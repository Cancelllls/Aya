import 'dart:math';
import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/database_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'surah_reader/surah_reader_screen.dart';
import 'surah_reader/surah_pager_screen.dart';
import 'surah_reader/surah_pager_screen.dart';

class QuranScreen extends StatefulWidget {
  final StorageService storage;

  const QuranScreen({super.key, required this.storage});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<Surah> _surahList = [];
  List<Surah> _filteredSurahList = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  int _activeSearchTab = 0;
  List<Map<String, dynamic>> _ayahSearchResults = [];
  bool _isSearchingAyahs = false;
  String _ayahSearchError = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final db = await DatabaseService.getInstance();
      final data = await db.getSurahs();
      final list = data.map((s) => Surah.fromJson(s)).toList();
      setState(() {
        _surahList = list;
        _filteredSurahList = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'فشل تحميل قائمة السور: $e'
                  : 'Failed to load Surah list: $e',
            ),
          ),
        );
      }
    }
  }

  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  Future<void> _searchAyahs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearchingAyahs = true;
      _ayahSearchError = '';
    });

    try {
      final db = await DatabaseService.getInstance();
      final results = await db.searchAyahs(query);
      if (mounted) {
        setState(() {
          _ayahSearchResults = results;
          _isSearchingAyahs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingAyahs = false;
          _ayahSearchError = TranslationService.isArabic
              ? "حدث خطأ أثناء البحث"
              : "Error occurred while searching";
        });
      }
    }
  }

  String _stripTashkeel(String input) {
    final RegExp tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
    return input.replaceAll(tashkeelRegex, '');
  }

  void _filterSurahs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSurahList = _surahList;
        _activeSearchTab = 0;
        _ayahSearchResults.clear();
      });
      return;
    }

    final lower = query.toLowerCase();
    final cleanQuery = _stripTashkeel(lower);
    setState(() {
      _filteredSurahList = _surahList.where((surah) {
        final cleanName = _stripTashkeel(surah.name);
        return surah.englishName.toLowerCase().contains(lower) ||
            surah.englishNameTranslation.toLowerCase().contains(lower) ||
            cleanName.contains(cleanQuery) ||
            surah.name.contains(query) ||
            surah.number.toString() == query;
      }).toList();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchAyahs(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.storage.isDarkMode();
    return Column(
      children: [
        // Search Bar Container
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterSurahs,
            style: TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: TranslationService.t('search_placeholder'),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Color(0xFFE5C158),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterSurahs('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFE5C158).withOpacity(0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white)
                          .withOpacity(0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE5C158)),
              ),
            ),
          ),
        ),

        // Segmented Controls for Search Results
        if (_searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSearchTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeSearchTab == 0
                            ? const Color(0xFFE5C158)
                            : theme.cardColor,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        border: Border.all(color: const Color(0xFFE5C158)),
                      ),
                      child: Center(
                        child: Text(
                          TranslationService.isArabic ? "السور" : "Surahs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeSearchTab == 0
                                ? Colors.black
                                : theme.textTheme.bodyLarge?.color,
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
                        color: _activeSearchTab == 1
                            ? const Color(0xFFE5C158)
                            : theme.cardColor,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                        border: Border.all(color: const Color(0xFFE5C158)),
                      ),
                      child: Center(
                        child: Text(
                          TranslationService.isArabic ? "الآيات" : "Verses",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeSearchTab == 1
                                ? Colors.black
                                : theme.textTheme.bodyLarge?.color,
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
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5C158)),
                )
              : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 12),
                      Text(
                        TranslationService.isArabic
                            ? "فشل تحميل قائمة السور"
                            : "Failed to load Surah list",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5C158),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _loadSurahs,
                        child: Text(
                          TranslationService.isArabic
                              ? "إعادة المحاولة"
                              : "Retry",
                        ),
                      ),
                    ],
                  ),
                )
              : _activeSearchTab == 1
              ? _buildAyahSearchResults(theme, isDark)
              : _filteredSurahList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      SizedBox(height: 12),
                      Text(
                        TranslationService.t('no_surah_match'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredSurahList.length,
                  itemBuilder: (context, index) {
                    final surah = _filteredSurahList[index];
                    return _buildSurahTile(surah, theme, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSurahTile(Surah surah, ThemeData theme, bool isDark) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: pi / 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE5C158).withOpacity(0.3),
                      width: 1.5,
                    ),
                    color: const Color(0xFFE5C158).withOpacity(0.08),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFE5C158).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              Text(
                surah.number.toString(),
                style: TextStyle(
                  color: Color(0xFFE5C158),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          surah.englishName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              surah.revelationType.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            Icon(Icons.circle, size: 4, color: theme.dividerColor),
            Text(
              "${surah.numberOfAyahs} ${TranslationService.t('verses')}",
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            Icon(Icons.circle, size: 4, color: theme.dividerColor),
            Text(
              "${TranslationService.t('juz')} ${surah.startingJuz} • ${TranslationService.t('hizb')} ${surah.startingHizb}",
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Hero(
          tag: 'surah_name_${surah.number}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              surah.name,
              style: TextStyle(
                fontFamily: 'Amiri', // Arabic font loaded
                color: Color(0xFFE5C158),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SurahPagerScreen(initialSurah: surah, storage: widget.storage),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAyahSearchResults(ThemeData theme, bool isDark) {
    if (_isSearchingAyahs) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5C158)),
      );
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
              TranslationService.isArabic
                  ? "لا توجد نتائج"
                  : "No matches found",
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
        final String surahName = match['surah_name'] ?? '';
        final String englishName = match['surah_englishName'] ?? '';
        final int numberInSurah = match['ayah_number'] ?? 0;
        final String text = _isArabic(_searchController.text) ? (match['text_arabic'] ?? '') : (match['text_english'] ?? '');
        final int surahNumber = match['surah_number'] ?? 1;

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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              text,
              style: TextStyle(fontSize: 16, height: 1.5),
              textDirection: _isArabic(text)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                TranslationService.isArabic
                    ? "$surahName - الآية $numberInSurah"
                    : "$englishName - Verse $numberInSurah",
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
                targetSurah = _surahList.firstWhere(
                  (s) => s.number == surahNumber,
                );
              } catch (_) {}

              if (targetSurah != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahPagerScreen(
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
