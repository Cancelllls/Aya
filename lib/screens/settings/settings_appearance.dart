part of 'settings_screen.dart';

extension SettingsAppearanceSection on _SettingsScreenState {
  Future<void> _changeLanguage(String lang) async {
    final navigator = Navigator.of(context);
    await widget.storage.setString('lang_code', lang);
    TranslationService.setLanguage(lang);
    widget.onThemeChanged();
    if (mounted) {
      unawaited(
        navigator.pushNamedAndRemoveUntil('/', (route) => false),
      );
    }
  }

  Future<void> _changeFirstDayOfWeek(int day) async {
    setState(() {
      _firstDayOfWeek = day;
    });
    await widget.storage.setInt('first_day_of_week', day);
  }

  List<Widget> _buildAppearanceSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;

    final primary = theme.colorScheme.primary;

    return [
      // Section Personalization
      SettingsSectionHeader(
        icon: Icons.palette_outlined,
        title: isAr ? 'التخصيص والمظهر' : 'Personalization',
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
                // App Language
                ListTile(
                  leading: Icon(Icons.language, color: primary),
                  title: Text(isAr ? 'لغة التطبيق' : 'App Language'),
                  trailing: SettingsValueChip<String>(
                    value: TranslationService.currentLanguage,
                    label: isAr ? 'اختر لغة التطبيق' : 'Select App Language',
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeLanguage(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Theme Preset
                ListTile(
                  leading: Icon(Icons.color_lens_outlined, color: primary),
                  title: Text(TranslationService.t('theme_preset_label')),
                  subtitle: Text(TranslationService.t('theme_preset_sub')),
                  trailing: SettingsValueChip<String>(
                    value: _themePreset,
                    label: isAr ? 'نمط المظهر' : 'Theme Preset',
                    items: [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text(isAr ? "فاتح" : "Light"),
                      ),
                      DropdownMenuItem(
                        value: 'sepia',
                        child: Text(isAr ? "بني (قراءة)" : "Sepia/Parchment"),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(isAr ? "داكن" : "Dark"),
                      ),
                      DropdownMenuItem(
                        value: 'black',
                        child: Text(isAr ? "أسود OLED" : "OLED Black"),
                      ),
                      DropdownMenuItem(
                        value: 'dark_monet',
                        child: Text(isAr ? "داكن متكيف" : "Adaptive Dark"),
                      ),
                      DropdownMenuItem(
                        value: 'white_monet',
                        child: Text(isAr ? "فاتح متكيف" : "Adaptive Light"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeThemePreset(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Bottom Navbar Style
                ListTile(
                  leading: Icon(Icons.view_quilt_outlined, color: primary),
                  title: Text(TranslationService.t('bottom_navbar_style_label')),
                  subtitle: Text(TranslationService.t('bottom_navbar_style_sub')),
                  trailing: SettingsValueChip<String>(
                    value: _bottomNavbarStyle,
                    label: isAr ? 'نمط شريط التنقل' : 'Navigation Bar Style',
                    items: [
                      DropdownMenuItem(
                        value: 'solid',
                        child: Text(TranslationService.t('bottom_navbar_solid')),
                      ),
                      DropdownMenuItem(
                        value: 'floating',
                        child: Text(TranslationService.t('bottom_navbar_floating')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeBottomNavbarStyle(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Quran Font
                ListTile(
                  leading: Icon(Icons.font_download_outlined, color: primary),
                  title: Text(TranslationService.t('quran_font')),
                  subtitle: Text(TranslationService.t('quran_font_sub')),
                  trailing: SettingsValueChip<String>(
                    value: _quranFont,
                    label: isAr ? 'خط المصحف' : 'Quran Font',
                    items: [
                      DropdownMenuItem(
                        value: 'font-scheherazade',
                        child: Text(isAr ? "خط شهرزاد" : "Scheherazade Font"),
                      ),
                      DropdownMenuItem(
                        value: 'font-amiri',
                        child: Text(isAr ? "الخط الأميري" : "Amiri Font"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeFont(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // First Day of Week
                ListTile(
                  leading: Icon(Icons.today_outlined, color: primary),
                  title: Text(isAr ? 'أول يوم في الأسبوع' : 'First Day of the Week'),
                  trailing: SettingsValueChip<int>(
                    value: _firstDayOfWeek,
                    label: isAr ? 'أول يوم في الأسبوع' : 'First Day of Week',
                    items: [
                      DropdownMenuItem(value: 6, child: Text(isAr ? 'السبت' : 'Saturday')),
                      DropdownMenuItem(value: 7, child: Text(isAr ? 'الأحد' : 'Sunday')),
                      DropdownMenuItem(value: 1, child: Text(isAr ? 'الإثنين' : 'Monday')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeFirstDayOfWeek(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // 24h Clock Format
                SwitchListTile(
                  secondary: Icon(Icons.schedule, color: primary),
                  title: Text(
                    isAr ? "تنسيق الوقت ٢٤ ساعة" : "24-Hour Time Format",
                  ),
                  subtitle: Text(
                    isAr
                        ? "عرض أوقات الصلاة بتنسيق ٢٤ ساعة بدلاً من ١٢ ساعة"
                        : "Display prayer times in 24h format instead of 12h",
                  ),
                  activeColor: primary,
                  value: _use24hFormat,
                  onChanged: _toggleUse24hFormat,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Swipe Navigation
                SwitchListTile(
                  secondary: Icon(Icons.swipe_outlined, color: primary),
                  title: Text(
                    isAr ? "سحب الشاشة للانتقال بين السور" : "Swipe to Navigate Surahs",
                  ),
                  subtitle: Text(
                    isAr
                        ? "اسحب لليمين أو اليسار للانتقال إلى السورة التالية أو السابقة"
                        : "Swipe left or right to read the previous or next Surah",
                  ),
                  activeColor: primary,
                  value: _swipeSurahNavigation,
                  onChanged: _toggleSwipeSurahNavigation,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Keep Screen Awake
                SwitchListTile(
                  secondary: Icon(Icons.screen_lock_portrait_outlined, color: theme.colorScheme.primary),
                  title: Text(TranslationService.t('wake_lock')),
                  subtitle: Text(TranslationService.t('wake_lock_sub')),
                  activeColor: theme.colorScheme.primary,
                  value: _keepScreenAwake,
                  onChanged: _toggleKeepScreenAwake,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
