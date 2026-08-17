part of 'settings_screen.dart';

extension SettingsCalculationsSection on _SettingsScreenState {
  List<Widget> _buildCalculationsSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;

    final primary = theme.colorScheme.primary;

    return [
      // Section Prayer Times
      SettingsSectionHeader(
        icon: Icons.mosque_outlined,
        title: isAr ? 'مواقيت الصلاة والحساب' : 'Prayer Times & Calculation',
      ),
      Card(
        color: theme.cardColor.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
                .withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              children: [
                // Calculation Method
                ListTile(
                  leading: Icon(Icons.calculate_outlined, color: primary),
                  title: Text(TranslationService.t('calc_method')),
                  subtitle: Text(TranslationService.t('calc_settings')),
                  trailing: SettingsValueChip<int>(
                    value: _calcMethod,
                    label: isAr ? 'طريقة الحساب' : 'Calculation Method',
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(isAr ? "جامعة العلوم الإسلامية بكراتشي" : "Karachi (UISK)"),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(isAr ? "أمريكا الشمالية (ISNA)" : "ISNA (North America)"),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(isAr ? "رابطة العالم الإسلامي" : "Muslim World League"),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text(isAr ? "جامعة أم القرى (مكة)" : "Umm Al-Qura (Makkah)"),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text(isAr ? "الهيئة المصرية العامة للمساحة" : "Egyptian Survey"),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text(isAr ? "وزارة الأوقاف (قطر)" : "Qatar Awqaf"),
                      ),
                      DropdownMenuItem(
                        value: 11,
                        child: Text(isAr ? "المجلس الإسلامي السنغافوري" : "Singapore (MUIS)"),
                      ),
                      DropdownMenuItem(
                        value: 12,
                        child: Text(isAr ? "اتحاد المنظمات (فرنسا)" : "France (UOIF)"),
                      ),
                      DropdownMenuItem(
                        value: 13,
                        child: Text(isAr ? "تركيا (الشؤون الدينية)" : "Turkey (Diyanet)"),
                      ),
                      DropdownMenuItem(
                        value: 14,
                        child: Text(isAr ? "الإدارة الدينية (روسيا)" : "Russia (SAMR)"),
                      ),
                      DropdownMenuItem(
                        value: 16,
                        child: Text(isAr ? "الهيئة العامة للأوقاف (الإمارات)" : "UAE (GAIAE)"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeCalcMethod(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Asr Method
                ListTile(
                  leading: Icon(Icons.access_time_filled_outlined, color: primary),
                  title: Text(TranslationService.t('asr_calc_label')),
                  subtitle: Text(TranslationService.t('asr_calc_sub')),
                  trailing: SettingsValueChip<int>(
                    value: _asrMethod,
                    label: isAr ? 'مذهب صلاة العصر' : 'Asr Method',
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(isAr ? "جمهور العلماء (الشافعي/المالكي/الحنبلي)" : "Standard (Shafi'i, Maliki, Hanbali)"),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(isAr ? "المذهب الحنفي" : "Hanafi School"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeAsrMethod(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Fine-Tune Navigation Tile
                ListTile(
                  leading: Icon(Icons.tune_outlined, color: primary),
                  title: Text(isAr ? 'تعديل مواقيت الصلاة (بالدقائق)' : 'Fine-Tune Prayer Times'),
                  subtitle: Text(isAr ? 'تقديم أو تأخير دقائق لضبط المواعيد حسب مسجدك المحلي' : 'Adjust minutes to match your local mosque'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrayerTimeAdjustScreen(storage: widget.storage),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
