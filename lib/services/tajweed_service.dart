import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'translation_service.dart';

enum TajweedRuleType {
  ghunnah,
  qalqalah,
  ikhfa,
  idgham,
  iqlab,
  madd,
}

class TajweedRuleInfo {
  final TajweedRuleType type;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final Color color;

  const TajweedRuleInfo({
    required this.type,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.color,
  });

  static const Map<TajweedRuleType, TajweedRuleInfo> rules = {
    TajweedRuleType.ghunnah: TajweedRuleInfo(
      type: TajweedRuleType.ghunnah,
      nameAr: 'غنة',
      nameEn: 'Ghunnah',
      descriptionAr: 'صوت لذيذ يخرج من الخيشوم ملازم للنون والميم المشددتين (مقدار حركتين).',
      descriptionEn: 'Nasalization sound produced from the nose on Nun or Mim with Shaddah (held for 2 beats).',
      color: Color(0xFFFF4081), // Pink Accent
    ),
    TajweedRuleType.qalqalah: TajweedRuleInfo(
      type: TajweedRuleType.qalqalah,
      nameAr: 'قلقلة',
      nameEn: 'Qalqalah',
      descriptionAr: 'اضطراب الصوت وتحريكه عند النطق بالحرف الساكن من حروف (قطب جد).',
      descriptionEn: 'Echoing or bouncing sound produced when pronouncing the silent letters (ق, ط, ب, ج, د).',
      color: Color(0xFF29B6F6), // Light Blue
    ),
    TajweedRuleType.ikhfa: TajweedRuleInfo(
      type: TajweedRuleType.ikhfa,
      nameAr: 'إخفاء',
      nameEn: 'Ikhfa',
      descriptionAr: 'نطق الحرف بحالة بين الإظهار والإدغام مع بقاء الغنة عند حروف الإخفاء (15 حرفاً).',
      descriptionEn: 'Concealing the Nun Sakinah or Tanween between clear pronunciation and assimilation with Ghunnah.',
      color: Color(0xFF26A69A), // Teal
    ),
    TajweedRuleType.idgham: TajweedRuleInfo(
      type: TajweedRuleType.idgham,
      nameAr: 'إدغام',
      nameEn: 'Idgham',
      descriptionAr: 'إدخال حرف ساكن بحرف متحرك بحيث يصيران حرفاً واحداً مشدداً عند حروف (يرملون).',
      descriptionEn: 'Merging a silent letter into a following voweled letter so they become one doubled letter (letters: ي, ر, م, ل, و, ن).',
      color: Color(0xFF66BB6A), // Light Green
    ),
    TajweedRuleType.iqlab: TajweedRuleInfo(
      type: TajweedRuleType.iqlab,
      nameAr: 'إقلاب',
      nameEn: 'Iqlab',
      descriptionAr: 'قلب النون الساكنة أو التنوين ميماً مخفاة بغنة عند التقائها بالحرف (ب).',
      descriptionEn: 'Converting Nun Sakinah or Tanween into a concealed Mim with Ghunnah when followed by the letter Ba (ب).',
      color: Color(0xFFFFB74D), // Amber / Orange
    ),
    TajweedRuleType.madd: TajweedRuleInfo(
      type: TajweedRuleType.madd,
      nameAr: 'مد',
      nameEn: 'Madd (Elongation)',
      descriptionAr: 'إطالة الصوت بحرف من حروف المد (الألف، الواو، الياء) عند وجود علامة المد.',
      descriptionEn: 'Elongation of sound on Madd letters (Alif, Waw, Ya) when marked with Maddah symbol.',
      color: Color(0xFFAB47BC), // Purple
    ),
  };
}

class TajweedService {
  /// Parses Arabic verse text and converts it into a list of styled [InlineSpan] objects.
  static List<InlineSpan> buildSpans({
    required String text,
    required TextStyle baseStyle,
    required BuildContext context,
    required bool isEnabled,
    GestureRecognizer? ayahRecognizer,
  }) {
    if (!isEnabled || text.isEmpty) {
      return [TextSpan(text: text, style: baseStyle, recognizer: ayahRecognizer)];
    }

    final spans = <InlineSpan>[];
    final chars = text.runes.map((r) => String.fromCharCode(r)).toList();
    int i = 0;
    // Buffer for normal (non-Tajweed) characters — kept together to preserve
    // Arabic ligature shaping. Flushed as a single span when a Tajweed rule
    // character is encountered.
    final StringBuffer normalBuf = StringBuffer();

    void flushNormal() {
      if (normalBuf.isNotEmpty) {
        spans.add(TextSpan(
          text: normalBuf.toString(),
          style: baseStyle,
          recognizer: ayahRecognizer,
        ));
        normalBuf.clear();
      }
    }

    while (i < chars.length) {
      final ch = chars[i];

      // Check Ghunnah: نّ or مّ
      if ((ch == 'ن' || ch == 'م') && i + 1 < chars.length && chars[i + 1] == 'ّ') {
        flushNormal();
        final segment = ch + chars[i + 1];
        spans.add(_buildRuleSpan(
          text: segment,
          baseStyle: baseStyle,
          rule: TajweedRuleInfo.rules[TajweedRuleType.ghunnah]!,
          context: context,
          ayahRecognizer: ayahRecognizer,
        ));
        i += 2;
        continue;
      }

      // Check Qalqalah: ق, ط, ب, ج, د with sukun (ْ)
      if ('قطبجد'.contains(ch) && i + 1 < chars.length && chars[i + 1] == 'ْ') {
        flushNormal();
        final segment = ch + chars[i + 1];
        spans.add(_buildRuleSpan(
          text: segment,
          baseStyle: baseStyle,
          rule: TajweedRuleInfo.rules[TajweedRuleType.qalqalah]!,
          context: context,
          ayahRecognizer: ayahRecognizer,
        ));
        i += 2;
        continue;
      }

      // Check Madd: آ, ۤ, ٰ, ٓ
      if ('آٰۤ'.contains(ch) || ch == '~' || ch == 'ٓ') {
        flushNormal();
        spans.add(_buildRuleSpan(
          text: ch,
          baseStyle: baseStyle,
          rule: TajweedRuleInfo.rules[TajweedRuleType.madd]!,
          context: context,
          ayahRecognizer: ayahRecognizer,
        ));
        i++;
        continue;
      }

      // Check Iqlab: small mim (ۘ or ۣ or ۢ)
      if (ch == 'ۘ' || ch == 'ۣ' || ch == 'ۢ') {
        flushNormal();
        spans.add(_buildRuleSpan(
          text: ch,
          baseStyle: baseStyle,
          rule: TajweedRuleInfo.rules[TajweedRuleType.iqlab]!,
          context: context,
          ayahRecognizer: ayahRecognizer,
        ));
        i++;
        continue;
      }

      // Normal character — buffer it (preserves Arabic ligatures)
      normalBuf.write(ch);
      i++;
    }

    flushNormal();
    return spans;
  }

  static TextSpan _buildRuleSpan({
    required String text,
    required TextStyle baseStyle,
    required TajweedRuleInfo rule,
    required BuildContext context,
    GestureRecognizer? ayahRecognizer,
  }) {
    // If we have an ayah tap recognizer, use it (so tapping a colored letter
    // triggers the ayah action sheet, not the Tajweed info sheet).
    // The Tajweed info sheet is accessible from within the ayah action sheet.
    return TextSpan(
      text: text,
      style: baseStyle.copyWith(
        color: rule.color,
        fontWeight: FontWeight.bold,
      ),
      recognizer: ayahRecognizer,
    );
  }

  /// Displays an interactive glassmorphic sheet explaining the tapped Tajweed rule.
  static void showTajweedRuleSheet(BuildContext context, TajweedRuleInfo rule) {
    final isAr = TranslationService.isArabic;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: rule.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? rule.nameAr : rule.nameEn,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rule.color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rule.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rule.color, width: 1),
                    ),
                    child: Text(
                      isAr ? "قاعدة تجويد" : "Tajweed Rule",
                      style: TextStyle(
                        color: rule.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isAr ? rule.descriptionAr : rule.descriptionEn,
                style: const TextStyle(fontSize: 14, height: 1.6),
                textAlign: isAr ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C158),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    TranslationService.t('close'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
