part of 'settings_screen.dart';

extension SettingsAudioSection on _SettingsScreenState {
  List<Widget> _buildAudioSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;
    final primary = theme.colorScheme.primary;

    return [
      // Section Quran & Audio
      SettingsSectionHeader(
        icon: Icons.menu_book_outlined,
        title: isAr ? 'القرآن والتلاوة والصوت' : 'Quran, Audio & Reading',
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
                // Qira'at Recitations Tile
                ListTile(
                  leading: Icon(Icons.record_voice_over_outlined, color: primary),
                  title: Text(
                    isAr ? 'تلاوات القراءات' : "Qira'at Recitations",
                  ),
                  subtitle: Text(
                    isAr
                        ? 'الاستماع للروايات المختلفة مثل ورش وقالون'
                        : 'Listen to different readings like Warsh and Qalun',
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Quran Downloads Tile
                ListTile(
                  leading: Icon(Icons.download_for_offline_outlined, color: primary),
                  title: Text(TranslationService.t('quran_downloads')),
                  subtitle: Text(TranslationService.t('quran_downloads_sub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranDownloadScreen(storage: widget.storage),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Continuous Recitation
                SwitchListTile(
                  secondary: Icon(Icons.play_circle_outline, color: primary),
                  title: Text(TranslationService.t('continuous_rec_label')),
                  subtitle: Text(TranslationService.t('continuous_rec_sub')),
                  activeColor: primary,
                  value: _continuousPlay,
                  onChanged: _toggleContinuousPlay,
                ),
                if (_continuousPlay) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  SwitchListTile(
                    secondary: Icon(Icons.border_clear_outlined, color: primary),
                    title: Text(
                      isAr ? "إخفاء حدود القراءة المتواصلة" : "Hide Continuous Mode Borders",
                    ),
                    subtitle: Text(
                      isAr
                          ? "إزالة الحواف والظلال لتصبح الصفحات متصلة تماماً"
                          : "Remove section borders and shadows for seamless reading",
                    ),
                    activeColor: primary,
                    value: _hideContinuousBorders,
                    onChanged: _toggleHideContinuousBorders,
                  ),
                ],
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Auto-Bookmark
                SwitchListTile(
                  secondary: Icon(Icons.bookmark_add_outlined, color: primary),
                  title: Text(
                    isAr ? "حفظ المرجعية تلقائياً" : "Auto-Bookmark on Play",
                  ),
                  subtitle: Text(
                    isAr
                        ? "حفظ الآية الحالية كعلامة مرجعية تلقائياً عند البدء بتشغيل التلاوة"
                        : "Automatically save current verse as bookmark when playback starts",
                  ),
                  activeColor: primary,
                  value: _autoBookmark,
                  onChanged: _toggleAutoBookmark,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Immersive Reader
                SwitchListTile(
                  secondary: Icon(Icons.fullscreen_outlined, color: primary),
                  title: Text(
                    isAr ? "وضع القارئ الغامر" : "Immersive Reader Mode",
                  ),
                  subtitle: Text(
                    isAr
                        ? "إخفاء أشرطة النظام أثناء قراءة القرآن لتقليل التشتيت"
                        : "Hide status and navigation bars while reading",
                  ),
                  activeColor: primary,
                  value: _immersiveReader,
                  onChanged: _toggleImmersiveReader,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Refresh Reciters List
                ValueListenableBuilder<bool>(
                  valueListenable: RecitersCacheService.loadingNotifier,
                  builder: (context, loading, _) {
                    return ListTile(
                      leading: loading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primary,
                              ),
                            )
                          : Icon(Icons.refresh, color: primary),
                      title: Text(
                        isAr ? 'تحديث قائمة القراء' : 'Refresh Reciters List',
                      ),
                      subtitle: Text(
                        isAr
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
                                        isAr
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
                                        isAr
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
    ];
  }
}
