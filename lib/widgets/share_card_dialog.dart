import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/translation_service.dart';

enum ShareCardTheme { darkGold, emerald, royalNavy, parchment }

class ShareCardDialog extends StatefulWidget {
  final String title;
  final String categoryOrSource;
  final String mainText;
  final String? translationText;
  final String? footnote;

  const ShareCardDialog({
    super.key,
    required this.title,
    required this.categoryOrSource,
    required this.mainText,
    this.translationText,
    this.footnote,
  });

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  ShareCardTheme _selectedTheme = ShareCardTheme.darkGold;
  bool _isExporting = false;

  Color get _bgColor {
    switch (_selectedTheme) {
      case ShareCardTheme.darkGold:
        return const Color(0xFF141921);
      case ShareCardTheme.emerald:
        return const Color(0xFF0F261C);
      case ShareCardTheme.royalNavy:
        return const Color(0xFF0D1B2A);
      case ShareCardTheme.parchment:
        return const Color(0xFFFBF8EE);
    }
  }

  Color get _textColor {
    switch (_selectedTheme) {
      case ShareCardTheme.parchment:
        return const Color(0xFF2C221E);
      default:
        return Colors.white;
    }
  }

  Color get _subtitleColor {
    switch (_selectedTheme) {
      case ShareCardTheme.parchment:
        return const Color(0xFF5C4033);
      default:
        return Colors.white70;
    }
  }

  Color get _accentColor {
    switch (_selectedTheme) {
      case ShareCardTheme.parchment:
        return const Color(0xFF8B5E3C);
      default:
        return const Color(0xFFE5C158);
    }
  }

  Future<void> _shareImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isExporting = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() => _isExporting = false);
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      final isAr = TranslationService.isArabic;
      final ref = widget.categoryOrSource.isNotEmpty
          ? widget.categoryOrSource
          : widget.title;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: isAr ? '$ref — آية' : '$ref — Aya',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'تعذر مشاركة الصورة: $e'
                  : 'Failed to share image: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5C158).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'مشاركة كصورة' : 'Share as Image',
                      style: const TextStyle(
                        color: Color(0xFFE5C158),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Preview Card
                RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accentColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Header Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: _accentColor, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              widget.categoryOrSource.isNotEmpty
                                  ? widget.categoryOrSource
                                  : widget.title,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.star, color: _accentColor, size: 14),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Main Text (Arabic / Dhikr / Hadith)
                        Text(
                          widget.mainText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            height: 1.8,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),

                        // Translation text (if available)
                        if (widget.translationText != null &&
                            widget.translationText!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Divider(
                            color: _accentColor.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.translationText!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                              color: _subtitleColor,
                            ),
                          ),
                        ],

                        // Footnote (repetition count or narrator reference)
                        if (widget.footnote != null &&
                            widget.footnote!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.footnote!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        // Bottom Branding Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: _accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Aya • آية',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Theme Style Selector
                Text(
                  isAr ? 'اختر النمط:' : 'Select Style:',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThemeChip(
                      ShareCardTheme.darkGold,
                      const Color(0xFF141921),
                      isAr ? 'ذهبي' : 'Dark Gold',
                    ),
                    _buildThemeChip(
                      ShareCardTheme.emerald,
                      const Color(0xFF0F261C),
                      isAr ? 'زمردي' : 'Emerald',
                    ),
                    _buildThemeChip(
                      ShareCardTheme.royalNavy,
                      const Color(0xFF0D1B2A),
                      isAr ? 'ملكي' : 'Navy',
                    ),
                    _buildThemeChip(
                      ShareCardTheme.parchment,
                      const Color(0xFFFBF8EE),
                      isAr ? 'ورقي' : 'Parchment',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5C158),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isExporting ? null : _shareImage,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      _isExporting
                          ? (isAr ? 'جاري التصدير...' : 'Exporting...')
                          : (isAr ? 'مشاركة الصورة' : 'Share Image'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  Widget _buildThemeChip(ShareCardTheme theme, Color bg, String label) {
    final isSelected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE5C158) : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: theme == ShareCardTheme.parchment
                ? Colors.black
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
