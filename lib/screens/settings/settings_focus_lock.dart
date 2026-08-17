part of 'settings_screen.dart';

extension SettingsFocusLockSection on _SettingsScreenState {
  List<Widget> _buildFocusLockSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;
    final primary = theme.colorScheme.primary;

    return [
      // Section About & Support
      SettingsSectionHeader(
        icon: Icons.info_outline,
        title: isAr ? "عن التطبيق والدعم" : "About & Support",
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
                ListTile(
                  leading: Icon(Icons.info_outline, color: primary),
                  title: Text(
                    isAr ? "حول تطبيق آية" : "About Aya App",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr ? "معلومات الإصدار وتفاصيل الحقوق والتطوير" : "App version, licenses, and development credits",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(Icons.volunteer_activism_outlined, color: primary),
                  title: Text(
                    isAr ? "دعم تطبيق آية" : "Support Aya App",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr
                        ? "ساهم في دعم استضافة التطبيق وتطويره بدون إعلانات"
                        : "Support server costs and development, ad-free continuous charity",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showDonateDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
