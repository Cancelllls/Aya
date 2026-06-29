import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    text = f.read()

def find_matching_brace(text, start_idx, open_char, close_char):
    count = 1
    idx = start_idx
    while count > 0 and idx < len(text):
        if text[idx] == open_char:
            count += 1
        elif text[idx] == close_char:
            count -= 1
        idx += 1
    return idx

def extract_block(start_str):
    start_idx = text.find(start_str)
    if start_idx == -1:
        raise Exception("Not found: " + start_str[:30])
    
    # We need to find the opening parenthesis of the top-level widget
    # The start_str should be something like `ListTile(` or `SwitchListTile(`
    open_idx = start_idx + len(start_str) - 1
    if text[open_idx] != '(':
        open_idx = text.find('(', start_idx)
    
    end_idx = find_matching_brace(text, open_idx + 1, '(', ')')
    # Include any trailing commas
    if end_idx < len(text) and text[end_idx] == ',':
        end_idx += 1
    
    return text[start_idx:end_idx]

def extract_if_block(start_str):
    start_idx = text.find(start_str)
    if start_idx == -1:
        raise Exception("Not found: " + start_str[:30])
    
    open_idx = text.find('[', start_idx)
    end_idx = find_matching_brace(text, open_idx + 1, '[', ']')
    if end_idx < len(text) and text[end_idx] == ',':
        end_idx += 1
        
    return text[start_idx:end_idx]

# Let's extract!
theme = extract_block("ListTile(\n                  title: Text(TranslationService.t('theme_preset_label'))")
navbar = extract_block("ListTile(\n                  title: Text(TranslationService.t('bottom_navbar_style_label'))")
quran_font = extract_block("ListTile(\n                  title: Text(TranslationService.t('quran_font'))")
quran_tafsir = extract_block("ListTile(\n                  title: Text(TranslationService.isArabic ? \"تفسير القرآن\" : \"Quran Tafsir\")")
time_format = extract_block("SwitchListTile(\n                  title: Text(TranslationService.isArabic ? \"تنسيق الوقت ٢٤ ساعة\" : \"24-Hour Time Format\")")
swipe_surah = extract_block("SwitchListTile(\n                  title: Text(TranslationService.isArabic ? \"سحب الشاشة للانتقال بين السور\" : \"Swipe to Navigate Surahs\")")

app_lang = extract_block("ListTile(\n              title: Text(TranslationService.t('app_lang'))")
# The original app_lang was inside a Card without trailing comma. Let's make sure we have a comma
if not app_lang.endswith(','): app_lang += ','

calc_method = extract_block("ListTile(\n                  title: Text(TranslationService.t('calc_method'))")
asr_method = extract_block("ListTile(\n                  title: Text(TranslationService.t('asr_calc_label'))")

pre_adhan_time = extract_block("ListTile(\n                  title: Text(TranslationService.isArabic ? \"وقت التنبيه قبل الأذان\" : \"Pre-Athan Alert Time\")")
pre_adhan_style = extract_block("ListTile(\n                  title: Text(TranslationService.isArabic ? \"نمط تنبيه قبل الأذان\" : \"Pre-Athan Alert Style\")")
voice_preview = extract_if_block("if (_preAdhanAlertMode == 'voice' || _preAdhanAlertMode == 'vibrate_and_voice') ...[")

adhan_style = extract_block("ListTile(\n                  title: Text(TranslationService.isArabic ? \"نوع تنبيه الأذان\" : \"Athan Alert Style\")")
adhan_reciters = extract_if_block("if (_adhanAlertMode == 'real_reciter' || _adhanAlertMode == 'vibrate_and_voice') ...[")

morning_azkar = extract_block("SwitchListTile(\n                  title: Text(TranslationService.t('morning_azkar_reminder'))")
evening_azkar = extract_block("SwitchListTile(\n                  title: Text(TranslationService.t('evening_azkar_reminder'))")
todays_verse = extract_block("SwitchListTile(\n                  title: Text(TranslationService.t('todays_verse_reminder'))")

qari = extract_block("ListTile(\n                  title: Text(TranslationService.t('qari'))")
continuous_rec = extract_block("SwitchListTile(\n                  title: Text(TranslationService.t('continuous_rec_label'))")
hide_borders = extract_block("SwitchListTile(\n                  title: Text(TranslationService.isArabic ? \"إخفاء حدود القراءة المتواصلة\" : \"Hide Continuous Mode Borders\")")
auto_bookmark = extract_block("SwitchListTile(\n                  title: Text(TranslationService.isArabic ? \"حفظ المرجعية تلقائياً\" : \"Auto-Bookmark on Play\")")
immersive_reader = extract_block("SwitchListTile(\n                  title: Text(TranslationService.isArabic ? \"وضع القارئ الغامر\" : \"Immersive Reader Mode\")")
downloads = extract_block("ListTile(\n                  leading: const Icon(Icons.download_for_offline")

wake_lock = extract_block("SwitchListTile(\n                  title: Text(TranslationService.t('wake_lock'))")
exact_alarms = extract_block("ListTile(\n                  title: Text(TranslationService.t('exact_alarms'))")
battery_opt = extract_block("ListTile(\n                  title: Text(TranslationService.t('battery_optimization'))")

focus_timer = extract_block("ListTile(\n                  title: Text(TranslationService.t('focus_timer'))")
focus_lock = extract_if_block("if (_focusLockDuration > 0) ...[")

support = extract_block("ListTile(\n              leading: const Icon(Icons.volunteer_activism")
if not support.endswith(','): support += ','
about = extract_block("ListTile(\n              leading: const Icon(Icons.info_outline")
if not about.endswith(','): about += ','
reset = extract_block("ListTile(\n              title: Text(\n                TranslationService.t('reset_settings')")
if not reset.endswith(','): reset += ','

app_info_start_idx = text.find("Center(\n            child: Column(\n              children: [\n                const Icon(Icons.mosque")
app_info_open_idx = text.find('(', app_info_start_idx)
app_info_end_idx = find_matching_brace(text, app_info_open_idx + 1, '(', ')')
app_info = text[app_info_start_idx:app_info_end_idx]

div = "\n                const Divider(height: 1, color: Colors.white10),\n                "

new_children = f"""
          // 1. Appearance & UI
          _buildSectionHeader(TranslationService.isArabic ? "المظهر وواجهة المستخدم" : "Appearance & UI"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {app_lang}{div}{theme}{div}{navbar}{div}{time_format}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Quran Reading Experience
          _buildSectionHeader(TranslationService.isArabic ? "تجربة قراءة القرآن" : "Quran Reading Experience"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {quran_font}{div}{quran_tafsir}{div}{swipe_surah}{div}{hide_borders}{div}{immersive_reader}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Audio & Recitation
          _buildSectionHeader(TranslationService.isArabic ? "الصوتيات والتلاوة" : "Audio & Recitation"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {qari}{div}{continuous_rec}{div}{auto_bookmark}{div}{downloads}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Prayer Times & Calculations
          _buildSectionHeader(TranslationService.isArabic ? "أوقات الصلاة والحساب" : "Prayer Times & Calculations"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {calc_method}{div}{asr_method}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Adhan & Notifications
          _buildSectionHeader(TranslationService.isArabic ? "الأذان والإشعارات" : "Adhan & Notifications"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {adhan_style}{div}
                {adhan_reciters}{div}
                {pre_adhan_time}{div}{pre_adhan_style}
                {voice_preview}{div}
                {morning_azkar}{div}{evening_azkar}{div}{todays_verse}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Focus Mode
          _buildSectionHeader(TranslationService.t('focus_prayer_lock')),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {focus_timer}
                {focus_lock}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 7. System & Permissions
          _buildSectionHeader(TranslationService.isArabic ? "النظام والصلاحيات" : "System & Permissions"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {wake_lock}{div}{exact_alarms}{div}{battery_opt}
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 8. Support & Management
          _buildSectionHeader(TranslationService.isArabic ? "الدعم والإدارة" : "Support & Management"),
          Card(
            color: theme.cardColor,
            child: Column(
              children: [
                {support}{div}{about}{div}{reset}
              ],
            ),
          ),
          const SizedBox(height: 40),

          {app_info}
"""

start_marker = "          // Section Appearance"
end_marker = "        ],\n      ),\n    );"

s = text.find(start_marker)
e = text.find(end_marker, s)

new_text = text[:s] + new_children + text[e:]

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_text)

print("Done")
