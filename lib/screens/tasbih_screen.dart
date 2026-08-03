import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';

class TasbihScreen extends StatefulWidget {
  final StorageService storage;

  const TasbihScreen({super.key, required this.storage});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  int _count = 0;
  int _target = 33;
  String _arabicText = 'سُبْحَانَ ٱللَّٰهِ';
  String _translationText = 'Glory be to Allah';
  String _currentDhikrName = 'SubhanAllah';

  List<Map<String, dynamic>> _presets = [];
  Timer? _debouncer;

  @override
  void initState() {
    super.initState();
    _presets = [
      {
        'name': 'SubhanAllah',
        'arabic': 'سُبْحَانَ ٱللَّٰهِ',
        'translation': 'Glory be to Allah',
        'target': 33,
      },
      {
        'name': 'Alhamdulillah',
        'arabic': 'ٱلْحَمْدُ لِلَّٰهِ',
        'translation': 'Praise be to Allah',
        'target': 33,
      },
      {
        'name': 'Allahu Akbar',
        'arabic': 'ٱللَّٰهُ أَكْبَرُ',
        'translation': 'Allah is the Greatest',
        'target': 34,
      },
      {
        'name': 'Astaghfirullah',
        'arabic': 'أَسْتَغْفِرُ ٱللَّٰهَ',
        'translation': 'I seek forgiveness from Allah',
        'target': 100,
      },
      {
        'name': 'La ilaha illallah',
        'arabic': 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
        'translation': 'There is no god but Allah',
        'target': 100,
      },
    ];
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );

    // Restore active dhikr and count
    final activeName = widget.storage.getString(
      'active_dhikr_name',
      defaultValue: 'SubhanAllah',
    );
    final activeItem = _presets.firstWhere(
      (p) => p['name'] == activeName,
      orElse: () => _presets[0],
    );
    _currentDhikrName = activeItem['name'];
    _arabicText = activeItem['arabic'] ?? '';
    _translationText = activeItem['translation'] ?? '';
    _target = activeItem['target'] ?? 33;
    _count = widget.storage.getInt(
      'tasbih_count_$_currentDhikrName',
      defaultValue: 0,
    );

    _updateWidgetData();
    _loadPresets();
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _loadPresets() async {
    final List<Map<String, dynamic>> standard = [
      {
        'name': 'SubhanAllah',
        'arabic': 'سُبْحَانَ ٱللَّٰهِ',
        'translation': 'Glory be to Allah',
        'target': 33,
      },
      {
        'name': 'Alhamdulillah',
        'arabic': 'ٱلْحَمْدُ لِلَّٰهِ',
        'translation': 'Praise be to Allah',
        'target': 33,
      },
      {
        'name': 'Allahu Akbar',
        'arabic': 'ٱللَّٰهُ أَكْبَرُ',
        'translation': 'Allah is the Greatest',
        'target': 34,
      },
      {
        'name': 'Astaghfirullah',
        'arabic': 'أَسْتَغْفِرُ ٱللَّٰهَ',
        'translation': 'I seek forgiveness from Allah',
        'target': 100,
      },
      {
        'name': 'La ilaha illallah',
        'arabic': 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
        'translation': 'There is no god but Allah',
        'target': 100,
      },
    ];

    final custom = await widget.storage.getCustomDhikrs();
    if (mounted) {
      setState(() {
        _presets = [...standard, ...custom];
        // Re-align selection if it matches one of the newly loaded custom presets
        final activeName = widget.storage.getString(
          'active_dhikr_name',
          defaultValue: 'SubhanAllah',
        );
        final activeItem = _presets.firstWhere(
          (p) => p['name'] == activeName,
          orElse: () => _presets[0],
        );
        _currentDhikrName = activeItem['name'];
        _arabicText = activeItem['arabic'] ?? '';
        _translationText = activeItem['translation'] ?? '';
        _target = activeItem['target'] ?? 33;
        _count = widget.storage.getInt(
          'tasbih_count_$_currentDhikrName',
          defaultValue: 0,
        );
      });
    }
  }

  void _selectDhikr(Map<String, dynamic> item) {
    _debouncer?.cancel();
    // Save current count immediately before switching
    widget.storage.setInt('tasbih_count_$_currentDhikrName', _count);

    setState(() {
      _currentDhikrName = item['name'];
      _arabicText = item['arabic'] ?? '';
      _translationText = item['translation'] ?? '';
      _target = item['target'] ?? 33;
      _count = widget.storage.getInt(
        'tasbih_count_$_currentDhikrName',
        defaultValue: 0,
      );
    });

    widget.storage.setString('active_dhikr_name', _currentDhikrName);
    widget.storage.setInt('tasbih_count_$_currentDhikrName', _count);
    _updateWidgetData();

    HapticFeedback.mediumImpact();
  }

  void _saveCountDebounced() {
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 500), () {
      widget.storage.setInt('tasbih_count_$_currentDhikrName', _count);
      _updateWidgetData();
    });
  }

  void _increment() {
    _bounceController
        .forward(from: 0.0)
        .then((_) => _bounceController.reverse());
    setState(() {
      _count++;
    });
    _saveCountDebounced();

    if (_count == _target) {
      HapticFeedback.vibrate(); // Long vibrate on target reached
      _showTargetReachedNotification();
    } else {
      HapticFeedback.lightImpact(); // Soft click feel
    }
  }

  void _reset() {
    unawaited(
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            TranslationService.isArabic
                ? "إعادة تعيين العداد؟"
                : "Reset Counter?",
            style: const TextStyle(
              color: Color(0xFFE5C158),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            TranslationService.isArabic
                ? "هل أنت متأكد من رغبتك في تصفير عداد الذكر الحالي؟"
                : "Are you sure you want to reset the counter for this Dhikr?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                TranslationService.t('cancel'),
                style: TextStyle(
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.white)
                          .withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                // Save to daily history before resetting
                if (_count > 0) {
                  final today = DateTime.now().toIso8601String().substring(0, 10);
                  final key = 'tasbih_history_$today';
                  final current = jsonDecode(
                    widget.storage.getString(key, defaultValue: '[]'),
                  );
                  current.add({
                    'dhikr': _arabicText,
                    'count': _count,
                    'time': DateTime.now().toIso8601String(),
                  });
                  widget.storage.setString(key, jsonEncode(current));
                }
                setState(() {
                  _count = 0;
                });
                HapticFeedback.heavyImpact();
                widget.storage.setInt('tasbih_count_$_currentDhikrName', 0);
                _updateWidgetData();
              },
              child: Text(TranslationService.isArabic ? "تصفير" : "Reset"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWidgetData() async {
    await widget.storage.setString('widget_tasbih_dhikr', _arabicText);
    await widget.storage.setInt('widget_tasbih_count', _count);
    await widget.storage.setInt('widget_tasbih_target', _target);
    try {
      const platform = MethodChannel('com.quran.aya/system');
      await platform.invokeMethod('updateWidget');
    } catch (_) {}
  }

  void _showTargetReachedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationService.isArabic
              ? 'تم الوصول للهدف $_target لـ $_currentDhikrName!'
              : 'Target of $_target reached for $_currentDhikrName!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddCustomDhikrDialog() {
    final nameController = TextEditingController();
    final arabicController = TextEditingController();
    final translationController = TextEditingController();
    final targetController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            TranslationService.t('add_custom_dhikr'),
            style: const TextStyle(
              color: Color(0xFFE5C158),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: TranslationService.t('dhikr_name'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: arabicController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: TranslationService.t('arabic_script'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: translationController,
                  decoration: InputDecoration(
                    labelText: TranslationService.isArabic
                        ? 'الترجمة (اختياري)'
                        : 'Translation (Optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: TranslationService.t('target_count'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                TranslationService.t('cancel'),
                style: TextStyle(
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.white)
                          .withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5C158),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final targetVal = int.tryParse(targetController.text) ?? 100;
                if (name.isNotEmpty) {
                  await widget.storage.addCustomDhikr(
                    name,
                    arabicController.text.trim(),
                    translationController.text.trim(),
                    targetVal,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadPresets();
                }
              },
              child: Text(TranslationService.t('add')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (_count / _target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          TranslationService.t('digital_tasbih'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adapt layout for mobile sizes
          final isCompact = constraints.maxHeight < 550;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Preset List (Horizontal selection)
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _presets.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _presets.length) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8.0),
                            child: ActionChip(
                              avatar: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFFE5C158),
                              ),
                              label: Text(TranslationService.t('custom')),
                              backgroundColor: theme.cardColor,
                              onPressed: _showAddCustomDhikrDialog,
                            ),
                          );
                        }

                        final preset = _presets[index];
                        final isSelected = preset['name'] == _currentDhikrName;

                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8.0),
                          child: ChoiceChip(
                            selectedColor: const Color(
                              0xFFE5C158,
                            ).withValues(alpha: 0.2),
                            disabledColor: theme.cardColor,
                            label: Text(
                              preset['name'],
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFE5C158)
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) _selectDhikr(preset);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 40),

                  // Active Dhikr Texts
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 90,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _arabicText,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 26,
                            color: Color(0xFFE5C158),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _translationText,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 40),

                  // Big Click Area
                  GestureDetector(
                    onTap: _increment,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress Circle Ring
                            SizedBox(
                              width: 250,
                              height: 250,
                              child: CircularProgressIndicator(
                                value: progressPercent,
                                strokeWidth: 8,
                                backgroundColor:
                                    (Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            Colors.white)
                                        .withValues(alpha: 0.04),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE5C158),
                                ),
                              ),
                            ),
                            // Inner Click Button
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _count.toString(),
                                    style: const TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Target: $_target",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 40),

                  // Reset Action Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                                    Colors.white)
                                .withValues(alpha: 0.24),
                      ),
                      foregroundColor: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(TranslationService.t('reset_count')),
                    onPressed: _reset,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
