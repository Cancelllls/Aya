import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/fiqh_chapters_data.dart';
import '../../data/fiqh_data.dart';
import '../../models/fiqh_model.dart';
import '../../models/islamic_library_models.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../full_book_reader_screen.dart';
import 'fiqh_topic_detail_screen.dart';
import 'sujood_sahw_wizard_screen.dart';
import 'zakat_calculator_screen.dart';

class FiqhScreen extends StatefulWidget {
  final StorageService? storage;
  const FiqhScreen({super.key, this.storage});

  @override
  State<FiqhScreen> createState() => _FiqhScreenState();
}

class _FiqhScreenState extends State<FiqhScreen> {
  // Topic Guides state
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Book Chapters state
  String _selectedChapterCategory = 'الكل';
  String _chapterSearchQuery = '';
  final _chapterSearchController = TextEditingController();

  StorageService? _storage;
  bool _isEnglish = false;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage;
    _isEnglish = widget.storage?.getBool(
          'fiqh_screen_is_english',
          defaultValue: !TranslationService.isArabic,
        ) ??
        !TranslationService.isArabic;
    if (_isEnglish) {
      _selectedChapterCategory = 'All';
    }
    if (_storage == null) {
      StorageService.getInstance().then((s) {
        if (mounted) {
          setState(() {
            _storage = s;
            _isEnglish = s.getBool(
              'fiqh_screen_is_english',
              defaultValue: !TranslationService.isArabic,
            );
            _selectedChapterCategory = _isEnglish ? 'All' : 'الكل';
          });
        }
      });
    }
  }

  void _toggleLanguage() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEnglish = !_isEnglish;
      _selectedChapterCategory = _isEnglish ? 'All' : 'الكل';
    });
    _storage?.setBool('fiqh_screen_is_english', _isEnglish);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chapterSearchController.dispose();
    super.dispose();
  }

  bool _isChapterRead(int id) {
    return _storage?.getBool('fiqh_chapter_read_$id', defaultValue: false) ?? false;
  }

  void _toggleChapterRead(int id) {
    HapticFeedback.lightImpact();
    final current = _isChapterRead(id);
    _storage?.setBool('fiqh_chapter_read_$id', !current);
    setState(() {});
  }

  int get _readChaptersCount {
    return FiqhChaptersData.chapters.where((c) => _isChapterRead(c.id)).length;
  }

  Future<void> _openFullBookReader() async {
    final storage = _storage ?? await StorageService.getInstance();
    await storage.setBool('book_reader_is_english', _isEnglish);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullBookReaderScreen(
          bookKey: 'fiqh_muyassar',
          defaultTitleAr: 'كتاب الفقه الميسر في ضوء الكتاب والسنة',
          defaultTitleEn: 'Al-Fiqh Al-Muyassar (Simplified Fiqh)',
          storage: storage,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openChapterReader(FiqhChapter chapter) async {
    final storage = _storage ?? await StorageService.getInstance();
    await storage.setBool('book_reader_is_english', _isEnglish);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullBookReaderScreen(
          bookKey: 'fiqh_muyassar',
          defaultTitleAr: chapter.titleAr,
          defaultTitleEn: chapter.titleEn,
          storage: storage,
          startPage: chapter.bookStartPage,
          endPage: chapter.bookEndPage,
          startPageEn: chapter.bookStartPageEn,
          endPageEn: chapter.bookEndPageEn,
          scopeTitleAr: 'الفقه الميسر: ${chapter.titleAr}',
          scopeTitleEn: 'Al-Fiqh Al-Muyassar: ${chapter.titleEn}',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  List<FiqhChapter> get _filteredChapters {
    final isArabic = !_isEnglish;
    var list = FiqhChaptersData.chapters;

    if (_selectedChapterCategory != 'الكل' && _selectedChapterCategory != 'All') {
      list = list.where((c) {
        return isArabic
            ? c.categoryAr == _selectedChapterCategory
            : c.categoryEn == _selectedChapterCategory;
      }).toList();
    }

    if (_chapterSearchQuery.isNotEmpty) {
      final q = _chapterSearchQuery.toLowerCase();
      list = list.where((c) {
        return c.titleAr.toLowerCase().contains(q) ||
            c.titleEn.toLowerCase().contains(q) ||
            c.summaryAr.toLowerCase().contains(q) ||
            c.summaryEn.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  List<FiqhTopic> get _filteredTopics {
    final isArabic = !_isEnglish;
    List<FiqhTopic> list = _searchQuery.isEmpty
        ? FiqhData.topics
        : FiqhData.searchTopics(_searchQuery, isArabic);

    if (_selectedCategoryId != 'all') {
      list = list.where((t) => t.categoryId == _selectedCategoryId).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = !_isEnglish;

    return Directionality(
      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              isArabic ? 'الفقه الإسلامي' : 'Islamic Fiqh',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    _isEnglish ? 'EN' : 'عربي',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C158),
                    ),
                  ),
                ),
                tooltip: _isEnglish ? 'Switch to Arabic (عربي)' : 'Switch to English (EN)',
                onPressed: _toggleLanguage,
              ),
              IconButton(
                icon: const Icon(Icons.auto_stories),
                tooltip: isArabic ? 'قراءة كتاب الفقه الميسر' : 'Read Full Book',
                onPressed: _openFullBookReader,
              ),
            ],
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5C158),
            labelColor: const Color(0xFFE5C158),
            unselectedLabelColor:
                theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                text: isArabic ? 'أبواب الكتاب (١٥)' : 'Book Chapters (15)',
              ),
              Tab(
                icon: const Icon(Icons.widgets_outlined, size: 20),
                text: isArabic ? 'الأدوات والدليل' : 'Tools & Guides',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChaptersTab(theme, isArabic),
            _buildGuidesAndToolsTab(theme, isArabic),
          ],
        ),
      ),
    ),
  );
}

  // ---------------------------------------------------------------------------
  // TAB 1: BOOK CHAPTERS (فصول وأبواب كتاب الفقه الميسر)
  // ---------------------------------------------------------------------------
  Widget _buildChaptersTab(ThemeData theme, bool isArabic) {
    final chapters = _filteredChapters;
    final categories =
        isArabic ? FiqhChaptersData.categoriesAr : FiqhChaptersData.categoriesEn;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reading progress banner
                _buildReadingProgressBanner(theme, isArabic),
                const SizedBox(height: 14),

                // Chapter Search Bar
                TextField(
                  controller: _chapterSearchController,
                  onChanged: (val) {
                    setState(() => _chapterSearchQuery = val.trim());
                  },
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'ابحث في أبواب الفقه الميسر...'
                        : 'Search book chapters...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _chapterSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _chapterSearchController.clear();
                              setState(() => _chapterSearchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSelected = _selectedChapterCategory == cat ||
                          (_selectedChapterCategory == 'الكل' && cat == 'All') ||
                          (_selectedChapterCategory == 'All' && cat == 'الكل');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          label: Text(cat),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : null,
                          ),
                          backgroundColor: theme.cardColor,
                          selectedColor: const Color(0xFFE5C158),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFE5C158)
                                  : theme.dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedChapterCategory = cat);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Chapters List
        if (chapters.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 54,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic ? 'لم نجد أبواباً مطابقة' : 'No matching chapters found',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = chapters[index];
                  return _buildChapterCard(chapter, theme, isArabic);
                },
                childCount: chapters.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReadingProgressBanner(ThemeData theme, bool isArabic) {
    final total = FiqhChaptersData.chapters.length;
    final read = _readChaptersCount;
    final progress = total > 0 ? (read / total) : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFFE5C158),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'تقدم قراءة كتاب الفقه الميسر'
                          : 'Al-Fiqh Al-Muyassar Progress',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'أتممت قراءة $read من أصل $total كتاباً وباباً'
                          : 'Completed $read of $total chapters',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFE5C158),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE5C158)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(FiqhChapter chapter, ThemeData theme, bool isArabic) {
    final isRead = _isChapterRead(chapter.id);
    final pageCount = chapter.bookEndPage - chapter.bookStartPage + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? const Color(0xFF0F766E).withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChapterReader(chapter),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Number + Category + Read toggle
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5C158).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${chapter.number}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5C158),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isArabic ? chapter.categoryAr : chapter.categoryEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isRead ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isRead ? const Color(0xFF0F766E) : theme.disabledColor,
                      size: 22,
                    ),
                    tooltip: isArabic
                        ? (isRead ? 'تمت القراءة' : 'تحديد كمقروء')
                        : (isRead ? 'Completed' : 'Mark as read'),
                    onPressed: () => _toggleChapterRead(chapter.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                isArabic ? chapter.titleAr : chapter.titleEn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic ? chapter.titleEn : chapter.titleAr,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),

              // Summary
              Text(
                isArabic ? chapter.summaryAr : chapter.summaryEn,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer: Pages + Time + Action
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories_outlined,
                    size: 14,
                    color: Color(0xFFE5C158),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isArabic
                        ? 'ص ${chapter.bookStartPage} - ${chapter.bookEndPage} ($pageCount ص)'
                        : 'pp. ${chapter.bookStartPage} - ${chapter.bookEndPage} ($pageCount p)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isArabic
                        ? '${chapter.readTimeMinutes} د'
                        : '${chapter.readTimeMinutes} min',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        isArabic ? 'قراءة الباب' : 'Read Chapter',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5C158),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isArabic ? Icons.chevron_left : Icons.chevron_right,
                        size: 16,
                        color: const Color(0xFFE5C158),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TOOLS & GUIDES (المسائل والأدوات التفاعلية)
  // ---------------------------------------------------------------------------
  Widget _buildGuidesAndToolsTab(ThemeData theme, bool isArabic) {
    final topics = _filteredTopics;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookHeroCard(theme, isArabic),
                const SizedBox(height: 18),
                Text(
                  isArabic ? 'أدوات فقهية تفاعلية' : 'Interactive Fiqh Tools',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolCard(
                        theme: theme,
                        title: isArabic ? 'مساعد سجود السهو' : 'Sujood as-Sahw',
                        subtitle: isArabic ? 'دليل الشك والنسيان' : 'Decision Wizard',
                        icon: Icons.flaky_rounded,
                        gradient: const [Color(0xFF0F766E), Color(0xFF134E4A)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SujoodSahwWizardScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToolCard(
                        theme: theme,
                        title: isArabic ? 'حاسبة الزكاة' : 'Zakah Calculator',
                        subtitle: isArabic ? 'نصاب الذهب والأموال' : 'Gold & Cash Nisab',
                        icon: Icons.calculate_outlined,
                        gradient: const [Color(0xFFB45309), Color(0xFF78350F)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ZakatCalculatorScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'ابحث في أبواب الفقه والمسائل الشائعة...'
                        : 'Search fiqh topics, rulings, and FAQs...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip(
                        id: 'all',
                        label: isArabic ? 'الكل' : 'All',
                        theme: theme,
                      ),
                      ...FiqhData.categories.map(
                        (c) => _buildCategoryChip(
                          id: c.id,
                          label: c.getTitle(isArabic),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Topics List or Empty state
        if (topics.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'لم نجد نتائج مطابقة لبحثك'
                          : 'No matching fiqh topics found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'جرب البحث بكلمات أخرى مثل: وضوء، سهو، قصر، صيام'
                          : 'Try searching for: wudu, sahw, travel, fasting, zakah',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topic = topics[index];
                  return _buildTopicCard(topic, theme, isArabic);
                },
                childCount: topics.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookHeroCard(ThemeData theme, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5C158).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openFullBookReader,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Color(0xFFE5C158),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5C158).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isArabic
                              ? 'الكتاب المعتمد • ٤٣٩ صفحة • ١٥ كتاباً'
                              : 'Canonical Book • 439 Pages • 15 Chapters',
                          style: const TextStyle(
                            color: Color(0xFFE5C158),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isArabic
                            ? 'كتاب الفقه الميسر'
                            : 'Al-Fiqh Al-Muyassar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isArabic
                            ? 'في ضوء الكتاب والسنة • قراءة كاملة مع الفهرس'
                            : 'In light of Quran & Sunnah • Full reader & TOC',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isArabic ? Icons.chevron_left : Icons.chevron_right,
                    color: const Color(0xFFE5C158),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : null,
        ),
        backgroundColor: theme.cardColor,
        selectedColor: const Color(0xFFE5C158),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFE5C158)
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategoryId = id;
          });
        },
      ),
    );
  }

  Widget _buildTopicCard(FiqhTopic topic, ThemeData theme, bool isArabic) {
    final category = FiqhData.getCategory(topic.categoryId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FiqhTopicDetailScreen(
                topic: topic,
                storage: _storage,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.getTitle(isArabic),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5C158),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isArabic
                        ? '${topic.readTimeMinutes} د'
                        : '${topic.readTimeMinutes} min',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                topic.getTitle(isArabic),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                topic.getSummary(isArabic),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    isArabic
                        ? '${topic.sections.length} فصول • ${topic.faqs.length} مسائل شائعة'
                        : '${topic.sections.length} sections • ${topic.faqs.length} FAQs',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isArabic ? Icons.chevron_left : Icons.chevron_right,
                    size: 16,
                    color: const Color(0xFFE5C158),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
