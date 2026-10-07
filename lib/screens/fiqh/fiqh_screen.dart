import 'package:flutter/material.dart';
import '../../data/fiqh_data.dart';
import '../../models/fiqh_model.dart';
import '../../services/translation_service.dart';
import 'fiqh_topic_detail_screen.dart';
import 'sujood_sahw_wizard_screen.dart';
import 'zakat_calculator_screen.dart';

class FiqhScreen extends StatefulWidget {
  const FiqhScreen({super.key});

  @override
  State<FiqhScreen> createState() => _FiqhScreenState();
}

class _FiqhScreenState extends State<FiqhScreen> {
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FiqhTopic> get _filteredTopics {
    final isArabic = TranslationService.isArabic;
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
    final isArabic = TranslationService.isArabic;
    final topics = _filteredTopics;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? 'الفقه الإسلامي' : 'Islamic Fiqh',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Interactive Tools Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFE5C158), size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
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
      padding: const EdgeInsetsDirectional.only(end: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategoryId = id;
          });
        },
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(FiqhTopic topic, ThemeData theme, bool isArabic) {
    final category = FiqhData.categories.firstWhere(
      (c) => c.id == topic.categoryId,
      orElse: () => FiqhData.categories.first,
    );

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
              builder: (_) => FiqhTopicDetailScreen(topic: topic),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isArabic ? 'قراءة الموضوع' : 'Read Topic',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isArabic ? Icons.chevron_left : Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.primary,
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
