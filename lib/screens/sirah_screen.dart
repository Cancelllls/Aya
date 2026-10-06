import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/sirah_data.dart';
import '../models/islamic_library_models.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../theme/app_colors.dart';
import 'full_book_reader_screen.dart';

class SirahScreen extends StatefulWidget {
  final StorageService storage;

  const SirahScreen({super.key, required this.storage});

  @override
  State<SirahScreen> createState() => _SirahScreenState();
}

class _SirahScreenState extends State<SirahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedPeriodIndex = 0; // 0: All, 1: Makkan, 2: Madinan

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

  List<SirahChapter> get _filteredChapters {
    var list = SirahData.chapters;

    if (_selectedPeriodIndex == 1) {
      list = list.where((c) => c.periodEn.contains('Makkan')).toList();
    } else if (_selectedPeriodIndex == 2) {
      list = list.where((c) => c.periodEn.contains('Madinan')).toList();
    }

    if (_searchQuery.isEmpty) return list;

    return list.where((c) {
      final titleAr = c.titleAr.toLowerCase();
      final titleEn = c.titleEn.toLowerCase();
      final summaryAr = c.summaryAr.toLowerCase();
      final summaryEn = c.summaryEn.toLowerCase();
      final yearAr = c.yearAr.toLowerCase();
      final yearEn = c.yearEn.toLowerCase();
      return titleAr.contains(_searchQuery) ||
          titleEn.contains(_searchQuery) ||
          summaryAr.contains(_searchQuery) ||
          summaryEn.contains(_searchQuery) ||
          yearAr.contains(_searchQuery) ||
          yearEn.contains(_searchQuery);
    }).toList();
  }

  bool _isChapterRead(int id) {
    return widget.storage.getBool('sirah_read_$id', defaultValue: false);
  }

  int get _readCount {
    return SirahData.chapters.where((c) => _isChapterRead(c.id)).length;
  }

  void _toggleChapterRead(int id) {
    HapticFeedback.lightImpact();
    final current = _isChapterRead(id);
    widget.storage.setBool('sirah_read_$id', !current);
    setState(() {});
  }

  void _openReader(SirahChapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullBookReaderScreen(
          bookKey: 'raheeq_makhtum',
          defaultTitleAr: 'فصل: ${chapter.titleAr}',
          defaultTitleEn: 'Chapter: ${chapter.titleEn}',
          storage: widget.storage,
          startPage: chapter.bookStartPage,
          endPage: chapter.bookEndPage,
          startPageEn: chapter.bookStartPageEn,
          endPageEn: chapter.bookEndPageEn,
          scopeTitleAr: 'الرحيق المختوم: ${chapter.titleAr}',
          scopeTitleEn: 'The Sealed Nectar: ${chapter.titleEn}',
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalCount = SirahData.chapters.length;
    final readCount = _readCount;
    final progress = totalCount > 0 ? (readCount / totalCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationService.isArabic
              ? 'السيرة النبوية الشريفة'
              : 'Prophetic Biography (Sīrah)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner Card
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
                            Icons.history_edu,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          TranslationService.isArabic
                              ? 'الرحيق المختوم وسيرة المصطفى'
                              : 'The Sealed Nectar Timeline',
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
                      ? 'محطات تاريخية خالدة من مولد الحبيب ﷺ حتى الرفيق الأعلى'
                      : 'Chronological epochs from the blessed birth to the highest companion',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Period Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildPeriodFilterChip(
                  0,
                  TranslationService.isArabic ? 'جميع المحطات' : 'All Epochs',
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterChip(
                  1,
                  TranslationService.isArabic
                      ? 'العهد المكي (١-١١)'
                      : 'Makkan (1-11)',
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterChip(
                  2,
                  TranslationService.isArabic
                      ? 'العهد المدني (١٢-٢٢)'
                      : 'Madinan (12-22)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: TranslationService.isArabic
                    ? 'ابحث في محطات وغزوات وأحداث السيرة...'
                    : 'Search events, battles, or periods...',
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

          const SizedBox(height: 6),

          // Chapters List
          Expanded(
            child: _filteredChapters.isEmpty
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
                              ? 'لم يتم العثور على محطات مطابقة'
                              : 'No chapters match your search',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredChapters.length,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemBuilder: (context, index) {
                      final chapter = _filteredChapters[index];
                      final isRead = _isChapterRead(chapter.id);

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
                          onTap: () => _openReader(chapter),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Number Badge
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
                                      '${chapter.number}',
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
                                                  ? chapter.titleAr
                                                  : chapter.titleEn,
                                              style: const TextStyle(
                                                fontSize: 16,
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
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _toggleChapterRead(chapter.id),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  chapter.periodEn.contains(
                                                    'Makkan',
                                                  )
                                                  ? Colors.amber.withAlpha(40)
                                                  : Colors.teal.withAlpha(40),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              TranslationService.isArabic
                                                  ? chapter.periodAr
                                                  : chapter.periodEn,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    chapter.periodEn.contains(
                                                      'Makkan',
                                                    )
                                                    ? Colors.amber.shade800
                                                    : Colors.teal.shade800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              TranslationService.isArabic
                                                  ? chapter.yearAr
                                                  : chapter.yearEn,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withAlpha(160),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        TranslationService.isArabic
                                            ? chapter.summaryAr
                                            : chapter.summaryEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withAlpha(180),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 13,
                                            color: theme.colorScheme.onSurface
                                                .withAlpha(140),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            TranslationService.isArabic
                                                ? '${chapter.readTimeMinutes} دقيقة للقراءة'
                                                : '${chapter.readTimeMinutes} min read',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurface
                                                  .withAlpha(140),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (chapter.bookStartPage != null && chapter.bookEndPage != null)
                                                                                        Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                                    TranslationService.isArabic
                                                        ? 'الرحيق المختوم (${chapter.bookEndPage! - chapter.bookStartPage! + 1} ص)'
                                                        : 'Sealed Nectar (${chapter.bookEndPage! - chapter.bookStartPage! + 1}p)',
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

  Widget _buildPeriodFilterChip(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriodIndex = index);
        }
      },
      selectedColor: AppColors.teal,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
