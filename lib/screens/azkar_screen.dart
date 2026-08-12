import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/azkar_data.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../widgets/share_card_dialog.dart';

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
  List<AzkarItem> _myAzkar = [];

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
      length: 11,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _initializeCounts();
    _loadMyAzkar();
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
    for (final list in AzkarData.allCategories) {
      for (var item in list) {
        _countsCache[item.id] = widget.storage.getInt(
          'azkar_count_${item.id}',
          defaultValue: item.count,
        );
      }
    }
  }

  void _loadMyAzkar() {
    final raw = widget.storage.getString('my_azkar_json', defaultValue: '[]');
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      _myAzkar = decoded.map((e) => AzkarItem(
        id: e['id'] as String,
        arabic: e['arabic'] as String,
        transliteration: e['transliteration'] as String? ?? '',
        translation: e['translation'] as String? ?? '',
        count: e['count'] as int? ?? 1,
        reference: e['reference'] as String? ?? '',
      )).toList();
    } catch (_) {
      _myAzkar = [];
    }
  }

  void _saveMyAzkar() {
    final data = _myAzkar.map((e) => {
      'id': e.id,
      'arabic': e.arabic,
      'transliteration': e.transliteration,
      'translation': e.translation,
      'count': e.count,
      'reference': e.reference,
    }).toList();
    widget.storage.setString('my_azkar_json', jsonEncode(data));
  }

  void _addMyAzkar() {
    final arabicCtrl = TextEditingController();
    final translitCtrl = TextEditingController();
    final translationCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(TranslationService.isArabic ? "أضف ذكر" : "Add Dhikr"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: arabicCtrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic ? "النص العربي" : "Arabic Text",
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: translitCtrl,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic ? "النطق (اختياري)" : "Transliteration (optional)",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: translationCtrl,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic ? "الترجمة (اختياري)" : "Translation (optional)",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic ? "عدد المرات" : "Count",
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(TranslationService.isArabic ? "إلغاء" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (arabicCtrl.text.trim().isEmpty) return;
              final id = 'my_${DateTime.now().millisecondsSinceEpoch}';
              setState(() {
                _myAzkar.add(AzkarItem(
                  id: id,
                  arabic: arabicCtrl.text.trim(),
                  transliteration: translitCtrl.text.trim(),
                  translation: translationCtrl.text.trim(),
                  count: int.tryParse(countCtrl.text) ?? 1,
                  reference: '',
                ));
              });
              _saveMyAzkar();
              Navigator.pop(ctx);
            },
            child: Text(TranslationService.isArabic ? "إضافة" : "Add"),
          ),
        ],
      ),
    );
  }

  void _deleteMyAzkar(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(TranslationService.isArabic ? "حذف الذكر" : "Delete Dhikr"),
        content: Text(TranslationService.isArabic
            ? "هل أنت متأكد من حذف هذا الذكر؟"
            : "Are you sure you want to delete this dhikr?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(TranslationService.isArabic ? "إلغاء" : "Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _myAzkar.removeAt(index);
              });
              _saveMyAzkar();
              Navigator.pop(ctx);
            },
            child: Text(TranslationService.isArabic ? "حذف" : "Delete"),
          ),
        ],
      ),
  void _editMyAzkar(int index) {
    if (index < 0 || index >= _myAzkar.length) return;
    final item = _myAzkar[index];

    final arabicCtrl = TextEditingController(text: item.arabic);
    final translitCtrl = TextEditingController(text: item.transliteration);
    final translationCtrl = TextEditingController(text: item.translation);
    final countCtrl = TextEditingController(text: item.count.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(TranslationService.isArabic ? "تعديل الذكر" : "Edit Dhikr"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: arabicCtrl,
                maxLines: 3,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic ? "نص الذكر" : "Arabic Text",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: translitCtrl,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic
                      ? "النطق اللاتيني (اختياري)"
                      : "Transliteration (Optional)",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: translationCtrl,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic
                      ? "الترجمة (اختياري)"
                      : "Translation (Optional)",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: TranslationService.isArabic ? "عدد المرات" : "Count",
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(TranslationService.isArabic ? "إلغاء" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (arabicCtrl.text.trim().isEmpty) return;
              setState(() {
                _myAzkar[index] = AzkarItem(
                  id: item.id,
                  arabic: arabicCtrl.text.trim(),
                  transliteration: translitCtrl.text.trim(),
                  translation: translationCtrl.text.trim(),
                  count: int.tryParse(countCtrl.text) ?? item.count,
                  reference: item.reference,
                );
              });
              _saveMyAzkar();
              Navigator.pop(ctx);
            },
            child: Text(TranslationService.isArabic ? "حفظ" : "Save"),
          ),
        ],
      ),
    );
  }

  void _showMyAzkarOptionsSheet(int index, AzkarItem item) {
    final isAr = TranslationService.isArabic;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "تعديل الذكر" : "Edit Dhikr"),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMyAzkar(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(isAr ? "حذف الذكر" : "Delete Dhikr"),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMyAzkar(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "مشاركة كصورة" : "Share as Image"),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => ShareCardDialog(
                      title: isAr ? 'ذكر مخصص' : 'Custom Dhikr',
                      categoryOrSource: isAr ? 'أذكاري' : 'My Azkar',
                      mainText: item.arabic,
                      translationText: item.translation.isNotEmpty ? item.translation : null,
                      footnote: '${item.count}x',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "مشاركة كنص" : "Share Text"),
                onTap: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${item.arabic}\n\n— ${isAr ? "أذكاري" : "My Azkar"} • Aya App',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "نسخ" : "Copy Text"),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: item.arabic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تم نسخ الذكر' : 'Dhikr copied to clipboard',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAzkarOptionsSheet(AzkarItem item) {
    final isAr = TranslationService.isArabic;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "مشاركة كصورة" : "Share as Image"),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => ShareCardDialog(
                      title: isAr ? 'ذكر ودعاء' : 'Dhikr',
                      categoryOrSource: item.category,
                      mainText: item.arabic,
                      translationText: item.translation.isNotEmpty ? item.translation : null,
                      footnote: '${item.count}x • ${item.reference}',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "مشاركة كنص" : "Share Text"),
                onTap: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${item.arabic}\n\n${item.translation}\n\n— ${item.category} • Aya App',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Color(0xFFE5C158)),
                title: Text(isAr ? "نسخ" : "Copy Text"),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: item.arabic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تم نسخ الذكر' : 'Dhikr copied to clipboard',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
                                .withValues(alpha: 0.7),
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
                const SizedBox(width: 8),
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
                                .withValues(alpha: 0.7),
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
                  ?.withValues(alpha: 0.5),
              isScrollable: true,
              physics: const BouncingScrollPhysics(),
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationService.t('morning')),
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.morning),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 0
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 
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
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.evening),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 1
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 
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
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.postPrayer),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 2
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 
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
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.daily),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 3
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 
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
                      const SizedBox(height: 2),
                      Text(
                        "99",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _tabController.index == 4
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 
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
                        TranslationService.isArabic ? "النوم" : "Sleep",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.sleepWaking),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _tabController.index == 5
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
                        TranslationService.isArabic ? "الصلاة" : "Salah",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.salahSpecific),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _tabController.index == 6
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
                        TranslationService.isArabic ? "أحداث" : "Life",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.lifeEvents),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _tabController.index == 7
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
                        TranslationService.isArabic ? "رقية" : "Protection",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.protectionRuqyah),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _tabController.index == 8
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
                        TranslationService.isArabic ? "توبة" : "Forgiveness",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTabProgress(AzkarData.forgivenessTawbah),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _tabController.index == 9
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
                        TranslationService.isArabic ? "أذكاري" : "My Azkar",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_myAzkar.length}",
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _tabController.index == 10
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
                _buildAzkarList(AzkarData.sleepWaking, theme),
                _buildAzkarList(AzkarData.salahSpecific, theme),
                _buildAzkarList(AzkarData.lifeEvents, theme),
                _buildAzkarList(AzkarData.protectionRuqyah, theme),
                _buildAzkarList(AzkarData.forgivenessTawbah, theme),
                _buildMyAzkarList(theme),
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
                icon: const Icon(
                  Icons.restore,
                  size: 16,
                  color: Color(0xFFE5C158),
                ),
                label: Text(
                  TranslationService.t('reset_counts'),
                  style: const TextStyle(
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

              return GestureDetector(
                onLongPress: () => _showAzkarOptionsSheet(item),
                child: Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : (Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.white)
                                .withValues(alpha: 0.04),
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
                                color: const Color(0xFFE5C158).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${TranslationService.t('read')} ${item.count} ${TranslationService.t('times')}",
                                style: const TextStyle(
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
                                style: const TextStyle(
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
                        const SizedBox(height: 16),
                        // Arabic text (Right Aligned)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            item.arabic,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              height: 1.8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if ((_showTransliteration &&
                                item.transliteration.isNotEmpty) ||
                            (_showTranslation &&
                                item.translation.isNotEmpty)) ...[
                          Divider(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 8),
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
                                  ?.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // English Translation
                        if (_showTranslation && item.translation.isNotEmpty) ...[
                          Text(
                            item.translation,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Reference citation
                        Text(
                          "${TranslationService.isArabic ? 'المصدر' : 'Source'}: ${item.reference}",
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
                              0.4,
                            ),
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
                      .withValues(alpha: 0.04),
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
                      color: const Color(0xFFE5C158).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "#${item.number}",
                      style: const TextStyle(
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
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5C158),
                  ),
                ),
                const SizedBox(height: 4),
                if (_showTransliteration)
                  Text(
                    item.transliteration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
                        0.6,
                      ),
                    ),
                  ),
                if (_showTranslation) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.translation,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
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

  Widget _buildMyAzkarList(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_myAzkar.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _myAzkar.clear());
                    _saveMyAzkar();
                  },
                  icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                  label: Text(
                    TranslationService.isArabic ? "مسح الكل" : "Clear All",
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else const SizedBox.shrink(),
              TextButton.icon(
                onPressed: _addMyAzkar,
                icon: const Icon(Icons.add_circle, size: 16, color: Color(0xFFE5C158)),
                label: Text(
                  TranslationService.isArabic ? "أضف ذكر" : "Add Dhikr",
                  style: const TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (_myAzkar.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_add_outlined, size: 64, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    TranslationService.isArabic ? "لا يوجد أذكار مخصصة" : "No custom adhkar yet",
                    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    TranslationService.isArabic ? "اضغط على '+' لإضافة ذكرك الخاص" : "Tap '+' to add your own dhikr",
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 85),
              itemCount: _myAzkar.length,
              itemBuilder: (context, index) {
                final item = _myAzkar[index];
                final currentCount = _countsCache[item.id] ?? item.count;
                final isDone = currentCount == 0;

                return GestureDetector(
                  onLongPress: () => _showMyAzkarOptionsSheet(index, item),
                  child: Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDone
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withValues(alpha: 0.04),
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
                                  color: const Color(0xFFE5C158).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${TranslationService.t('read')} ${item.count} ${TranslationService.t('times')}",
                                  style: const TextStyle(
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
                                  style: const TextStyle(
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
                          const SizedBox(height: 16),

                          // Arabic text (Right Aligned)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              item.arabic,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 22,
                                height: 1.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if ((_showTransliteration && item.transliteration.isNotEmpty) ||
                              (_showTranslation && item.translation.isNotEmpty)) ...[
                            Divider(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Transliteration
                          if (_showTransliteration && item.transliteration.isNotEmpty) ...[
                            Text(
                              item.transliteration,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Translation
                          if (_showTranslation && item.translation.isNotEmpty) ...[
                            Text(
                              item.translation,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Source Citation
                          Text(
                            "${TranslationService.isArabic ? 'المصدر' : 'Source'}: ${item.reference.isNotEmpty ? item.reference : (TranslationService.isArabic ? 'أذكار مخصصة' : 'Custom Dhikr')}",
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
    );
  }
}
