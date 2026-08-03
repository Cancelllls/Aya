part of 'settings_screen.dart';

extension SettingsBackupSection on _SettingsScreenState {
  static const _platform = MethodChannel('com.quran.aya/system');

  List<Widget> _buildBackupSection(ThemeData theme) {
    final isArabic = TranslationService.isArabic;
    return [
      _buildSectionHeader(isArabic ? "النسخ الاحتياطي" : "Backup & Restore"),
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
                  leading: const Icon(Icons.upload, color: Color(0xFFE5C158)),
                  title: Text(isArabic ? "تصدير البيانات" : "Export Data"),
                  subtitle: Text(
                    isArabic
                        ? "مشاركة نسخة احتياطية من الإشارات والإعدادات"
                        : "Share backup of bookmarks, settings & tracker",
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    try {
                      await BackupService.shareBackup();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${isArabic ? "فشل" : "Failed"}: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFFE5C158)),
                  title: Text(isArabic ? "استيراد البيانات" : "Import Data"),
                  subtitle: Text(
                    isArabic
                        ? "استعادة من نسخة احتياطية سابقة"
                        : "Restore from a previous backup",
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    try {
                      final path = await _platform
                          .invokeMethod<String?>('pickFile');
                      if (path == null || path.isEmpty) return;

                      final content =
                          await BackupService.readBackupFromPath(path);
                      if (content == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? "تعذر فتح الملف. تأكد أنه ملف JSON صالح."
                                    : "Could not open file. Make sure it's a valid JSON.",
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      final data =
                          jsonDecode(content) as Map<String, dynamic>;
                      final count = await BackupService.importData(data);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? "✅ تم استيراد $count عنصر بنجاح"
                                  : "✅ $count items imported successfully",
                            ),
                            backgroundColor: const Color(0xFFE5C158),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isArabic ? "فشل" : "Failed"}: $e',
                            ),
                          ),
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
