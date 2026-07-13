part of 'settings_screen.dart';

extension SettingsLanguageSection on _SettingsScreenState {
  List<Widget> _buildLanguageSection(ThemeData theme) {
    return [
// Section Language
          _buildSectionHeader(TranslationService.t('app_lang')),
          Card(
            color: theme.cardColor,
            child: ListTile(
              title: Text(TranslationService.t('app_lang')),
              subtitle: Text(TranslationService.t('app_lang_sub')),
              trailing: SizedBox(
                width: 160,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: TranslationService.currentLanguage,
                  underline: SizedBox(),
                  dropdownColor: theme.cardColor,
                  items: [
                    const DropdownMenuItem(
                      value: 'ar',
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text("العربية"),
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'en',
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text("English"),
                      ),
                    ),
                  ],
                  onChanged: (lang) async {
                    if (lang != null) {
                      final navigator = Navigator.of(context);
                      await widget.storage.setString('lang_code', lang);
                      TranslationService.setLanguage(lang);

                      // Root level rebuild & reload navigation stack to main dashboard page
                      widget.onThemeChanged();
                      if (mounted) {
                        unawaited(
                          navigator.pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 20)
    ];
  }
}
