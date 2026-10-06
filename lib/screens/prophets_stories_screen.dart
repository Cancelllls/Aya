import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
  double _fontSize = 18.0;
  String _viewMode = 'bilingual'; // 'bilingual', 'arabic', 'english'

  @override
  void initState() {
    super.initState();
    _fontSize = widget.storage.getDouble(
      'library_font_size',
      defaultValue: 18.0,
    );
    _viewMode = widget.storage.getString(
      'library_view_mode',
      defaultValue: 'bilingual',
    );
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
        builder: (context) => ProphetReaderScreen(
          story: story,
          storage: widget.storage,
          initialFontSize: _fontSize,
          initialViewMode: _viewMode,
          onFontChange: (size) {
            setState(() => _fontSize = size);
            widget.storage.setDouble('library_font_size', size);
          },
          onViewModeChange: (mode) {
            setState(() => _viewMode = mode);
            widget.storage.setString('library_view_mode', mode);
          },
          onReadToggle: () => setState(() {}),
        ),
      ),
    );
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
                                            InkWell(
                                              onTap: () {
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
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
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

class ProphetReaderScreen extends StatefulWidget {
  final ProphetStory story;
  final StorageService storage;
  final double initialFontSize;
  final String initialViewMode;
  final Function(double) onFontChange;
  final Function(String) onViewModeChange;
  final VoidCallback onReadToggle;

  const ProphetReaderScreen({
    super.key,
    required this.story,
    required this.storage,
    required this.initialFontSize,
    required this.initialViewMode,
    required this.onFontChange,
    required this.onViewModeChange,
    required this.onReadToggle,
  });

  @override
  State<ProphetReaderScreen> createState() => _ProphetReaderScreenState();
}

class _ProphetReaderScreenState extends State<ProphetReaderScreen> {
  late double _fontSize;
  late String _viewMode;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.initialFontSize;
    _viewMode = widget.initialViewMode;
  }

  bool get _isRead {
    return widget.storage.getBool(
      'prophet_read_${widget.story.id}',
      defaultValue: false,
    );
  }

  void _toggleRead() {
    HapticFeedback.mediumImpact();
    widget.storage.setBool('prophet_read_${widget.story.id}', !_isRead);
    widget.onReadToggle();
    setState(() {});
  }

  void _shareStory() {
    final buffer = StringBuffer();
    buffer.writeln('${widget.story.nameAr} - ${widget.story.nameEn}');
    buffer.writeln('${widget.story.titleAr} (${widget.story.titleEn})');
    buffer.writeln('\n${widget.story.summaryAr}\n');
    buffer.writeln('${widget.story.summaryEn}\n');

    for (final sec in widget.story.sections) {
      buffer.writeln('--- ${sec.titleAr} / ${sec.titleEn} ---');
      if (sec.quranVerseAr != null) {
        buffer.writeln('﴿ ${sec.quranVerseAr} ﴾');
        buffer.writeln('"${sec.quranVerseEn}" [${sec.quranRef}]\n');
      }
    }
    buffer.writeln('Shared via Aya Islamic App');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRead = _isRead;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationService.isArabic
              ? widget.story.nameAr
              : widget.story.nameEn,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isRead ? Icons.check_circle : Icons.check_circle_outline,
              color: isRead ? AppColors.teal : null,
            ),
            tooltip: TranslationService.isArabic
                ? 'تحديد كمقروء'
                : 'Mark as Read',
            onPressed: _toggleRead,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: TranslationService.isArabic ? 'مشاركة' : 'Share',
            onPressed: _shareStory,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune),
            tooltip: TranslationService.isArabic
                ? 'خيارات القراءة'
                : 'Reading Options',
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  TranslationService.isArabic ? 'لغة العرض' : 'View Mode',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              CheckedPopupMenuItem(
                checked: _viewMode == 'bilingual',
                value: 'bilingual',
                child: Text(
                  TranslationService.isArabic ? 'ثنائي اللغة' : 'Bilingual',
                ),
              ),
              CheckedPopupMenuItem(
                checked: _viewMode == 'arabic',
                value: 'arabic',
                child: Text(
                  TranslationService.isArabic ? 'عربي فقط' : 'Arabic Only',
                ),
              ),
              CheckedPopupMenuItem(
                checked: _viewMode == 'english',
                value: 'english',
                child: Text(
                  TranslationService.isArabic ? 'إنجليزي فقط' : 'English Only',
                ),
              ),
            ],
            onSelected: (mode) {
              setState(() => _viewMode = mode);
              widget.onViewModeChange(mode);
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withAlpha(40)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: _fontSize > 14
                      ? () {
                          setState(() => _fontSize -= 2);
                          widget.onFontChange(_fontSize);
                        }
                      : null,
                ),
                Text(
                  '${_fontSize.toInt()} pt',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: _fontSize < 30
                      ? () {
                          setState(() => _fontSize += 2);
                          widget.onFontChange(_fontSize);
                        }
                      : null,
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _toggleRead,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRead ? AppColors.teal : AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(isRead ? Icons.check : Icons.done_all, size: 18),
              label: Text(
                isRead
                    ? (TranslationService.isArabic
                          ? 'تمت القراءة'
                          : 'Completed')
                    : (TranslationService.isArabic
                          ? 'تحديد كمقروء'
                          : 'Mark as Read'),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Title Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withAlpha(100)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.story.nameAr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.story.nameEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      TranslationService.isArabic
                          ? widget.story.titleAr
                          : widget.story.titleEn,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip(
                        theme,
                        Icons.timer_outlined,
                        TranslationService.isArabic
                            ? widget.story.periodAr
                            : widget.story.periodEn,
                      ),
                      _buildChip(
                        theme,
                        Icons.menu_book,
                        TranslationService.isArabic
                            ? 'ذكر في القرآن ${widget.story.quranMentions} مرة'
                            : '${widget.story.quranMentions} Quranic Mentions',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  right: TranslationService.isArabic
                      ? const BorderSide(color: AppColors.teal, width: 4)
                      : BorderSide.none,
                  left: !TranslationService.isArabic
                      ? const BorderSide(color: AppColors.teal, width: 4)
                      : BorderSide.none,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_viewMode != 'english') ...[
                    Text(
                      widget.story.summaryAr,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                    if (_viewMode == 'bilingual') const SizedBox(height: 12),
                  ],
                  if (_viewMode != 'arabic') ...[
                    Text(
                      widget.story.summaryEn,
                      style: TextStyle(
                        fontSize: _fontSize - 1,
                        color: theme.colorScheme.onSurface.withAlpha(210),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (widget.story.bookStartPage != null && widget.story.bookEndPage != null) ...[
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullBookReaderScreen(
                        bookKey: widget.story.id == 25 ? 'raheeq_makhtum' : 'qisas_al_anbiya',
                        defaultTitleAr: widget.story.id == 25
                            ? 'السيرة النبوية (الرحيق المختوم)'
                            : 'قصة ${widget.story.nameAr} (ابن كثير)',
                        defaultTitleEn: widget.story.id == 25
                            ? 'Prophetic Sirah'
                            : 'Story of ${widget.story.nameEn}',
                        storage: widget.storage,
                        startPage: widget.story.bookStartPage,
                        endPage: widget.story.bookEndPage,
                        startPageEn: widget.story.bookStartPageEn,
                        endPageEn: widget.story.bookEndPageEn,
                        scopeTitleAr: widget.story.id == 25
                            ? 'الرحيق المختوم: ${widget.story.nameAr}'
                            : 'قصص الأنبياء (ابن كثير): ${widget.story.nameAr}',
                        scopeTitleEn: widget.story.id == 25
                            ? 'The Sealed Nectar: ${widget.story.nameEn}'
                            : 'Ibn Kathir: ${widget.story.nameEn}',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.teal.withAlpha(isDark ? 45 : 25),
                        AppColors.gold.withAlpha(isDark ? 35 : 18),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withAlpha(120), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_stories, color: AppColors.gold, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.story.id == 25
                                  ? (TranslationService.isArabic
                                      ? 'قراءة كتاب الرحيق المختوم كاملاً'
                                      : 'Read The Sealed Nectar Full Book')
                                  : (TranslationService.isArabic
                                      ? 'قراءة قصة ${widget.story.nameAr} كاملة'
                                      : 'Read Full Story of ${widget.story.nameEn}'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.story.id == 25
                                  ? (TranslationService.isArabic
                                      ? '٤٥٢ صفحة - السيرة النبوية الشريفة للمباركفوري'
                                      : '452 pages - Complete prophetic biography')
                                  : (TranslationService.isArabic
                                      ? 'النص الكامل من كتاب قصص الأنبياء لابن كثير (${widget.story.bookEndPage! - widget.story.bookStartPage! + 1} صفحة)'
                                      : 'Complete unabridged text from Ibn Kathir (${widget.story.bookEndPage! - widget.story.bookStartPage! + 1} pages)'),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gold),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 24),
            ],

            // Sections
            ...widget.story.sections.map(
              (sec) => _buildSection(context, sec, theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    StorySection sec,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  TranslationService.isArabic ? sec.titleAr : sec.titleEn,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Narrative Text
          if (_viewMode != 'english') ...[
            Text(
              sec.contentAr,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.7,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (_viewMode == 'bilingual') const SizedBox(height: 12),
          ],
          if (_viewMode != 'arabic') ...[
            Text(
              sec.contentEn,
              style: TextStyle(
                fontSize: _fontSize - 1,
                height: 1.55,
                color: theme.colorScheme.onSurface.withAlpha(210),
              ),
            ),
          ],

          // Quranic Verse Box if available
          if (sec.quranVerseAr != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withAlpha(120)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '﴿ ${sec.quranVerseAr} ﴾',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                      height: 1.7,
                    ),
                  ),
                  if (sec.quranVerseEn != null && _viewMode != 'arabic') ...[
                    const SizedBox(height: 10),
                    Text(
                      '"${sec.quranVerseEn}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _fontSize - 2,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withAlpha(200),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (sec.quranRef != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      sec.quranRef!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
