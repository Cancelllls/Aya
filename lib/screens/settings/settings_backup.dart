part of 'settings_screen.dart';

extension SettingsBackupSection on _SettingsScreenState {
  static const _platform = MethodChannel('com.quran.aya/system');

  List<Widget> _buildBackupSection(ThemeData theme) {
    final isArabic = TranslationService.isArabic;
    final primary = theme.colorScheme.primary;
    return [
      // Section Data & Backup
      SettingsSectionHeader(
        icon: Icons.storage_outlined,
        title: isArabic ? "إدارة البيانات والنسخ الاحتياطي" : "Data & Backup Management",
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
                  leading: Icon(Icons.upload_outlined, color: primary),
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
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(Icons.download_outlined, color: primary),
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
                            backgroundColor: Colors.teal,
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
                  leading: Icon(Icons.cleaning_services_outlined, color: primary),
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
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              isArabic ? "مسح" : "Clear",
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
                              backgroundColor: Colors.teal,
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
      const SizedBox(height: 12),

      // Separate Danger Card for Reset Settings
      Card(
        color: Colors.red.shade900.withValues(alpha: 0.15),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
          title: Text(
            TranslationService.t('reset_settings'),
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isArabic ? "إعادة ضبط جميع الإعدادات إلى وضعها الافتراضي الاصلي" : "Reset all app preferences to original factory defaults",
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(TranslationService.t('reset_settings')),
                content: Text(
                  isArabic
                      ? "هل أنت أصلًا متأكد من إعادة ضبط كافة الإعدادات؟"
                      : "Are you sure you want to reset all settings to defaults?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(TranslationService.t('cancel')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      isArabic ? "إعادة ضبط" : "Reset",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await widget.storage.clearAll();
              if (mounted) {
                widget.onThemeChanged();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            }
          },
        ),
      ),
    ];
  }
}
