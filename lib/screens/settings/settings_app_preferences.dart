part of 'settings_screen.dart';

extension SettingsAppPreferencesSection on _SettingsScreenState {
  List<Widget> _buildAppPreferencesSection(ThemeData theme) {
    return [
      // Section App Preferences
      _buildSectionHeader(
        TranslationService.isArabic ? "تفضيلات التطبيق" : "App Preferences",
      ),
      Card(
        color: theme.cardColor.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
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
                  title: Text(
                    TranslationService.isArabic
                        ? "أول أيام الأسبوع"
                        : "First Day of the Week",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "يوم بداية الأسبوع لمتتبع الصلاة"
                        : "Start day for the prayer tracker",
                  ),
                  trailing: SizedBox(
                    width: 160,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _firstDayOfWeek,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "الاثنين"
                                  : "Monday",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "السبت"
                                  : "Saturday",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic ? "الأحد" : "Sunday",
                            ),
                          ),
                        ),
                      ],
                      onChanged: _changeFirstDayOfWeek,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }
}
