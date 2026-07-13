import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../models/prayer_models.dart';
import '../quran_download_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/adhan_audio_service.dart';
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
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String _bottomNavbarStyle = 'solid';
  String _quranFont = 'font-amiri';
  String _quranScriptType = 'hafs';
  String _reciter = 'ar.alafasy';
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

  // Focus lock
  int _focusLockDuration = 0;
  bool _focusAutoStart = false;
  String _focusLockType = 'app_only'; // app_only vs whole_phone

  bool _morningAzkarReminder = true;
  bool _eveningAzkarReminder = true;
  bool _todaysVerseReminder = true;

  // New settings options
  bool _use24hFormat = false;
  bool _swipeSurahNavigation = true;
  int _firstDayOfWeek = 1;
  String _preAdhanAlertMode = 'vibrate'; // vibrate vs voice
  int _preAdhanDuration = 10; // minutes before adhan
  String _adhanAlertMode = 'real_reciter'; // silent vs vibrate vs real_reciter
  String _adhanReciter = 'mishary'; // mishary, abdul_basit, makkah, madinah
  String _athanStopGesture = 'both'; // both, volume_only, flip_only, none
  bool _isPreviewPlaying = false;
  bool _isPreAdhanPreviewPlaying = false;

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
    _quranScriptType = widget.storage.getString(
      'quran_script_type',
      defaultValue: 'hafs',
    );
    _reciter = widget.storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
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
    _focusLockDuration = widget.storage.getInt(
      'focus_lock_duration',
      defaultValue: 0,
    );
    _focusAutoStart = widget.storage.getBool(
      'focus_auto_start',
      defaultValue: false,
    );
    _focusLockType = widget.storage.getString(
      'focus_lock_type',
      defaultValue: 'app_only',
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
    _firstDayOfWeek = widget.storage.getInt('first_day_of_week', defaultValue: 1);

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
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        // handle error here
      },
    );
  }

  @override
  void dispose() {
    AdhanAudioService.instance.stopPreview();
    _purchaseSubscription?.cancel();
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

  Future<void> _changeFocusDuration(int? val) async {
    if (val != null) {
      setState(() {
        _focusLockDuration = val;
        if (val == 0) _focusAutoStart = false;
      });
      await widget.storage.setInt('focus_lock_duration', val);
      if (val == 0) {
        await widget.storage.setBool('focus_auto_start', false);
      }
    }
  }

  Future<void> _toggleFocusAutoStart(bool val) async {
    setState(() {
      _focusAutoStart = val;
    });
    await widget.storage.setBool('focus_auto_start', val);
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
      setState(() {
        _preAdhanDuration = val;
      });
      await widget.storage.setInt('pre_adhan_duration', val);
      await _rescheduleAlarms();
    }
  }

  Future<void> _changePreAdhanAlertMode(String? val) async {
    if (val != null) {
      setState(() {
        _preAdhanAlertMode = val;
      });
      await widget.storage.setString('pre_adhan_alert_mode', val);
      if (val == 'voice' || val == 'vibrate_and_voice') {
        await AdhanAudioService.instance.stopPreview();
        await AdhanAudioService.instance.playPreAdhanPreview(TranslationService.currentLanguage);
      }
      await _rescheduleAlarms();
    }
  }

  Future<void> _changeAdhanAlertMode(String? val) async {
    if (val != null) {
      setState(() {
        _adhanAlertMode = val;
      });
      await widget.storage.setString('adhan_alert_mode', val);
      if (val == 'real_reciter' || val == 'vibrate_and_voice') {

      }
      await _rescheduleAlarms();
    }
  }

  Future<void> _changeAdhanReciter(String? val) async {
    if (val != null) {
      setState(() {
        _adhanReciter = val;
      });
      await widget.storage.setString('adhan_reciter', val);

      await _rescheduleAlarms();

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

  Future<void> _changeFocusLockType(String? val) async {
    if (val != null) {
      setState(() {
        _focusLockType = val;
      });
      await widget.storage.setString('focus_lock_type', val);
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

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending dialog
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? "فشلت عملية الدعم، يرجى المحاولة مرة أخرى."
                  : "Support donation failed. Please try again.",
            ),
          ),
        );
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Complete donation!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              TranslationService.isArabic
                  ? "تقبل الله منكم! شكراً جزيلاً لدعمكم الكريم."
                  : "Thank you for your generous support!",
            ),
          ),
        );
      }
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _supportProject(double amount) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? "متجر Google Play غير متوفر حالياً."
                : "Google Play Store is currently unavailable.",
          ),
        ),
      );
      return;
    }

    // Dynamic product ID based on amount
    final String productId = 'support_donation_${amount.toInt()}';

    final ProductDetailsResponse response = await InAppPurchase.instance
        .queryProductDetails({productId});
    if (response.notFoundIDs.contains(productId) ||
        response.productDetails.isEmpty) {
      // Fallback message if localized products are not configured in Play Console yet
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? "جاري إرسال طلب الدعم بقيمة \$$amount عبر Google Play..."
                : "Initiating support for \$$amount via Google Play...",
          ),
        ),
      );
      // Simulate launch request or handle gracefully
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } catch (_) {}
  }

  void _showDonateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<ProductDetailsResponse>(
          future: InAppPurchase.instance.queryProductDetails({
            'support_donation_1',
            'support_donation_5',
            'support_donation_10',
            'support_donation_20',
            'support_donation_50',
          }),
          builder: (context, snapshot) {
            final products = snapshot.data?.productDetails ?? [];
            final productMap = {for (var p in products) p.id: p};

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                TranslationService.isArabic
                    ? "دعم وتطوير التطبيق"
                    : "Support Project & Development",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationService.isArabic
                        ? "تطبيق آية مجاني وخالٍ تماماً من الإعلانات صدقة جارية. يمكنك المساهمة في دعم خوادم وتطوير التطبيق:"
                        : "Aya is completely free and ad-free as a continuous charity. You can support server costs and development:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 20),
                  ...[1.0, 5.0, 10.0, 20.0, 50.0].map((val) {
                    final productId = 'support_donation_${val.toInt()}';
                    final product = productMap[productId];
                    final displayPrice =
                        product?.price ?? '\$${val.toInt()} USD';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5C158),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _supportProject(val);
                        },
                        child: Text(
                          TranslationService.isArabic
                              ? "دعم بقيمة $displayPrice"
                              : "Support $displayPrice",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
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

  Future<void> _changeReciter(String? val) async {
    if (val != null) {
      setState(() {
        _reciter = val;
      });
      await widget.storage.setString('default_reciter', val);
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
      await _rescheduleAlarms();
    }
  }

  Future<void> _changeAsrMethod(int? val) async {
    if (val != null) {
      setState(() {
        _asrMethod = val;
      });
      await widget.storage.setInt('asr_method', val);
      widget.onThemeChanged();
      await _rescheduleAlarms();
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
            style: TextStyle(
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
                          .withOpacity(0.7),
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
                  _reciter = 'ar.alafasy';
                  _tafsirEdition = 'ar.muyassar';
                  _calcMethod = 2;
                  _asrMethod = 0;
                  _continuousPlay = true;
                  _hideContinuousBorders = false;
                  _autoBookmark = true;
                  _immersiveReader = false;
                  _keepScreenAwake = false;
                  _focusLockDuration = 0;
                  _focusAutoStart = false;
                  _focusLockType = 'app_only';
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          ..._buildFocusLockSection(theme),
          SizedBox(height: 40),

          // App info credits
          Center(
            child: Column(
              children: [
                Icon(Icons.mosque, color: Color(0xFFE5C158), size: 48),
                SizedBox(height: 12),
                Text(
                  TranslationService.t('app_title').toUpperCase(),
                  style: TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  TranslationService.t('version_premium'),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  TranslationService.t('bless_journey'),
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.white)
                            .withOpacity(0.3),
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
        style: TextStyle(
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
