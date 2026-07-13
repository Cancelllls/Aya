import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../widgets/islamic_logo_painter.dart';

class WelcomeScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onThemeChanged;
  final VoidCallback onComplete;

  const WelcomeScreen({
    super.key,
    required this.storage,
    required this.onThemeChanged,
    required this.onComplete,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  late AnimationController _logoController;
  int _currentPage = 0;

  static const _platform = MethodChannel('com.quran.aya/system');

  bool _wantAdhan = true;
  bool _locationGranted = false;
  bool _bgLocationGranted = false;
  bool _exactAlarmGranted = false;
  bool _notifGranted = false;
  int _androidSdkVersion = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    _initSdkAndPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 400), _checkAllPermissions);
    }
  }

  Future<void> _initSdkAndPermissions() async {
    try {
      final sdk =
          await _platform.invokeMethod<int>('getAndroidSdkVersion') ?? 24;
      _androidSdkVersion = sdk;
    } catch (_) {
      _androidSdkVersion = 24;
    }
    await _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final gpsPerm = await Geolocator.checkPermission();
    final locOk =
        gpsPerm == LocationPermission.always ||
        gpsPerm == LocationPermission.whileInUse;
    final bgLocOk = gpsPerm == LocationPermission.always;
    final notifOk = await NotificationService().checkPermissions();
    bool exactAlarmOk = true;
    try {
      exactAlarmOk =
          await _platform.invokeMethod<bool>('checkExactAlarmPermission') ??
          true;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _locationGranted = locOk;
        _bgLocationGranted = bgLocOk;
        _notifGranted = notifOk;
        _exactAlarmGranted = exactAlarmOk;
      });
    }
  }

  Future<void> _requestLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      } else if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
        await _checkAllPermissions();
      }
    } catch (_) {}
  }

  Future<void> _requestBgLocation() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  Future<void> _requestNotif() async {
    try {
      await NotificationService().requestPermissions();
      await _checkAllPermissions();
    } catch (_) {}
  }

  Future<void> _requestExactAlarm() async {
    try {
      await _platform.invokeMethod('requestExactAlarmPermission');
    } catch (_) {}
  }

  void _onProceedClick() {
    if (!_wantAdhan) {
      _finishOnboarding();
      return;
    }

    final bgRequired = _androidSdkVersion >= 29;
    final alarmRequired = _androidSdkVersion >= 31;
    final allGood =
        _locationGranted &&
        (!bgRequired || _bgLocationGranted) &&
        _notifGranted &&
        (!alarmRequired || _exactAlarmGranted);
    if (allGood) {
      _finishOnboarding();
      return;
    }

    final cardColor = Theme.of(context).cardColor;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              TranslationService.isArabic
                  ? "صلاحيات غير مكتملة"
                  : "Permissions Incomplete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          TranslationService.isArabic
              ? "تحذير: إذا واصلت بدون تفعيل صلاحيات الموقع والتنبيهات، فقد لا يتم تشغيل الأذان في موعده بدقة في الخلفية أو عند قفل الهاتف. هل تود المتابعة على أي حال؟"
              : "Warning: If you proceed without granting location and notifications, Athan alarms and alerts may fail to run accurately in the background or when your screen is locked. Do you want to proceed anyway?",
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              TranslationService.isArabic
                  ? "الرجوع وتفعيلها"
                  : "Go Back & Enable",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _finishOnboarding();
            },
            child: Text(
              TranslationService.isArabic
                  ? "متابعة على أي حال"
                  : "Proceed Anyway",
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    await widget.storage.setBool('first_time_v2', false);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF07090E)
          : const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildWelcomeSlide(isDark),
                      _buildFeaturesSlide(isDark),
                      _buildPermissionsSlide(isDark),
                    ],
                  ),
                ),
                _buildBottomControls(isDark),
              ],
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 16,
              top: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5C158).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    final newLang = TranslationService.isArabic ? 'en' : 'ar';
                    await widget.storage.setString('lang_code', newLang);
                    TranslationService.setLanguage(newLang);
                    widget.onThemeChanged();
                  },
                  icon: Icon(
                    Icons.language,
                    size: 16,
                    color: Color(0xFFE5C158),
                  ),
                  label: Text(
                    TranslationService.isArabic ? 'English' : 'العربية',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C158),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Glowing Animated Custom Vector Logo
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5C158).withOpacity(
                        0.06 + 0.04 * sin(_logoController.value * 2 * pi),
                      ),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: IslamicLogoPainter(
                    animationValue: _logoController.value,
                    color: const Color(0xFFE5C158),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 48),
          Text(
            TranslationService.t('welcome_app_name'),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Color(0xFFE5C158),
            ),
          ),
          SizedBox(height: 12),
          Text(
            TranslationService.t('welcome_spiritual_companion'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            TranslationService.t('welcome_intro_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? (Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.white)
                        .withOpacity(0.3)
                  : Colors.black38,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFeaturesSlide(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            TranslationService.t('welcome_features_title'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
          SizedBox(height: 8),
          Text(
            TranslationService.t('welcome_features_sub'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 32),
          _buildFeatureRow(
            icon: Icons.access_time_filled,
            title: TranslationService.t('welcome_feat_prayer_title'),
            description: TranslationService.t('welcome_feat_prayer_desc'),
          ),
          SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.menu_book,
            title: TranslationService.t('welcome_feat_quran_title'),
            description: TranslationService.t('welcome_feat_quran_desc'),
          ),
          SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.explore,
            title: TranslationService.t('welcome_feat_qibla_title'),
            description: TranslationService.t('welcome_feat_qibla_desc'),
          ),
          SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.volunteer_activism,
            title: TranslationService.t('welcome_feat_tasbih_title'),
            description: TranslationService.t('welcome_feat_tasbih_desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = widget.storage.isDarkMode();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE5C158).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.2)),
          ),
          child: Icon(icon, color: const Color(0xFFE5C158), size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isDark
                      ? (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.white)
                            .withOpacity(0.38)
                      : Colors.black45,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSlide(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_rounded, color: Color(0xFFE5C158), size: 64),
          SizedBox(height: 16),
          Text(
            TranslationService.isArabic
                ? "صلاحيات النظام المطلوبة"
                : "Required System Permissions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            TranslationService.isArabic
                ? "يتطلب التطبيق الصلاحيات التالية للعمل بشكل صحيح وتشغيل الأذان في وقته بالخلفية."
                : "Aya requires the following permissions to function correctly and sound the Athan alarms on time in the background.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          CheckboxListTile(
            title: Text(
              TranslationService.isArabic
                  ? "أريد استلام تنبيهات الأذان والأذكار"
                  : "I want to receive Adhan and Notification alerts",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            value: _wantAdhan,
            activeColor: Color(0xFFE5C158),
            checkColor: Colors.black,
            onChanged: (val) {
              setState(() {
                _wantAdhan = val ?? true;
              });
            },
          ),
          if (!_wantAdhan)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                TranslationService.isArabic
                    ? "لن يتم طلب الصلاحيات الآن. يمكنك تفعيل الأذان لاحقاً من الإعدادات."
                    : "Permissions won't be requested. You can enable Adhan later from Settings.",
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          if (_wantAdhan)
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildPermissionItem(
                  icon: Icons.location_on,
                  title: TranslationService.isArabic
                      ? "إذن الموقع الجغرافي"
                      : "Location Permission",
                  description: TranslationService.isArabic
                      ? "لحساب مواقيت الصلاة بدقة بناءً على موقعك."
                      : "Used to calculate prayer times accurately based on your location.",
                  isGranted: _locationGranted,
                  onRequest: _requestLocation,
                ),
                // Always Allow — only on API 29+ (Android 10+)
                if (_androidSdkVersion >= 29) ...[
                  SizedBox(height: 10),
                  _buildPermissionItem(
                    icon: Icons.location_searching,
                    title: TranslationService.isArabic
                        ? "السماح دائماً بالموقع"
                        : "Always Allow Location",
                    description: TranslationService.isArabic
                        ? "لحساب مواقيت الصلاة في الخلفية حتى عند إغلاق التطبيق."
                        : "Needed to calculate prayer times in background when app is closed.",
                    isGranted: _bgLocationGranted,
                    onRequest: _requestBgLocation,
                    requiresPrior: !_locationGranted,
                    priorLabel: TranslationService.isArabic
                        ? "يتطلب إذن الموقع أولاً"
                        : "Requires location permission first",
                  ),
                ],
                SizedBox(height: 10),
                _buildPermissionItem(
                  icon: Icons.notifications_active,
                  title: TranslationService.isArabic
                      ? "إذن الإشعارات"
                      : "Notification Alerts",
                  description: TranslationService.isArabic
                      ? "لإرسال تنبيهات الأذان والأذكار في مواقيتها."
                      : "Used to send sound and voice alerts on prayer times.",
                  isGranted: _notifGranted,
                  onRequest: _requestNotif,
                ),
                // Alarms & Reminders — only on API 31+ (Android 12+)
                if (_androidSdkVersion >= 31) ...[
                  SizedBox(height: 10),
                  _buildPermissionItem(
                    icon: Icons.access_alarm,
                    title: TranslationService.isArabic
                        ? "التنبيهات والتذكيرات"
                        : "Alarms & Reminders",
                    description: TranslationService.isArabic
                        ? "يسمح بجدولة تنبيهات الأذان الدقيقة حتى في وضع توفير الطاقة."
                        : "Allows scheduling precise Athan alarms even in Doze mode.",
                    isGranted: _exactAlarmGranted,
                    onRequest: _requestExactAlarm,
                  ),
                ],
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    bool requiresPrior = false,
    String? priorLabel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGranted
                    ? Colors.green.withOpacity(0.12)
                    : theme.primaryColor.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : theme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 2),
                  Text(
                    requiresPrior && priorLabel != null
                        ? priorLabel
                        : description,
                    style: TextStyle(
                      color: requiresPrior
                          ? Colors.orangeAccent
                          : (isDark ? Colors.white54 : Colors.black54),
                      fontSize: 11,
                      height: 1.3,
                      fontStyle: requiresPrior
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            isGranted
                ? Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: requiresPrior ? null : onRequest,
                    child: Text(
                      TranslationService.isArabic ? "تفعيل" : "Enable",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicator Dots
          Row(
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsetsDirectional.only(end: 6),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFFE5C158)
                      : const Color(0xFFE5C158).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Next / Get Started Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5C158),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              } else {
                _onProceedClick();
              }
            },
            child: Text(
              _currentPage == 2
                  ? TranslationService.t('welcome_start_now')
                  : TranslationService.t('welcome_next'),
            ),
          ),
        ],
      ),
    );
  }
}
