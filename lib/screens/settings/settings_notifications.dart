part of 'settings_screen.dart';

extension SettingsNotificationsSection on _SettingsScreenState {
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

  Future<void> _changeNotificationLang(String val) async {
    setState(() {
      _notificationLang = val;
    });
    await widget.storage.setString('notification_lang', val);
    try {
      await NotificationService().scheduleDailyReminders(widget.storage);
    } catch (_) {}
    _debouncedReschedule();
  }

  Future<void> _changeDefaultAdhanReciter(String val) async {
    setState(() {
      _adhanReciter = val;
    });
    await widget.storage.setString('adhan_reciter', val);
    _debouncedReschedule();
  }

  List<Widget> _buildNotificationsSection(ThemeData theme) {
    final isAr = TranslationService.isArabic;
    final primary = theme.colorScheme.primary;

    final standardReciters = isAr
        ? {
            'mishary': 'مشاري العفاسي (الكويت)',
            'abdul_basit': 'عبد الباسط عبد الصمد (مصر)',
            'manssour': 'منصور الزهراني (السعودية)',
            'maghriby': 'نور الدين الهذيوي (القدس)',
            'kazabri': 'عمر القزابري (المغرب)',
            'riad': 'رياض الجزائري (الجزائر)',
            'nakshabandi': 'سيد النقشبندي (مصر)',
          }
        : {
            'mishary': 'Mishary Al-Afasy (Kuwait)',
            'abdul_basit': 'Abdul Basit (Egypt)',
            'manssour': 'Manssour Al-Zahrani (Saudi Arabia)',
            'maghriby': 'Nurdin Al-Maghriby (Al-Quds)',
            'kazabri': 'Omar Al-Kazabri (Morocco)',
            'riad': 'Riad Al-Djazairi (Algeria)',
            'nakshabandi': 'Sayed Al-Nakshabandi (Egypt)',
          };

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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
                // 1. Notification Language (independent of app language)
                ListTile(
                  leading: Icon(Icons.language_outlined, color: primary),
                  title: Text(
                    isAr ? "لغة الإشعارات والتنبيهات" : "Notification Language",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr
                        ? "تحديد لغة نصوص الأذان والتنبيهات بشكل مستقل"
                        : "Alert & reminder language independent of app language",
                  ),
                  trailing: SettingsValueChip<String>(
                    value: _notificationLang,
                    label: isAr ? 'لغة الإشعارات' : 'Notification Language',
                    items: [
                      DropdownMenuItem(
                        value: 'follow_app',
                        child: Text(isAr ? "حسب لغة التطبيق" : "Follow App Language"),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(isAr ? "العربية (Arabic)" : "Arabic (العربية)"),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(isAr ? "الإنجليزية (English)" : "English"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _changeNotificationLang(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // 3. Default Adhan Reciter Voice
                ListTile(
                  leading: Icon(Icons.record_voice_over_outlined, color: primary),
                  title: Text(
                    isAr ? "صوت الأذان العام المفضل" : "Default Adhan Sound",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr
                        ? "المؤذن الافتراضي لجميع مواقيت الصلاة"
                        : "Global reciter voice for all prayer times",
                  ),
                  trailing: SettingsValueChip<String>(
                    value: standardReciters.containsKey(_adhanReciter) ? _adhanReciter : 'mishary',
                    label: isAr ? 'صوت المؤذن' : 'Adhan Reciter',
                    items: standardReciters.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _changeDefaultAdhanReciter(val);
                      }
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),

                // 4. Per-Prayer & Multi-Reminder Customization Sub-screen
                ListTile(
                  leading: Icon(Icons.tune_outlined, color: primary),
                  title: Text(
                    isAr
                        ? "تخصيص الأذان والتنبيهات المتعددة (لكل صلاة)"
                        : "Adhan & Multi-Reminder Customization",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAr
                        ? "تخصيص كل صلاة على حدة، تنبيهات مبكرة، وتنبيه الإقامة"
                        : "Per-prayer reciters, early pre-alerts & iqamah reminders",
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
                    isAr ? "إيقاف الأذان بالإيماءات" : "Adhan Stop Gesture",
                  ),
                  subtitle: Text(
                    isAr
                        ? "إيقاف الأذان بأزرار الصوت أو قلب الهاتف"
                        : "Stop adhan using volume buttons or flipping phone",
                  ),
                  trailing: SettingsValueChip<String>(
                    value: _athanStopGesture,
                    label: isAr ? 'طريقة إيقاف الأذان' : 'Adhan Stop Gesture',
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
              ],
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
        child: Material(
          color: Colors.transparent,
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
      ];
  }
}
