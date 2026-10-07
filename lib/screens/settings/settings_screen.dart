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
import 'package:path_provider/path_provider.dart';
import '../../services/adhan_audio_service.dart';
import '../../core/adhan_native_controller.dart';
import '../../services/reciters_cache_service.dart';
import '../../donation/flavor.dart';
import '../../donation/google_play_donation.dart';
import '../../version.dart';
import '../about_screen.dart';
import '../qiraat_screen.dart';
import 'adhan_settings_screen.dart';
import 'prayer_time_adjust_screen.dart';
import 'ramadan_reminders_screen.dart';
import '../../widgets/settings_section_header.dart';
import '../../widgets/settings_value_chip.dart';
import '../../widgets/permission_status_badge.dart';

part 'settings_appearance.dart';
part 'settings_calculations.dart';
part 'settings_notifications.dart';
part 'settings_audio.dart';
part 'settings_permissions.dart';
part 'settings_about.dart';
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

  // Add calculation settings
  int _calcMethod = 0;
  double _customFajrAngle = 18.0;
  double _customIshaAngle = 17.0;
  int _asrMethod = 0;
  bool _continuousPlay = true;
  bool _hideContinuousBorders = false;
  bool _autoBookmark = true;
  bool _immersiveReader = false;

  // Permissions and wake lock
  bool _exactAlarmPermitted = true;
  bool _notificationPermitted = true;
  bool _locationPermitted = true;
  bool _dndPolicyPermitted = true;
  bool _keepScreenAwake = false;

  bool _morningAzkarReminder = true;
  bool _eveningAzkarReminder = true;
  bool _todaysVerseReminder = true;
  bool _islamicEventsEnabled = true;

  // New settings options
  bool _use24hFormat = false;
  bool _swipeSurahNavigation = true;
  int _firstDayOfWeek = 1;
  String _adhanReciter = 'mishary'; // mishary, abdul_basit, makkah, madinah
  String _notificationLang = 'follow_app'; // follow_app, ar, en
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

    _calcMethod = widget.storage.getInt('calc_method', defaultValue: 0);
    _customFajrAngle = widget.storage.getDouble(
      'custom_fajr_angle',
      defaultValue: 18.0,
    );
    _customIshaAngle = widget.storage.getDouble(
      'custom_isha_angle',
      defaultValue: 17.0,
    );
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
    _adhanReciter = widget.storage.getString(
      'adhan_reciter',
      defaultValue: 'mishary',
    );
    _notificationLang = widget.storage.getString(
      'notification_lang',
      defaultValue: 'follow_app',
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
      final notif = await NotificationService().checkPermissions();
      final locPerm = await Geolocator.checkPermission();
      final loc =
          locPerm == LocationPermission.always ||
          locPerm == LocationPermission.whileInUse;
      final dnd =
          await _platform.invokeMethod<bool>('checkNotificationPolicyAccess') ??
          true;
      if (mounted) {
        setState(() {
          _exactAlarmPermitted = alarm;
          _notificationPermitted = notif;
          _locationPermitted = loc;
          _dndPolicyPermitted = dnd;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestExactAlarm() async {
    try {
      await _platform.invokeMethod('requestExactAlarmPermission');
      Future.delayed(const Duration(seconds: 2), _checkPermissions);
    } catch (_) {}
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationService().requestPermissions();
      Future.delayed(const Duration(seconds: 1), _checkPermissions);
    } catch (_) {}
  }

  Future<void> _requestLocationPermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      Future.delayed(const Duration(seconds: 1), _checkPermissions);
    } catch (_) {}
  }

  Future<void> _requestDndPermission() async {
    try {
      await _platform.invokeMethod('requestNotificationPolicyAccess');
      Future.delayed(const Duration(seconds: 1), _checkPermissions);
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
    try {
      await _platform.invokeMethod('updateWidget');
    } catch (_) {}
  }

  Future<void> _toggleSwipeSurahNavigation(bool val) async {
    setState(() {
      _swipeSurahNavigation = val;
    });
    await widget.storage.setBool('swipe_surah_navigation', val);
  }

  Future<void> _changeAthanStopGesture(String? val) async {
    if (val != null) {
      setState(() {
        _athanStopGesture = val;
      });
      await widget.storage.setString('athan_stop_gesture', val);
    }
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
      await widget.storage.setBool(
        'widget_is_dark',
        widget.storage.isDarkMode(),
      );
      widget.onThemeChanged();
      try {
        await _platform.invokeMethod('updateWidget');
      } catch (_) {}
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
      final method = widget.storage.getInt('calc_method', defaultValue: 0);
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

  Future<void> _changeCustomFajrAngle(double val) async {
    setState(() {
      _customFajrAngle = val;
    });
    await widget.storage.setDouble('custom_fajr_angle', val);
    widget.onThemeChanged();
    _debouncedReschedule();
  }

  Future<void> _changeCustomIshaAngle(double val) async {
    setState(() {
      _customIshaAngle = val;
    });
    await widget.storage.setDouble('custom_isha_angle', val);
    widget.onThemeChanged();
    _debouncedReschedule();
  }

  String _getSmartMethodName(bool isAr) {
    final loc = widget.storage.getLocation();
    final smartId = widget.storage.determineSmartCalculationMethod(
      loc['city']?.toString() ?? '',
      loc['country']?.toString() ?? '',
    );
    switch (smartId) {
      case 1:
        return isAr ? "جامعة العلوم الإسلامية بكراتشي" : "Karachi (UISK)";
      case 2:
        return isAr ? "أمريكا الشمالية (ISNA)" : "ISNA (North America)";
      case 3:
        return isAr ? "رابطة العالم الإسلامي" : "Muslim World League";
      case 4:
        return isAr ? "جامعة أم القرى (مكة)" : "Umm Al-Qura (Makkah)";
      case 5:
        return isAr ? "الهيئة المصرية العامة للمساحة" : "Egyptian Survey";
      case 6:
        return isAr ? "ديوان الوقف السني (العراق)" : "Sunni Endowment (Iraq)";
      case 10:
        return isAr ? "وزارة الأوقاف (قطر)" : "Qatar Awqaf";
      case 11:
        return isAr ? "المجلس الإسلامي السنغافوري" : "Singapore (MUIS)";
      case 12:
        return isAr ? "اتحاد المنظمات (فرنسا)" : "France (UOIF)";
      case 13:
        return isAr ? "تركيا (الشؤون الدينية)" : "Turkey (Diyanet)";
      case 14:
        return isAr ? "الإدارة الدينية (روسيا)" : "Russia (SAMR)";
      case 16:
        return isAr ? "الهيئة العامة للأوقاف (الإمارات)" : "UAE (GAIAE)";
      default:
        return isAr ? "رابطة العالم الإسلامي" : "Muslim World League";
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
          ..._buildCalculationsSection(theme),
          ..._buildNotificationsSection(theme),
          ..._buildAudioSection(theme),
          ..._buildPermissionsSection(theme),
          ..._buildBackupSection(theme),
          ..._buildAboutSection(theme),
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
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.4,
                    ),
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
}
