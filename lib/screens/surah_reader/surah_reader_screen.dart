import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/quran_models.dart';
import '../../services/api_service.dart';
import '../../services/local_quran_service.dart';
import '../../models/offline_surahs.dart';
import '../../services/reciters_cache_service.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/audio_manager.dart';
import '../../services/tajweed_service.dart';
import '../../widgets/share_ayah_dialog.dart';

part 'surah_reader_audio.dart';
part 'surah_reader_bookmarks.dart';
part 'surah_reader_ui.dart';
part 'surah_reader_autoscroll.dart';
part 'surah_reader_navigation.dart';
part 'surah_reader_data.dart';
part 'surah_reader_actions.dart';

class SurahReaderScreen extends StatefulWidget {
  final Surah surah;
  final StorageService storage;
  final int? initialAyahNumber;
  final bool isInsidePager;
  final bool hideAppBar;
  final String? readingMode;
  final String? quranScriptType;
  final double? fontSizeMultiplier;
  final VoidCallback? onGoToNext;
  final VoidCallback? onGoToPrev;
  /// External hifz notifier from the pager — when provided, the reader
  /// mirrors this notifier instead of its own internal one.
  final ValueNotifier<bool>? hifzNotifier;

  const SurahReaderScreen({
    super.key,
    required this.surah,
    required this.storage,
    this.initialAyahNumber,
    this.isInsidePager = false,
    this.hideAppBar = false,
    this.readingMode,
    this.quranScriptType,
    this.fontSizeMultiplier,
    this.onGoToNext,
    this.onGoToPrev,
    this.hifzNotifier,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen>
    with SingleTickerProviderStateMixin {
  late Surah _currentSurah;
  List<Surah> _allSurahs = [];
  bool _swipeSurahNavigation = true;

  List<Ayah> _ayahList = [];
  bool _isLoading = true;
  int _slideDirection = 1;
  double _fontSizeMultiplier = 1.0;
  double _baseFontSizeMultiplier = 1.0;
  String _readingMode =
      'translation'; // 'translation', 'arabic_only', 'tafseer', 'continuous'
  String _quranScriptType = 'hafs';
  bool _isBookmarked = false;
  int? _bookmarkedAyahNumber;
  int? _lastScrolledAyah;
  // ValueNotifiers so toggling hifz/masking never remounts the ListView.
  final ValueNotifier<bool> _hifzNotifier = ValueNotifier(false);
  final ValueNotifier<Set<int>> _unmaskedNotifier = ValueNotifier({});
  // Convenience getters so existing code compiles unchanged.
  bool get _isHifzMode => _hifzNotifier.value;
  Set<int> get _unmaskedAyahs => _unmaskedNotifier.value;
  bool _isTajweedEnabled = true;

  Ticker? _ticker;
  double _scrollSpeed = 1.0;
  int _speedLevel = 2;
  bool _isAutoScrolling = false;
  Timer? _resumeTimer;
  bool _isAutoScrollPaused = false;
  bool _hideContinuousBorders = false;
  bool _tafsirLoaded = false;
  Timer? _savePositionTimer;

  bool _isLoadingReciters = false;
  List<dynamic> _dynamicReciters = [];
  final Set<int> _selectedAyahs = {};

  // ── Cached computed values ──────────────────────────────────
  /// Cached selected Quran font — read once from storage, never per-ayah.
  String _selectedFont = 'font-amiri';
  /// Cached Hizb/Juz range string for AppBar — recomputed only on ayah load.
  String _hizbRangeText = '';

  final AutoScrollController _scrollController = AutoScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  final Map<int, GlobalKey> _pageKeys = {};
  final Map<int, List<GestureRecognizer>> _pageRecognizers = {};
  double? _horizontalDragStartX;
  int _scrollToAyahSequence = 0;

  @override
  void initState() {
    super.initState();
    final bool immersive = widget.storage.getBool(
      'setting_immersive_reader',
      defaultValue: false,
    );
    if (immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    _currentSurah = widget.surah;
    // Use pager-provided overrides if available, otherwise read from storage
    _readingMode = widget.readingMode ??
        widget.storage.getString('reading_mode', defaultValue: 'continuous');
    // Legacy: if readingMode was persisted as 'hifz', ignore it (hifz is now
    // a separate notifier, not a reading mode).
    if (_readingMode == 'hifz') {
      _readingMode = 'continuous';
    }
    // Wire external hifz notifier from pager (if provided).
    if (widget.hifzNotifier != null) {
      // Sync initial value
      _hifzNotifier.value = widget.hifzNotifier!.value;
      // Mirror any future changes
      widget.hifzNotifier!.addListener(_onExternalHifzChanged);
    }
    _quranScriptType = widget.quranScriptType ??
        widget.storage.getString('quran_script_type', defaultValue: 'hafs');
    _hideContinuousBorders = widget.storage.getBool(
      'setting_hide_continuous_borders',
      defaultValue: false,
    );
    _swipeSurahNavigation = widget.storage.getBool(
      'swipe_surah_navigation',
      defaultValue: true,
    );
    _fontSizeMultiplier = widget.fontSizeMultiplier ??
        widget.storage.getDouble('setting_quran_font_size_multiplier', defaultValue: 1.0);
    _isTajweedEnabled = widget.storage.getBool(
      'tajweed_enabled',
      defaultValue: true,
    );
    // Cache font once — avoids repeated SharedPrefs reads per-ayah (fix #4).
    _selectedFont = widget.storage.getString(
      'quran_font',
      defaultValue: 'font-amiri',
    );
    _loadAyahs();
    _fetchDynamicReciters(_quranScriptType);
    _checkBookmarkStatus();
    _loadAllSurahs();
    AudioManager.instance.playState.addListener(_onPlayStateChanged);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    AudioManager.instance.playState.removeListener(_onPlayStateChanged);
    widget.hifzNotifier?.removeListener(_onExternalHifzChanged);
    _savePositionTimer?.cancel();
    _ticker?.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    for (var recs in _pageRecognizers.values) {
      for (var r in recs) {
        r.dispose();
      }
    }
    _pageRecognizers.clear();
    _hifzNotifier.dispose();
    _unmaskedNotifier.dispose();
    super.dispose();
  }

  TextStyle _getArabicTextStyle(
    double fontSize, {
    double? height,
    Color? color,
    FontWeight? fontWeight,
    Color? backgroundColor,
  }) {
    // Use cached font — never read SharedPrefs per-ayah (fix #4).
    if (_selectedFont == 'font-scheherazade') {
      return TextStyle(
        fontFamily: 'Scheherazade New',
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        backgroundColor: backgroundColor,
      );
    }
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
      backgroundColor: backgroundColor,
    );
  }

  /// Returns the cached Hizb/Juz range string (fix #5).
  /// Call [_computeHizbRangeText] after loading ayahs to refresh.
  String _getHizbRangeText() => _hizbRangeText;

  void _computeHizbRangeText() {
    if (_ayahList.isEmpty) {
      _hizbRangeText =
          "${TranslationService.t('juz')} ${_currentSurah.startingJuz} • "
          "${TranslationService.t('hizb')} ${_currentSurah.startingHizb}";
      return;
    }
    final uniqueJuz = _ayahList.map((e) => e.juz).toSet().toList()..sort();
    final uniqueHizb = _ayahList.map((e) => e.hizb).toSet().toList()..sort();

    final String juzText = uniqueJuz.length == 1
        ? "${TranslationService.t('juz')} ${uniqueJuz.first}"
        : "${TranslationService.t('juz')} ${uniqueJuz.first}-${uniqueJuz.last}";

    final String hizbText = uniqueHizb.length == 1
        ? "${TranslationService.t('hizb')} ${uniqueHizb.first}"
        : "${TranslationService.t('hizb')} ${uniqueHizb.first}-${uniqueHizb.last}";

    _hizbRangeText = "$juzText • $hizbText";
  }

  void _toggleHifzMode() {
    // Toggle via ValueNotifier ONLY — zero setState, zero rebuilds.
    final next = !_hifzNotifier.value;
    _hifzNotifier.value = next;
    _unmaskedNotifier.value = {};
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next
              ? (TranslationService.isArabic
                  ? "تم تفعيل وضع التسميع والحفظ (انقر على الآية لإظهارها)"
                  : "Hifz Mode enabled (tap verse to reveal)")
              : (TranslationService.isArabic
                  ? "تم إيقاف وضع التسميع والحفظ"
                  : "Hifz Mode disabled"),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFE5C158),
      ),
    );
  }

  /// Mirrors changes from the pager's external hifzNotifier.
  void _onExternalHifzChanged() {
    if (widget.hifzNotifier == null) return;
    _hifzNotifier.value = widget.hifzNotifier!.value;
    _unmaskedNotifier.value = {}; // reset revealed set on each toggle
  }

  void _toggleAyahMasking(int ayahNum) {
    if (!_isHifzMode) return;
    // Mutate via ValueNotifier — no setState, preserves scroll position.
    final current = Set<int>.from(_unmaskedNotifier.value);
    if (current.contains(ayahNum)) {
      current.remove(ayahNum);
    } else {
      current.add(ayahNum);
    }
    _unmaskedNotifier.value = current;
  }

  void _toggleTajweedMode() {
    setState(() {
      _isTajweedEnabled = !_isTajweedEnabled;
    });
    widget.storage.setBool('setting_tajweed_enabled', _isTajweedEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTajweedEnabled
              ? (TranslationService.isArabic ? 'تم تفعيل التجويد الملون' : 'Tajweed color highlighting enabled')
              : (TranslationService.isArabic ? 'تم إيقاف التجويد الملون' : 'Tajweed color highlighting disabled'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _navigateToSurahWithAnimation(int nextSurahNum, bool goingForward) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SurahReaderScreen(
              surah: _allSurahs.isNotEmpty
                  ? _allSurahs[nextSurahNum - 1]
                  : Surah(
                      number: nextSurahNum,
                      name: allOfflineSurahs[nextSurahNum - 1].name,
                      englishName:
                          allOfflineSurahs[nextSurahNum - 1].englishName,
                      englishNameTranslation: '',
                      numberOfAyahs:
                          allOfflineSurahs[nextSurahNum - 1].numberOfAyahs,
                      revelationType: '',
                    ),
              storage: widget.storage,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final begin = Offset(goingForward ? 0.3 : -0.3, 0.0);
          return SlideTransition(
            position: Tween(begin: begin, end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation),
            child: FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.storage.isDarkMode();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.hideAppBar ? null : AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSurah.englishName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "${_currentSurah.name} • ${_getHizbRangeText()}",
              style: TextStyle(
                fontSize: 11,
                color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          // Hifz icon — uses ValueListenableBuilder so ONLY the icon
          // repaints when toggled; the rest of the screen stays frozen.
          ValueListenableBuilder<bool>(
            valueListenable: _hifzNotifier,
            builder: (context, isHifz, _) => IconButton(
              icon: Icon(
                isHifz ? Icons.school : Icons.school_outlined,
                color: isHifz
                    ? const Color(0xFFE5C158)
                    : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withValues(alpha: 0.7),
              ),
              onPressed: _toggleHifzMode,
              tooltip: TranslationService.isArabic ? "وضع التسميع والحفظ" : "Hifz / Memorization Mode",
            ),
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFFE5C158),
            ),
            onPressed: _toggleBookmark,
            tooltip: 'Bookmark Surah',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.chrome_reader_mode,
              color:
                  (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
            ),
            tooltip: TranslationService.isArabic
                ? "تغيير نمط العرض"
                : "Change View Mode",
            color: theme.cardColor,
            onSelected: (mode) async {
              setState(() {
                _readingMode = mode;
                widget.storage.setString('reading_mode', mode);
              });
              if (mode == 'tafseer') {
                await _ensureTafsirLoaded();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'continuous',
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: _readingMode == 'continuous'
                          ? const Color(0xFFE5C158)
                          : Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic
                          ? "المصحف المتصل"
                          : "Continuous",
                      style: TextStyle(
                        color: _readingMode == 'continuous'
                            ? const Color(0xFFE5C158)
                            : null,
                        fontWeight: _readingMode == 'continuous'
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'arabic_only',
                child: Row(
                  children: [
                    Icon(
                      Icons.text_format,
                      color: _readingMode == 'arabic_only'
                          ? const Color(0xFFE5C158)
                          : Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic
                          ? "العربية فقط"
                          : "Arabic Only",
                      style: TextStyle(
                        color: _readingMode == 'arabic_only'
                            ? const Color(0xFFE5C158)
                            : null,
                        fontWeight: _readingMode == 'arabic_only'
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'translation',
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      color: _readingMode == 'translation'
                          ? const Color(0xFFE5C158)
                          : Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic ? "الترجمة" : "Translation",
                      style: TextStyle(
                        color: _readingMode == 'translation'
                            ? const Color(0xFFE5C158)
                            : null,
                        fontWeight: _readingMode == 'translation'
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tafseer',
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _readingMode == 'tafseer'
                          ? const Color(0xFFE5C158)
                          : Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic ? "التفسير" : "Tafsir",
                      style: TextStyle(
                        color: _readingMode == 'tafseer'
                            ? const Color(0xFFE5C158)
                            : null,
                        fontWeight: _readingMode == 'tafseer'
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.cardColor,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => StatefulBuilder(
                  builder: (context, setModalState) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.85,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (context, scrollController) => SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                            TranslationService.t('reading_settings'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ── Tajweed toggle — most requested, at the TOP ──
                          Container(
                            decoration: BoxDecoration(
                              color: _isTajweedEnabled
                                  ? const Color(0xFF26A69A).withValues(alpha: 0.12)
                                  : theme.dividerColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isTajweedEnabled
                                    ? const Color(0xFF26A69A).withValues(alpha: 0.4)
                                    : theme.dividerColor,
                                width: 1,
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              activeColor: const Color(0xFF26A69A),
                              secondary: Icon(
                                Icons.palette_outlined,
                                color: _isTajweedEnabled
                                    ? const Color(0xFF26A69A)
                                    : theme.disabledColor,
                              ),
                              title: Text(
                                TranslationService.isArabic
                                    ? 'تلوين أحكام التجويد'
                                    : 'Color Tajweed Highlights',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                TranslationService.isArabic
                                    ? 'تلوين أحرف التجويد (غنة، قلقلة، مد...)'
                                    : 'Highlight Ghunnah, Qalqalah, Madd…',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                              value: _isTajweedEnabled,
                              onChanged: (val) {
                                setModalState(() => _isTajweedEnabled = val);
                                _toggleTajweedMode();
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationService.isArabic
                                    ? 'الرواية'
                                    : "Qira'ah",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                              ),

                              SizedBox(
                                width: 170,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _quranScriptType,
                                  dropdownColor: theme.cardColor,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFFE5C158),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'hafs',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'حفص عن عاصم'
                                            : 'Hafs A\'n Assem',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'warsh',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'ورش عن نافع'
                                            : 'Warsh A\'n Nafi\'',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'qaloon',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'قالون عن نافع'
                                            : 'Qalun A\'n Nafi\'',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'shuba',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'شعبة عن عاصم'
                                            : 'Shuba A\'n Assem',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'duri',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'الدوري عن أبي عمرو'
                                            : 'Al-Duri A\'n Abi Amr',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'susi',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'السوسي عن أبي عمرو'
                                            : 'As-Susi A\'n Abi Amr',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'bazzi',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'البزي عن ابن كثير'
                                            : 'Al-Bazzi A\'n Ibn Katheer',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'qunbul',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'قنبل عن ابن كثير'
                                            : 'Qunbul A\'n Ibn Katheer',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'hisham',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'هشام عن ابن عامر'
                                            : 'Hisham A\'n Ibn Amir',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ibn-dhakwan',
                                      child: Text(
                                        TranslationService.isArabic
                                            ? 'ابن ذكوان عن ابن عامر'
                                            : 'Ibn Dhakwan A\'n Ibn Amir',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setModalState(() {
                                        _quranScriptType = newValue;
                                      });
                                      setState(() {
                                        _quranScriptType = newValue;
                                      });
                                      widget.storage.setString(
                                        'quran_script_type',
                                        newValue,
                                      );

                                      // Switch reciter
                                      if (newValue == 'hafs') {
                                        widget.storage.setString(
                                          'default_reciter',
                                          'ar.alafasy',
                                        );
                                      }

                                      _fetchDynamicReciters(
                                        newValue,
                                        modalSetState: setModalState,
                                      );
                                      _loadAyahs();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationService.isArabic
                                    ? 'القارئ'
                                    : 'Reciter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                              ),
                              if (_isLoadingReciters)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE5C158),
                                  ),
                                )
                              else if (_quranScriptType == 'hafs')
                                SizedBox(
                                  width: 170,
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value:
                                        widget.storage.getString(
                                          'default_reciter',
                                          defaultValue: 'ar.alafasy',
                                        ),
                                    dropdownColor: theme.cardColor,
                                    underline: const SizedBox(),
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFFE5C158),
                                    ),
                                    items:
                                        (List.from(availableReciters)..sort(
                                              (a, b) =>
                                                  TranslationService.isArabic
                                                  ? a.nameAr.compareTo(b.nameAr)
                                                  : a.nameEn.compareTo(
                                                      b.nameEn,
                                                    ),
                                            ))
                                            .map<DropdownMenuItem<String>>((r) {
                                              return DropdownMenuItem(
                                                value: r.id,
                                                child: Text(
                                                  TranslationService.isArabic
                                                      ? r.nameAr
                                                      : r.nameEn,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            })
                                            .toList(),
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                          return (List.from(
                                                availableReciters,
                                              )..sort(
                                                (a, b) =>
                                                    TranslationService.isArabic
                                                    ? a.nameAr.compareTo(
                                                        b.nameAr,
                                                      )
                                                    : a.nameEn.compareTo(
                                                        b.nameEn,
                                                      ),
                                              ))
                                              .map((r) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    TranslationService.isArabic
                                                        ? 8
                                                        : -8,
                                                    0,
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .centerStart,
                                                    child: Text(
                                                      TranslationService
                                                              .isArabic
                                                          ? r.nameAr
                                                          : r.nameEn,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                );
                                              })
                                              .toList();
                                        },
                                    onChanged: (String? val) {
                                      if (val != null) {
                                        AudioManager.instance.stop();
                                        widget.storage.setString(
                                          'default_reciter',
                                          val,
                                        );

                                        setModalState(() {});
                                        setState(() {});

                                        // Audio stopped on reciter change
                                      }
                                    },
                                  ),
                                )
                              else
                                SizedBox(
                                  width: 170,
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: (() {
                                      final current =
                                          widget.storage.getString(
                                            'default_reciter',
                                          );
                                      if (!current.startsWith(
                                            'mp3quran_server_',
                                          ) ||
                                          _dynamicReciters.isEmpty)
                                        return null;
                                      final serverCurrent = current.substring(
                                        16,
                                      );
                                      final match = _dynamicReciters.where((r) {
                                        final moshaf = r['moshaf'] as List;
                                        if (moshaf.isEmpty) return false;
                                        return (moshaf[0]['server']
                                                as String) ==
                                            serverCurrent;
                                      }).toList();
                                      return match.isNotEmpty
                                          ? serverCurrent
                                          : null;
                                    })(),
                                    dropdownColor: theme.cardColor,
                                    underline: const SizedBox(),
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFFE5C158),
                                    ),
                                    items: _dynamicReciters
                                        .map((r) {
                                          final moshaf = r['moshaf'] as List;
                                          if (moshaf.isEmpty) return null;
                                          final server =
                                              moshaf[0]['server'] as String;
                                          return DropdownMenuItem(
                                            value: server,
                                            child: Text(
                                              r['name'] as String,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        })
                                        .whereType<DropdownMenuItem<String>>()
                                        .toList(),
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                          return _dynamicReciters.map((r) {
                                            final moshaf = r['moshaf'] as List;
                                            if (moshaf.isEmpty)
                                              return const SizedBox.shrink();
                                            return Transform.translate(
                                              offset: Offset(
                                                TranslationService.isArabic
                                                    ? 8
                                                    : -8,
                                                0,
                                              ),
                                              child: Align(
                                                alignment: AlignmentDirectional
                                                    .centerStart,
                                                child: Text(
                                                  r['name'] as String,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                    onChanged: (String? val) async {
                                      if (val != null) {
                                        AudioManager.instance.stop();
                                        widget.storage.setString(
                                          'default_reciter',
                                          'mp3quran_server_$val',
                                        );

                                        setModalState(() {});
                                        setState(() {});

                                        // Audio stopped on reciter change
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationService.t('arabic_font_size'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Color(0xFFE5C158),
                                    ),
                                    onPressed: () {
                                      _changeFontSize(-0.1);
                                      setModalState(() {});
                                    },
                                  ),
                                  Text(
                                    "${(_fontSizeMultiplier * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFFE5C158),
                                    ),
                                    onPressed: () {
                                      _changeFontSize(0.1);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: widget.isInsidePager
            ? null
            : (details) {
                _horizontalDragStartX = details.globalPosition.dx;
              },
        onHorizontalDragEnd: widget.isInsidePager
            ? null
            : (details) {
                if (!_swipeSurahNavigation) return;
                if (_horizontalDragStartX != null) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (_horizontalDragStartX! < 40 ||
                      _horizontalDragStartX! > screenWidth - 40) {
                    _horizontalDragStartX = null;
                    return;
                  }
                }
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! > 150) {
                  _goToNextSurah();
                } else if (details.primaryVelocity! < -150) {
                  _goToPrevSurah();
                }
                _horizontalDragStartX = null;
              },
        onScaleStart: (details) {
          _baseFontSizeMultiplier = _fontSizeMultiplier;
        },
        onScaleUpdate: (details) {
          if (details.scale == 1.0) return;
          setState(() {
            double scaleDiff = details.scale - 1.0;
            double adjustedScale = 1.0 + (scaleDiff * 2.5);
            _fontSizeMultiplier = (_baseFontSizeMultiplier * adjustedScale)
                .clamp(0.5, 3.0);
          });
        },
        onScaleEnd: (details) {
          widget.storage.setDouble(
            'setting_quran_font_size_multiplier',
            _fontSizeMultiplier,
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: Offset(_slideDirection * 0.3, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              ),
            );
          },
          child: _isLoading
              ? const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(color: Color(0xFFE5C158)),
                )
              : Column(
                  key: ValueKey(_currentSurah.number),
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<AudioPlayState>(
                        valueListenable: AudioManager.instance.playState,
                        builder: (context, playState, child) {
                          return Stack(
                            children: [
                              Column(
                                children: [
                                  // Multi-selection action bar
                                  if (_selectedAyahs.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5C158),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.black),
                                            onPressed: _clearAyahSelection,
                                            tooltip: TranslationService.isArabic ? "إلغاء التحديد" : "Clear Selection",
                                          ),
                                          Text(
                                            TranslationService.isArabic
                                                ? "${_selectedAyahs.length} آيات محددة"
                                                : "${_selectedAyahs.length} Selected",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Colors.black),
                                            onPressed: _copySelectedAyahsText,
                                            tooltip: TranslationService.isArabic ? "نسخ" : "Copy",
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share, color: Colors.black),
                                            onPressed: _shareSelectedAyahsText,
                                            tooltip: TranslationService.isArabic ? "مشاركة" : "Share",
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (playState.title.isNotEmpty)
                                    _buildTopMiniPlayer(
                                      theme,
                                      isDark,
                                      playState,
                                    ),
                                  if (_readingMode != 'continuous' &&
                                      playState.title.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      color: theme.cardColor,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.volume_up,
                                            color: Color(0xFFE5C158),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            TranslationService.t(
                                              'listen_full_surah',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Spacer(),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE5C158,
                                              ),
                                              foregroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            icon:
                                                (playState.isLoading &&
                                                    playState.surahNum ==
                                                        _currentSurah.number &&
                                                    playState.ayahNum == 0)
                                                ? const SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.black,
                                                        ),
                                                  )
                                                : (playState.isPlaying &&
                                                      playState.surahNum ==
                                                          _currentSurah.number)
                                                ? const Icon(
                                                    Icons.pause,
                                                    size: 16,
                                                  )
                                                : const Icon(
                                                    Icons.play_arrow,
                                                    size: 16,
                                                  ),
                                            label: Text(
                                              (playState.isLoading &&
                                                      playState.surahNum ==
                                                          _currentSurah
                                                              .number &&
                                                      playState.ayahNum == 0)
                                                  ? (TranslationService.isArabic
                                                        ? 'تحميل...'
                                                        : 'Loading...')
                                                  : (playState.isPlaying &&
                                                        playState.surahNum ==
                                                            _currentSurah
                                                                .number)
                                                  ? (TranslationService.isArabic
                                                        ? 'إيقاف'
                                                        : 'Pause')
                                                  : TranslationService.t(
                                                      'play',
                                                    ),
                                            ),
                                            onPressed: () {
                                              if (playState.isPlaying &&
                                                  playState.surahNum ==
                                                      _currentSurah.number) {
                                                AudioManager.instance
                                                    .togglePlayPause();
                                              } else {
                                                _playAudioWithDisclaimer();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      TranslationService
                                                              .isArabic
                                                          ? 'جاري تشغيل سورة ${_currentSurah.name}...'
                                                          : 'Streaming Surah ${_currentSurah.englishName}...',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: _readingMode == 'continuous'
                                        ? _buildContinuousLayout(playState)
                                        : NotificationListener<ScrollNotification>(
                                            onNotification: (notification) {
                                              if (notification is ScrollEndNotification) {
                                                if (_ayahList.isNotEmpty && _scrollController.hasClients) {
                                                  final offset = _scrollController.offset;
                                                  final approxIndex = (offset / 160.0).floor().clamp(0, _ayahList.length - 1);
                                                  _debouncedSavePosition(_currentSurah.number, _ayahList[approxIndex].numberInSurah);
                                                }
                                              }
                                              return false;
                                            },
                                            child: ListView.builder(
                                              controller: _scrollController,
                                              physics: const BouncingScrollPhysics(),
                                              padding: EdgeInsets.only(
                                                top: 8,
                                                bottom: 16.0 + MediaQuery.of(context).padding.bottom + 58.0 + 16.0,
                                              ),
                                              itemCount: _ayahList.length + 1,
                                              itemBuilder: (context, index) {
                                                if (index == 0) {
                                                  if (_currentSurah.number == 9) {
                                                    return const SizedBox.shrink();
                                                  }
                                                  bool hasBismillahEmbedded = false;
                                                  if (_ayahList.isNotEmpty) {
                                                    hasBismillahEmbedded = Ayah.startsWithBasmalah(_ayahList.first.text);
                                                  }
                                                  if (hasBismillahEmbedded) {
                                                    return const SizedBox.shrink();
                                                  }
                                                  return Container(
                                                    alignment: Alignment.center,
                                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                                    child: Text(
                                                      "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                                      style: _getArabicTextStyle(
                                                        30,
                                                        color: const Color(0xFFE5C158),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                final ayah = _ayahList[index - 1];
                                                final showHizbHeader = index == 1 ||
                                                    (index > 1 && ayah.hizb != 0 && ayah.hizb != _ayahList[index - 2].hizb) ||
                                                    (index > 1 && ayah.hizb == 0 && ayah.juz != _ayahList[index - 2].juz);
                                                return Column(
                                                  children: [
                                                    if (showHizbHeader)
                                                      _buildHizbDivider(ayah.hizb, ayah.juz),
                                                    _buildAyahCard(
                                                      ayah,
                                                      theme,
                                                      playState,
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              if (_readingMode == 'continuous')
                                _buildAutoScrollFloatingControls(
                                  isDark,
                                  playState,
                                ),
                              if (playState.isPlaying &&
                                  playState.surahNum != 0 &&
                                  playState.surahNum != _currentSurah.number)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          TranslationService.isArabic
                                              ? 'يتم الآن تشغيل سورة أخرى'
                                              : 'Playing a different Surah',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
