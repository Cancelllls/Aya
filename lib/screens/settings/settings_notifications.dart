part of 'settings_screen.dart';

extension SettingsNotificationsSection on _SettingsScreenState {
  Future<void> _toggleAutoDndEnabled(bool val) async {
    setState(() {
      _autoDndEnabled = val;
    });
    await widget.storage.setBool('auto_dnd_enabled', val);
  }

  Future<void> _changeAutoDndDuration(int val) async {
    setState(() {
      _autoDndDuration = val;
    });
    await widget.storage.setInt('auto_dnd_duration', val);
    await widget.storage.setInt('auto_dnd_minutes', val);
  }

  Future<void> _toggleMorningAzkarReminder(bool val) async {
    setState(() {
      _morningAzkarReminder = val;
    });
    await widget.storage.setBool('morning_azkar_reminder', val);
    try {
      await NotificationService().scheduleDailyReminders(widget.storage);
    } catch (_) {}
  }

  Future<void> _toggleEveningAzkarReminder(bool val) async {
    setState(() {
      _eveningAzkarReminder = val;
    });
    await widget.storage.setBool('evening_azkar_reminder', val);
    try {
      await NotificationService().scheduleDailyReminders(widget.storage);
    } catch (_) {}
  }

  Future<void> _toggleTodaysVerseReminder(bool val) async {
    setState(() {
      _todaysVerseReminder = val;
    });
    await widget.storage.setBool('todays_verse_reminder', val);
    try {
      await NotificationService().scheduleDailyReminders(widget.storage);
    } catch (_) {}
  }

  Future<void> _toggleIslamicEventsEnabled(bool val) async {
    setState(() {
      _islamicEventsEnabled = val;
    });
    await widget.storage.setBool('islamic_events_enabled', val);
    try {
      await NotificationService().scheduleDailyReminders(widget.storage);
    } catch (_) {}
  }

  List<Widget> _buildNotificationsSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;
    final primary = theme.colorScheme.primary;

    return [
      // === SECTION 1: ADHAN & ALERTS ===
      SettingsSectionHeader(
        icon: Icons.notifications_active_outlined,
        title: isAr ? 'الأذان والتنبيهات' : 'Adhan & Alerts',
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
                // Advanced Adhan & Pre-Alert Settings Tile
                ListTile(
                  leading: Icon(Icons.tune_outlined, color: primary),
                  title: Text(
                    isAr
                        ? "إعدادات الأذان والتنبيه المسبق (لكل صلاة)"
                        : "Adhan & Pre-Alert Customization",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr
                        ? "تخصيص صوت المؤذن، التنبيه المسبق، التدرج بالصوت، والوضع الصامت التلقائي"
                        : "Per-prayer reciters, pre-alerts, volume ramp & auto-DND",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdhanSettingsScreen()),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Adhan Stop Gesture
                ListTile(
                  leading: Icon(Icons.gesture_outlined, color: primary),
                  title: Text(
                    isAr ? "إيقاف الأذان بالإيماءات" : "Athan Stop Gesture",
                  ),
                  subtitle: Text(
                    isAr
                        ? "إيقاف الأذان بأزرار الصوت أو قلب الهاتف"
                        : "Stop adhan using volume buttons or flipping phone",
                  ),
                  trailing: SettingsValueChip<String>(
                    value: _athanStopGesture,
                    label: isAr ? 'طريقة إيقاف الأذان' : 'Athan Stop Gesture',
                    items: [
                      DropdownMenuItem(
                        value: 'both',
                        child: Text(isAr ? "أزرار الصوت وقلب الشاشة" : "Volume Keys & Flip"),
                      ),
                      DropdownMenuItem(
                        value: 'volume_only',
                        child: Text(isAr ? "أزرار الصوت فقط" : "Volume Keys Only"),
                      ),
                      DropdownMenuItem(
                        value: 'flip_only',
                        child: Text(isAr ? "قلب الشاشة فقط" : "Flip Phone Only"),
                      ),
                      DropdownMenuItem(
                        value: 'none',
                        child: Text(isAr ? "إيقاف من التطبيق فقط" : "App Button Only"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeAthanStopGesture(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // Auto DND During Prayer
                SwitchListTile(
                  secondary: Icon(Icons.do_not_disturb_on_outlined, color: primary),
                  title: Text(
                    isAr ? "الصامت التلقائي أثناء الصلاة" : "Auto Silence (DND) During Prayer",
                  ),
                  subtitle: Text(
                    isAr
                        ? "تفعيل وضع عدم الإزعاج تلقائياً عند وقت الصلاة"
                        : "Silence phone automatically during prayer time",
                  ),
                  activeColor: primary,
                  value: _autoDndEnabled,
                  onChanged: _toggleAutoDndEnabled,
                ),
                if (_autoDndEnabled) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: Icon(Icons.timer_outlined, color: primary),
                    title: Text(
                      isAr ? "مدة الوضع الصامت" : "Auto Silence Duration",
                    ),
                    trailing: SettingsValueChip<int>(
                      value: _autoDndDuration,
                      label: isAr ? 'مدة الصامت' : 'Silence Duration',
                      items: [15, 20, 30, 45].map((m) {
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text('$m ${isAr ? "دقيقة" : "mins"}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _changeAutoDndDuration(val);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      // === SECTION 2: DAILY REMINDERS ===
      SettingsSectionHeader(
        icon: Icons.notifications_paused_outlined,
        title: isAr ? 'التذكيرات اليومية والإسلامية' : 'Daily & Islamic Reminders',
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
                SwitchListTile(
                  secondary: Icon(Icons.wb_sunny_outlined, color: primary),
                  title: Text(
                    isAr ? "تذكير أذكار الصباح" : "Morning Azkar Reminder",
                  ),
                  activeColor: primary,
                  value: _morningAzkarReminder,
                  onChanged: _toggleMorningAzkarReminder,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.nights_stay_outlined, color: primary),
                  title: Text(
                    isAr ? "تذكير أذكار المساء" : "Evening Azkar Reminder",
                  ),
                  activeColor: primary,
                  value: _eveningAzkarReminder,
                  onChanged: _toggleEveningAzkarReminder,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.menu_book_outlined, color: primary),
                  title: Text(
                    isAr ? "تذكير آية اليوم" : "Today's Verse Reminder",
                  ),
                  activeColor: primary,
                  value: _todaysVerseReminder,
                  onChanged: _toggleTodaysVerseReminder,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.event_outlined, color: primary),
                  title: Text(
                    isAr ? "تنبيهات المناسبات الإسلامية" : "Islamic Event Reminders",
                  ),
                  subtitle: Text(
                    isAr
                        ? "تنبيه يوم الجمعة والأعياد ونهار الأيام المباركة"
                        : "Alerts for Friday, Eids, and blessed days",
                  ),
                  activeColor: primary,
                  value: _islamicEventsEnabled,
                  onChanged: _toggleIslamicEventsEnabled,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(Icons.brightness_3_outlined, color: primary),
                  title: Text(
                    isAr ? "تنبيهات شهر رمضان (الإمساك والإفطار)" : "Ramadan Reminders (Imsak & Iftar)",
                  ),
                  subtitle: Text(
                    isAr
                        ? "ضبط وقت التنبيه قبل السحور والإفطار"
                        : "Configure Imsak suhoor and Iftar alert timings",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RamadanRemindersScreen(storage: widget.storage),
                      ),
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
