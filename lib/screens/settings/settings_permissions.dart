part of 'settings_screen.dart';

extension SettingsPermissionsSection on _SettingsScreenState {
  List<Widget> _buildPermissionsSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;
    return [
      // Section Permissions & Health Diagnostics
      _buildSectionHeader(TranslationService.t('system_settings_permissions')),
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
                  title: Text(TranslationService.t('wake_lock')),
                  subtitle: Text(TranslationService.t('wake_lock_sub')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _keepScreenAwake,
                  onChanged: _toggleKeepScreenAwake,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  title: TranslationService.t('exact_alarms'),
                  subtitle: TranslationService.t('exact_alarms_sub'),
                  isGranted: _exactAlarmPermitted,
                  onTap: _requestExactAlarm,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  title: isAr ? "تحسين البطارية" : "Battery Optimization",
                  subtitle: isAr
                      ? "السماح بالعمل في الخلفية لتشغيل الأذان"
                      : "Allow background execution for adhan alarms",
                  isGranted: _batteryOptIgnored,
                  onTap: _requestBatteryOptimization,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  title: isAr ? "الإشعارات" : "Notifications",
                  subtitle: isAr
                      ? "إشعارات الأذان والتهجُّد والأذكار اليومية"
                      : "Adhan & daily dhikr notifications",
                  isGranted: _notificationPermitted,
                  onTap: _requestNotificationPermission,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  title: isAr ? "خدمات الموقع" : "Location Services",
                  subtitle: isAr
                      ? "حساب مواقيت الصلاة واتجاه القبلة تلقائياً"
                      : "Auto-calculate prayer times and Qibla direction",
                  isGranted: _locationPermitted,
                  onTap: _requestLocationPermission,
                ),
                _buildDivider(),
                _buildPermissionStatusTile(
                  title: isAr ? "وصول وضع عدم الإزعاج" : "Do Not Disturb Access",
                  subtitle: isAr
                      ? "كتم صوت الهاتف تلقائياً أثناء وقت الصلاة"
                      : "Auto-silence ringer during prayer times",
                  isGranted: _dndPolicyPermitted,
                  onTap: _requestDndPermission,
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
    );
  }

  Widget _buildPermissionStatusTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    final isAr = TranslationService.isArabic;
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withValues(alpha: 0.15)
                  : const Color(0xFFE5C158).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGranted ? Colors.green : const Color(0xFFE5C158),
                width: 1,
              ),
            ),
            child: Text(
              isGranted
                  ? (isAr ? "مفعل" : "Granted")
                  : (isAr ? "إعداد مطلوب" : "Setup Required"),
              style: TextStyle(
                color: isGranted ? Colors.green : const Color(0xFFE5C158),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isAr ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
            size: 12,
            color: isGranted
                ? (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white)
                    .withValues(alpha: 0.3)
                : const Color(0xFFE5C158),
          ),
        ],
      ),
      onTap: isGranted ? null : onTap,
    );
  }
}
