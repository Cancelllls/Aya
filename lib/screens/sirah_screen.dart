import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
  double _fontSize = 18.0;
  String _viewMode = 'bilingual';

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

  void _openReader(SirahChapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SirahReaderScreen(
          chapter: chapter,
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
                                          if (isRead)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.teal,
                                              size: 20,
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
                                            InkWell(
                                              onTap: () {
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
                                                      scopeTitleAr: 'الرحيق المختوم: ${chapter.titleAr}',
                                                      scopeTitleEn: 'The Sealed Nectar: ${chapter.titleEn}',
                                                    ),
                                                  ),
                                                ).then((_) => setState(() {}));
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
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

class SirahReaderScreen extends StatefulWidget {
  final SirahChapter chapter;
  final StorageService storage;
  final double initialFontSize;
  final String initialViewMode;
  final Function(double) onFontChange;
  final Function(String) onViewModeChange;
  final VoidCallback onReadToggle;

  const SirahReaderScreen({
    super.key,
    required this.chapter,
    required this.storage,
    required this.initialFontSize,
    required this.initialViewMode,
    required this.onFontChange,
    required this.onViewModeChange,
    required this.onReadToggle,
  });

  @override
  State<SirahReaderScreen> createState() => _SirahReaderScreenState();
}

class _SirahReaderScreenState extends State<SirahReaderScreen> {
  late SirahChapter _currentChapter;
  late double _fontSize;
  late String _viewMode;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _fontSize = widget.initialFontSize;
    _viewMode = widget.initialViewMode;
  }

  bool get _isRead {
    return widget.storage.getBool(
      'sirah_read_${_currentChapter.id}',
      defaultValue: false,
    );
  }

  void _toggleRead() {
    HapticFeedback.mediumImpact();
    widget.storage.setBool('sirah_read_${_currentChapter.id}', !_isRead);
    widget.onReadToggle();
    setState(() {});
  }

  void _shareChapter() {
    final buffer = StringBuffer();
    buffer.writeln('${_currentChapter.titleAr} - ${_currentChapter.titleEn}');
    buffer.writeln('${_currentChapter.periodAr} | ${_currentChapter.yearAr}\n');
    buffer.writeln('${_currentChapter.summaryAr}\n');
    buffer.writeln('${_currentChapter.summaryEn}\n');

    for (final sec in _currentChapter.sections) {
      buffer.writeln('--- ${sec.titleAr} / ${sec.titleEn} ---');
      if (sec.quranVerseAr != null) {
        buffer.writeln('﴿ ${sec.quranVerseAr} ﴾');
        buffer.writeln('"${sec.quranVerseEn}" [${sec.quranRef}]\n');
      }
    }
    buffer.writeln('Shared via Aya Islamic App - Al-Sīrah al-Nabawiyyah');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _goToChapter(int id) {
    final next = SirahData.chapters.firstWhere(
      (c) => c.id == id,
      orElse: () => _currentChapter,
    );
    setState(() {
      _currentChapter = next;
    });
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
              ? _currentChapter.titleAr
              : _currentChapter.titleEn,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            onPressed: _shareChapter,
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
            // Chapter Header Card
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
                          ? 'المحطة ${_currentChapter.number} من ٢٢'
                          : 'Epoch ${_currentChapter.number} of 22',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentChapter.titleAr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentChapter.titleEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(200),
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
                        Icons.place_outlined,
                        TranslationService.isArabic
                            ? _currentChapter.periodAr
                            : _currentChapter.periodEn,
                      ),
                      _buildChip(
                        theme,
                        Icons.calendar_today_outlined,
                        TranslationService.isArabic
                            ? _currentChapter.yearAr
                            : _currentChapter.yearEn,
                      ),
                      _buildChip(
                        theme,
                        Icons.timer_outlined,
                        TranslationService.isArabic
                            ? '${_currentChapter.readTimeMinutes} دقيقة للقراءة'
                            : '${_currentChapter.readTimeMinutes} min read',
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
                      _currentChapter.summaryAr,
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
                      _currentChapter.summaryEn,
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

            if (_currentChapter.bookStartPage != null && _currentChapter.bookEndPage != null) ...[
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullBookReaderScreen(
                        bookKey: 'raheeq_makhtum',
                        defaultTitleAr: 'فصل: ${_currentChapter.titleAr}',
                        defaultTitleEn: 'Chapter: ${_currentChapter.titleEn}',
                        storage: widget.storage,
                        startPage: _currentChapter.bookStartPage,
                        endPage: _currentChapter.bookEndPage,
                        scopeTitleAr: 'الرحيق المختوم: ${_currentChapter.titleAr}',
                        scopeTitleEn: 'The Sealed Nectar: ${_currentChapter.titleEn}',
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
                              TranslationService.isArabic
                                  ? 'قراءة أحداث هذا الفصل من الرحيق المختوم'
                                  : 'Read Full Chapter from The Sealed Nectar',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              TranslationService.isArabic
                                  ? 'النص الكامل غير مختصر للمباركفوري (${_currentChapter.bookEndPage! - _currentChapter.bookStartPage! + 1} صفحة)'
                                  : 'Complete unabridged text (${_currentChapter.bookEndPage! - _currentChapter.bookStartPage! + 1} pages)',
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
            ..._currentChapter.sections.map(
              (sec) => _buildSection(context, sec, theme, isDark),
            ),

            const SizedBox(height: 16),

            // Chapter Navigation (Previous / Next)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentChapter.id > 1)
                  OutlinedButton.icon(
                    onPressed: () => _goToChapter(_currentChapter.id - 1),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      TranslationService.isArabic
                          ? 'المحطة السابقة'
                          : 'Previous',
                    ),
                  )
                else
                  const SizedBox(),
                if (_currentChapter.id < SirahData.chapters.length)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                    ),
                    onPressed: () => _goToChapter(_currentChapter.id + 1),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: Text(
                      TranslationService.isArabic ? 'المحطة التالية' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const SizedBox(),
              ],
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
