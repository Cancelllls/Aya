part of 'settings_screen.dart';

extension SettingsNotificationsSection on _SettingsScreenState {
  List<Widget> _buildNotificationsSection(ThemeData theme) {
    return [
      // Section Notifications & Alerts
      _buildSectionHeader(
        TranslationService.isArabic
            ? "الإشعارات والتنبيهات"
            : "Notifications & Alerts",
      ),
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
                ListTile(
                  title: Text(
                    TranslationService.isArabic
                        ? "وقت التنبيه قبل الأذان"
                        : "Pre-Athan Alert Time",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "اختر وقت التنبيه بالدقائق قبل الأذان"
                        : "Choose alert timing in minutes before Athan",
                  ),
                  trailing: SizedBox(
                    width: 160,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _preAdhanDuration,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [0, 5, 10, 15, 20].map((mins) {
                        return DropdownMenuItem<int>(
                          value: mins,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              mins == 0
                                  ? (TranslationService.isArabic
                                        ? "إيقاف"
                                        : "Off")
                                  : (TranslationService.isArabic
                                        ? "$mins دقائق"
                                        : "$mins Mins"),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _changePreAdhanDuration,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                if (_preAdhanDuration > 0)
                  ListTile(
                    title: Text(
                      TranslationService.isArabic
                          ? "نمط تنبيه قبل الأذان"
                          : "Pre-Athan Alert Style",
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _preAdhanAlertMode,
                        underline: const SizedBox(),
                        dropdownColor: theme.cardColor,
                        items: [
                          DropdownMenuItem(
                            value: 'off',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic ? "إيقاف" : "Off",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'silent',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic ? "صامت" : "Silent",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'vibrate',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "اهتزاز فقط"
                                    : "Vibrate Only",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'voice',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "تنبيه صوتي"
                                    : "Voice Announcement",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'vibrate_and_voice',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "اهتزاز + تنبيه صوتي"
                                    : "Vibrate + Voice",
                              ),
                            ),
                          ),
                        ],
                        onChanged: _changePreAdhanAlertMode,
                      ),
                    ),
                  ),

                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                if (_preAdhanDuration > 0)
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ListTile(
                  title: Text(
                    TranslationService.isArabic
                        ? "نوع تنبيه الأذان"
                        : "Athan Alert Style",
                  ),
                  subtitle: Text(
                    TranslationService.isArabic
                        ? "التنبيه عند دخول وقت الصلاة"
                        : "Alert when prayer time starts",
                  ),
                  trailing: SizedBox(
                    width: 160,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _adhanAlertMode,
                      underline: const SizedBox(),
                      dropdownColor: theme.cardColor,
                      items: [
                        DropdownMenuItem(
                          value: 'off',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic ? "إيقاف" : "Off",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'silent',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic ? "صامت" : "Silent",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'vibrate',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "اهتزاز"
                                  : "Vibrate",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'real_reciter',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "أذان بصوت المؤذن"
                                  : "Real Reciter Adhan",
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'vibrate_and_voice',
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              TranslationService.isArabic
                                  ? "اهتزاز + صوت المؤذن"
                                  : "Vibrate + Reciter Voice",
                            ),
                          ),
                        ),
                      ],
                      onChanged: _changeAdhanAlertMode,
                    ),
                  ),
                ),
                if (_adhanAlertMode == 'real_reciter' ||
                    _adhanAlertMode == 'vibrate_and_voice') ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    title: Text(
                      TranslationService.isArabic ? "المؤذن" : "Athan Reciter",
                    ),
                    subtitle: Text(
                      TranslationService.isArabic
                          ? "اختر صوت المؤذن للأذان"
                          : "Select voice for the Athan",
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _adhanReciter,
                        underline: const SizedBox(),
                        dropdownColor: theme.cardColor,
                        items: [
                          DropdownMenuItem(
                            value: 'mishary',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "مشاري العفاسي"
                                    : "Mishary Alafasy",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'abdul_basit',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "عبد الباسط عبد الصمد"
                                    : "Abdul Basit",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'madinah',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "أذان الحرم المدني"
                                    : "Al Haram Al Madani",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'kazabri',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "عمر القزابري"
                                    : "Omar Al Kazabri",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'riad',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "رياض الجزائري"
                                    : "Riad Al Djazairi",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'manssour',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "منصور الزهراني"
                                    : "Manssour El Zahrani",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'nakshabandi',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "سيد النقشبندي"
                                    : "Sayed Al Nakshabandi",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'maghriby',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "نور الدين المغربي"
                                    : "Nurdin Al Maghriby",
                              ),
                            ),
                          ),
                        ],
                        onChanged: _changeAdhanReciter,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    title: Text(
                      TranslationService.isArabic
                          ? "إيماءة إيقاف الأذان"
                          : "Athan Stop Gesture",
                    ),
                    subtitle: Text(
                      TranslationService.isArabic
                          ? "إيقاف الأذان بالضغط على أزرار الصوت أو قلب الهاتف وجهه لأسفل"
                          : "Stop Athan by pressing volume buttons or flipping the phone face down",
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _athanStopGesture,
                        underline: const SizedBox(),
                        dropdownColor: theme.cardColor,
                        items: [
                          DropdownMenuItem(
                            value: 'both',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "أزرار الصوت وقلب الهاتف"
                                    : "Volume keys & Flip",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'volume_only',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "أزرار الصوت فقط"
                                    : "Volume keys only",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'flip_only',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "قلب الهاتف فقط"
                                    : "Flip phone only",
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'none',
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                TranslationService.isArabic
                                    ? "لا توقف"
                                    : "Don't stop",
                              ),
                            ),
                          ),
                        ],
                        onChanged: _changeAthanStopGesture,
                      ),
                    ),
                  ),
                ],
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: Text(TranslationService.t('morning_azkar_reminder')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _morningAzkarReminder,
                  onChanged: (val) => _toggleDailyReminder(
                    'morning_azkar_reminder',
                    val,
                    (v) => _morningAzkarReminder = v,
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: Text(TranslationService.t('evening_azkar_reminder')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _eveningAzkarReminder,
                  onChanged: (val) => _toggleDailyReminder(
                    'evening_azkar_reminder',
                    val,
                    (v) => _eveningAzkarReminder = v,
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: Text(TranslationService.t('todays_verse_reminder')),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _todaysVerseReminder,
                  onChanged: (val) => _toggleDailyReminder(
                    'todays_verse_reminder',
                    val,
                    (v) => _todaysVerseReminder = v,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      // ── Ramadan Section ──
      _buildSectionHeader(
        TranslationService.isArabic ? "رمضان" : "Ramadan",
      ),
      Card(
        color: theme.cardColor.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "تنبيه الإمساك (السحور)" : "Imsak Alarm (Suhoor)"),
                  subtitle: Text(TranslationService.isArabic ? "تنبيه عند وقت الإمساك في رمضان" : "Alert at Imsak time during Ramadan"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _ramadanImsakEnabled,
                  onChanged: (val) {
                    setState(() => _ramadanImsakEnabled = val);
                    widget.storage.setBool('ramadan_imsak_enabled', val);
                    _debouncedReschedule();
                  },
                ),
                if (_ramadanImsakEnabled)
                  ListTile(
                    title: Text(TranslationService.isArabic ? "وقت التنبيه قبل الإمساك" : "Imsak Alert Offset"),
                    trailing: SizedBox(
                      width: 160,
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _ramadanImsakOffset,
                        underline: const SizedBox(),
                        dropdownColor: theme.cardColor,
                        items: [0, 5, 10, 15].map((mins) {
                          return DropdownMenuItem<int>(
                            value: mins,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(mins == 0
                                  ? (TranslationService.isArabic ? "وقت الفجر" : "At Fajr")
                                  : (TranslationService.isArabic ? "قبل الفجر بـ $mins د" : "$mins min before Fajr")),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _ramadanImsakOffset = val);
                            widget.storage.setInt('ramadan_imsak_offset', val);
                            _debouncedReschedule();
                          }
                        },
                      ),
                    ),
                  ),
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                SwitchListTile(
                  title: Text(TranslationService.isArabic ? "تنبيه الإفطار" : "Iftar Reminder"),
                  subtitle: Text(TranslationService.isArabic ? "تنبيه عند أذان المغرب في رمضان" : "Alert at Maghrib during Ramadan"),
                  activeThumbColor: const Color(0xFFE5C158),
                  value: _ramadanIftarEnabled,
                  onChanged: (val) {
                    setState(() => _ramadanIftarEnabled = val);
                    widget.storage.setBool('ramadan_iftar_enabled', val);
                    _debouncedReschedule();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      // ── Islamic Events ──
      _buildSectionHeader(
        TranslationService.isArabic ? "المناسبات الإسلامية" : "Islamic Events",
      ),
      Card(
        color: theme.cardColor.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: SwitchListTile(
              title: Text(TranslationService.isArabic ? "تذكير بالمناسبات" : "Event Reminders"),
              subtitle: Text(TranslationService.isArabic
                  ? "عيد الفطر، عيد الأضحى، عاشوراء، ليلة القدر وغيرها"
                  : "Eid, Ashura, Laylatul Qadr, Arafah and more"),
              activeThumbColor: const Color(0xFFE5C158),
              value: _islamicEventsEnabled,
              onChanged: (val) {
                setState(() => _islamicEventsEnabled = val);
                widget.storage.setBool('islamic_events_enabled', val);
                _debouncedReschedule();
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }
}
