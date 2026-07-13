part of 'settings_screen.dart';

extension SettingsAppearanceSection on _SettingsScreenState {
  List<Widget> _buildAppearanceSection(ThemeData theme) {
    return [
// Section Appearance
          _buildSectionHeader(TranslationService.t('appearance')),
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
                      title: Text(TranslationService.t('theme_preset_label')),
                      subtitle: Text(TranslationService.t('theme_preset_sub')),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _themePreset,
                          underline: SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 'light',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "فاتح"
                                      : "Light",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'sepia',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "بني (قراءة)"
                                      : "Sepia/Parchment",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'dark',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic ? "داكن" : "Dark",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'black',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "أسود OLED"
                                      : "OLED Black",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'dark_monet',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "داكن متكيف"
                                      : "Adaptive Dark",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'white_monet',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "فاتح متكيف"
                                      : "Adaptive Light",
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeThemePreset,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    ListTile(
                      title: Text(
                        TranslationService.t('bottom_navbar_style_label'),
                      ),
                      subtitle: Text(
                        TranslationService.t('bottom_navbar_style_sub'),
                      ),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _bottomNavbarStyle,
                          underline: SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 'solid',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.t('bottom_navbar_solid'),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'floating',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.t(
                                    'bottom_navbar_floating',
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeBottomNavbarStyle,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    ListTile(
                      title: Text(TranslationService.t('quran_font')),
                      subtitle: Text(TranslationService.t('quran_font_sub')),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _quranFont,
                          underline: SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 'font-scheherazade',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "خط شهرزاد"
                                      : "Scheherazade Font",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'font-amiri',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "الخط الأميري"
                                      : "Amiri Font",
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeFont,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),

                    ListTile(
                      title: Text(
                        TranslationService.isArabic
                            ? "تفسير القرآن"
                            : "Quran Tafsir",
                      ),
                      subtitle: Text(
                        TranslationService.isArabic
                            ? "اختر كتاب التفسير المفضل"
                            : "Choose preferred Tafsir book",
                      ),
                      trailing: SizedBox(
                        width: 160,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _tafsirEdition,
                          underline: SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 'ar.muyassar',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "التفسير الميسر (المجمع)"
                                      : "Al-Muyassar (Assembly)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar.jalalayn',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "تفسير الجلالين"
                                      : "Tafsir Al-Jalalayn",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar.qurtubi',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "تفسير القرطبي"
                                      : "Tafsir Al-Qurtubi",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar.miqbas',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "تنوير المقباس (ابن عباس)"
                                      : "Tanwir al-Miqbas (Ibn Abbas)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar.waseet',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "التفسير الوسيط (الطنطاوي)"
                                      : "Al-Waseet (Tantawi)",
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar.baghawi',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  TranslationService.isArabic
                                      ? "تفسير البغوي"
                                      : "Tafsir Al-Baghawi",
                                ),
                              ),
                            ),
                          ],
                          onChanged: _changeTafsirEdition,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    SwitchListTile(
                      title: Text(
                        TranslationService.isArabic
                            ? "تنسيق الوقت ٢٤ ساعة"
                            : "24-Hour Time Format",
                      ),
                      subtitle: Text(
                        TranslationService.isArabic
                            ? "عرض أوقات الصلاة بتنسيق ٢٤ ساعة بدلاً من ١٢ ساعة"
                            : "Display prayer times in 24h format instead of 12h",
                      ),
                      activeThumbColor: const Color(0xFFE5C158),
                      value: _use24hFormat,
                      onChanged: _toggleUse24hFormat,
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    SwitchListTile(
                      title: Text(
                        TranslationService.isArabic
                            ? "سحب الشاشة للانتقال بين السور"
                            : "Swipe to Navigate Surahs",
                      ),
                      subtitle: Text(
                        TranslationService.isArabic
                            ? "اسحب لليمين أو اليسار للانتقال إلى السورة التالية أو السابقة"
                            : "Swipe left or right to read the previous or next Surah",
                      ),
                      activeThumbColor: const Color(0xFFE5C158),
                      value: _swipeSurahNavigation,
                      onChanged: _toggleSwipeSurahNavigation,
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
