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
  bool _dndGranted = false;
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
    final dndOk = await _platform.invokeMethod<bool>('checkNotificationPolicyAccess') ?? false;
    final exactAlarmOk = await _platform.invokeMethod<bool>(
      'checkExactAlarmPermission',
    ) ??
        false;
    if (mounted) {
      setState(() {
        _locationGranted = locOk;
        _bgLocationGranted = bgLocOk;
        _notifGranted = notifOk;
        _dndGranted = dndOk;
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

  Future<void> _requestDnd() async {
    try {
      setState(() => _dndGranted = false);
      await _platform.invokeMethod('requestNotificationPolicyAccess');
      await _checkAllPermissions();
    } catch (_) {}
  }

  Future<void> _requestExactAlarm() async {
    try {
      setState(() => _exactAlarmGranted = false);
      await _platform.invokeMethod('requestExactAlarmPermission');
      await _checkAllPermissions();
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
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              TranslationService.isArabic
                  ? "صلاحيات غير مكتملة"
                  : "Permissions Incomplete",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          TranslationService.isArabic
              ? "تحذير: إذا واصلت بدون تفعيل صلاحيات الموقع والتنبيهات، فقد لا يتم تشغيل الأذان في موعده بدقة في الخلفية أو عند قفل الهاتف. هل تود المتابعة على أي حال؟"
              : "Warning: If you proceed without granting location and notifications, Adhan alarms and alerts may fail to run accurately in the background or when your screen is locked. Do you want to proceed anyway?",
          style: const TextStyle(height: 1.5, fontSize: 14),
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

    if (!_wantAdhan) {
      await widget.storage.setString('pre_adhan_alert_mode', 'off');
      await widget.storage.setString('adhan_alert_mode', 'off');
      await widget.storage.setBool('morning_azkar_reminder', false);
      await widget.storage.setBool('evening_azkar_reminder', false);
      await widget.storage.setBool('todays_verse_reminder', false);
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      _buildWelcomeSlide(theme, isDark),
                      _buildFeaturesSlide(theme, isDark),
                      _buildPermissionsSlide(theme, isDark),
                    ],
                  ),
                ),
                _buildBottomControls(theme, isDark),
              ],
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 16,
              top: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
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
                    color: primaryColor,
                  ),
                  label: Text(
                    TranslationService.isArabic ? 'English' : 'العربية',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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

  Widget _buildWelcomeSlide(ThemeData theme, bool isDark) {
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    final subtextColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white60 : Colors.black54);

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
                      color: primaryColor.withValues(alpha: 
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
                    color: primaryColor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            TranslationService.t('welcome_app_name'),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            TranslationService.t('welcome_spiritual_companion'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: subtextColor,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            TranslationService.t('welcome_intro_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: subtextColor.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFeaturesSlide(ThemeData theme, bool isDark) {
    final primaryColor = theme.primaryColor;
    final subtextColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white60 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            TranslationService.isArabic
                ? "ماذا يقدم التطبيق"
                : "What Aya Offers",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            TranslationService.isArabic
                ? "رفيقك الإسلامي المتكامل"
                : "Your complete Islamic companion",
            style: TextStyle(
              fontSize: 14,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.access_time_filled,
                  title: TranslationService.isArabic
                      ? 'مواقيت الصلاة والأذان'
                      : 'Prayer Times & Adhan',
                  description: TranslationService.isArabic
                      ? 'مواقيت دقيقة وأذان مع اختيار القراء ونداء قبل الأذان.'
                      : 'Accurate times, adhan with reciter selection & pre-adhan alerts.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.menu_book_rounded,
                  title: TranslationService.isArabic
                      ? 'القرآن الكريم'
                      : 'Holy Quran',
                  description: TranslationService.isArabic
                      ? 'تلاوة مع ١٠ قراءات مختلفة وتفسير ميسر وتحفيظ آية.'
                      : 'Read with 10 Qira\'at, tafsir, and verse-by-verse memorization.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.library_books,
                  title: TranslationService.isArabic
                      ? '١٣ كتاب حديث مع الشرح'
                      : '13 Hadith Books + Sharh',
                  description: TranslationService.isArabic
                      ? 'كل كتب الحديث الستة والمزيد مع التخريج والشرح دون اتصال.'
                      : 'All 6 major collections + 7 more. Offline grading & classical explanations.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.search_rounded,
                  title: TranslationService.isArabic
                      ? 'البحث في كل كتب الحديث'
                      : 'Cross-Book Hadith Search',
                  description: TranslationService.isArabic
                      ? 'ابحث في ٧٥ ألف حديث دفعة واحدة بدون تشكيل.'
                      : 'Search 75K+ hadiths across all books at once — no tashkeel needed.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.calendar_month,
                  title: TranslationService.isArabic
                      ? 'رمضان والمناسبات'
                      : 'Ramadan & Events',
                  description: TranslationService.isArabic
                      ? 'تنبيهات الإمساك والإفطار والتذكير بالمناسبات الإسلامية.'
                      : 'Imsak/Iftar alerts and Islamic event reminders throughout the year.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.spa,
                  title: TranslationService.isArabic
                      ? 'الأذكار اليومية'
                      : 'Daily Azkar',
                  description: TranslationService.isArabic
                      ? 'أذكار الصباح والمساء والنوم والصلاة مع إمكانية إضافة أذكارك الخاصة.'
                      : 'Morning/evening/sleep/prayer azkar with custom entry support.',
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  theme: theme,
                  icon: Icons.wifi_off,
                  title: TranslationService.isArabic
                      ? 'بدون اتصال بالإنترنت'
                      : '100% Offline-First',
                  description: TranslationService.isArabic
                      ? 'كل شيء يعمل بدون إنترنت: قرآن، حديث، أذكار، مواقيت، أذان.'
                      : 'Everything works offline: Quran, Hadith, Azkar, Prayer Times, Adhan.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final subtextColor = theme.textTheme.bodyMedium?.color ?? Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSlide(ThemeData theme, bool isDark) {
    final primaryColor = theme.primaryColor;
    final subtextColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white60 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_rounded,
            color: primaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            TranslationService.isArabic
                ? "صلاحيات النظام المطلوبة"
                : "Required System Permissions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.isArabic
                ? "لتشغيل الأذان والمواقيت بدقة والتنبيهات في الخلفية"
                : "To run accurate Adhan, prayer times & background alerts",
            style: TextStyle(
              fontSize: 13,
              color: subtextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Adhan Toggle Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _wantAdhan
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: _wantAdhan ? primaryColor : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.isArabic
                            ? "تفعيل الأذان والتنبيهات"
                            : "Enable Adhan Alarms & Alerts",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _wantAdhan
                            ? (TranslationService.isArabic
                                ? "ستتلقى تنبيهات الأذان والأذكار"
                                : "You will receive adhan & azkar alerts")
                            : (TranslationService.isArabic
                                ? "لن يتم تشغيل أي تنبيهات أو أذان"
                                : "All alarms & alerts disabled"),
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _wantAdhan,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() => _wantAdhan = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Permission Cards List
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _wantAdhan ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !_wantAdhan,
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      icon: Icons.location_on_rounded,
                      title: TranslationService.isArabic
                          ? "صلاحية الموقع (GPS)"
                          : "Location Access (GPS)",
                      description: TranslationService.isArabic
                          ? "لحساب مواقيت الصلاة واتجاه القبلة بدقة"
                          : "For accurate prayer times & Qibla direction",
                      isGranted: _locationGranted,
                      onRequest: _requestLocation,
                    ),
                    const SizedBox(height: 10),
                    if (_androidSdkVersion >= 29) ...[
                      _buildPermissionItem(
                        icon: Icons.my_location_rounded,
                        title: TranslationService.isArabic
                            ? "الموقع في الخلفية (دائم)"
                            : "Background Location (Always)",
                        description: TranslationService.isArabic
                            ? "لتحديث المواقيت تلقائياً عند السفر والتنقل"
                            : "To update times automatically when traveling",
                        isGranted: _bgLocationGranted,
                        requiresPrior: !_locationGranted,
                        priorLabel: TranslationService.isArabic
                            ? "يتطلب تفعيل الموقع أولاً"
                            : "Requires basic location permission first",
                        onRequest: _requestBgLocation,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildPermissionItem(
                      icon: Icons.notifications_rounded,
                      title: TranslationService.isArabic
                          ? "إشعارات النظام"
                          : "System Notifications",
                      description: TranslationService.isArabic
                          ? "لعرض الإشعارات والتنبيهات على الشاشة"
                          : "To display alerts & prayer cards on screen",
                      isGranted: _notifGranted,
                      onRequest: _requestNotif,
                    ),
                    const SizedBox(height: 10),
                    if (_androidSdkVersion >= 31) ...[
                      _buildPermissionItem(
                        icon: Icons.alarm_rounded,
                        title: TranslationService.isArabic
                            ? "جدولة التنبيهات الدقيقة"
                            : "Schedule Exact Alarms",
                        description: TranslationService.isArabic
                            ? "ضروري لتشغيل الأذان في موعده بدقة في الخلفية"
                            : "Required to launch adhan exactly on time in background",
                        isGranted: _exactAlarmGranted,
                        onRequest: _requestExactAlarm,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildPermissionItem(
                      icon: Icons.do_not_disturb_on_rounded,
                      title: TranslationService.isArabic
                          ? "الوضع الصامت التلقائي (DND)"
                          : "Do Not Disturb (DND) Access",
                      description: TranslationService.isArabic
                          ? "لتفعيل الوضع الصامت تلقائياً أثناء الصلاة وإعادته"
                          : "To automatically silence device during prayer",
                      isGranted: _dndGranted,
                      onRequest: _requestDnd,
                    ),
                  ],
                ),
              ),
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
    final subtextColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white54 : Colors.black54);

    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
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
                    ? Colors.green.withValues(alpha: 0.12)
                    : theme.primaryColor.withValues(alpha: 0.08),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : theme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    requiresPrior && priorLabel != null
                        ? priorLabel
                        : description,
                    style: TextStyle(
                      color: requiresPrior ? Colors.orangeAccent : subtextColor,
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
            const SizedBox(width: 8),
            isGranted
                ? GestureDetector(
                    onTap: onRequest,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          TranslationService.isArabic ? "إدارة" : "Manage",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: requiresPrior ? null : onRequest,
                    child: Text(
                      TranslationService.isArabic ? "تفعيل" : "Enable",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, bool isDark) {
    final primaryColor = theme.primaryColor;

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
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Next / Get Started Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
