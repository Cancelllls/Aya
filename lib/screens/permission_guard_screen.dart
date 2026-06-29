import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';

class PermissionGuardScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onPassed;

  const PermissionGuardScreen({
    super.key,
    required this.storage,
    required this.onPassed,
  });

  @override
  State<PermissionGuardScreen> createState() => _PermissionGuardScreenState();
}

class _PermissionGuardScreenState extends State<PermissionGuardScreen>
    with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.quran.aya/system');

  bool _locationGranted = false;
  bool _bgLocationGranted = false;
  bool _notifGranted = false;
  bool _batteryIgnored = false;
  bool _exactAlarmGranted = false;
  bool _checking = true;
  int _androidSdkVersion = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSdkVersion().then((_) => _checkAllPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Slight delay so OS has time to commit the new permission state
      Future.delayed(const Duration(milliseconds: 400), _checkAllPermissions);
    }
  }

  Future<void> _initSdkVersion() async {
    try {
      final sdk =
          await _platform.invokeMethod<int>('getAndroidSdkVersion') ?? 24;
      _androidSdkVersion = sdk;
    } catch (_) {
      _androidSdkVersion = 24;
    }
  }

  Future<void> _checkAllPermissions() async {
    if (!mounted) return;
    setState(() => _checking = true);

    final gpsPerm = await Geolocator.checkPermission();
    final locOk =
        gpsPerm == LocationPermission.always ||
        gpsPerm == LocationPermission.whileInUse;
    final bgLocOk = gpsPerm == LocationPermission.always;

    final notifOk = await NotificationService().checkPermissions();

    bool batteryOk = true;
    try {
      batteryOk =
          await _platform.invokeMethod<bool>('checkBatteryOptimization') ??
          true;
    } catch (_) {}

    bool exactAlarmOk = true;
    try {
      exactAlarmOk =
          await _platform.invokeMethod<bool>('checkExactAlarmPermission') ??
          true;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _locationGranted = locOk;
      _bgLocationGranted = bgLocOk;
      _notifGranted = notifOk;
      _batteryIgnored = batteryOk;
      _exactAlarmGranted = exactAlarmOk;
      _checking = false;
    });

    final bgRequired = _androidSdkVersion >= 29;
    final alarmRequired = _androidSdkVersion >= 31;
    final allGood =
        locOk &&
        (!bgRequired || bgLocOk) &&
        notifOk &&
        batteryOk &&
        (!alarmRequired || exactAlarmOk);
    if (allGood) widget.onPassed();
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
      // On API 29+ users must manually select "Always" in App Settings
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  Future<void> _requestNotif() async {
    try {
      await NotificationService().requestPermissions();
      await _checkAllPermissions();
    } catch (_) {}
  }

  Future<void> _requestBattery() async {
    try {
      await _platform.invokeMethod('requestDisableBatteryOptimization');
    } catch (_) {}
  }

  Future<void> _requestExactAlarm() async {
    try {
      await _platform.invokeMethod('requestExactAlarmPermission');
    } catch (_) {}
  }

  void _onProceedClick() {
    final bgRequired = _androidSdkVersion >= 29;
    final alarmRequired = _androidSdkVersion >= 31;
    final allGood =
        _locationGranted &&
        (!bgRequired || _bgLocationGranted) &&
        _notifGranted &&
        _batteryIgnored &&
        (!alarmRequired || _exactAlarmGranted);

    if (allGood) {
      widget.onPassed();
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
            Expanded(
              child: Text(
                TranslationService.isArabic
                    ? "صلاحيات غير مكتملة"
                    : "Permissions Incomplete",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          TranslationService.isArabic
              ? "تحذير: بدون الصلاحيات المطلوبة، قد لا يعمل الأذان بدقة في الخلفية. هل تود المتابعة على أي حال؟"
              : "Warning: Without the required permissions, Athan alarms may not work accurately in the background. Proceed anyway?",
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onPassed();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showBgLocation = _androidSdkVersion >= 29;
    final showExactAlarm = _androidSdkVersion >= 31;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: theme.primaryColor,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                TranslationService.isArabic
                    ? "صلاحيات النظام المطلوبة"
                    : "Required System Permissions",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                TranslationService.isArabic
                    ? "يتطلب تطبيق آية الصلاحيات التالية للعمل بشكل صحيح وتشغيل الأذان في وقته التلقائي بالخلفية."
                    : "Aya requires the following permissions to function correctly and sound the Athan alarms on time in the background.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      icon: Icons.location_on,
                      title: TranslationService.isArabic
                          ? "إذن الموقع الجغرافي"
                          : "Location Permission",
                      description: TranslationService.isArabic
                          ? "لحساب أوقات الصلاة بدقة بناءً على موقعك."
                          : "Used to calculate prayer times accurately based on your location.",
                      isGranted: _locationGranted,
                      onRequest: _requestLocation,
                    ),
                    if (showBgLocation) ...[
                      const SizedBox(height: 12),
                      _buildPermissionItem(
                        icon: Icons.location_searching,
                        title: TranslationService.isArabic
                            ? "السماح دائماً بالموقع"
                            : "Always Allow Location",
                        description: TranslationService.isArabic
                            ? "لحساب مواقيت الصلاة في الخلفية حتى عند إغلاق التطبيق."
                            : "Needed to calculate prayer times in the background when the app is closed.",
                        isGranted: _bgLocationGranted,
                        onRequest: _requestBgLocation,
                        requiresPrior: !_locationGranted,
                        priorLabel: TranslationService.isArabic
                            ? "يتطلب إذن الموقع أولاً"
                            : "Requires location permission first",
                      ),
                    ],
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _buildPermissionItem(
                      icon: Icons.battery_saver,
                      title: TranslationService.isArabic
                          ? "تجاهل تحسين البطارية"
                          : "Ignore Battery Optimization",
                      description: TranslationService.isArabic
                          ? "لمنع النظام من تعطيل تنبيهات الصلاة بالخلفية."
                          : "Prevents Android from putting Athan alarms to sleep in background.",
                      isGranted: _batteryIgnored,
                      onRequest: _requestBattery,
                    ),
                    if (showExactAlarm) ...[
                      const SizedBox(height: 12),
                      _buildPermissionItem(
                        icon: Icons.access_alarm,
                        title: TranslationService.isArabic
                            ? "التنبيهات والتذكيرات"
                            : "Alarms & Reminders",
                        description: TranslationService.isArabic
                            ? "يتيح جدولة تنبيهات الأذان الدقيقة حتى في وضع توفير الطاقة."
                            : "Allows scheduling precise Athan alarms even in Doze mode.",
                        isGranted: _exactAlarmGranted,
                        onRequest: _requestExactAlarm,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _checking ? null : _checkAllPermissions,
                    icon: _checking
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(
                      TranslationService.isArabic ? "إعادة فحص" : "Re-Check",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _onProceedClick,
                    child: Text(
                      TranslationService.isArabic ? "متابعة" : "Proceed",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGranted
                    ? Colors.green.withOpacity(0.12)
                    : theme.primaryColor.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    requiresPrior && priorLabel != null
                        ? priorLabel
                        : description,
                    style: TextStyle(
                      color: requiresPrior
                          ? Colors.orangeAccent
                          : (isDark ? Colors.white54 : Colors.black54),
                      fontSize: 11,
                      height: 1.4,
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
                ? const Icon(Icons.check_circle, color: Colors.green)
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
}
