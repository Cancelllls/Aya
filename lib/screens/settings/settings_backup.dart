part of 'settings_screen.dart';

extension SettingsBackupSection on _SettingsScreenState {
  List<Widget> _buildBackupSection(ThemeData theme) {
    return [
      _buildSectionHeader(
        TranslationService.isArabic ? "النسخ الاحتياطي" : "Backup & Restore",
      ),
      Card(
        color: theme.cardColor.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
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
                  leading: const Icon(Icons.upload, color: Color(0xFFE5C158)),
                  title: Text(
                    TranslationService.isArabic
                        ? "تصدير البيانات"
                        : "Export Backup",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "الإشارات، الإعدادات، الأذكار، متتبع الصلاة"
                        : "Bookmarks, settings, azkar, prayer tracker",
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    try {
                      await BackupService.shareBackup();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${TranslationService.isArabic ? "فشل" : "Failed"}: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFFE5C158)),
                  title: Text(
                    TranslationService.isArabic
                        ? "استيراد البيانات"
                        : "Import Backup",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "استعادة من ملف النسخ الاحتياطي"
                        : "Restore from backup file",
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    try {
                      // Open file picker or instruct user
                      await BackupService.shareBackup();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              TranslationService.isArabic
                                  ? "للاستيراد، افتح ملف .json في تطبيق آية"
                                  : "To import, open the .json file with Aya app",
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${TranslationService.isArabic ? "فشل" : "Failed"}: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
