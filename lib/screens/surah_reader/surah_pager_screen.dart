import 'package:flutter/material.dart';
import '../../models/quran_models.dart';
import '../../services/storage_service.dart';
import '../../services/reciters_cache_service.dart';
import '../../services/translation_service.dart';
import '../../models/offline_surahs.dart';
import 'surah_reader_screen.dart';

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
  double _fontSizeMultiplier = 1.0;
  List<dynamic> _dynamicReciters = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSurah.number - 1;
    _pageController = PageController(initialPage: _currentPage);
    _readingMode = widget.storage.getString('reading_mode', defaultValue: 'continuous');
    _quranScriptType = widget.storage.getString('quran_script_type', defaultValue: 'hafs');
    _fontSizeMultiplier = widget.storage.getDouble('setting_quran_font_size_multiplier', defaultValue: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onQiraahChanged(String val) {
    widget.storage.setString('quran_script_type', val);
    if (val == 'hafs') {
      widget.storage.setString('default_reciter', 'ar.alafasy');
    }
    setState(() {
      _quranScriptType = val;
      _reloadKey++;
    });
  }

  void _onReciterChanged(String val) {
    widget.storage.setString('default_reciter', val);
    if (mounted) setState(() {});
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSizeMultiplier = (_fontSizeMultiplier + delta).clamp(0.8, 1.8);
    });
    widget.storage.setDouble('setting_quran_font_size_multiplier', _fontSizeMultiplier);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surahData = allOfflineSurahs[_currentPage];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surahData.englishName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              surahData.name,
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
          PopupMenuButton<String>(
            icon: Icon(
              Icons.chrome_reader_mode,
              color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
            ),
            tooltip: TranslationService.isArabic ? "تغيير نمط العرض" : "Change View Mode",
            color: theme.cardColor,
            onSelected: (mode) {
              setState(() => _readingMode = mode);
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
      body: PageView.builder(
        controller: _pageController,
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
            key: ValueKey('surah_${_reloadKey}_$surahNum'),
            surah: surah,
            storage: widget.storage,
            initialAyahNumber: surahNum == widget.initialSurah.number
                ? widget.initialAyahNumber
                : null,
            isInsidePager: true,
            hideAppBar: true,
            readingMode: _readingMode,
            quranScriptType: _quranScriptType,
            fontSizeMultiplier: _fontSizeMultiplier,
            onGoToNext: () {
              if (index < 113) {
                _pageController.animateToPage(index + 1, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
              }
            },
            onGoToPrev: () {
              if (index > 0) {
                _pageController.animateToPage(index - 1, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
              }
            },
          );
        },
      ),
    );
  }

  void _showReadingSettings(BuildContext context, ThemeData theme) {
    // Read fresh from storage every time the popup opens
    String storedReciter = widget.storage.getString('default_reciter', defaultValue: 'ar.alafasy');
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
                        }
                        storedReciter = widget.storage.getString('default_reciter', defaultValue: 'ar.alafasy');
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
                            onChanged: (v) { if (v != null) { storedReciter = v; _onReciterChanged(v); setModalState(() {}); } },
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
                            onChanged: (v) { if (v != null) { storedReciter = 'mp3quran_server_$v'; _onReciterChanged('mp3quran_server_$v'); setModalState(() {}); } },
                          )),
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
