part of 'settings_screen.dart';

extension SettingsPermissionsSection on _SettingsScreenState {
  List<Widget> _buildPermissionsSection(ThemeData theme) {
    return [
// Section Permissions
          _buildSectionHeader(
            TranslationService.t('system_settings_permissions'),
          ),
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
                    SwitchListTile(
                      title: Text(TranslationService.t('wake_lock')),
                      subtitle: Text(TranslationService.t('wake_lock_sub')),
                      activeThumbColor: const Color(0xFFE5C158),
                      value: _keepScreenAwake,
                      onChanged: _toggleKeepScreenAwake,
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    ListTile(
                      title: Text(TranslationService.t('exact_alarms')),
                      subtitle: Text(TranslationService.t('exact_alarms_sub')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _exactAlarmPermitted
                                ? (TranslationService.isArabic
                                      ? "مسموح"
                                      : "Allowed")
                                : (TranslationService.isArabic
                                      ? "إعداد مطلوب"
                                      : "Setup Required"),
                            style: TextStyle(
                              color: _exactAlarmPermitted
                                  ? Colors.green
                                  : const Color(0xFFE5C158),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            TranslationService.isArabic
                                ? Icons.arrow_back_ios
                                : Icons.arrow_forward_ios,
                            size: 12,
                            color: _exactAlarmPermitted
                                ? (Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color ??
                                          Colors.white)
                                      .withOpacity(0.3)
                                : const Color(0xFFE5C158),
                          ),
                        ],
                      ),
                      onTap: _exactAlarmPermitted ? null : _requestExactAlarm,
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
