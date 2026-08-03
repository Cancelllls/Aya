part of 'settings_screen.dart';

extension SettingsAudioSection on _SettingsScreenState {
  List<Widget> _buildAudioSection(ThemeData theme) {
    return [
      // Section Audio & Quran
      _buildSectionHeader(TranslationService.t('recitations')),
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
                SwitchListTile(
                  title: Text(TranslationService.t('continuous_rec_label')),
                  subtitle: Text(TranslationService.t('continuous_rec_sub')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _continuousPlay,
                  onChanged: _toggleContinuousPlay,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: Text(
                    TranslationService.isArabic
                        ? "إخفاء حدود القراءة المتواصلة"
                        : "Hide Continuous Mode Borders",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "إزالة الحواف والظلال لتصبح الصفحات متصلة تماماً"
                        : "Remove section borders and shadows for seamless reading",
                  ),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _hideContinuousBorders,
                  onChanged: _toggleHideContinuousBorders,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: Text(
                    TranslationService.isArabic
                        ? "حفظ المرجعية تلقائياً"
                        : "Auto-Bookmark on Play",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "حفظ الآية الحالية كعلامة مرجعية تلقائياً عند البدء بتشغيل التلاوة"
                        : "Automatically save the current verse as bookmark when audio playback starts",
                  ),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _autoBookmark,
                  onChanged: _toggleAutoBookmark,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: Text(
                    TranslationService.isArabic
                        ? "وضع القارئ الغامر"
                        : "Immersive Reader Mode",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "إخفاء أشرطة النظام (شريط الحالة والتنقل) أثناء قراءة القرآن لتقليل التشتيت"
                        : "Hide system bars (status and navigation) while reading Quran to reduce distraction",
                  ),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _immersiveReader,
                  onChanged: _toggleImmersiveReader,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.download_for_offline,
                    color: Color(0xFFE5C158),
                  ),
                  title: Text(TranslationService.t('quran_downloads')),
                  subtitle: Text(TranslationService.t('quran_downloads_sub')),
                  trailing: Icon(
                    TranslationService.isArabic
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    size: 14,
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.white)
                            .withValues(alpha: 0.3),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QuranDownloadScreen(storage: widget.storage),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: (Theme.of(context).dividerColor).withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.record_voice_over,
                    color: Color(0xFFE5C158),
                  ),
                  title: Text(
                    TranslationService.isArabic
                        ? 'تلاوات القراءات'
                        : "Qira'at Recitations",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? 'الاستماع للروايات المختلفة مثل ورش وقالون'
                        : 'Listen to different readings like Warsh and Qalun',
                  ),
                  trailing: Icon(
                    TranslationService.isArabic
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    size: 14,
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.white)
                            .withValues(alpha: 0.3),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QiraatScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: (Theme.of(context).dividerColor).withValues(alpha: 0.1),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: RecitersCacheService.loadingNotifier,
                  builder: (context, loading, _) {
                    return ListTile(
                      leading: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE5C158),
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              color: Color(0xFFE5C158),
                            ),
                      title: Text(
                        TranslationService.isArabic
                            ? 'تحديث قائمة القراء'
                            : 'Refresh Reciters List',
                      ),
                      subtitle: Text(
                        TranslationService.isArabic
                            ? 'جلب أحدث قائمة القراء من الخادم'
                            : 'Fetch the latest reciter list from the server',
                      ),
                      onTap: loading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await RecitersCacheService.refresh();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        TranslationService.isArabic
                                            ? 'تم تحديث قائمة القراء بنجاح'
                                            : 'Reciters list refreshed successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        TranslationService.isArabic
                                            ? 'فشل تحديث قائمة القراء'
                                            : 'Failed to refresh reciters list',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }
}
