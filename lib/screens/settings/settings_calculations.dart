part of 'settings_screen.dart';

extension SettingsCalculationsSection on _SettingsScreenState {
  List<Widget> _buildCalculationsSection(ThemeData theme) {
    return [
// Section Calculations
          _buildSectionHeader(TranslationService.t('calc_settings')),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white)
                        .withOpacity(0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(TranslationService.t('calc_method')),
                      subtitle: Text(TranslationService.t('calc_settings')),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _calcMethod,
                          underline: SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "جامعة العلوم الإسلامية بكراتشي"
                                      : "University of Islamic Sciences, Karachi",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "الهيئة الإسلامية لأمريكا الشمالية (ISNA)"
                                      : "Islamic Society of North America (ISNA)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "رابطة العالم الإسلامي"
                                      : "Muslim World League (MWL)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "جامعة أم القرى (مكة)"
                                      : "Umm Al-Qura University (Makkah)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "الهيئة المصرية العامة للمساحة"
                                      : "Egyptian General Authority of Survey",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 10,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "وزارة الأوقاف والشؤون الإسلامية (قطر)"
                                      : "Ministry of Awqaf (Qatar)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 11,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "المجلس الإسلامي السنغافوري (MUIS)"
                                      : "Majlis Ugama Islam Singapura (MUIS)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 12,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "اتحاد المنظمات الإسلامية بفرنسا (UOIF)"
                                      : "Union of Islamic Organisations of France (UOIF)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 13,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "تركيا (الشؤون الدينية)"
                                      : "Turkey (Diyanet)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 14,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "الإدارة الدينية لمسلمي روسيا الاتحادية"
                                      : "Spiritual Administration of Muslims of Russia",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 16,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "الهيئة العامة للشؤون الإسلامية والأوقاف (الإمارات)"
                                      : "General Authority of Islamic Affairs & Endowments (UAE)",
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeCalcMethod,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    ListTile(
                      title: Text(TranslationService.t('asr_calc_label')),
                      subtitle: Text(TranslationService.t('asr_calc_sub')),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _asrMethod,
                          underline: SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "الشافعي، المالكي، الحنبلي"
                                      : "Standard (Shafi'i, Maliki, Hanbali)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "المذهب الحنفي"
                                      : "Hanafi School",
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeAsrMethod,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20)
    ];
  }
}
