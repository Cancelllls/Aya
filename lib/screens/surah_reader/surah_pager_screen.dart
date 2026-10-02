import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/storage_service.dart';
import '../../services/reciters_cache_service.dart';
import '../../services/translation_service.dart';
import '../../services/audio_manager.dart';
import '../../models/offline_surahs.dart';
import '../tajweed_guide_screen.dart';
import 'surah_reader_screen.dart';
import '../../services/database_service.dart';
import 'madinah_mushaf_view.dart';

class SurahPagerScreen extends StatefulWidget {
  final Surah initialSurah;
  final StorageService storage;
  final int? initialAyahNumber;

  const SurahPagerScreen({
    super.key,
    required this.initialSurah,
    required this.storage,
    this.initialAyahNumber,
  });

  @override
  _SurahPagerScreenState createState() => _SurahPagerScreenState();
}

class _SurahPagerScreenState extends State<SurahPagerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  int _reloadKey = 0;
  String _readingMode = 'continuous';
  String _quranScriptType = 'hafs';
  String _translationEdition = 'en.sahih';
  double _fontSizeMultiplier = 1.0;
  bool _isPinching = false;
  double _basePinchMultiplier = 1.0;
  bool _showZoomPill = false;
  Timer? _zoomPillTimer;
  List<dynamic> _dynamicReciters = [];
  // Hifz is a separate notifier — never part of _readingMode, so
  // toggling it never remounts or rebuilds the SurahReaderScreen.
  final ValueNotifier<bool> _hifzNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _tajweedNotifier = ValueNotifier(true);
  final ValueNotifier<Set<int>> _bookmarksNotifier = ValueNotifier({});
  int? _madinahSurahNumber;
  String? _madinahSurahName;
  String? _madinahEnglishName;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSurah.number - 1;
    _pageController = PageController(initialPage: _currentPage);
    _readingMode = widget.storage.getString('reading_mode', defaultValue: 'continuous');
    _quranScriptType = widget.storage.getString('quran_script_type', defaultValue: 'hafs');
    _translationEdition = widget.storage.getString('default_translation', defaultValue: 'en.sahih');
    _fontSizeMultiplier = widget.storage.getDouble('setting_quran_font_size_multiplier', defaultValue: 1.0);
    _tajweedNotifier.value = widget.storage.getBool('tajweed_enabled', defaultValue: true);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _zoomPillTimer?.cancel();
    _pageController.dispose();
    _hifzNotifier.dispose();
    _tajweedNotifier.dispose();
    _bookmarksNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await widget.storage.getBookmarks();
    final surahNums = bookmarks.map((b) => b['surahNumber'] as int).toSet();
    _bookmarksNotifier.value = surahNums;
  }

  Future<void> _toggleSurahBookmark(Surah surahData) async {
    final current = Set<int>.from(_bookmarksNotifier.value);
    final isBookmarked = current.contains(surahData.number);

    if (isBookmarked) {
      await widget.storage.removeBookmark(surahData.number);
      current.remove(surahData.number);
      _bookmarksNotifier.value = current;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? 'تم إزالة العلامة من سورة ${surahData.name}'
                : 'Removed Bookmark from Surah ${surahData.englishName}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      await widget.storage.addBookmark(
        surahData.number,
        surahData.englishName,
        1,
      );
      current.add(surahData.number);
      _bookmarksNotifier.value = current;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? 'تم حفظ علامة لسورة ${surahData.name}'
                : 'Bookmarked Surah ${surahData.englishName}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  int _riwayahIdFor(String script) {
    switch (script) {
      case 'warsh': return 2;
      case 'qaloon': return 5;
      case 'shuba': return 15;
      case 'duri': return 13;
      case 'susi': return 7;
      case 'bazzi': return 4;
      case 'qunbul': return 6;
      case 'hisham': return 19;
      case 'ibn-dhakwan': return 16;
      default: return 1;
    }
  }

  /// Save reciter for current Qira'ah AND sync to global default_reciter
  /// (used by AudioManager for playback).
  void _saveReciter(String val) {
    AudioManager.instance.stop();
    widget.storage.setString('default_reciter_$_quranScriptType', val);
    widget.storage.setString('default_reciter', val);
    if (mounted) setState(() {});
  }

  /// Read reciter for a Qira'ah. Falls back to global default_reciter for
  /// Hafs, otherwise returns empty string (auto-select first available).
  String _getReciterFor(String script) {
    final perKey = widget.storage.getString('default_reciter_$script');
    if (perKey != null && perKey.isNotEmpty) return perKey;
    // For Hafs, try legacy global key
    if (script == 'hafs') {
      final old = widget.storage.getString('default_reciter');
      if (old != null && old.isNotEmpty && !old.startsWith('mp3quran_server_')) {
        return old;
      }
    }
    return script == 'hafs' ? 'ar.alafasy' : '';
  }

  void _onQiraahChanged(String val) {
    widget.storage.setString('quran_script_type', val);
    setState(() {
      _quranScriptType = val;
      _reloadKey++;
    });
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSizeMultiplier = (_fontSizeMultiplier + delta).clamp(0.8, 1.8);
    });
    widget.storage.setDouble('setting_quran_font_size_multiplier', _fontSizeMultiplier);
  }

  @override
  Widget build(BuildContext context) {
    final freshTranslation = widget.storage.getString(
      'default_translation',
      defaultValue: 'en.sahih',
    );
    if (freshTranslation != _translationEdition) {
      _translationEdition = freshTranslation;
      _reloadKey++;
    }
    final theme = Theme.of(context);
    final surahData = allOfflineSurahs[_currentPage];
    final String currentEnglishName =
        (_readingMode == 'madinah_page' && _madinahEnglishName != null)
            ? _madinahEnglishName!
            : surahData.englishName;
    final String currentArabicName =
        (_readingMode == 'madinah_page' && _madinahSurahName != null)
            ? _madinahSurahName!
            : surahData.name;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentEnglishName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              currentArabicName,
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
          // Hifz icon — ValueListenableBuilder so ONLY the icon repaints,
          // the PageView and readers are never remounted.
          ValueListenableBuilder<bool>(
            valueListenable: _hifzNotifier,
            builder: (context, isHifz, _) => IconButton(
              icon: Icon(
                isHifz ? Icons.school : Icons.school_outlined,
                color: isHifz
                    ? const Color(0xFFE5C158)
                    : (theme.appBarTheme.iconTheme?.color ?? Colors.white).withValues(alpha: 0.8),
              ),
              onPressed: () {
                _hifzNotifier.value = !_hifzNotifier.value;
              },
              tooltip: TranslationService.isArabic ? "وضع التسميع والحفظ" : "Hifz / Memorization Mode",
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.auto_stories,
              color: Color(0xFFE5C158),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TajweedGuideScreen(storage: widget.storage),
                ),
              );
            },
            tooltip: TranslationService.isArabic ? 'دليل أحكام التجويد والتشكيل' : 'Tajweed & Tashkeel Guide',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.chrome_reader_mode,
              color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
            ),
            tooltip: TranslationService.isArabic ? "تغيير نمط العرض" : "Change View Mode",
            color: theme.cardColor,
            onSelected: (mode) {
              setState(() {
                _readingMode = mode;
                if (mode != 'madinah_page') {
                  _madinahSurahNumber = null;
                  _madinahSurahName = null;
                  _madinahEnglishName = null;
                }
              });
              widget.storage.setString('reading_mode', mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'continuous',
                child: Row(children: [
                  Icon(Icons.menu_book, color: _readingMode == 'continuous' ? const Color(0xFFE5C158) : Theme.of(context).disabledColor),
                  const SizedBox(width: 8),
                  Text(TranslationService.isArabic ? "المصحف المتصل" : "Continuous", style: TextStyle(color: _readingMode == 'continuous' ? const Color(0xFFE5C158) : null, fontWeight: _readingMode == 'continuous' ? FontWeight.bold : null)),
                ]),
              ),
              PopupMenuItem(
                value: 'madinah_page',
                child: Row(children: [
                  Icon(Icons.auto_stories, color: _readingMode == 'madinah_page' ? const Color(0xFFE5C158) : Theme.of(context).disabledColor),
                  const SizedBox(width: 8),
                  Text(TranslationService.isArabic ? "صفحات المدينة (١٥ سطر)" : "15-Line Madinah Mushaf", style: TextStyle(color: _readingMode == 'madinah_page' ? const Color(0xFFE5C158) : null, fontWeight: _readingMode == 'madinah_page' ? FontWeight.bold : null)),
                ]),
              ),

              PopupMenuItem(
                value: 'arabic_only',
                child: Row(children: [
                  Icon(Icons.text_format, color: _readingMode == 'arabic_only' ? const Color(0xFFE5C158) : Theme.of(context).disabledColor),
                  const SizedBox(width: 8),
                  Text(TranslationService.isArabic ? "العربية فقط" : "Arabic Only", style: TextStyle(color: _readingMode == 'arabic_only' ? const Color(0xFFE5C158) : null, fontWeight: _readingMode == 'arabic_only' ? FontWeight.bold : null)),
                ]),
              ),
              PopupMenuItem(
                value: 'translation',
                child: Row(children: [
                  Icon(Icons.translate, color: _readingMode == 'translation' ? const Color(0xFFE5C158) : Theme.of(context).disabledColor),
                  const SizedBox(width: 8),
                  Text(TranslationService.isArabic ? "الترجمة" : "Translation", style: TextStyle(color: _readingMode == 'translation' ? const Color(0xFFE5C158) : null, fontWeight: _readingMode == 'translation' ? FontWeight.bold : null)),
                ]),
              ),
              PopupMenuItem(
                value: 'tafseer',
                child: Row(children: [
                  Icon(Icons.info_outline, color: _readingMode == 'tafseer' ? const Color(0xFFE5C158) : Theme.of(context).disabledColor),
                  const SizedBox(width: 8),
                  Text(TranslationService.isArabic ? "التفسير" : "Tafsir", style: TextStyle(color: _readingMode == 'tafseer' ? const Color(0xFFE5C158) : null, fontWeight: _readingMode == 'tafseer' ? FontWeight.bold : null)),
                ]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => _showReadingSettings(context, theme),
          ),
        ],
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          if (details.pointerCount >= 2) {
            _isPinching = true;
            _basePinchMultiplier = _fontSizeMultiplier;
            setState(() {});
          }
        },
        onScaleUpdate: (details) {
          if (_isPinching && details.scale != 1.0) {
            final double scaleDiff = details.scale - 1.0;
            final double newScale =
                (_basePinchMultiplier * (1.0 + scaleDiff * 1.5)).clamp(0.7, 2.2);
            setState(() {
              _fontSizeMultiplier = newScale;
              _showZoomPill = true;
            });
          }
        },
        onScaleEnd: (details) {
          if (_isPinching) {
            _isPinching = false;
            widget.storage.setDouble(
              'setting_quran_font_size_multiplier',
              _fontSizeMultiplier,
            );
            setState(() {});
            _zoomPillTimer?.cancel();
            _zoomPillTimer = Timer(const Duration(milliseconds: 1000), () {
              if (mounted) setState(() => _showZoomPill = false);
            });
          }
        },
        child: Stack(
          children: [
            _readingMode == 'madinah_page'
                ? FutureBuilder<int>(
                    future: DatabaseService.getInstance().then(
                      (db) => db.getPageForAyah(
                        widget.initialSurah.number,
                        widget.initialAyahNumber ?? 1,
                      ),
                    ),
                    builder: (context, snapshot) {
                      final initialPage = snapshot.data ?? 1;
                      return MadinahMushafView(
                        key: ValueKey('mushaf_view_${_reloadKey}_$initialPage'),
                        initialPage: initialPage,
                        storage: widget.storage,
                        fontSizeMultiplier: _fontSizeMultiplier,
                        onFontSizeMultiplierChanged: (newScale) {
                          setState(() => _fontSizeMultiplier = newScale);
                        },
                        onSurahChanged: (surahNum, surahName, englishName) {
                          if (mounted && (_madinahSurahNumber != surahNum)) {
                            setState(() {
                              _madinahSurahNumber = surahNum;
                              _madinahSurahName = surahName;
                              _madinahEnglishName = englishName;
                              _currentPage = (surahNum - 1).clamp(0, 113);
                            });
                          }
                        },
                      );
                    },
                  )
                : PageView.builder(
                    controller: _pageController,
                    physics: _isPinching
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: 114,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      final surahNum = index + 1;
                      final data = allOfflineSurahs[index];
                      final surah = Surah(
                        number: surahNum,
                        name: data.name,
                        englishName: data.englishName,
                        englishNameTranslation: '',
                        numberOfAyahs: data.numberOfAyahs,
                        revelationType: '',
                      );

                      return SurahReaderScreen(
                        key: ValueKey(
                          'surah_${_reloadKey}_${_translationEdition}_${_readingMode}_${_quranScriptType}_$surahNum',
                        ),
                        surah: surah,
                        storage: widget.storage,
                        translationEdition: _translationEdition,
                        initialAyahNumber: surahNum == widget.initialSurah.number
                            ? widget.initialAyahNumber
                            : null,
                        isInsidePager: true,
                        hideAppBar: true,
                        readingMode: _readingMode,
                        hifzNotifier: _hifzNotifier,
                        tajweedNotifier: _tajweedNotifier,
                        quranScriptType: _quranScriptType,
                        fontSizeMultiplier: _fontSizeMultiplier,
                        onFontSizeMultiplierChanged: (newScale) {
                          setState(() => _fontSizeMultiplier = newScale);
                        },
                        onGoToNext: () {
                          if (index < 113) {
                            _pageController.animateToPage(
                              index + 1,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        onGoToPrev: () {
                          if (index > 0) {
                            _pageController.animateToPage(
                              index - 1,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                      );
                    },
                  ),
            if (_showZoomPill)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5C158),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${(_fontSizeMultiplier * 100).toInt()}%",
                      style: const TextStyle(
                        color: Color(0xFFE5C158),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReadingSettings(BuildContext context, ThemeData theme) {
    // Read fresh from storage every time the popup opens
    String storedReciter = _getReciterFor(_quranScriptType);
    String storedTranslation = widget.storage.getString(
      'default_translation',
      defaultValue: 'en.sahih',
    );
    bool loadingReciters = false;
    List<dynamic> dynamicReciters = List.from(_dynamicReciters);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TranslationService.t('reading_settings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  // ── Tajweed toggle — top of sheet, matches gold app theme ──
                  ValueListenableBuilder<bool>(
                    valueListenable: _tajweedNotifier,
                    builder: (ctx, isTajweed, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: isTajweed
                              ? const Color(0xFFE5C158).withValues(alpha: 0.12)
                              : theme.dividerColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTajweed
                                ? const Color(0xFFE5C158).withValues(alpha: 0.4)
                                : theme.dividerColor,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          activeColor: const Color(0xFFE5C158),
                          secondary: Icon(
                            Icons.palette_outlined,
                            color: isTajweed ? const Color(0xFFE5C158) : theme.disabledColor,
                          ),
                          title: Text(
                            TranslationService.isArabic ? 'تلوين أحكام التجويد' : 'Color Tajweed Highlights',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            TranslationService.isArabic
                                ? 'تلوين أحرف التجويد (غنة، قلقلة، مد...)'
                                : 'Highlight Ghunnah, Qalqalah, Madd…',
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                          ),
                          value: isTajweed,
                          onChanged: (val) {
                            widget.storage.setBool('tajweed_enabled', val);
                            _tajweedNotifier.value = val;
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(TranslationService.isArabic ? 'الرواية' : "Qira'ah", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                    SizedBox(width: 170, child: DropdownButton<String>(isExpanded: true, value: _quranScriptType, dropdownColor: theme.cardColor, underline: const SizedBox(), icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5C158)),
                      items: ['hafs','warsh','qaloon','shuba','duri','susi','bazzi','qunbul','hisham','ibn-dhakwan'].map((v) {
                        final labels = {'hafs': ['حفص عن عاصم', "Hafs A'n Assem"], 'warsh': ['ورش عن نافع', "Warsh A'n Nafi'"], 'qaloon': ['قالون عن نافع', "Qalun A'n Nafi'"], 'shuba': ['شعبة عن عاصم', "Shuba A'n Assem"], 'duri': ['الدوري عن أبي عمرو', "Al-Duri A'n Abi Amr"], 'susi': ['السوسي عن أبي عمرو', "As-Susi A'n Abi Amr"], 'bazzi': ['البزي عن ابن كثير', "Al-Bazzi A'n Ibn Katheer"], 'qunbul': ['قنبل عن ابن كثير', "Qunbul A'n Ibn Katheer"], 'hisham': ['هشام عن ابن عامر', "Hisham A'n Ibn Amir"], 'ibn-dhakwan': ['ابن ذكوان عن ابن عامر', "Ibn Dhakwan A'n Ibn Amir"]};
                        return DropdownMenuItem(value: v, child: Text(labels[v]![TranslationService.isArabic ? 0 : 1], overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setModalState(() => loadingReciters = true);
                        _onQiraahChanged(v);
                        if (v != 'hafs') {
                          dynamicReciters = await RecitersCacheService.getRecitersForRiwayah(_riwayahIdFor(v));
                          _dynamicReciters = dynamicReciters;
                          // Select previously chosen reciter for this Qira'ah
                          final prev = _getReciterFor(v);
                          if (prev.isNotEmpty && dynamicReciters.any((r) {
                            final m = r['moshaf'] as List;
                            return m.isNotEmpty && ('mp3quran_server_${m[0]['server']}' == prev);
                          })) {
                            storedReciter = prev;
                          } else if (dynamicReciters.isNotEmpty) {
                            final m = dynamicReciters[0]['moshaf'] as List;
                            if (m.isNotEmpty) {
                              storedReciter = 'mp3quran_server_${m[0]['server']}';
                              _saveReciter(storedReciter);
                            }
                          }
                        } else {
                          storedReciter = _getReciterFor('hafs');
                          _saveReciter(storedReciter);
                        }
                        setModalState(() => loadingReciters = false);
                      },
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(TranslationService.isArabic ? 'القارئ' : 'Reciter', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                    loadingReciters
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5C158)))
                        : _quranScriptType == 'hafs'
                        ? SizedBox(width: 170, child: DropdownButton<String>(isExpanded: true,
                            value: availableReciters.any((r) => r.id == storedReciter) ? storedReciter : 'ar.alafasy',
                            dropdownColor: theme.cardColor, underline: const SizedBox(), icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5C158)),
                            items: (List.from(availableReciters)..sort((a, b) => TranslationService.isArabic ? a.nameAr.compareTo(b.nameAr) : a.nameEn.compareTo(b.nameEn)))
                                .map<DropdownMenuItem<String>>((r) => DropdownMenuItem(value: r.id, child: Text(TranslationService.isArabic ? r.nameAr : r.nameEn, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) { if (v != null) { storedReciter = v; _saveReciter(v); setModalState(() {}); } },
                          ))
                        : SizedBox(width: 170, child: DropdownButton<String>(isExpanded: true,
                            value: (() {
                              if (!storedReciter.startsWith('mp3quran_server_') || dynamicReciters.isEmpty) return null;
                              final sc = storedReciter.substring(16);
                              return dynamicReciters.any((r) => (r['moshaf'] as List).isNotEmpty && (r['moshaf'][0]['server'] as String) == sc) ? sc : null;
                            })(),
                            dropdownColor: theme.cardColor, underline: const SizedBox(), icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5C158)),
                            items: (dynamicReciters.where((r) => (r['moshaf'] as List).isNotEmpty).toList()
                              ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String)))
                              .map((r) => DropdownMenuItem<String>(value: (r['moshaf'][0]['server'] as String), child: Text(r['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) { if (v != null) { storedReciter = 'mp3quran_server_$v'; _saveReciter('mp3quran_server_$v'); setModalState(() {}); } },
                          )),
                  ]),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      TranslationService.isArabic ? 'ترجمة القرآن' : 'Translation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: availableTranslations.any((t) => t.identifier == storedTranslation)
                            ? storedTranslation
                            : 'en.sahih',
                        dropdownColor: theme.cardColor,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5C158)),
                        items: availableTranslations.map((t) {
                          return DropdownMenuItem(
                            value: t.identifier,
                            child: Text(
                              TranslationService.isArabic ? t.nameAr : t.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) async {
                          if (v != null) {
                            storedTranslation = v;
                            _translationEdition = v;
                            _reloadKey++;
                            await widget.storage.setString('default_translation', v);
                            setModalState(() {});
                            if (mounted) setState(() {});
                          }
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(TranslationService.t('arabic_font_size'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE5C158)), onPressed: () { _changeFontSize(-0.1); setModalState(() {}); }),
                      Text("${(_fontSizeMultiplier * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE5C158)), onPressed: () { _changeFontSize(0.1); setModalState(() {}); }),
                    ]),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
