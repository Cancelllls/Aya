with open('lib/screens/settings_screen.dart', 'r') as f:
    lines = f.readlines()

def get_lines(start, end):
    return "".join(lines[start:end+1])

def get_lines_clean(start, end, add_comma=True):
    block = get_lines(start, end).rstrip()
    if block.endswith(','):
        block = block[:-1]
    if add_comma:
        block += ','
    return block + '\n'

theme = get_lines_clean(700, 717)
navbar = get_lines_clean(719, 732)
quran_font = get_lines_clean(734, 747)
quran_tafsir = get_lines_clean(749, 766)
time_format = get_lines_clean(768, 776)
swipe_surah = get_lines_clean(778, 786)

app_lang = get_lines_clean(796, 821).replace('child: ListTile', 'ListTile')
calc_method = get_lines_clean(831, 933)
asr_method = get_lines_clean(935, 970)

pre_adhan_time = get_lines_clean(980, 1002)
pre_adhan_style = get_lines_clean(1004, 1042)
voice_preview = get_lines_clean(1043, 1072)

adhan_style = get_lines_clean(1074, 1115)
adhan_reciters = get_lines_clean(1116, 1252)

morning_azkar = get_lines_clean(1254, 1259)
evening_azkar = get_lines_clean(1261, 1266)
todays_verse = get_lines_clean(1268, 1273)

qari = get_lines_clean(1285, 1300)
continuous_rec = get_lines_clean(1302, 1308)
hide_borders = get_lines_clean(1310, 1318)
auto_bookmark = get_lines_clean(1320, 1328)
immersive_reader = get_lines_clean(1330, 1338)
downloads = get_lines_clean(1340, 1353)

wake_lock = get_lines_clean(1365, 1371)
exact_alarms = get_lines_clean(1373, 1398)
battery_opt = get_lines_clean(1400, 1425)

focus_timer = get_lines_clean(1437, 1454)
focus_lock = get_lines_clean(1455, 1493)

support = get_lines_clean(1502, 1515).replace('child: ListTile', 'ListTile')
about = get_lines_clean(1519, 1530).replace('child: ListTile', 'ListTile')
reset = get_lines_clean(1537, 1546).replace('child: ListTile', 'ListTile')

app_info = get_lines(1551, 1571)

div = "                const Divider(height: 1, color: Colors.white10),\n"

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

start_idx = 709  # 'children: ['
end_idx = 1571   # end of app_info (1571 is the last `)` of app_info)

new_text = "".join(lines[:start_idx+1]) + new_children + "".join(lines[end_idx+1:])

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_text)

print("Done")
