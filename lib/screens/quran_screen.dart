import 'dart:math';
import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import 'surah_reader_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final list = await ApiService.fetchSurahList();
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

  String _stripTashkeel(String input) {
    final RegExp tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
    return input.replaceAll(tashkeelRegex, '');
  }

  void _filterSurahs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSurahList = _surahList;
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
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: TranslationService.t('search_placeholder'),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Color(0xFFE5C158),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
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
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5C158)),
              ),
            ),
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
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        TranslationService.isArabic
                            ? "فشل تحميل قائمة السور"
                            : "Failed to load Surah list",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      Text(
                        TranslationService.t('no_surah_match'),
                        style: const TextStyle(
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
                style: const TextStyle(
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
        trailing: Text(
          surah.name,
          style: const TextStyle(
            fontFamily: 'Amiri', // Arabic font loaded
            color: Color(0xFFE5C158),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SurahReaderScreen(surah: surah, storage: widget.storage),
            ),
          );
        },
      ),
    );
  }
}
