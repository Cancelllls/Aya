import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quran_models.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';

class ShareAyahDialog extends StatefulWidget {
  final Ayah? ayah;
  final List<Ayah>? ayahs;
  final String surahName;
  final int surahNumber;

  const ShareAyahDialog({
    super.key,
    this.ayah,
    this.ayahs,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  State<ShareAyahDialog> createState() => _ShareAyahDialogState();
}

class _ShareAyahDialogState extends State<ShareAyahDialog> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isGenerating = false;
  int _selectedThemeIndex = 0;
  String _langMode = 'both'; // 'both', 'ar_only', 'en_only'
  bool _includeTafsir = false;
  String _tafsirText = '';
  bool _isLoadingTafsir = false;

  bool _includeAyahNumbers = true;

  List<Ayah> get _ayahList {
    if (widget.ayahs != null && widget.ayahs!.isNotEmpty) {
      return widget.ayahs!;
    }
    if (widget.ayah != null) {
      return [widget.ayah!];
    }
    return [];
  }

  Ayah? get _firstAyah =>
      _ayahList.isNotEmpty ? _ayahList.first : widget.ayah;

  String get _headerRefText {
    final isAr = TranslationService.isArabic;
    final firstNum = _firstAyah?.numberInSurah ?? 1;
    if (_ayahList.length <= 1) {
      return '${widget.surahName} • ${isAr ? 'آية' : 'Ayah'} $firstNum';
    } else {
      return '${widget.surahName} • ${isAr ? 'الآيات' : 'Ayahs'} ${_ayahList.first.numberInSurah}-${_ayahList.last.numberInSurah}';
    }
  }

  String get _formattedTranslationText {
    return _ayahList
        .map((a) => a.translation)
        .where((t) => t.isNotEmpty)
        .join("\n\n");
  }

  @override
  void initState() {
    super.initState();
    _tafsirText = _firstAyah?.tafseer.trim() ?? '';
  }

  void _onToggleTafsir(bool val) {
    setState(() => _includeTafsir = val);
    if (val && _tafsirText.isEmpty && _firstAyah != null) {
      setState(() => _isLoadingTafsir = true);
      ApiService.fetchTafsirTextForAyah(
        'ar.muyassar',
        widget.surahNumber,
        _firstAyah!.numberInSurah,
      ).then((text) {
        if (mounted) {
          setState(() {
            _tafsirText = text;
            _isLoadingTafsir = false;
          });
        }
      });
    }
  }

  final List<Map<String, dynamic>> _themes = [
    {
      'nameAr': 'ذهبي وداكن',
      'nameEn': 'Dark Gold',
      'bgColor': const Color(0xFF141921),
      'borderColor': const Color(0xFFE5C158),
      'textColor': Colors.white,
      'accentColor': const Color(0xFFE5C158),
    },
    {
      'nameAr': 'زمرّدي مذهب',
      'nameEn': 'Emerald',
      'bgColor': const Color(0xFF0F261C),
      'borderColor': const Color(0xFF81C784),
      'textColor': const Color(0xFFE8F5E9),
      'accentColor': const Color(0xFF81C784),
    },
    {
      'nameAr': 'نيلي ملكي',
      'nameEn': 'Royal Navy',
      'bgColor': const Color(0xFF0D1B2A),
      'borderColor': const Color(0xFF64B5F6),
      'textColor': const Color(0xFFE3F2FD),
      'accentColor': const Color(0xFF64B5F6),
    },
    {
      'nameAr': 'ورقي كريمي',
      'nameEn': 'Parchment',
      'bgColor': const Color(0xFFFBF8EE),
      'borderColor': const Color(0xFFB08968),
      'textColor': const Color(0xFF3D2C1E),
      'accentColor': const Color(0xFF7F5539),
    },
  ];

  Future<void> _captureAndShareImage() async {
    setState(() => _isGenerating = true);
    try {
      final boundary =
          _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final firstAyahNum = _firstAyah?.numberInSurah ?? 1;
      final filePath =
          '${tempDir.path}/ayah_${widget.surahNumber}_${firstAyahNum}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      final isAr = TranslationService.isArabic;
      final ref = _headerRefText;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: isAr ? 'آية من القرآن الكريم — $ref' : 'Ayah from Quran — $ref',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'تعذر مشاركة الصورة'
                  : 'Failed to share image: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = _themes[_selectedThemeIndex];
    final isAr = TranslationService.isArabic;
    final theme = Theme.of(context);

    final showArabic = _langMode == 'both' || _langMode == 'ar_only';
    final showEnglish = _langMode == 'both' || _langMode == 'en_only';

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'مشاركة الآية كصورة' : 'Share Verse as Image',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(isAr ? 'العربية فقط' : 'Arabic Only'),
                    selected: _langMode == 'ar_only',
                    selectedColor: const Color(0xFFE5C158),
                    onSelected: (val) {
                      if (val) setState(() => _langMode = 'ar_only');
                    },
                  ),
                  ChoiceChip(
                    label: Text(isAr ? 'الإنجليزية فقط' : 'English Only'),
                    selected: _langMode == 'en_only',
                    selectedColor: const Color(0xFFE5C158),
                    onSelected: (val) {
                      if (val) setState(() => _langMode = 'en_only');
                    },
                  ),
                  ChoiceChip(
                    label: Text(isAr ? 'كلاهما' : 'Both'),
                    selected: _langMode == 'both',
                    selectedColor: const Color(0xFFE5C158),
                    onSelected: (val) {
                      if (val) setState(() => _langMode = 'both');
                    },
                  ),
                  FilterChip(
                    avatar: Icon(
                      _includeAyahNumbers
                          ? Icons.format_list_numbered
                          : Icons.format_list_numbered_outlined,
                      size: 16,
                      color: _includeAyahNumbers ? Colors.black : Colors.grey,
                    ),
                    label: Text(isAr ? 'أرقام الآيات' : 'Ayah Numbers'),
                    selected: _includeAyahNumbers,
                    selectedColor: const Color(0xFFE5C158),
                    onSelected: (val) => setState(() => _includeAyahNumbers = val),
                  ),
                  FilterChip(
                    avatar: Icon(
                      _includeTafsir
                          ? Icons.auto_stories
                          : Icons.auto_stories_outlined,
                      size: 16,
                      color: _includeTafsir ? Colors.black : Colors.grey,
                    ),
                    label: Text(isAr ? 'تضمين التفسير' : 'Include Tafsir'),
                    selected: _includeTafsir,
                    selectedColor: const Color(0xFFE5C158),
                    onSelected: _onToggleTafsir,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Image Preview Card wrapped in RepaintBoundary (Horizontal layout)
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: themeConfig['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (themeConfig['borderColor'] as Color).withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Motif
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_outline_rounded,
                            color: themeConfig['accentColor'] as Color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _headerRefText,
                            style: TextStyle(
                              color: themeConfig['accentColor'] as Color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star_outline_rounded,
                            color: themeConfig['accentColor'] as Color,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Arabic Text (If enabled) with Gold Ayah Numbering
                      if (showArabic)
                        Text.rich(
                          TextSpan(
                            children: [
                              for (int i = 0; i < _ayahList.length; i++) ...[
                                TextSpan(
                                  text: "${_ayahList[i].text} ",
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 22,
                                    height: 2.0,
                                    fontWeight: FontWeight.bold,
                                    color: themeConfig['textColor'] as Color,
                                  ),
                                ),
                                if (_includeAyahNumbers)
                                  TextSpan(
                                    text: "﴿${_ayahList[i].numberInSurah}﴾ ",
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 20,
                                      height: 2.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE5C158),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),

                        // Translation (If enabled & present)
                        if (showEnglish && _formattedTranslationText.isNotEmpty) ...[
                          if (showArabic) const SizedBox(height: 12),
                          Text(
                            _formattedTranslationText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: (themeConfig['textColor'] as Color).withValues(alpha: 0.85),
                            ),
                          ),
                        ],

                      // Tafsir (If enabled)
                      if (_includeTafsir) ...[
                        const SizedBox(height: 14),
                        Divider(
                          color: (themeConfig['accentColor'] as Color).withValues(alpha: 0.4),
                          thickness: 1,
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingTafsir)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE5C158),
                              ),
                            ),
                          )
                        else
                          Text(
                            _tafsirText.isNotEmpty
                                ? _tafsirText
                                : (isAr ? 'التفسير الميسر غير متوفر' : 'Tafsir not available'),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 13,
                              height: 1.7,
                              color: (themeConfig['textColor'] as Color).withValues(alpha: 0.9),
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

                      // Footer branding (Aya • آية)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 1,
                            color: (themeConfig['accentColor'] as Color).withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Aya • آية',
                            style: TextStyle(
                              fontSize: 10,
                              color: (themeConfig['accentColor'] as Color).withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 30,
                            height: 1,
                            color: (themeConfig['accentColor'] as Color).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Theme Style Picker
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _themes.length,
                  itemBuilder: (ctx, idx) {
                    final t = _themes[idx];
                    final isSelected = idx == _selectedThemeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedThemeIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (t['bgColor'] as Color),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (t['accentColor'] as Color)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          isAr ? t['nameAr'] : t['nameEn'],
                          style: TextStyle(
                            fontSize: 11,
                            color: t['textColor'] as Color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Share Action Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C158),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isGenerating ? null : _captureAndShareImage,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.share, color: Colors.black),
                  label: Text(
                    isAr ? 'مشاركة الصورة' : 'Share Image',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
