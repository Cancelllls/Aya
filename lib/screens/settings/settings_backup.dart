part of 'settings_screen.dart';

extension SettingsBackupSection on _SettingsScreenState {
  List<Widget> _buildBackupSection(ThemeData theme) {
    final isArabic = TranslationService.isArabic;
    return [
      _buildSectionHeader(isArabic ? "النسخ الاحتياطي" : "Backup & Restore"),
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
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isArabic ? "تأكيد الاستيراد" : "Confirm Import"),
                        content: Text(
                          isArabic
                              ? "سيتم استبدال الإشارات والإعدادات الحالية. هل تريد المتابعة؟"
                              : "This will replace your current bookmarks and settings. Continue?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(isArabic ? "إلغاء" : "Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5C158),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              isArabic ? "استيراد" : "Import",
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      // Try default backup location + Downloads
                      final content = await BackupService.readDefaultBackup();
                      if (content == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? "لم يتم العثور على ملف aya_backup.json. تأكد من وجوده في مجلد التنزيلات."
                                    : "No aya_backup.json found. Make sure it's in your Downloads folder.",
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                        return;
                      }
                      final data = jsonDecode(content) as Map<String, dynamic>;
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
                          SnackBar(content: Text('${isArabic ? "فشل" : "Failed"}: $e')),
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
