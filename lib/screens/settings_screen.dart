import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/prayer_models.dart';
import 'quran_download_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/adhan_audio_service.dart';
import 'about_screen.dart';

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

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.quran.aya/system');

  String _themePreset = 'dark';
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String _bottomNavbarStyle = 'solid';
  String _quranFont = 'font-scheherazade';
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
  bool _batteryIgnored = true;
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
    _themePreset = widget.storage.getString('theme_preset', defaultValue: 'dark');
    _bottomNavbarStyle = widget.storage.getString('bottom_navbar_style', defaultValue: 'solid');
    _quranFont = widget.storage.getString('quran_font', defaultValue: 'font-scheherazade');
    _reciter = widget.storage.getString('default_reciter', defaultValue: 'ar.alafasy');
    _tafsirEdition = widget.storage.getString('default_tafsir', defaultValue: 'ar.muyassar');
    
    _calcMethod = widget.storage.getInt('calc_method', defaultValue: 2);
    _asrMethod = widget.storage.getInt('asr_method', defaultValue: 0);
    _continuousPlay = widget.storage.getBool('setting_continuous_play', defaultValue: true);
    _hideContinuousBorders = widget.storage.getBool('setting_hide_continuous_borders', defaultValue: false);
    _autoBookmark = widget.storage.getBool('setting_auto_bookmark', defaultValue: true);
    _immersiveReader = widget.storage.getBool('setting_immersive_reader', defaultValue: false);

    _keepScreenAwake = widget.storage.getBool('keep_screen_awake', defaultValue: false);
    _focusLockDuration = widget.storage.getInt('focus_lock_duration', defaultValue: 0);
    _focusAutoStart = widget.storage.getBool('focus_auto_start', defaultValue: false);
    _focusLockType = widget.storage.getString('focus_lock_type', defaultValue: 'app_only');

    _morningAzkarReminder = widget.storage.getBool('morning_azkar_reminder', defaultValue: true);
    _eveningAzkarReminder = widget.storage.getBool('evening_azkar_reminder', defaultValue: true);
    _todaysVerseReminder = widget.storage.getBool('todays_verse_reminder', defaultValue: true);

    _use24hFormat = widget.storage.getBool('use_24h_format', defaultValue: false);
    _swipeSurahNavigation = widget.storage.getBool('swipe_surah_navigation', defaultValue: true);
    _preAdhanAlertMode = widget.storage.getString('pre_adhan_alert_mode', defaultValue: 'vibrate');
    _preAdhanDuration = widget.storage.getInt('pre_adhan_duration', defaultValue: 10);
    _adhanAlertMode = widget.storage.getString('adhan_alert_mode', defaultValue: 'real_reciter');
    _adhanReciter = widget.storage.getString('adhan_reciter', defaultValue: 'mishary');
    _athanStopGesture = widget.storage.getString('athan_stop_gesture', defaultValue: 'both');

    _checkPermissions();
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _purchaseSubscription?.cancel();
    }, onError: (error) {
      // handle error here
    });
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
      final alarm = await _platform.invokeMethod<bool>('checkExactAlarmPermission') ?? true;
      final batteryOptimized = await _platform.invokeMethod<bool>('checkBatteryOptimization') ?? false;
      setState(() {
        _exactAlarmPermitted = alarm;
        _batteryIgnored = batteryOptimized; // true means ignored (disabled), false means optimized (not ignored)
      });
    } catch (_) {}
  }

  Future<void> _requestExactAlarm() async {
    try {
      await _platform.invokeMethod('requestExactAlarmPermission');
      Future.delayed(const Duration(seconds: 2), _checkPermissions);
    } catch (_) {}
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      await _platform.invokeMethod('requestDisableBatteryOptimization');
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
        await _autoDownloadPreAdhanVoice();
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
        await _autoDownloadReciterAudio(_adhanReciter);
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
      await _autoDownloadReciterAudio(val);
      await _rescheduleAlarms();
    }
  }

  Future<void> _autoDownloadReciterAudio(String reciterId) async {
    final isDownloaded = await AdhanAudioService.instance.isReciterDownloaded(reciterId);
    if (!isDownloaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(TranslationService.isArabic 
                    ? 'جاري تنزيل صوت المؤذن...' 
                    : 'Downloading reciter audio...'),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      final success = await AdhanAudioService.instance.downloadReciterAudio(reciterId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? (TranslationService.isArabic ? 'تم تنزيل صوت المؤذن ✓' : 'Reciter audio downloaded ✓')
                : (TranslationService.isArabic ? 'فشل التنزيل، سيتم التنزيل عند الأذان' : 'Download failed, will retry at athan time')),
            backgroundColor: success ? Colors.green : Colors.orangeAccent,
          ),
        );
      }
    }
  }

  Future<void> _autoDownloadPreAdhanVoice() async {
    final isDownloaded = await AdhanAudioService.instance.isPreAdhanDownloaded();
    if (!isDownloaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(TranslationService.isArabic 
                    ? 'جاري تنزيل التنبيه الصوتي...' 
                    : 'Downloading pre-adhan voice alert...'),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      final success = await AdhanAudioService.instance.downloadPreAdhanVoice();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? (TranslationService.isArabic ? 'تم تنزيل التنبيه الصوتي ✓' : 'Pre-adhan voice alert downloaded ✓')
                : (TranslationService.isArabic ? 'فشل التنزيل، سيتم التنزيل عند التنبيه' : 'Download failed, will retry at alert time')),
            backgroundColor: success ? Colors.green : Colors.orangeAccent,
          ),
        );
      }
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

  Future<void> _toggleDailyReminder(String key, bool val, Function(bool) updateState) async {
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
          SnackBar(content: Text(TranslationService.isArabic ? "فشلت عملية الدعم، يرجى المحاولة مرة أخرى." : "Support donation failed. Please try again.")),
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
                  : "Thank you for your generous support!"
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
        SnackBar(content: Text(TranslationService.isArabic ? "متجر Google Play غير متوفر حالياً." : "Google Play Store is currently unavailable.")),
      );
      return;
    }

    // Dynamic product ID based on amount
    final String productId = 'support_donation_${amount.toInt()}';
    
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({productId});
    if (response.notFoundIDs.contains(productId) || response.productDetails.isEmpty) {
      // Fallback message if localized products are not configured in Play Console yet
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic 
                ? "جاري إرسال طلب الدعم بقيمة \$$amount عبر Google Play..." 
                : "Initiating support for \$$amount via Google Play..."
          )
        ),
      );
      // Simulate launch request or handle gracefully
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    try {
      await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } catch (_) {}
  }

  void _showDonateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          TranslationService.isArabic ? "دعم وتطوير التطبيق" : "Support Project & Development",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TranslationService.isArabic 
                  ? "تطبيق آية مجاني وخالٍ تماماً من الإعلانات صدقة جارية. يمكنك المساهمة في دعم خوادم وتطوير التطبيق:" 
                  : "Aya is completely free and ad-free as a continuous charity. You can support server costs and development:",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ...[1.0, 5.0, 10.0, 20.0, 50.0].map((val) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C158),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _supportProject(val);
                  },
                  child: Text(
                    TranslationService.isArabic ? "دعم بقيمة \$$val دولار" : "Support \$$val USD",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
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

      final PrayerTimeData data;
      if (loc['source'] == 'default' || loc['latitude'] == 30.0444) {
        data = await ApiService.fetchPrayerTimesByCity(
          city: loc['city'] ?? 'Cairo',
          country: loc['country'] ?? 'Egypt',
          method: method,
          school: school,
        );
      } else {
        data = await ApiService.fetchPrayerTimes(
          latitude: loc['latitude'],
          longitude: loc['longitude'],
          method: method,
          school: school,
        );
      }
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
    unawaited(showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          "${TranslationService.t('reset_settings')}?", 
          style: const TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold),
          textAlign: TextAlign.start,
        ),
        content: Text(
          TranslationService.t('reset_settings_sub'),
          textAlign: TextAlign.start,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(TranslationService.t('cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              await widget.storage.setString('theme_preset', 'dark');
              await widget.storage.setString('quran_font', 'font-scheherazade');
              await widget.storage.setString('default_reciter', 'ar.alafasy');
              await widget.storage.setString('default_tafsir', 'ar.muyassar');
              await widget.storage.setString('lang_code', 'ar');
              await widget.storage.setString('quran_bookmarks', '[]');
              await widget.storage.setString('custom_dhikrs', '[]');
              await widget.storage.setInt('calc_method', 2);
              await widget.storage.setInt('asr_method', 0);
              await widget.storage.setBool('setting_continuous_play', true);
              await widget.storage.setBool('setting_hide_continuous_borders', false);
              await widget.storage.setBool('setting_auto_bookmark', true);
              await widget.storage.setBool('setting_immersive_reader', false);
              await widget.storage.setBool('first_time_v2', true); // Reset onboarding too

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
              await widget.storage.setString('pre_adhan_alert_mode', 'vibrate');
              await widget.storage.setInt('pre_adhan_duration', 10);
              await widget.storage.setString('adhan_alert_mode', 'real_reciter');
              await widget.storage.setString('adhan_reciter', 'mishary');
              
              TranslationService.setLanguage('ar');
              
              setState(() {
                _themePreset = 'dark';
                _quranFont = 'font-scheherazade';
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
                SnackBar(content: Text(TranslationService.isArabic ? 'تم إعادة تعيين التطبيق.' : 'Application reset.')),
              );
            },
            child: Text(TranslationService.t('reset_settings')),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          TranslationService.t('settings'), 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section Appearance
          _buildSectionHeader(TranslationService.t('appearance')),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
              children: [
                ListTile(
                  title: Text(TranslationService.t('theme_preset_label')),
                  subtitle: Text(TranslationService.t('theme_preset_sub')),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _themePreset,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 'light', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "فاتح" : "Light"))),
                      DropdownMenuItem(value: 'sepia', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "بني (قراءة)" : "Sepia/Parchment"))),
                      DropdownMenuItem(value: 'dark', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "داكن" : "Dark"))),
                      DropdownMenuItem(value: 'black', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "أسود OLED" : "OLED Black"))),
                      DropdownMenuItem(value: 'dark_monet', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "داكن متكيف" : "Adaptive Dark"))),
                      DropdownMenuItem(value: 'white_monet', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "فاتح متكيف" : "Adaptive Light"))),
                    ],
                    onChanged: _changeThemePreset,
                  )),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.t('bottom_navbar_style_label')),
                  subtitle: Text(TranslationService.t('bottom_navbar_style_sub')),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _bottomNavbarStyle,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 'solid', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.t('bottom_navbar_solid')))),
                      DropdownMenuItem(value: 'floating', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.t('bottom_navbar_floating')))),
                    ],
                    onChanged: _changeBottomNavbarStyle,
                  )),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.t('quran_font')),
                  subtitle: Text(TranslationService.t('quran_font_sub')),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _quranFont,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 'font-scheherazade', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "خط شهرزاد" : "Scheherazade Font"))),
                      DropdownMenuItem(value: 'font-amiri', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "الخط الأميري" : "Amiri Font"))),
                    ],
                    onChanged: _changeFont,
                  )),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.isArabic ? "تفسير القرآن" : "Quran Tafsir"),
                  subtitle: Text(TranslationService.isArabic ? "اختر كتاب التفسير المفضل" : "Choose preferred Tafsir book"),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _tafsirEdition,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 'ar.muyassar', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "التفسير الميسر (المجمع)" : "Al-Muyassar (Assembly)"))),
                      DropdownMenuItem(value: 'ar.jalalayn', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "تفسير الجلالين" : "Tafsir Al-Jalalayn"))),
                      DropdownMenuItem(value: 'ar.qurtubi', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "تفسير القرطبي" : "Tafsir Al-Qurtubi"))),
                      DropdownMenuItem(value: 'ar.miqbas', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "تنوير المقباس (ابن عباس)" : "Tanwir al-Miqbas (Ibn Abbas)"))),
                      DropdownMenuItem(value: 'ar.waseet', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "التفسير الوسيط (الطنطاوي)" : "Al-Waseet (Tantawi)"))),
                      DropdownMenuItem(value: 'ar.baghawi', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "تفسير البغوي" : "Tafsir Al-Baghawi"))),
                    ],
                    onChanged: _changeTafsirEdition,
                  )),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "تنسيق الوقت ٢٤ ساعة" : "24-Hour Time Format"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "عرض أوقات الصلاة بتنسيق ٢٤ ساعة بدلاً من ١٢ ساعة" 
                      : "Display prayer times in 24h format instead of 12h"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _use24hFormat,
                  onChanged: _toggleUse24hFormat,
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "سحب الشاشة للانتقال بين السور" : "Swipe to Navigate Surahs"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "اسحب لليمين أو اليسار للانتقال إلى السورة التالية أو السابقة" 
                      : "Swipe left or right to read the previous or next Surah"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _swipeSurahNavigation,
                  onChanged: _toggleSwipeSurahNavigation,
                ),
              ],
            )
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Language
          _buildSectionHeader(TranslationService.t('app_lang')),
          Card(
            color: theme.cardColor,
            child: ListTile(
              title: Text(TranslationService.t('app_lang')),
              subtitle: Text(TranslationService.t('app_lang_sub')),
              trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                value: TranslationService.currentLanguage,
                underline: const SizedBox(),
                dropdownColor: theme.cardColor,
                items: [
                  const DropdownMenuItem(value: 'ar', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("العربية"))),
                  const DropdownMenuItem(value: 'en', child: Align(alignment: AlignmentDirectional.centerStart, child: Text("English"))),
                ],
                onChanged: (lang) async {
                  if (lang != null) {
                    final navigator = Navigator.of(context);
                    await widget.storage.setString('lang_code', lang);
                    TranslationService.setLanguage(lang);
                    
                    // Root level rebuild & reload navigation stack to main dashboard page
                    widget.onThemeChanged();
                    if (mounted) {
                      unawaited(navigator.pushNamedAndRemoveUntil('/', (route) => false));
                    }
                  }
                },
              )),
            ),
          ),
          const SizedBox(height: 20),

          // Section Calculations
          _buildSectionHeader(TranslationService.t('calc_settings')),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
              children: [
                ListTile(
                  title: Text(TranslationService.t('calc_method')),
                  subtitle: Text(TranslationService.t('calc_settings')),
                  trailing: SizedBox(
                    width: 160,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _calcMethod,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 1, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "جامعة العلوم الإسلامية بكراتشي" : "University of Islamic Sciences, Karachi"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "الهيئة الإسلامية لأمريكا الشمالية (ISNA)" 
                                : "Islamic Society of North America (ISNA)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "رابطة العالم الإسلامي" 
                                : "Muslim World League (MWL)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 4, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "جامعة أم القرى (مكة)" 
                                : "Umm Al-Qura University (Makkah)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 5, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "الهيئة المصرية العامة للمساحة" 
                                : "Egyptian General Authority of Survey"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 10, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "وزارة الأوقاف والشؤون الإسلامية (قطر)" : "Ministry of Awqaf (Qatar)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 11, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "المجلس الإسلامي السنغافوري (MUIS)" : "Majlis Ugama Islam Singapura (MUIS)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 12, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "اتحاد المنظمات الإسلامية بفرنسا (UOIF)" : "Union of Islamic Organisations of France (UOIF)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 13, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "تركيا (الشؤون الدينية)" 
                                : "Turkey (Diyanet)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 14, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "الإدارة الدينية لمسلمي روسيا الاتحادية" : "Spiritual Administration of Muslims of Russia"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 16, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "الهيئة العامة للشؤون الإسلامية والأوقاف (الإمارات)" : "General Authority of Islamic Affairs & Endowments (UAE)"),
                          ),
                        ),
                      ],
                      onChanged: _changeCalcMethod,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.t('asr_calc_label')),
                  subtitle: Text(TranslationService.t('asr_calc_sub')),
                  trailing: SizedBox(
                    width: 160,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _asrMethod,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 0, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "الشافعي، المالكي، الحنبلي" 
                                : "Standard (Shafi'i, Maliki, Hanbali)"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 1, 
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic 
                                ? "المذهب الحنفي" 
                                : "Hanafi School"),
                          ),
                        ),
                      ],
                      onChanged: _changeAsrMethod,
                    ),
                  ),
                ),
              ],
            )
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Notifications & Alerts
          _buildSectionHeader(TranslationService.isArabic ? "الإشعارات والتنبيهات" : "Notifications & Alerts"),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
              children: [
                ListTile(
                  title: Text(TranslationService.isArabic ? "وقت التنبيه قبل الأذان" : "Pre-Athan Alert Time"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "اختر وقت التنبيه بالدقائق قبل الأذان" 
                      : "Choose alert timing in minutes before Athan"),
                  trailing: SizedBox(width: 160, child: DropdownButton<int>(isExpanded: true, 
                    value: _preAdhanDuration,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [0, 5, 10, 15, 20].map((mins) {
                      return DropdownMenuItem<int>(
                        value: mins,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(mins == 0 
                              ? (TranslationService.isArabic ? "إيقاف" : "Off")
                              : (TranslationService.isArabic ? "$mins دقائق" : "$mins Mins")),
                        ),
                      );
                    }).toList(),
                    onChanged: _changePreAdhanDuration,
                  )),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.isArabic ? "نمط تنبيه قبل الأذان" : "Pre-Athan Alert Style"),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _preAdhanAlertMode,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(
                        value: 'silent',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "صامت" : "Silent"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'vibrate',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "اهتزاز فقط" : "Vibrate Only"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'voice',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "تنبيه صوتي" : "Voice Announcement"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'vibrate_and_voice',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "اهتزاز + تنبيه صوتي" : "Vibrate + Voice"),
                        ),
                      ),
                    ],
                    onChanged: _changePreAdhanAlertMode,
                  )),
                ),
                if (_preAdhanAlertMode == 'voice' || _preAdhanAlertMode == 'vibrate_and_voice') ...[
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    title: Text(TranslationService.isArabic ? "معاينة التنبيه الصوتي" : "Voice Alert Preview"),
                    subtitle: Text(TranslationService.isArabic 
                        ? "تشغيل معاينة لصوت التنبيه" 
                        : "Play a preview of the voice alert"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_isPreAdhanPreviewPlaying ? Icons.stop : Icons.play_arrow),
                          onPressed: () async {
                            if (_isPreAdhanPreviewPlaying) {
                              await AdhanAudioService.instance.stopPreview();
                              setState(() => _isPreAdhanPreviewPlaying = false);
                            } else {
                              setState(() => _isPreAdhanPreviewPlaying = true);
                              final lang = TranslationService.currentLanguage;
                              await AdhanAudioService.instance.playPreAdhanPreview(lang);
                              Future.delayed(const Duration(seconds: 8), () {
                                if (mounted) setState(() => _isPreAdhanPreviewPlaying = false);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.isArabic ? "نوع تنبيه الأذان" : "Athan Alert Style"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "التنبيه عند دخول وقت الصلاة" 
                      : "Alert when prayer time starts"),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _adhanAlertMode,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(
                        value: 'silent',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "صامت" : "Silent"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'vibrate',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "اهتزاز" : "Vibrate"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'real_reciter',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "أذان بصوت المؤذن" : "Real Reciter Adhan"),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'vibrate_and_voice',
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(TranslationService.isArabic ? "اهتزاز + صوت المؤذن" : "Vibrate + Reciter Voice"),
                        ),
                      ),
                    ],
                    onChanged: _changeAdhanAlertMode,
                  )),
                ),
                if (_adhanAlertMode == 'real_reciter' || _adhanAlertMode == 'vibrate_and_voice') ...[
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    title: Text(TranslationService.isArabic ? "المؤذن" : "Athan Reciter"),
                    subtitle: Text(TranslationService.isArabic 
                        ? "اختر صوت المؤذن للأذان" 
                        : "Select voice for the Athan"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_isPreviewPlaying ? Icons.stop : Icons.play_arrow),
                          onPressed: () async {
                            if (_isPreviewPlaying) {
                              await AdhanAudioService.instance.stopPreview();
                              setState(() => _isPreviewPlaying = false);
                            } else {
                              setState(() => _isPreviewPlaying = true);
                              await AdhanAudioService.instance.playPreview(_adhanReciter);
                              Future.delayed(const Duration(seconds: 8), () {
                                if (mounted) setState(() => _isPreviewPlaying = false);
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _adhanReciter,
                          underline: const SizedBox(),
                          dropdownColor: theme.cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 'mishary',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "مشاري العفاسي" : "Mishary Alafasy"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'abdul_basit',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "عبد الباسط عبد الصمد" : "Abdul Basit"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'madinah',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "أذان الحرم المدني" : "Al Haram Al Madani"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'kazabri',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "عمر القزابري" : "Omar Al Kazabri"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'riad',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "رياض الجزائري" : "Riad Al Djazairi"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'manssour',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "منصور الزهراني" : "Manssour El Zahrani"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'nakshabandi',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "سيد النقشبندي" : "Sayed Al Nakshabandi"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'maghriby',
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(TranslationService.isArabic ? "نور الدين المغربي" : "Nurdin Al Maghriby"),
                              ),
                            ),
                          ],
                          onChanged: _changeAdhanReciter,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    title: Text(TranslationService.isArabic ? "إيماءة إيقاف الأذان" : "Athan Stop Gesture"),
                    subtitle: Text(TranslationService.isArabic 
                        ? "إيقاف الأذان بالضغط على أزرار الصوت أو قلب الهاتف وجهه لأسفل" 
                        : "Stop Athan by pressing volume buttons or flipping the phone face down"),
                    trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                      value: _athanStopGesture,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 'both',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "أزرار الصوت وقلب الهاتف" : "Volume keys & Flip"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'volume_only',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "أزرار الصوت فقط" : "Volume keys only"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'flip_only',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "قلب الهاتف فقط" : "Flip phone only"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'none',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "لا توقف" : "Don't stop"),
                          ),
                        ),
                      ],
                      onChanged: _changeAthanStopGesture,
                    )),
                  ),
                ],
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.t('morning_azkar_reminder')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _morningAzkarReminder,
                  onChanged: (val) => _toggleDailyReminder('morning_azkar_reminder', val, (v) => _morningAzkarReminder = v),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.t('evening_azkar_reminder')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _eveningAzkarReminder,
                  onChanged: (val) => _toggleDailyReminder('evening_azkar_reminder', val, (v) => _eveningAzkarReminder = v),
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.t('todays_verse_reminder')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _todaysVerseReminder,
                  onChanged: (val) => _toggleDailyReminder('todays_verse_reminder', val, (v) => _todaysVerseReminder = v),
                ),
              ],
            )
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Audio & Quran
          _buildSectionHeader(TranslationService.t('recitations')),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
              children: [
                ListTile(
                  title: Text(TranslationService.t('qari')),
                  subtitle: Text(TranslationService.t('qari_sub')),
                  trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                    value: _reciter,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 'ar.alafasy', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "مشاري العفاسي" : "Mishary Alafasy"))),
                      DropdownMenuItem(value: 'ar.abdurrahmaansudais', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "عبد الرحمن السديس" : "Abdurrahman As-Sudais"))),
                      DropdownMenuItem(value: 'ar.mahermuaiqly', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "ماهر المعيقلي" : "Maher Al-Muaiqly"))),
                      DropdownMenuItem(value: 'ar.saadalghamidi', child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "سعد الغامدي" : "Saad Al-Ghamdi"))),
                    ],
                    onChanged: _changeReciter,
                  )),
                ),
                const Divider(height: 1, color: Colors.white10),
                 SwitchListTile(
                  title: Text(TranslationService.t('continuous_rec_label')),
                  subtitle: Text(TranslationService.t('continuous_rec_sub')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _continuousPlay,
                  onChanged: _toggleContinuousPlay,
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "إخفاء حدود القراءة المتواصلة" : "Hide Continuous Mode Borders"),
                  subtitle: Text(TranslationService.isArabic 
                      ? "إزالة الحواف والظلال لتصبح الصفحات متصلة تماماً" 
                      : "Remove section borders and shadows for seamless reading"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _hideContinuousBorders,
                  onChanged: _toggleHideContinuousBorders,
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "حفظ المرجعية تلقائياً" : "Auto-Bookmark on Play"),
                  subtitle: Text(TranslationService.isArabic
                      ? "حفظ الآية الحالية كعلامة مرجعية تلقائياً عند البدء بتشغيل التلاوة"
                      : "Automatically save the current verse as bookmark when audio playback starts"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _autoBookmark,
                  onChanged: _toggleAutoBookmark,
                ),
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "وضع القارئ الغامر" : "Immersive Reader Mode"),
                  subtitle: Text(TranslationService.isArabic
                      ? "إخفاء أشرطة النظام (شريط الحالة والتنقل) أثناء قراءة القرآن لتقليل التشتيت"
                      : "Hide system bars (status and navigation) while reading Quran to reduce distraction"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _immersiveReader,
                  onChanged: _toggleImmersiveReader,
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.download_for_offline, color: Color(0xFFE5C158)),
                  title: Text(TranslationService.t('quran_downloads')),
                  subtitle: Text(TranslationService.t('quran_downloads_sub')),
                  trailing: Icon(TranslationService.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranDownloadScreen(storage: widget.storage),
                      ),
                    );
                  },
                ),
              ],
            )
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Permissions
          _buildSectionHeader(TranslationService.t('system_settings_permissions')),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
              children: [
                SwitchListTile(
                  title: Text(TranslationService.t('wake_lock')),
                  subtitle: Text(TranslationService.t('wake_lock_sub')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _keepScreenAwake,
                  onChanged: _toggleKeepScreenAwake,
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.t('exact_alarms')),
                  subtitle: Text(TranslationService.t('exact_alarms_sub')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _exactAlarmPermitted 
                            ? (TranslationService.isArabic ? "مسموح" : "Allowed") 
                            : (TranslationService.isArabic ? "إعداد مطلوب" : "Setup Required"),
                        style: TextStyle(
                          color: _exactAlarmPermitted ? Colors.green : const Color(0xFFE5C158),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        TranslationService.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                        size: 12,
                        color: _exactAlarmPermitted ? Colors.white30 : const Color(0xFFE5C158),
                      ),
                    ],
                  ),
                  onTap: _exactAlarmPermitted ? null : _requestExactAlarm,
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text(TranslationService.t('battery_optimization')),
                  subtitle: Text(TranslationService.t('battery_optimization_sub')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _batteryIgnored 
                            ? (TranslationService.isArabic ? "متجاهل" : "Ignored") 
                            : (TranslationService.isArabic ? "إعداد مطلوب" : "Setup Required"),
                        style: TextStyle(
                          color: _batteryIgnored ? Colors.green : const Color(0xFFE5C158),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        TranslationService.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                        size: 12,
                        color: _batteryIgnored ? Colors.white30 : const Color(0xFFE5C158),
                      ),
                    ],
                  ),
                  onTap: _batteryIgnored ? null : _requestBatteryOptimization,
                ),
              ],
            )
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Focus Lock
          _buildSectionHeader(TranslationService.t('focus_prayer_lock')),
          Card(
            color: theme.cardColor.withOpacity(0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
              children: [
                ListTile(
                  title: Text(TranslationService.t('focus_timer')),
                  subtitle: Text(TranslationService.t('focus_prayer_lock_sub')),
                  trailing: SizedBox(width: 160, child: DropdownButton<int>(isExpanded: true, 
                    value: _focusLockDuration,
                    underline: const SizedBox(),
                    dropdownColor: theme.cardColor,
                    items: [
                      DropdownMenuItem(value: 0, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "إيقاف" : "Off"))),
                      DropdownMenuItem(value: 5, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "٥ دقائق" : "5 Minutes"))),
                      DropdownMenuItem(value: 10, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "١٠ دقائق" : "10 Minutes"))),
                      DropdownMenuItem(value: 15, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "١٥ دقيقة" : "15 Minutes"))),
                      DropdownMenuItem(value: 20, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "٢٠ دقيقة" : "20 Minutes"))),
                      DropdownMenuItem(value: 30, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(TranslationService.isArabic ? "٣٠ دقيقة" : "30 Minutes"))),
                    ],
                    onChanged: _changeFocusDuration,
                  )),
                ),
                if (_focusLockDuration > 0) ...[
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    title: Text(TranslationService.isArabic ? "نوع قفل التركيز" : "Focus Lock Mode"),
                    subtitle: Text(TranslationService.isArabic 
                        ? "اختر قفل التطبيق فقط أو قفل الهاتف بالكامل" 
                        : "Choose whether to lock the app or the entire phone"),
                    trailing: SizedBox(width: 160, child: DropdownButton<String>(isExpanded: true, 
                      value: _focusLockType,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 'app_only',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "قفل التطبيق فقط" : "App Lock Only"),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'whole_phone',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(TranslationService.isArabic ? "قفل الهاتف بالكامل" : "Whole Phone Lock"),
                          ),
                        ),
                      ],
                      onChanged: _changeFocusLockType,
                    )),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  SwitchListTile(
                    title: Text(TranslationService.t('focus_setting_auto')),
                    activeThumbColor: const Color(0xFFE5C158),
                    value: _focusAutoStart,
                    onChanged: _toggleFocusAutoStart,
                  ),
                ],
              ],
            )
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Donation Support Section
          _buildSectionHeader(TranslationService.isArabic ? "الدعم والمساهمة" : "Support & Contribution"),
          Card(
            color: theme.cardColor,
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism, color: Color(0xFFE5C158)),
              title: Text(
                TranslationService.isArabic ? "دعم تطبيق آية" : "Support Aya App", 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              subtitle: Text(
                TranslationService.isArabic 
                    ? "ساهم في دعم استضافة التطبيق وتطويره بدون إعلانات صدقة جارية" 
                    : "Support server costs and development, ad-free continuous charity"
              ),
              trailing: Icon(TranslationService.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 14, color: const Color(0xFFE5C158)),
              onTap: _showDonateDialog,
            ),
          ),
          Card(
            color: theme.cardColor,
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFE5C158)),
              title: Text(TranslationService.isArabic ? "حول التطبيق" : "About Aya", style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Icon(TranslationService.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 14, color: const Color(0xFFE5C158)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Reset Section
          _buildSectionHeader(TranslationService.t('system_management')),
          Card(
            color: theme.cardColor,
            child: ListTile(
              title: Text(
                TranslationService.t('reset_settings'), 
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)
              ),
              subtitle: Text(TranslationService.t('reset_settings_sub')),
              trailing: Icon(TranslationService.isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 14, color: Colors.redAccent),
              onTap: _resetApp,
            ),
          ),
          const SizedBox(height: 40),

          // App info credits
          Center(
            child: Column(
              children: [
                const Icon(Icons.mosque, color: Color(0xFFE5C158), size: 48),
                const SizedBox(height: 12),
                Text(
                  TranslationService.t('app_title').toUpperCase(),
                  style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  TranslationService.t('version_premium'),
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4), fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  TranslationService.t('bless_journey'),
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadStatusIcon(String reciterId) {
    return ValueListenableBuilder<Map<String, DownloadStatus>>(
      valueListenable: AdhanAudioService.instance.downloadStates,
      builder: (context, states, child) {
        final status = states[reciterId] ?? DownloadStatus.notDownloaded;
        switch (status) {
          case DownloadStatus.downloaded:
            return const Icon(Icons.check_circle, color: Colors.green, size: 16);
          case DownloadStatus.downloading:
            return const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5C158)),
              ),
            );
          case DownloadStatus.notDownloaded:
            return const Icon(Icons.cloud_download, color: Colors.orangeAccent, size: 16);
        }
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4.0, bottom: 8.0, end: 4.0),
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
