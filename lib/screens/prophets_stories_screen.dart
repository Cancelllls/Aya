import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/prophets_data.dart';
import '../models/islamic_library_models.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../theme/app_colors.dart';
import 'full_book_reader_screen.dart';

class ProphetsStoriesScreen extends StatefulWidget {
  final StorageService storage;

  const ProphetsStoriesScreen({super.key, required this.storage});

  @override
  State<ProphetsStoriesScreen> createState() => _ProphetsStoriesScreenState();
}

class _ProphetsStoriesScreenState extends State<ProphetsStoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProphetStory> get _filteredProphets {
    if (_searchQuery.isEmpty) return ProphetsData.prophets;
    return ProphetsData.prophets.where((p) {
      final nameAr = p.nameAr.toLowerCase();
      final nameEn = p.nameEn.toLowerCase();
      final titleAr = p.titleAr.toLowerCase();
      final titleEn = p.titleEn.toLowerCase();
      final surahs = p.keySurahs.join(' ').toLowerCase();
      return nameAr.contains(_searchQuery) ||
          nameEn.contains(_searchQuery) ||
          titleAr.contains(_searchQuery) ||
          titleEn.contains(_searchQuery) ||
          surahs.contains(_searchQuery);
    }).toList();
  }

  bool _isProphetRead(int id) {
    return widget.storage.getBool('prophet_read_$id', defaultValue: false);
  }

  void _toggleProphetRead(int id) {
    HapticFeedback.lightImpact();
    final current = _isProphetRead(id);
    widget.storage.setBool('prophet_read_$id', !current);
    setState(() {});
  }

  int get _readCount {
    return ProphetsData.prophets.where((p) => _isProphetRead(p.id)).length;
  }

  void _openReader(ProphetStory story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullBookReaderScreen(
          bookKey: story.id == 25 ? 'raheeq_makhtum' : 'qisas_al_anbiya',
          defaultTitleAr: story.id == 25
              ? 'السيرة النبوية (الرحيق المختوم)'
              : 'قصة ${story.nameAr} (ابن كثير)',
          defaultTitleEn: story.id == 25 ? 'Prophetic Sirah' : 'Story of ${story.nameEn}',
          storage: widget.storage,
          startPage: story.bookStartPage,
          endPage: story.bookEndPage,
          startPageEn: story.bookStartPageEn,
          endPageEn: story.bookEndPageEn,
          scopeTitleAr: story.id == 25
              ? 'الرحيق المختوم: ${story.nameAr}'
              : 'قصص الأنبياء (ابن كثير): ${story.nameAr}',
          scopeTitleEn: story.id == 25
              ? 'The Sealed Nectar: ${story.nameEn}'
              : 'Ibn Kathir: ${story.nameEn}',
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalCount = ProphetsData.prophets.length;
    final readCount = _readCount;
    final progress = totalCount > 0 ? (readCount / totalCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationService.isArabic
              ? 'قصص الأنبياء'
              : 'Stories of the Prophets',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header banner with progress
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0F766E).withAlpha(100),
                        const Color(0xFF1E293B),
                      ]
                    : [const Color(0xFF0F766E), const Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          TranslationService.isArabic
                              ? 'سير وعبر من هدي النبوة'
                              : 'Prophetic Lives & Wisdom',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withAlpha(120),
                        ),
                      ),
                      child: Text(
                        '$readCount / $totalCount',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(40),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TranslationService.isArabic
                      ? '٢٥ نبياً ورسولاً ورد ذكرهم في القرآن الكريم'
                      : '25 Prophets and Messengers mentioned in the Holy Quran',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: TranslationService.isArabic
                    ? 'ابحث باسم النبي أو السورة...'
                    : 'Search prophet or surah...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withAlpha(100)
                    : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // List of Prophets
          Expanded(
            child: _filteredProphets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withAlpha(100),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          TranslationService.isArabic
                              ? 'لم يتم العثور على نتائج'
                              : 'No prophets match your search',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredProphets.length,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemBuilder: (context, index) {
                      final story = _filteredProphets[index];
                      final isRead = _isProphetRead(story.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isRead
                                ? AppColors.teal.withAlpha(80)
                                : theme.dividerColor.withAlpha(40),
                          ),
                        ),
                        elevation: 0,
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(80)
                            : Colors.white,
                        child: InkWell(
                          onTap: () => _openReader(story),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Number badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? AppColors.teal.withAlpha(40)
                                        : AppColors.gold.withAlpha(30),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isRead
                                          ? AppColors.teal
                                          : AppColors.gold,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${story.id}',
                                      style: TextStyle(
                                        color: isRead
                                            ? AppColors.teal
                                            : AppColors.gold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              TranslationService.isArabic
                                                  ? story.nameAr
                                                  : story.nameEn,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isRead
                                                  ? Icons.check_circle
                                                  : Icons.check_circle_outline,
                                              color: isRead
                                                  ? AppColors.teal
                                                  : theme.dividerColor,
                                              size: 22,
                                            ),
                                            onPressed: () =>
                                                _toggleProphetRead(story.id),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        TranslationService.isArabic
                                            ? story.titleAr
                                            : story.titleEn,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        TranslationService.isArabic
                                            ? story.summaryAr
                                            : story.summaryEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withAlpha(180),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.teal.withAlpha(
                                                25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              TranslationService.isArabic
                                                  ? '${story.quranMentions} مرات بالقرآن'
                                                  : '${story.quranMentions}x in Quran',
                                              style: const TextStyle(
                                                color: AppColors.teal,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          ...story.keySurahs
                                              .take(2)
                                              .map(
                                                (surah) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .surfaceContainerHighest
                                                        .withAlpha(120),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    surah,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withAlpha(160),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          if (story.bookStartPage != null && story.bookEndPage != null)
                                                                                        Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.gold.withAlpha(35),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.gold.withAlpha(120)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.menu_book, color: AppColors.gold, size: 12),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    story.id == 25
                                                        ? (TranslationService.isArabic
                                                            ? 'الرحيق المختوم (٤٥٢ ص)'
                                                            : 'Sealed Nectar (452p)')
                                                        : (TranslationService.isArabic
                                                            ? 'ابن كثير (${story.bookEndPage! - story.bookStartPage! + 1} ص)'
                                                            : 'Ibn Kathir (${story.bookEndPage! - story.bookStartPage! + 1}p)'),
                                                    style: const TextStyle(
                                                      color: Color(0xFFB45309),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
