part of 'settings_screen.dart';

extension SettingsBackupSection on _SettingsScreenState {
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
                    // Show path input dialog — user pastes the file path
                    final controller = TextEditingController();
                    // Pre-fill common locations
                    controller.text = '/storage/emulated/0/Download/aya_backup.json';
                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    );

                    final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isArabic ? "استيراد نسخة احتياطية" : "Import Backup"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isArabic
                                  ? 'الصق مسار ملف النسخة الاحتياطية:'
                                  : 'Paste the backup file path:',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: '/storage/emulated/0/...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isArabic
                                  ? 'تلميح: يستخدم مدراء الملفات "نسخ المسار" أو "Copy Path". '
                                      'أو حرّك الملف لمجلد التنزيلات ليكتشفه التطبيق تلقائياً.'
                                  : 'Tip: Use your file manager\'s "Copy Path". '
                                      'Or move the file to Downloads for auto-detection.',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(isArabic ? "إلغاء" : "Cancel"),
                          ),
                          // Auto-detect button
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 'auto'),
                            child: Text(
                              isArabic ? "بحث تلقائي" : "Auto-detect",
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5C158),
                            ),
                            onPressed: () => Navigator.pop(ctx, controller.text),
                            child: Text(
                              isArabic ? "استيراد" : "Import",
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (result == null || result.isEmpty) return;

                    try {
                      String? content;
                      if (result == 'auto') {
                        content = await BackupService.readDefaultBackup();
                      } else {
                        content = await BackupService.readBackupFromPath(result);
                      }
                      if (content == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? "تعذر فتح الملف. تحقق من المسار والصلاحيات."
                                    : "Could not open file. Check the path and permissions.",
                              ),
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
