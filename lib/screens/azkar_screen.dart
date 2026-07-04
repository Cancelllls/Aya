import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/azkar_data.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';

class AzkarScreen extends StatefulWidget {
  final StorageService storage;
  final int initialTabIndex;

  const AzkarScreen({
    super.key,
    required this.storage,
    this.initialTabIndex = 0,
  });

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, int> _countsCache = {};
  bool _showTranslation = true;
  bool _showTransliteration = true;

  @override
  void initState() {
    super.initState();
    _showTranslation = widget.storage.getBool(
      'azkar_show_translation',
      defaultValue: !TranslationService.isArabic,
    );
    _showTransliteration = widget.storage.getBool(
      'azkar_show_transliteration',
      defaultValue: !TranslationService.isArabic,
    );
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _initializeCounts();
  }

  @override
  void didUpdateWidget(covariant AzkarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex ||
        _tabController.index != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeCounts() {
    // Set up standard counts for each item, loading from persistence if available
    for (var item in AzkarData.morning) {
      _countsCache[item.id] = widget.storage.getInt(
        'azkar_count_${item.id}',
        defaultValue: item.count,
      );
    }
    for (var item in AzkarData.evening) {
      _countsCache[item.id] = widget.storage.getInt(
        'azkar_count_${item.id}',
        defaultValue: item.count,
      );
    }
    for (var item in AzkarData.postPrayer) {
      _countsCache[item.id] = widget.storage.getInt(
        'azkar_count_${item.id}',
        defaultValue: item.count,
      );
    }
    for (var item in AzkarData.daily) {
      _countsCache[item.id] = widget.storage.getInt(
        'azkar_count_${item.id}',
        defaultValue: item.count,
      );
    }
  }

  void _decrementCount(String id, int originalMax) {
    final current = _countsCache[id] ?? originalMax;
    if (current > 0) {
      final newCount = current - 1;
      setState(() {
        _countsCache[id] = newCount;
      });
      widget.storage.setInt('azkar_count_$id', newCount);
      if (newCount == 0) {
        HapticFeedback.vibrate(); // Celebration vibration
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _resetAzkarTab(List<AzkarItem> items) {
    setState(() {
      for (var item in items) {
        _countsCache[item.id] = item.count;
        widget.storage.setInt('azkar_count_${item.id}', item.count);
      }
    });
    HapticFeedback.mediumImpact();
  }

  String _getTabProgress(List<AzkarItem> items) {
    int completed = 0;
    for (var item in items) {
      final current = _countsCache[item.id] ?? item.count;
      if (current == 0) {
        completed++;
      }
    }
    return "$completed/${items.length}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // Language Option Chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    TranslationService.isArabic
                        ? "إظهار الترجمة"
                        : "Show Translation",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _showTranslation
                          ? Colors.black
                          : (Theme.of(context).textTheme.bodyMedium?.color ??
                                    Colors.white)
                                .withOpacity(0.7),
                    ),
                  ),
                  selected: _showTranslation,
                  selectedColor: const Color(0xFFE5C158),
                  checkmarkColor: Colors.black,
                  backgroundColor: theme.cardColor,
                  onSelected: (val) {
                    setState(() {
                      _showTranslation = val;
                    });
                    widget.storage.setBool('azkar_show_translation', val);
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    TranslationService.isArabic
                        ? "النطق اللاتيني"
                        : "Transliteration",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _showTransliteration
                          ? Colors.black
                          : (Theme.of(context).textTheme.bodyMedium?.color ??
                                    Colors.white)
                                .withOpacity(0.7),
                    ),
                  ),
                  selected: _showTransliteration,
                  selectedColor: const Color(0xFFE5C158),
                  checkmarkColor: Colors.black,
                  backgroundColor: theme.cardColor,
                  onSelected: (val) {
                    setState(() {
                      _showTransliteration = val;
                    });
                    widget.storage.setBool('azkar_show_transliteration', val);
                  },
                ),
              ],
            ),
          ),
          // Category Tabs
          Container(
            height: 56,
            margin: const EdgeInsets.only(top: 4),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFE5C158),
              labelColor: const Color(0xFFE5C158),
              unselectedLabelColor: theme.textTheme.bodyMedium?.color
                  ?.withOpacity(0.5),
              isScrollable: true,
              physics: const BouncingScrollPhysics(),
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationService.t('morning')),
                      SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.morning),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 0
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.4,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationService.t('evening')),
                      SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.evening),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 1
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.4,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationService.t('post_prayer')),
                      SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.postPrayer),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 2
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.4,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationService.t('daily_duas')),
                      SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.daily),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 3
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.4,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        TranslationService.isArabic
                            ? "أسماء الله"
                            : "Allah's Names",
                      ),
                      SizedBox(height: 2),
                      Text(
                        "99",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 4
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.4,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildAzkarList(AzkarData.morning, theme),
                _buildAzkarList(AzkarData.evening, theme),
                _buildAzkarList(AzkarData.postPrayer, theme),
                _buildAzkarList(AzkarData.daily, theme),
                _buildNamesOfAllahGrid(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarList(List<AzkarItem> list, ThemeData theme) {
    return Column(
      children: [
        // Tab Actions (Reset button)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _resetAzkarTab(list),
                icon: Icon(Icons.restore, size: 16, color: Color(0xFFE5C158)),
                label: Text(
                  TranslationService.t('reset_counts'),
                  style: TextStyle(
                    color: Color(0xFFE5C158),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 85),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final currentCount = _countsCache[item.id] ?? item.count;
              final isDone = currentCount == 0;

              return Card(
                color: theme.cardColor,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDone
                        ? const Color(0xFF10B981).withOpacity(0.5)
                        : (Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.white)
                              .withOpacity(0.04),
                    width: isDone ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5C158).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${TranslationService.t('read')} ${item.count} ${TranslationService.t('times')}",
                              style: TextStyle(
                                color: Color(0xFFE5C158),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Interactive decrement counter
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE5C158),
                              foregroundColor: isDone
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(
                              isDone ? Icons.check : Icons.fingerprint,
                              size: 14,
                            ),
                            label: Text(
                              isDone
                                  ? TranslationService.t('done')
                                  : "$currentCount ${TranslationService.t('remaining')}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: isDone
                                ? null
                                : () => _decrementCount(item.id, item.count),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Arabic text (Right Aligned)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.arabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            height: 1.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      if ((_showTransliteration &&
                              item.transliteration.isNotEmpty) ||
                          (_showTranslation &&
                              item.translation.isNotEmpty)) ...[
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                        SizedBox(height: 8),
                      ],
                      // Transliteration (Italicized)
                      if (_showTransliteration &&
                          item.transliteration.isNotEmpty) ...[
                        Text(
                          item.transliteration,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                      // English Translation
                      if (_showTranslation && item.translation.isNotEmpty) ...[
                        Text(
                          item.translation,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                      // Reference citation
                      Text(
                        "${TranslationService.isArabic ? 'المصدر' : 'Source'}: ${item.reference}",
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNamesOfAllahGrid(ThemeData theme) {
    final list = NamesOfAllahData.names;
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 85),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          color: theme.cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
                      .withOpacity(0.04),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C158).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "#${item.number}",
                      style: TextStyle(
                        color: Color(0xFFE5C158),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  item.arabic,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5C158),
                  ),
                ),
                SizedBox(height: 4),
                if (_showTransliteration)
                  Text(
                    item.transliteration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                if (_showTranslation) ...[
                  SizedBox(height: 2),
                  Text(
                    item.translation,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}
