part of 'settings_screen.dart';

extension SettingsFocusLockSection on _SettingsScreenState {
  List<Widget> _buildFocusLockSection(ThemeData theme) {
    return [
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
