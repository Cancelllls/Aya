part of 'settings_screen.dart';

extension SettingsFocusLockSection on _SettingsScreenState {
  List<Widget> _buildFocusLockSection(ThemeData theme) {
    return [
      // Section Focus Lock
      _buildSectionHeader(TranslationService.t('focus_prayer_lock')),
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
                ListTile(
                  title: Text(TranslationService.t('focus_timer')),
                  subtitle: Text(TranslationService.t('focus_prayer_lock_sub')),
                  trailing: SizedBox(
                    width: 160,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _focusLockDuration,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic ? "إيقاف" : "Off",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "٥ دقائق"
                                  : "5 Minutes",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "١٠ دقائق"
                                  : "10 Minutes",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 15,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "١٥ دقيقة"
                                  : "15 Minutes",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 20,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "٢٠ دقيقة"
                                  : "20 Minutes",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "٣٠ دقيقة"
                                  : "30 Minutes",
                            ),
                          ),
                        ),
                      ],
                      onChanged: _changeFocusDuration,
                    ),
                  ),
                ),
                if (_focusLockDuration > 0) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    title: Text(
                      TranslationService.isArabic
                          ? "نوع قفل التركيز"
                          : "Focus Lock Mode",
                    ),
                    subtitle: Text(
                      TranslationService.isArabic
                          ? "اختر قفل التطبيق فقط أو قفل الهاتف بالكامل"
                          : "Choose whether to lock the app or the entire phone",
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _focusLockType,
                        underline: const SizedBox(),
                        dropdownColor: theme.cardColor,
                        items: [
                          DropdownMenuItem(
                            value: 'app_only',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "قفل التطبيق فقط"
                                    : "App Lock Only",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'whole_phone',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "قفل الهاتف بالكامل"
                                    : "Whole Phone Lock",
                              ),
                            ),
                          ),
                        ],
                        onChanged: _changeFocusLockType,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  SwitchListTile(
                    title: Text(TranslationService.t('focus_setting_auto')),
                    activeThumbColor: const Color(0xFFE5C158),
                    value: _focusAutoStart,
                    onChanged: _toggleFocusAutoStart,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Donation Support Section
      _buildSectionHeader(
        TranslationService.isArabic
            ? "الدعم والمساهمة"
            : "Support & Contribution",
      ),
      Card(
        color: theme.cardColor,
        child: ListTile(
          leading: const Icon(
            Icons.volunteer_activism,
            color: Color(0xFFE5C158),
          ),
          title: Text(
            TranslationService.isArabic ? "دعم تطبيق آية" : "Support Aya App",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            TranslationService.isArabic
                ? "ساهم في دعم استضافة التطبيق وتطويره بدون إعلانات صدقة جارية"
                : "Support server costs and development, ad-free continuous charity",
          ),
          trailing: Icon(
            TranslationService.isArabic
                ? Icons.arrow_back_ios
                : Icons.arrow_forward_ios,
            size: 14,
            color: const Color(0xFFE5C158),
          ),
          onTap: _showDonateDialog,
        ),
      ),
      Card(
        color: theme.cardColor,
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: Color(0xFFE5C158)),
          title: Text(
            TranslationService.isArabic ? "حول التطبيق" : "About Aya",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Icon(
            TranslationService.isArabic
                ? Icons.arrow_back_ios
                : Icons.arrow_forward_ios,
            size: 14,
            color: const Color(0xFFE5C158),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          },
        ),
      ),
      const SizedBox(height: 20),

      // Reset Section
      _buildSectionHeader(TranslationService.t('system_management')),
      Card(
        color: theme.cardColor,
        child: ListTile(
          title: Text(
            TranslationService.t('reset_settings'),
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(TranslationService.t('reset_settings_sub')),
          trailing: Icon(
            TranslationService.isArabic
                ? Icons.arrow_back_ios
                : Icons.arrow_forward_ios,
            size: 14,
            color: Colors.redAccent,
          ),
          onTap: _resetApp,
        ),
      ),
    ];
  }
}
