with open('lib/screens/settings_screen.dart', 'r') as f:
    text = f.read()

# Blocks to extract from Appearance
quran_font_block = """                ListTile(
                  title: Text(TranslationService.t('quran_font')),
                  subtitle: Text(TranslationService.t('quran_font_sub')),
                  trailing: DropdownButton<String>(
                    value: _quranFont,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 'font-scheherazade', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "خط شهرزاد" : "Scheherazade Font"))),
                      DropdownMenuItem(value: 'font-amiri', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "الخط الأميري" : "Amiri Font"))),
                    ],
                    onChanged: _changeFont,
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
"""

tafsir_block = """                ListTile(
                  title: Text(TranslationService.isArabic ? "تفسير القرآن" : "Quran Tafsir"),
                  subtitle: Text(TranslationService.isArabic ? "اختر كتاب التفسير المفضل" : "Choose preferred Tafsir book"),
                  trailing: DropdownButton<String>(
                    value: _tafsirEdition,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: const [
                      DropdownMenuItem(value: 'ar.muyassar', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("التفسير الميسر (المجمع)"))),
                      DropdownMenuItem(value: 'ar.jalalayn', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("تفسير الجلالين"))),
                      DropdownMenuItem(value: 'ar.qurtubi', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("تفسير القرطبي"))),
                      DropdownMenuItem(value: 'ar.miqbas', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("تنوير المقباس (ابن عباس)"))),
                      DropdownMenuItem(value: 'ar.waseet', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("التفسير الوسيط (الطنطاوي)"))),
                      DropdownMenuItem(value: 'ar.baghawi', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("تفسير البغوي"))),
                    ],
                    onChanged: _changeTafsirEdition,
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
"""

swipe_block = """                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "سحب الشاشة للانتقال بين السور" : "Swipe to Navigate Surahs"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "اسحب لليمين أو اليسار للانتقال إلى السورة التالية أو السابقة" 
                      : "Swipe left or right to read the previous or next Surah"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _swipeSurahNavigation,
                  onChanged: _toggleSwipeSurahNavigation,
                ),
"""

# Blocks to extract from Audio & Quran
hide_borders_block = """                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "إخفاء حدود القراءة المتواصلة" : "Hide Continuous Mode Borders"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "إزالة الحواف والظلال لتصبح الصفحات متصلة تماماً" 
                      : "Remove section borders and shadows for seamless reading"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _hideContinuousBorders,
                  onChanged: _toggleHideContinuousBorders,
                ),
                const Divider(height: 1, color: Colors.white10),
"""

immersive_block = """                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "وضع القارئ الغامر" : "Immersive Reader Mode"),
                  subtitle: Text(TranslationService.isArabic
                      ? "إخفاء أشرطة النظام (شريط الحالة والتنقل) أثناء قراءة القرآن لتقليل التشتيت"
                      : "Hide system bars (status and navigation) while reading Quran to reduce distraction"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _immersiveReader,
                  onChanged: _toggleImmersiveReader,
                ),
                const Divider(height: 1, color: Colors.white10),
"""

# 1. Remove from Appearance
if quran_font_block not in text: print("quran_font_block not found!")
if tafsir_block not in text: print("tafsir_block not found!")
# Note: swipe_block might not have a divider after it, let's just remove it.
if swipe_block not in text: print("swipe_block not found!")
text = text.replace(quran_font_block, "")
text = text.replace(tafsir_block, "")
text = text.replace(swipe_block, "")

# 2. Remove from Audio
if hide_borders_block not in text: print("hide_borders_block not found!")
if immersive_block not in text: print("immersive_block not found!")
text = text.replace(hide_borders_block, "")
text = text.replace(immersive_block, "")

# Now create the new Quran Reading section
new_quran_reading_section = f"""          // Section Quran Reading Experience
          _buildSectionHeader(TranslationService.isArabic ? "تجربة قراءة القرآن" : "Quran Reading Experience"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
{quran_font_block}{tafsir_block}{hide_borders_block}{immersive_block}{swipe_block}              ],
            ),
          ),
          const SizedBox(height: 20),

"""

# Insert it before "Section Language"
insertion_point = "          // Section Language"
if insertion_point not in text: print("insertion_point not found!")
text = text.replace(insertion_point, new_quran_reading_section + insertion_point)

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(text)

print("Done")
