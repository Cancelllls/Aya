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
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services, color: Color(0xFFE5C158)),
                  title: Text(isArabic ? "إدارة التخزين والتخزين المؤقت" : "Storage & Cache Management"),
                  subtitle: Text(
                    isArabic
                        ? "مسح الملفات المؤقتة وذاكرة التخزين التلقائية"
                        : "Clear temporary audio & system cache files",
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(
                          isArabic ? "مسح ذاكرة التخزين؟" : "Clear Cache?",
                          style: const TextStyle(
                            color: Color(0xFFE5C158),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          isArabic
                              ? "سيتم حذف الملفات المؤقتة فقط. لن تفقد إشاراتك أو إعداداتك."
                              : "This will only delete temporary files. Your bookmarks and settings will remain safe.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(TranslationService.t('cancel')),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5C158),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              isArabic ? "مسح" : "Clear",
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        final tempDir = await getTemporaryDirectory();
                        if (await tempDir.exists()) {
                          final entities = tempDir.listSync();
                          for (final entity in entities) {
                            try {
                              entity.deleteSync(recursive: true);
                            } catch (_) {}
                          }
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? "✅ تم مسح ذاكرة التخزين المؤقت."
                                    : "✅ Temporary cache cleared.",
                              ),
                              backgroundColor: const Color(0xFFE5C158),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${isArabic ? "فشل" : "Failed"}: $e'),
                            ),
                          );
                        }
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
