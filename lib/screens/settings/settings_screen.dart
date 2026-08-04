import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../services/backup_service.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../models/prayer_models.dart';
import '../quran_download_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/adhan_audio_service.dart';
import '../../services/reciters_cache_service.dart';
import '../../donation/flavor.dart';
import '../../donation/google_play_donation.dart';
import '../../version.dart';
import '../about_screen.dart';
import '../qiraat_screen.dart';

part 'settings_appearance.dart';
part 'settings_language.dart';
part 'settings_calculations.dart';
part 'settings_app_preferences.dart';
part 'settings_notifications.dart';
part 'settings_audio.dart';
part 'settings_permissions.dart';
part 'settings_focus_lock.dart';
part 'settings_backup.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.storage,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.quran.aya/system');

  String _themePreset = 'dark';
  String _bottomNavbarStyle = 'solid';
  String _quranFont = 'font-amiri';
  String _tafsirEdition = 'ar.muyassar';

  // Add calculation settings
  int _calcMethod = 2;
  int _asrMethod = 0;
  bool _continuousPlay = true;
  bool _hideContinuousBorders = false;
  bool _autoBookmark = true;
  bool _immersiveReader = false;

  // Permissions and wake lock
  bool _exactAlarmPermitted = true;
  bool _keepScreenAwake = false;

  bool _morningAzkarReminder = true;
  bool _eveningAzkarReminder = true;
  bool _todaysVerseReminder = true;
  bool _ramadanImsakEnabled = true;
  int _ramadanImsakOffset = 0;
  bool _ramadanIftarEnabled = true;
  bool _islamicEventsEnabled = true;

  // New settings options
  bool _use24hFormat = false;
  bool _swipeSurahNavigation = true;
  int _firstDayOfWeek = 1;
  String _preAdhanAlertMode = 'vibrate'; // vibrate vs voice
  int _preAdhanDuration = 10; // minutes before adhan
  String _adhanAlertMode = 'real_reciter'; // silent vs vibrate vs real_reciter
  String _adhanReciter = 'mishary'; // mishary, abdul_basit, makkah, madinah
  String _athanStopGesture = 'both'; // both, volume_only, flip_only, none
  Timer? _rescheduleTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdhanAudioService.instance.init();
    _themePreset = widget.storage.getString(
      'theme_preset',
      defaultValue: 'dark',
    );
    _bottomNavbarStyle = widget.storage.getString(
      'bottom_navbar_style',
      defaultValue: 'floating',
    );
    _quranFont = widget.storage.getString(
      'quran_font',
      defaultValue: 'font-amiri',
    );
    _tafsirEdition = widget.storage.getString(
      'default_tafsir',
      defaultValue: 'ar.muyassar',
    );

    _calcMethod = widget.storage.getInt('calc_method', defaultValue: 2);
    _asrMethod = widget.storage.getInt('asr_method', defaultValue: 0);
    _continuousPlay = widget.storage.getBool(
      'setting_continuous_play',
      defaultValue: true,
    );
    _hideContinuousBorders = widget.storage.getBool(
      'setting_hide_continuous_borders',
      defaultValue: false,
    );
    _autoBookmark = widget.storage.getBool(
      'setting_auto_bookmark',
      defaultValue: true,
    );
    _immersiveReader = widget.storage.getBool(
      'setting_immersive_reader',
      defaultValue: false,
    );

    _keepScreenAwake = widget.storage.getBool(
      'keep_screen_awake',
      defaultValue: false,
    );

    _morningAzkarReminder = widget.storage.getBool(
      'morning_azkar_reminder',
      defaultValue: true,
    );
    _eveningAzkarReminder = widget.storage.getBool(
      'evening_azkar_reminder',
      defaultValue: true,
    );
    _todaysVerseReminder = widget.storage.getBool(
      'todays_verse_reminder',
      defaultValue: true,
    );
    _ramadanImsakEnabled = widget.storage.getBool(
      'ramadan_imsak_enabled',
      defaultValue: true,
    );
    _ramadanImsakOffset = widget.storage.getInt(
      'ramadan_imsak_offset',
      defaultValue: 0,
    );
    _ramadanIftarEnabled = widget.storage.getBool(
      'ramadan_iftar_enabled',
      defaultValue: true,
    );
    _islamicEventsEnabled = widget.storage.getBool(
      'islamic_events_enabled',
      defaultValue: true,
    );
    _firstDayOfWeek = widget.storage.getInt(
      'first_day_of_week',
      defaultValue: 1,
    );

    _use24hFormat = widget.storage.getBool(
      'use_24h_format',
      defaultValue: false,
    );
    _swipeSurahNavigation = widget.storage.getBool(
      'swipe_surah_navigation',
      defaultValue: true,
    );
    _preAdhanAlertMode = widget.storage.getString(
      'pre_adhan_alert_mode',
      defaultValue: 'vibrate',
    );
    _preAdhanDuration = widget.storage.getInt(
      'pre_adhan_duration',
      defaultValue: 10,
    );
    _adhanAlertMode = widget.storage.getString(
      'adhan_alert_mode',
      defaultValue: 'real_reciter',
    );
    _adhanReciter = widget.storage.getString(
      'adhan_reciter',
      defaultValue: 'mishary',
    );
    _athanStopGesture = widget.storage.getString(
      'athan_stop_gesture',
      defaultValue: 'both',
    );

    _checkPermissions();
  }

  @override
  void dispose() {
    // Flush any pending alarm reschedule before leaving settings
    _rescheduleTimer?.cancel();
    _rescheduleAlarms();
    AdhanAudioService.instance.stopPreview();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 400), _checkPermissions);
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final alarm =
          await _platform.invokeMethod<bool>('checkExactAlarmPermission') ??
          true;
      setState(() {
        _exactAlarmPermitted = alarm;
      });
    } catch (_) {}
  }

  Future<void> _requestExactAlarm() async {
    try {
      await _platform.invokeMethod('requestExactAlarmPermission');
      Future.delayed(const Duration(seconds: 2), _checkPermissions);
    } catch (_) {}
  }

  Future<void> _toggleKeepScreenAwake(bool val) async {
    setState(() {
      _keepScreenAwake = val;
    });
    await widget.storage.setBool('keep_screen_awake', val);
    try {
      await _platform.invokeMethod('setKeepScreenOn', {'enabled': val});
    } catch (_) {}
  }

  Future<void> _toggleUse24hFormat(bool val) async {
    setState(() {
      _use24hFormat = val;
    });
    await widget.storage.setBool('use_24h_format', val);
  }

  Future<void> _toggleSwipeSurahNavigation(bool val) async {
    setState(() {
      _swipeSurahNavigation = val;
    });
    await widget.storage.setBool('swipe_surah_navigation', val);
  }

  Future<void> _changeFirstDayOfWeek(int? val) async {
    if (val != null) {
      setState(() => _firstDayOfWeek = val);
      await widget.storage.setInt('first_day_of_week', val);
    }
  }

  Future<void> _changePreAdhanDuration(int? val) async {
    if (val != null) {
      final wasOff = _preAdhanDuration == 0;
      setState(() {
        _preAdhanDuration = val;
      });
      await widget.storage.setInt('pre_adhan_duration', val);
      if (val > 0 && wasOff) {
        final granted = await _ensureAdhanPermissions();
        if (!granted) {
          setState(() { _preAdhanDuration = 0; });
          await widget.storage.setInt('pre_adhan_duration', 0);
          return;
        }
      }
      _debouncedReschedule();
    }
  }

  Future<void> _changePreAdhanAlertMode(String? val) async {
    if (val != null) {
      // If turning ON from OFF, check exact alarm permission first
      final wasOff = _preAdhanAlertMode == 'off';
      setState(() {
        _preAdhanAlertMode = val;
      });
      await widget.storage.setString('pre_adhan_alert_mode', val);
      if (val != 'off' && wasOff) {
        final granted = await _ensureAdhanPermissions();
        if (!granted) {
          // User refused — revert to OFF
          setState(() {
            _preAdhanAlertMode = 'off';
          });
          await widget.storage.setString('pre_adhan_alert_mode', 'off');
          return;
        }
      }
      if (val == 'voice' || val == 'vibrate_and_voice') {
        await AdhanAudioService.instance.stopPreview();
        await AdhanAudioService.instance.playPreAdhanPreview(
          TranslationService.currentLanguage,
        );
      }
      _debouncedReschedule();
    }
  }

  Future<void> _changeAdhanAlertMode(String? val) async {
    if (val != null) {
      // If turning ON from OFF, check all permissions first
      final wasOff = _adhanAlertMode == 'off';
      setState(() {
        _adhanAlertMode = val;
      });
      await widget.storage.setString('adhan_alert_mode', val);
      if (val != 'off' && wasOff) {
        final granted = await _ensureAdhanPermissions();
        if (!granted) {
          // User refused — revert to OFF
          setState(() {
            _adhanAlertMode = 'off';
          });
          await widget.storage.setString('adhan_alert_mode', 'off');
          return;
        }
      }
      _debouncedReschedule();
    }
  }

  /// Strict permission gate — loops until all 3 permissions are granted
  /// or the user explicitly cancels. Mirrors onboarding exactly:
  /// exact-alarm on API 31+, notification, and location **always** (not just while-in-use).
  ///
  /// Returns true if all permissions were granted, false if user cancelled.
  Future<bool> _ensureAdhanPermissions() async {
    while (mounted) {
      final perm = await Geolocator.checkPermission();
      final hasLocation = perm == LocationPermission.always;
      final hasNotif = await NotificationService().checkPermissions();
      final canSchedule = await NotificationService.canScheduleExactAlarms();

      final missing = <String>[];
      if (!canSchedule) missing.add(
        TranslationService.isArabic
            ? 'المنبهات الدقيقة (Alarms & Reminders)'
            : 'Exact Alarm schedule',
      );
      if (!hasNotif) missing.add(
        TranslationService.isArabic ? 'الإشعارات' : 'Notification access',
      );
      if (!hasLocation) missing.add(
        TranslationService.isArabic
            ? 'الموقع (السماح دائماً)'
            : 'Location (Allow all the time)',
      );

      if (missing.isEmpty) return true;

      if (!mounted) return false;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            TranslationService.isArabic
                ? "صلاحيات مطلوبة"
                : "Permissions Required",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5C158)),
          ),
          content: Text(
            TranslationService.isArabic
                ? "لتشغيل الأذان بدقة في الخلفية، يجب منح الصلاحيات التالية:\n• ${missing.join('\n• ')}\n\nسيتم فتح إعدادات الهاتف لكل صلاحية."
                : "For the adhan to work reliably in the background, the following must be granted:\n• ${missing.join('\n• ')}\n\nSettings will open for each one.",
            style: const TextStyle(height: 1.6, fontSize: 14),
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
                TranslationService.isArabic ? "منح الصلاحيات" : "Grant Permissions",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );

      if (ok != true) return false; // user cancelled

      // Request each missing permission — these open system settings
      if (!hasNotif) {
        await NotificationService().requestPermissions();
      }
      if (!canSchedule) {
        await _platform.invokeMethod('requestExactAlarmPermission');
        // Give the user time to toggle the switch
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!hasLocation) {
        await Geolocator.openAppSettings();
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      // Loop back and re-check
    }
    return false;
  }

  Future<void> _changeAdhanReciter(String? val) async {
    if (val != null) {
      setState(() {
        _adhanReciter = val;
      });
      await widget.storage.setString('adhan_reciter', val);

      _debouncedReschedule();

      // Auto-play the newly selected reciter
      await AdhanAudioService.instance.stopPreview();
      await AdhanAudioService.instance.playPreview(val);
    }
  }

  Future<void> _changeAthanStopGesture(String? val) async {
    if (val != null) {
      setState(() {
        _athanStopGesture = val;
      });
      await widget.storage.setString('athan_stop_gesture', val);
    }
  }

  Future<void> _toggleDailyReminder(
    String key,
    bool val,
    Function(bool) updateState,
  ) async {
    await widget.storage.setBool(key, val);
    setState(() {
      updateState(val);
    });
    try {
      await NotificationService().scheduleDailyReminders(widget.storage);
    } catch (_) {}
  }

  void _showDonateDialog() {
    final isAr = TranslationService.isArabic;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isAr ? "دعم وتطوير التطبيق" : "Support Project & Development",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr
                    ? "تطبيق آية مجاني وخالٍ تماماً من الإعلانات صدقة جارية. يمكنك المساهمة في دعم خوادم وتطوير التطبيق:"
                    : "Aya is completely free and ad-free as a continuous charity. You can support server costs and development:",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (kIsGooglePlay) ...[
                FutureBuilder<Widget?>(
                  future: GooglePlayDonation.buildIapButtons(context),
                  builder: (ctx, snap) => snap.data ?? const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
              ],
              Text(
                isAr ? "تبرع عبر باي بال:" : "Donate via PayPal:",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF003087),
                  side: const BorderSide(color: Color(0xFF003087)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.payment),
                label: const Text(
                  'paypal.me/Cancells',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse('https://www.paypal.me/Cancells'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeThemePreset(String? val) async {
    if (val != null) {
      setState(() {
        _themePreset = val;
      });
      await widget.storage.setString('theme_preset', val);
      widget.onThemeChanged();
    }
  }

  Future<void> _changeBottomNavbarStyle(String? val) async {
    if (val != null) {
      setState(() {
        _bottomNavbarStyle = val;
      });
      await widget.storage.setString('bottom_navbar_style', val);
      widget.onThemeChanged();
    }
  }

  Future<void> _changeFont(String? val) async {
    if (val != null) {
      setState(() {
        _quranFont = val;
      });
      await widget.storage.setString('quran_font', val);
      widget.onThemeChanged();
    }
  }


  Future<void> _changeTafsirEdition(String? val) async {
    if (val != null) {
      setState(() {
        _tafsirEdition = val;
      });
      await widget.storage.setString('default_tafsir', val);
      widget.onThemeChanged();
    }
  }

  /// Debounced wrapper — batches rapid-fire settings toggles into one reschedule.
  void _debouncedReschedule() {
    _rescheduleTimer?.cancel();
    _rescheduleTimer = Timer(const Duration(seconds: 2), () {
      _rescheduleAlarms();
    });
  }

  Future<void> _rescheduleAlarms() async {
    try {
      final loc = widget.storage.getLocation();
      final method = widget.storage.getInt('calc_method', defaultValue: 2);
      final school = widget.storage.getInt('asr_method', defaultValue: 0);

      final PrayerTimeData data = await ApiService.fetchPrayerTimes(
        latitude: loc['latitude'] ?? 30.0444,
        longitude: loc['longitude'] ?? 31.2357,
        method: method,
        school: school,
      );
      await NotificationService().schedulePrayerAlarms(data, widget.storage);
    } catch (_) {}
  }

  Future<void> _changeCalcMethod(int? val) async {
    if (val != null) {
      setState(() {
        _calcMethod = val;
      });
      await widget.storage.setInt('calc_method', val);
      widget.onThemeChanged();
      _debouncedReschedule();
    }
  }

  Future<void> _changeAsrMethod(int? val) async {
    if (val != null) {
      setState(() {
        _asrMethod = val;
      });
      await widget.storage.setInt('asr_method', val);
      widget.onThemeChanged();
      _debouncedReschedule();
    }
  }

  Future<void> _toggleContinuousPlay(bool val) async {
    setState(() {
      _continuousPlay = val;
    });
    await widget.storage.setBool('setting_continuous_play', val);
  }

  Future<void> _toggleHideContinuousBorders(bool val) async {
    setState(() {
      _hideContinuousBorders = val;
    });
    await widget.storage.setBool('setting_hide_continuous_borders', val);
  }

  Future<void> _toggleAutoBookmark(bool val) async {
    setState(() {
      _autoBookmark = val;
    });
    await widget.storage.setBool('setting_auto_bookmark', val);
  }

  Future<void> _toggleImmersiveReader(bool val) async {
    setState(() {
      _immersiveReader = val;
    });
    await widget.storage.setBool('setting_immersive_reader', val);
  }

  Future<void> _resetApp() async {
    unawaited(
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            "${TranslationService.t('reset_settings')}?",
            style: const TextStyle(
              color: Color(0xFFE5C158),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.start,
          ),
          content: Text(
            TranslationService.t('reset_settings_sub'),
            textAlign: TextAlign.start,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                TranslationService.t('cancel'),
                style: TextStyle(
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.white)
                          .withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                await widget.storage.setString('theme_preset', 'dark');
                await widget.storage.setString(
                  'quran_font',
                  'font-scheherazade',
                );
                await widget.storage.setString('default_reciter', 'ar.alafasy');
                await widget.storage.setString('default_tafsir', 'ar.muyassar');
                await widget.storage.setString('lang_code', 'ar');
                await widget.storage.setString('quran_bookmarks', '[]');
                await widget.storage.setString('custom_dhikrs', '[]');
                await widget.storage.setInt('calc_method', 2);
                await widget.storage.setInt('asr_method', 0);
                await widget.storage.setBool('setting_continuous_play', true);
                await widget.storage.setBool(
                  'setting_hide_continuous_borders',
                  false,
                );
                await widget.storage.setBool('setting_auto_bookmark', true);
                await widget.storage.setBool('setting_immersive_reader', false);
                await widget.storage.setBool(
                  'first_time_v2',
                  true,
                ); // Reset onboarding too

                await widget.storage.setBool('alert_fajr', true);
                await widget.storage.setBool('alert_dhuhr', true);
                await widget.storage.setBool('alert_asr', true);
                await widget.storage.setBool('alert_maghrib', true);
                await widget.storage.setBool('alert_isha', true);

                await widget.storage.setBool('keep_screen_awake', false);
                await widget.storage.setInt('focus_lock_duration', 0);
                await widget.storage.setBool('focus_auto_start', false);
                await widget.storage.setString('focus_lock_type', 'app_only');

                await widget.storage.setBool('use_24h_format', false);
                await widget.storage.setBool('swipe_surah_navigation', true);
                await widget.storage.setString(
                  'pre_adhan_alert_mode',
                  'vibrate',
                );
                await widget.storage.setInt('pre_adhan_duration', 10);
                await widget.storage.setString(
                  'adhan_alert_mode',
                  'real_reciter',
                );
                await widget.storage.setString('adhan_reciter', 'mishary');

                TranslationService.setLanguage('ar');

                setState(() {
                  _themePreset = 'dark';
                  _quranFont = 'font-amiri';
                  _tafsirEdition = 'ar.muyassar';
                  _calcMethod = 2;
                  _asrMethod = 0;
                  _continuousPlay = true;
                  _hideContinuousBorders = false;
                  _autoBookmark = true;
                  _immersiveReader = false;
                  _keepScreenAwake = false;
                  _use24hFormat = false;
                  _swipeSurahNavigation = true;
                  _preAdhanAlertMode = 'vibrate';
                  _preAdhanDuration = 10;
                  _adhanAlertMode = 'real_reciter';
                  _adhanReciter = 'mishary';
                  _athanStopGesture = 'both';
                });
                navigator.pop();
                widget.onThemeChanged();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.isArabic
                          ? 'تم إعادة تعيين التطبيق.'
                          : 'Application reset.',
                    ),
                  ),
                );
              },
              child: Text(TranslationService.t('reset_settings')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          TranslationService.t('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          ..._buildAppearanceSection(theme),
          ..._buildLanguageSection(theme),
          ..._buildCalculationsSection(theme),
          ..._buildAppPreferencesSection(theme),
          ..._buildNotificationsSection(theme),
          ..._buildAudioSection(theme),
          ..._buildPermissionsSection(theme),
          ..._buildBackupSection(theme),
          ..._buildFocusLockSection(theme),
          const SizedBox(height: 40),

          // App info credits
          Center(
            child: Column(
              children: [
                const Icon(Icons.mosque, color: Color(0xFFE5C158), size: 48),
                const SizedBox(height: 12),
                Text(
                  TranslationService.t('app_title').toUpperCase(),
                  style: const TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${TranslationService.t('version_prefix')} $appVersion',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TranslationService.t('bless_journey'),
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.white)
                            .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 4.0,
        bottom: 8.0,
        end: 4.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF0F766E),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }
}
