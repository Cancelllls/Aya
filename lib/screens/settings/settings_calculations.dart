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
            color:
                (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
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
                  subtitle: Text(
                    _calcMethod == 0
                        ? (isAr
                              ? 'تلقائي: ${_getSmartMethodName(isAr)}'
                              : 'Auto: ${_getSmartMethodName(isAr)}')
                        : _calcMethod == -1
                        ? (isAr
                              ? 'فجر: ${_customFajrAngle.toStringAsFixed(1)}° • عشاء: ${_customIshaAngle.toStringAsFixed(1)}°'
                              : 'Fajr: ${_customFajrAngle.toStringAsFixed(1)}° • Isha: ${_customIshaAngle.toStringAsFixed(1)}°')
                        : TranslationService.t('calc_settings'),
                  ),
                  trailing: SettingsValueChip<int>(
                    value: _calcMethod,
                    label: isAr ? 'طريقة الحساب' : 'Calculation Method',
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(
                          isAr
                              ? "تلقائي (حسب الموقع)"
                              : "Auto (Based on Location)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          isAr
                              ? "جامعة العلوم الإسلامية بكراتشي"
                              : "Karachi (UISK)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                          isAr
                              ? "أمريكا الشمالية (ISNA)"
                              : "ISNA (North America)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(
                          isAr
                              ? "رابطة العالم الإسلامي"
                              : "Muslim World League",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text(
                          isAr
                              ? "جامعة أم القرى (مكة)"
                              : "Umm Al-Qura (Makkah)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text(
                          isAr
                              ? "الهيئة المصرية العامة للمساحة"
                              : "Egyptian Survey",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text(
                          isAr
                              ? "ديوان الوقف السني (العراق)"
                              : "Sunni Endowment (Iraq)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text(
                          isAr ? "وزارة الأوقاف (قطر)" : "Qatar Awqaf",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 11,
                        child: Text(
                          isAr
                              ? "المجلس الإسلامي السنغافوري"
                              : "Singapore (MUIS)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 12,
                        child: Text(
                          isAr ? "اتحاد المنظمات (فرنسا)" : "France (UOIF)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 13,
                        child: Text(
                          isAr ? "تركيا (الشؤون الدينية)" : "Turkey (Diyanet)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 14,
                        child: Text(
                          isAr ? "الإدارة الدينية (روسيا)" : "Russia (SAMR)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 16,
                        child: Text(
                          isAr
                              ? "الهيئة العامة للأوقاف (الإمارات)"
                              : "UAE (GAIAE)",
                        ),
                      ),
                      DropdownMenuItem(
                        value: -1,
                        child: Text(
                          isAr
                              ? "مخصص (زوايا الفجر والعشاء)"
                              : "Custom (Fajr & Isha Angles)",
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeCalcMethod(val);
                      }
                    },
                  ),
                ),
                if (_calcMethod == -1) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: primary),
                            const SizedBox(width: 8),
                            Text(
                              isAr
                                  ? 'ضبط الزوايا الفلكية المخصصة'
                                  : 'Custom Astronomical Angles',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildAngleSlider(
                          context: context,
                          label: isAr ? 'زاوية الفجر (درجة)' : 'Fajr Angle (°)',
                          value: _customFajrAngle,
                          min: 10.0,
                          max: 22.0,
                          primaryColor: primary,
                          onChanged: _changeCustomFajrAngle,
                        ),
                        const SizedBox(height: 10),
                        _buildAngleSlider(
                          context: context,
                          label: isAr
                              ? 'زاوية العشاء (درجة)'
                              : 'Isha Angle (°)',
                          value: _customIshaAngle,
                          min: 10.0,
                          max: 22.0,
                          primaryColor: primary,
                          onChanged: _changeCustomIshaAngle,
                        ),
                      ],
                    ),
                  ),
                ],
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Asr Method
                ListTile(
                  leading: Icon(
                    Icons.access_time_filled_outlined,
                    color: primary,
                  ),
                  title: Text(TranslationService.t('asr_calc_label')),
                  subtitle: Text(TranslationService.t('asr_calc_sub')),
                  trailing: SettingsValueChip<int>(
                    value: _asrMethod,
                    label: isAr ? 'مذهب صلاة العصر' : 'Asr Method',
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(
                          isAr
                              ? "جمهور العلماء (الشافعي/المالكي/الحنبلي)"
                              : "Standard (Shafi'i, Maliki, Hanbali)",
                        ),
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
                  title: Text(
                    isAr
                        ? 'تعديل مواقيت الصلاة (بالدقائق)'
                        : 'Fine-Tune Prayer Times',
                  ),
                  subtitle: Text(
                    isAr
                        ? 'تقديم أو تأخير دقائق لضبط المواعيد حسب مسجدك المحلي'
                        : 'Adjust minutes to match your local mosque',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrayerTimeAdjustScreen(storage: widget.storage),
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

  Widget _buildAngleSlider({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required Color primaryColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: primaryColor,
            thumbColor: primaryColor,
            inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 2).toInt(),
            onChanged: (v) {
              final rounded = (v * 2).round() / 2.0;
              onChanged(rounded);
            },
          ),
        ),
      ],
    );
  }
}
