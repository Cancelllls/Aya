part of 'settings_screen.dart';

extension SettingsPermissionsSection on _SettingsScreenState {
  List<Widget> _buildPermissionsSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;
    final allGranted = _exactAlarmPermitted && _notificationPermitted && _locationPermitted;

    return [
      // Section Permissions & Health Diagnostics
      SettingsSectionHeader(
        icon: Icons.health_and_safety_outlined,
        title: isAr ? 'الأذونات واعتمادية التنبيهات' : 'Permissions & Reliability',
        iconColor: allGranted ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
      ),

      // Summary Status Card
      Card(
        elevation: 0,
        color: allGranted ? Colors.teal.shade50.withValues(alpha: 0.2) : Colors.amber.shade50.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: allGranted ? Colors.teal.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Icon(
                allGranted ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                color: allGranted ? Colors.teal : Colors.amber.shade800,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allGranted
                          ? (isAr ? 'الأذونات والمنبهات في حالة ممتازة 🟢' : 'Permissions & Alarms Healthy 🟢')
                          : (isAr ? 'بعض الأذونات تتطلب الضبط 🟡' : 'Permission Action Required 🟡'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allGranted
                          ? (isAr ? 'تأكد من ضبط التشغيل التلقائي في أجهزة شاومي وهواوي وسامسونج' : 'Ensure autostart is allowed on OEM devices')
                          : (isAr ? 'انقر على الأذونات المتبقية لتفعيلها لضمان وصول الأذان' : 'Tap missing permissions to ensure reliable adhan'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),

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
                _buildPermissionStatusTile(
                  icon: Icons.alarm_on_outlined,
                  title: TranslationService.t('exact_alarms'),
                  subtitle: TranslationService.t('exact_alarms_sub'),
                  isGranted: _exactAlarmPermitted,
                  onTap: _requestExactAlarm,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  icon: Icons.notifications_active_outlined,
                  title: isAr ? "الإشعارات" : "Notifications",
                  subtitle: isAr
                      ? "إشعارات الأذان والتهجُّد والأذكار اليومية"
                      : "Adhan & daily dhikr notifications",
                  isGranted: _notificationPermitted,
                  onTap: _requestNotificationPermission,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  icon: Icons.location_on_outlined,
                  title: isAr ? "خدمات الموقع" : "Location Services",
                  subtitle: isAr
                      ? "حساب مواقيت الصلاة واتجاه القبلة تلقائياً"
                      : "Auto-calculate prayer times and Qibla direction",
                  isGranted: _locationPermitted,
                  onTap: _requestLocationPermission,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  icon: Icons.do_not_disturb_outlined,
                  title: isAr ? "وصول وضع عدم الإزعاج" : "Do Not Disturb Access",
                  subtitle: isAr
                      ? "كتم صوت الهاتف تلقائياً أثناء وقت الصلاة"
                      : "Auto-silence ringer during prayer times",
                  isGranted: _dndPolicyPermitted,
                  onTap: _requestDndPermission,
                ),
                _buildDivider(),
                ListTile(
                  leading: const Icon(Icons.launch_outlined, color: Color(0xFF15803D)),
                  title: Text(
                    isAr ? "إعدادات التشغيل التلقائي (OEM)" : "OEM Autostart Settings",
                  ),
                  subtitle: Text(
                    isAr
                        ? "حماية الأذان من الإغلاق في هواتف (Xiaomi, Samsung, Huawei, Oppo...)"
                        : "Protect adhan from being killed on OEM battery savers",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AdhanNativeController.instance.requestOemAutostart();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
    );
  }

  Widget _buildPermissionStatusTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isGranted ? const Color(0xFF15803D) : Colors.amber.shade800),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: PermissionStatusBadge(
        isGranted: isGranted,
        grantedLabel: TranslationService.isArabic ? "مفعل" : "Granted",
        requiredLabel: TranslationService.isArabic ? "إعداد مطلوب" : "Required",
      ),
      onTap: isGranted ? null : onTap,
    );
  }
}
