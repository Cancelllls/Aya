import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'translation_service.dart';
import 'quran_verses.dart';
import 'adhan_audio_service.dart';
import 'database_service.dart';
import '../core/adhan_native_controller.dart';
import 'offline_prayer_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (notificationResponse.actionId == 'action_prayed' ||
      notificationResponse.actionId == 'action_missed') {
    final payload = notificationResponse.payload;
    if (payload != null && payload.startsWith('tracker:')) {
      final parts = payload.split(':');
      if (parts.length >= 3) {
        try {
          final dateStr = parts[1];
          final prayerKey = parts[2];
          final db = await DatabaseService.getInstance();
          await db.updatePrayerTracker(
            dateStr,
            prayerKey,
            notificationResponse.actionId == 'action_prayed' ? 1 : 0,
          );
        } catch (e) {
          // Ignore
        }
      }
    }
    // Force cancel the notification
    if (notificationResponse.id != null) {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(id: notificationResponse.id!);
    }
  } else if (notificationResponse.actionId == 'action_stop_adhan') {
    try {
      const MethodChannel('com.quran.aya/system').invokeMethod('stopAdhan');
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void backgroundPrayerTimesUpdateCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await StorageService.getInstance();
    final loc = storage.getLocation();
    if (loc['source'] == 'gps') {
      try {
        Position? position = await ApiService.getBestLocation();
        double lat;
        double lng;
        String city;
        String country;

        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
          final cityCountry = await ApiService.reverseGeocode(lat, lng);
          city = cityCountry['city'] ?? 'My Location';
          country = cityCountry['country'] ?? 'GPS';
        } else {
          throw Exception('GPS position unavailable');
        }

        await storage.setLocation(city, country, lat, lng, 'gps');
        final method = storage.getInt('calc_method', defaultValue: 2);
        final school = storage.getInt('asr_method', defaultValue: 0);
        final prayerData = await ApiService.fetchPrayerTimes(
          latitude: lat,
          longitude: lng,
          method: method,
          school: school,
        );
        await NotificationService().schedulePrayerAlarms(prayerData, storage);
      } catch (e) {
        // Fallback to offline prayer times when in deep Doze mode or network fails
        double lat = loc['latitude'] as double? ?? 0.0;
        double lng = loc['longitude'] as double? ?? 0.0;
        if (lat != 0.0 && lng != 0.0) {
          final method = storage.getInt('calc_method', defaultValue: 2);
          final school = storage.getInt('asr_method', defaultValue: 0);
          final offlineData = await OfflinePrayerService.getPrayerTimes(
            latitude: lat,
            longitude: lng,
            method: method,
            school: school,
          );
          await NotificationService().schedulePrayerAlarms(
            offlineData,
            storage,
          );
        }
      }
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error in background location prayer times update callback: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const List<int> islamicVibrationPattern = [
    0,
    300,
    150,
    300,
    150,
    200,
    150,
    300,
    150,
    300,
    150,
    200,
    150,
    300,
    150,
    300,
    150,
    200,
  ];

  static const List<int> islamicVibrationAmplitudes = [
    0,
    200,
    0,
    200,
    0,
    100,
    0,
    200,
    0,
    200,
    0,
    100,
    0,
    200,
    0,
    200,
    0,
    100,
  ];

  static void stopActiveAthan() {
    try {
      const MethodChannel('com.quran.aya/system').invokeMethod('stopAdhan');
    } catch (_) {}
  }

  Future<void> scheduleHijriEventReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'hijri_reminders',
      'Hijri Event Reminders',
      channelDescription: 'Reminders for special Islamic Hijri events',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'prayer_times',
      );
    } catch (_) {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'prayer_times',
      );
    }
  }

  static bool timezoneFallbackToUtc = false;
  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      // ponytail: YAGNI external dependency for this simple string check
      final String timeZoneName =
          await const MethodChannel(
            'com.quran.aya/system',
          ).invokeMethod<String>('getTimeZoneName') ??
          'UTC';
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      timezoneFallbackToUtc = true;
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Pre-create all notification channels so they exist before any use
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Adhan channel is created natively in AdhanBroadcastReceiver (v4).
      // Pre-adhan / tracker / ramadan channels created here.
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'pre_adhan_native_v3',
          'Pre-Athan Alerts',
          description: 'Reminders before prayer time',
          importance: Importance.max,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      // Exact alarm permission warning channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'exact_alarm_warning',
          'Permission Required',
          description: 'Alerts when exact alarm permission is missing',
          importance: Importance.high,
        ),
      );
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'action_stop_adhan') {
          stopActiveAthan();
          return;
        }
        if (response.actionId == 'action_prayed' ||
            response.actionId == 'action_missed') {
          final payload = response.payload;
          if (payload != null && payload.startsWith('tracker:')) {
            final parts = payload.split(':');
            if (parts.length >= 3) {
              try {
                final dateStr = parts[1];
                final prayerKey = parts[2];
                final db = await DatabaseService.getInstance();
                await db.updatePrayerTracker(
                  dateStr,
                  prayerKey,
                  response.actionId == 'action_prayed' ? 1 : 0,
                );
              } catch (e) {
                // Ignore
              }
            }
          }
          if (response.id != null) {
            await _notificationsPlugin.cancel(id: response.id!);
          }
        }
        selectNotificationStream.add(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    try {
      final storage = await StorageService.getInstance();
      await scheduleDailyReminders(storage);
    } catch (_) {}
  }

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      try {
        final bool? enabled = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
        return enabled ?? false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<bool> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? androidGranted = await androidImplementation
        ?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final bool? iosGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  /// Check whether the device can schedule exact alarms (Android 12+).
  /// Returns true if granted or on a platform where it isn't required.
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      const platform = MethodChannel('com.quran.aya/system');
      return await platform.invokeMethod<bool>('checkExactAlarmPermission') ??
          false;
    } catch (_) {
      return true; // Don't block scheduling on check failure
    }
  }

  /// Show a system notification telling the user to grant exact alarm
  /// permission (mirrors Five Prayers' CannotScheduleExactAlarmNotification).
  static Future<void> _warnMissingExactAlarmPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        'exact_alarm_warning',
        'Permission Required',
        channelDescription: 'Alerts when exact alarm permission is missing',
        importance: Importance.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await plugin.zonedSchedule(
        id: 9001,
        title: TranslationService.isArabic
            ? 'مطلوب إذن المنبهات الدقيقة'
            : 'Exact Alarm Permission Required',
        body: TranslationService.isArabic
            ? 'بدون هذا الإذن، لن يتم تشغيل الأذان في موعده. امنحه من الإعدادات.'
            : 'Without this permission, Adhan will not play. Grant it in Settings.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(
          const Duration(seconds: 2),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> schedulePrayerAlarms(
    PrayerTimeData prayerData,
    StorageService storage,
  ) async {
    // Validate prayer data
    final isValid =
        prayerData.fajr.isNotEmpty &&
        prayerData.dhuhr.isNotEmpty &&
        prayerData.asr.isNotEmpty &&
        prayerData.maghrib.isNotEmpty &&
        prayerData.isha.isNotEmpty;
    if (!isValid) return;

    // Guard: all prayer-critical notifications (adhan, pre-adhan, tracker,
    // ramadan, islamic events) use exact alarms. Skip everything and warn
    // once if the permission is missing (mirrors Five Prayers).
    final canSchedule = await canScheduleExactAlarms();
    if (!canSchedule) {
      await _warnMissingExactAlarmPermission();
      return;
    }

    // Cancel all existing prayer notifications
    final List<Future<void>> cancelFutures = [];
    for (int i = 1; i <= 70; i++) {
      cancelFutures.add(_notificationsPlugin.cancel(id: i));
      cancelFutures.add(_notificationsPlugin.cancel(id: i + 2000));
      cancelFutures.add(_notificationsPlugin.cancel(id: i + 5000));
    }
    await Future.wait(cancelFutures);

    final alertFajr = storage.getBool('alert_fajr', defaultValue: true);
    final alertDhuhr = storage.getBool('alert_dhuhr', defaultValue: true);
    final alertAsr = storage.getBool('alert_asr', defaultValue: true);
    final alertMaghrib = storage.getBool('alert_maghrib', defaultValue: true);
    final alertIsha = storage.getBool('alert_isha', defaultValue: true);

    final prayersToSchedule = <String, String>{};
    if (alertFajr && prayerData.fajr.isNotEmpty) {
      prayersToSchedule['Fajr'] = prayerData.fajr;
    }
    if (alertDhuhr && prayerData.dhuhr.isNotEmpty) {
      prayersToSchedule['Dhuhr'] = prayerData.dhuhr;
    }
    if (alertAsr && prayerData.asr.isNotEmpty) {
      prayersToSchedule['Asr'] = prayerData.asr;
    }
    if (alertMaghrib && prayerData.maghrib.isNotEmpty) {
      prayersToSchedule['Maghrib'] = prayerData.maghrib;
    }
    if (alertIsha && prayerData.isha.isNotEmpty) {
      prayersToSchedule['Isha'] = prayerData.isha;
    }

    final now = DateTime.now();

    // Adhan notification details — sound played by Android OS via notification channel
    // This is exactly how FivePrayers does it: the notification itself carries the sound
    final adhanMode = storage.getString(
      'adhan_alert_mode',
      defaultValue: 'real_reciter',
    );
    final adhanReciter = storage.getString(
      'adhan_reciter',
      defaultValue: 'mishary',
    );
    final fajrReciter = storage.getString(
      'fajr_adhan_reciter',
      defaultValue: 'mishary',
    );

    String _getAdhanSound(String prayerName) {
      if (adhanMode == 'silent' || adhanMode == 'vibrate') return '';
      final isFajr = prayerName == 'Fajr' || prayerName == 'fajr';
      final reciter = isFajr ? fajrReciter : adhanReciter;
      final filename = isFajr
          ? AdhanAudioService.fajrReciterUrls[reciter]
          : AdhanAudioService.standardReciterUrls[reciter];
      if (filename == null) return 'default_adhan';
      return filename.replaceAll('.mp3', '');
    }

    int id = 1;

    for (final entry in prayersToSchedule.entries) {
      final name = entry.key;
      final timeStr = entry.value.trim().split(' ')[0];
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final isAr = TranslationService.isArabic;
      final localizedName = isAr ? _arabicPrayerName(name) : name;

      final int preAdhanMins = storage.getInt(
        'pre_adhan_duration',
        defaultValue: 10,
      );
      final String preAdhanAlertMode = storage.getString(
        'pre_adhan_alert_mode',
        defaultValue: 'vibrate',
      );

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(Duration(days: dayOffset));

        if (!scheduledDate.isAfter(now)) continue;

        final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
        final notificationId = id + (dayOffset * 10);

        // === ADHAN — native AlarmManager → MediaPlayer + silent notification ===
        // (Five-Prayers model: notification is just a card, audio is separate)
        if (adhanMode != 'off') {
          try {
            await AdhanNativeController.instance.schedulePrayerAlarm(
              id: notificationId,
              time: scheduledDate,
              mp3ResName: _getAdhanSound(name),
              prayerName: isAr
                  ? 'حان الآن موعد صلاة $localizedName'
                  : 'Time for $localizedName prayer',
              enableVibration: adhanMode != 'silent',
            );
          } catch (_) {}
        }

        // === PRE-ADHAN NOTIFICATION ===
        if (preAdhanMins > 0 && preAdhanAlertMode != 'off') {
          final preAzanTime = scheduledDate.subtract(
            Duration(minutes: preAdhanMins),
          );
          if (preAzanTime.isAfter(now)) {
            final tzPreDateTime = tz.TZDateTime.from(preAzanTime, tz.local);
            final preNotificationId = notificationId + 2000;

            final preAndroidDetails = AndroidNotificationDetails(
              'pre_adhan_native_v3',
              'Pre-Athan Alerts',
              channelDescription: 'Reminders before prayer time',
              importance: Importance.max,
              priority: Priority.high,
              playSound:
                  preAdhanAlertMode != 'silent' &&
                  preAdhanAlertMode != 'vibrate',
              sound:
                  (preAdhanAlertMode != 'silent' &&
                      preAdhanAlertMode != 'vibrate')
                  ? const RawResourceAndroidNotificationSound(
                      'default_pre_adhan',
                    )
                  : null,
              enableVibration: preAdhanAlertMode != 'silent',
              vibrationPattern: preAdhanAlertMode != 'silent'
                  ? Int64List.fromList([0, 500, 200, 500, 200, 200])
                  : null,
              icon: 'ic_notification',
              color: const Color(0xFF0F766E),
              visibility: NotificationVisibility.public,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            );

            final preDetails = NotificationDetails(
              android: preAndroidDetails,
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentSound: true,
              ),
            );

            try {
              await _notificationsPlugin.zonedSchedule(
                id: preNotificationId,
                title: isAr ? 'اقترب موعد الأذان' : 'Athan is approaching',
                body: isAr
                    ? 'بقي $preAdhanMins دقائق على أذان الـ $localizedName.'
                    : '$preAdhanMins minutes remaining until $localizedName Athan.',
                scheduledDate: tzPreDateTime,
                notificationDetails: preDetails,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                payload: 'prayer_times',
              );
            } catch (_) {
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: preNotificationId,
                  title: isAr ? 'اقترب موعد الأذان' : 'Athan is approaching',
                  body: isAr
                      ? 'بقي $preAdhanMins دقائق على أذان الـ $localizedName.'
                      : '$preAdhanMins minutes remaining until $localizedName Athan.',
                  scheduledDate: tzPreDateTime,
                  notificationDetails: preDetails,
                  androidScheduleMode:
                      AndroidScheduleMode.inexactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              } catch (_) {}
            }
          }
        }

        // === RAMADAN: IMSAK & IFTAR ===
        final hijriMonth = int.tryParse(prayerData.hijriMonth) ?? 0;
        if (hijriMonth == 9) {
          final imsakEnabled = storage.getBool('ramadan_imsak_enabled', defaultValue: true);
          final imsakOffset = storage.getInt('ramadan_imsak_offset', defaultValue: 0);
          final iftarEnabled = storage.getBool('ramadan_iftar_enabled', defaultValue: true);

          if (imsakEnabled && adhanMode != 'off') {
            final imsakTime = scheduledDate.subtract(Duration(minutes: imsakOffset));
            if (imsakTime.isAfter(now)) {
              final tzImsakTime = tz.TZDateTime.from(imsakTime, tz.local);
              final imsakSoundName = _getAdhanSound(name);
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: notificationId + 7000,
                  title: isAr ? 'سحور / إمساك' : 'Suhoor / Imsak',
                  body: isAr ? 'حان وقت الإمساك عن الطعام.' : 'Time to stop eating for the fast.',
                  scheduledDate: tzImsakTime,
                  notificationDetails: NotificationDetails(
                    android: AndroidNotificationDetails(
                      'ramadan_imsak',
                      'Ramadan Imsak',
                      channelDescription: 'Imsak (Suhoor) alerts during Ramadan',
                      importance: Importance.max,
                      priority: Priority.high,
                      playSound: imsakSoundName.isNotEmpty,
                      sound: imsakSoundName.isNotEmpty
                          ? RawResourceAndroidNotificationSound(imsakSoundName)
                          : null,
                      enableVibration: true,
                      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 200]),
                      icon: 'ic_notification',
                      color: const Color(0xFF0F766E),
                      audioAttributesUsage: AudioAttributesUsage.alarm,
                    ),
                  ),
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              } catch (_) {}
            }
          }

          if (iftarEnabled && adhanMode != 'off' && name == 'Maghrib') {
            if (scheduledDate.isAfter(now)) {
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: notificationId + 8000,
                  title: isAr ? 'إفطار' : 'Iftar',
                  body: isAr ? 'حان وقت الإفطار، اللهم لك صمت وعلى رزقك أفطرت.' : 'Time to break your fast. O Allah, for You I fasted and with Your provision I break my fast.',
                  scheduledDate: tzDateTime,
                  notificationDetails: NotificationDetails(
                    android: AndroidNotificationDetails(
                      'ramadan_iftar',
                      'Ramadan Iftar',
                      channelDescription: 'Iftar (breaking fast) alerts during Ramadan',
                      importance: Importance.max,
                      priority: Priority.high,
                      playSound: adhanMode != 'silent' && adhanMode != 'vibrate',
                      sound: (adhanMode != 'silent' && adhanMode != 'vibrate')
                          ? const RawResourceAndroidNotificationSound('prayer_reminder_call')
                          : null,
                      enableVibration: true,
                      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 200]),
                      icon: 'ic_notification',
                      color: const Color(0xFF0F766E),
                      audioAttributesUsage: AudioAttributesUsage.alarm,
                    ),
                  ),
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              } catch (_) {}
            }
          }
        }

        // === ISLAMIC EVENTS REMINDERS ===
        if (name == 'Fajr' && dayOffset == 0) {
          _scheduleIslamicEvents(storage, now, isAr);
        }

        // === PRAYER TRACKER REMINDER (15 mins before next prayer) ===
        final prevPrayerKeys = {
          'Fajr': 'isha',
          'Dhuhr': 'fajr',
          'Asr': 'dhuhr',
          'Maghrib': 'asr',
          'Isha': 'maghrib',
        };

        final prevPrayerKey = prevPrayerKeys[name];
        if (prevPrayerKey != null) {
          final trackerTime = scheduledDate.subtract(
            const Duration(minutes: 15),
          );
          if (trackerTime.isAfter(now)) {
            final tzTrackerTime = tz.TZDateTime.from(trackerTime, tz.local);
            final trackerNotificationId = notificationId + 5000;

            final prevPrayerNameAr = _arabicPrayerName(prevPrayerKey);
            final prevPrayerNameEn =
                prevPrayerKey[0].toUpperCase() + prevPrayerKey.substring(1);
            final prevPrayerName = isAr ? prevPrayerNameAr : prevPrayerNameEn;

            final targetDateForTracker = name == 'Fajr'
                ? scheduledDate.subtract(const Duration(days: 1))
                : scheduledDate;
            final dateStr = DateFormat(
              'yyyy-MM-dd',
            ).format(targetDateForTracker);

            final trackerDetails = NotificationDetails(
              android: AndroidNotificationDetails(
                'tracker_channel',
                'Prayer Tracker',
                channelDescription: 'Reminders to log your prayers',
                importance: Importance.high,
                priority: Priority.high,
                actions: [
                  AndroidNotificationAction(
                    'action_prayed',
                    isAr ? 'صُليت' : 'Prayed',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    'action_missed',
                    isAr ? 'فائتة' : 'Missed',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                ],
              ),
            );

            try {
              await _notificationsPlugin.zonedSchedule(
                id: trackerNotificationId,
                title: isAr
                    ? 'هل صليت $prevPrayerName اليوم؟'
                    : 'Did you pray $prevPrayerName today?',
                body: isAr ? 'سجل صلاتك الآن.' : 'Log your prayer now.',
                scheduledDate: tzTrackerTime,
                notificationDetails: trackerDetails,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                payload: 'tracker:$dateStr:$prevPrayerKey',
              );
            } catch (_) {}
          }
        }
      }
      id++;
    }
  }

  String _arabicPrayerName(String englishName) {
    switch (englishName.toLowerCase()) {
      case 'fajr':
        return 'الفجر';
      case 'sunrise':
        return 'الشروق';
      case 'dhuhr':
        return 'الظهر';
      case 'asr':
        return 'العصر';
      case 'maghrib':
        return 'المغرب';
      case 'isha':
        return 'العشاء';
      default:
        return englishName;
    }
  }

  Future<void> scheduleDailyReminders(StorageService storage) async {
    // Cancel previous notifications
    await _notificationsPlugin.cancel(id: 3000); // Morning Azkar
    await _notificationsPlugin.cancel(id: 3001); // Evening Azkar
    for (int i = 0; i < 7; i++) {
      await _notificationsPlugin.cancel(
        id: 3002 + i,
      ); // Today's Verse (next 7 days)
    }

    final now = DateTime.now();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminders_channel_id',
          'Daily Reminders',
          channelDescription:
              'Notifications for daily Azkar and verse reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: 'ic_notification',
          color: Color(0xFF0F766E),
          styleInformation: BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 1. Morning Azkar — scheduled after Fajr
    if (storage.getBool('morning_azkar_reminder', defaultValue: true)) {
      final fajrStr = storage.getString('widget_prayer_fajr');
      DateTime scheduledTime;
      if (fajrStr.isNotEmpty) {
        final parts = fajrStr.split(' ')[0].split(':');
        final h = int.tryParse(parts[0]) ?? 7;
        final m = int.tryParse(parts[1]) ?? 0;
        scheduledTime = DateTime(now.year, now.month, now.day, h, m).add(
          const Duration(minutes: 15),
        ); // 15 min after Fajr
      } else {
        scheduledTime = DateTime(now.year, now.month, now.day, 7, 0);
      }
      final tzDateTime = _nextOccurrence(scheduledTime);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: 3000,
          title: TranslationService.isArabic
              ? 'أذكار الصباح ☀️'
              : 'Morning Azkar ☀️',
          body: TranslationService.isArabic
              ? 'اقرأ أذكار الصباح لتبدأ يومك ببركة وحفظ.'
              : 'Read your morning Adhkar to start your day with blessing.',
          scheduledDate: tzDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'azkar_morning',
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          id: 3000,
          title: TranslationService.isArabic
              ? 'أذكار الصباح ☀️'
              : 'Morning Azkar ☀️',
          body: TranslationService.isArabic
              ? 'اقرأ أذكار الصباح لتبدأ يومك ببركة وحفظ.'
              : 'Read your morning Adhkar to start your day with blessing.',
          scheduledDate: tzDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'azkar_morning',
        );
      }
    }

    // 2. Evening Azkar — scheduled after Maghrib
    if (storage.getBool('evening_azkar_reminder', defaultValue: true)) {
      final maghribStr = storage.getString('widget_prayer_maghrib');
      DateTime scheduledTime;
      if (maghribStr.isNotEmpty) {
        final parts = maghribStr.split(' ')[0].split(':');
        final h = int.tryParse(parts[0]) ?? 17;
        final m = int.tryParse(parts[1]) ?? 0;
        scheduledTime = DateTime(now.year, now.month, now.day, h, m).add(
          const Duration(minutes: 15),
        ); // 15 min after Maghrib
      } else {
        scheduledTime = DateTime(now.year, now.month, now.day, 17, 0);
      }
      final tzDateTime = _nextOccurrence(scheduledTime);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: 3001,
          title: TranslationService.isArabic
              ? 'أذكار المساء 🌙'
              : 'Evening Azkar 🌙',
          body: TranslationService.isArabic
              ? 'حان وقت أذكار المساء لطمأنينة وحفظ.'
              : 'It is time for evening Adhkar for peace and protection.',
          scheduledDate: tzDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'azkar_evening',
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          id: 3001,
          title: TranslationService.isArabic
              ? 'أذكار المساء 🌙'
              : 'Evening Azkar 🌙',
          body: TranslationService.isArabic
              ? 'حان وقت أذكار المساء لطمأنينة وحفظ.'
              : 'It is time for evening Adhkar for peace and protection.',
          scheduledDate: tzDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'azkar_evening',
        );
      }
    }

    // 3. Today's Verse Reminder
    if (storage.getBool('todays_verse_reminder', defaultValue: true)) {
      final isArabic = TranslationService.isArabic;
      for (int i = 0; i < 7; i++) {
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          9,
          0,
        ).add(Duration(days: i)); // 9:00 AM
        if (scheduledTime.isBefore(now)) continue;
        final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

        final index = (now.day + i) % QuranVersesData.verses.length;
        final verseObj = QuranVersesData.verses[index];
        final verseBody = verseObj.getDisplayString(isArabic);

        final AndroidNotificationDetails verseAndroidDetails =
            AndroidNotificationDetails(
              'daily_verse_channel_id',
              'Daily Verse',
              channelDescription: 'Notifications for daily Quranic verses',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              icon: 'ic_notification',
              color: const Color(0xFF0F766E),
              styleInformation: BigTextStyleInformation(
                verseBody,
                contentTitle: isArabic ? 'آية اليوم 📖' : "Today's Verse 📖",
                summaryText: isArabic ? 'آية اليوم' : "Today's Verse",
              ),
            );

        final NotificationDetails verseNotificationDetails =
            NotificationDetails(android: verseAndroidDetails, iOS: iosDetails);

        final versePayload =
            'quran_verse:${verseObj.surahNumber}:${verseObj.ayahNumber}';
        try {
          await _notificationsPlugin.zonedSchedule(
            id: 3002 + i,
            title: isArabic ? 'آية اليوم 📖' : "Today's Verse 📖",
            body: verseBody,
            scheduledDate: tzDateTime,
            notificationDetails: verseNotificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: versePayload,
          );
        } catch (_) {
          await _notificationsPlugin.zonedSchedule(
            id: 3002 + i,
            title: isArabic ? 'آية اليوم 📖' : "Today's Verse 📖",
            body: verseBody,
            scheduledDate: tzDateTime,
            notificationDetails: verseNotificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: versePayload,
          );
        }
      }
    }
  }

  void _scheduleIslamicEvents(StorageService storage, DateTime now, bool isAr) {
    if (!storage.getBool('islamic_events_enabled', defaultValue: true)) return;

    // Islamic events mapped to approximate Gregorian dates for 1448 AH (2026-2027)
    // These shift ~10-11 days earlier each Gregorian year — update annually.
    final events = <MapEntry<String, DateTime>>[
      MapEntry(isAr ? 'رأس السنة الهجرية ١٤٤٨' : 'Islamic New Year 1448', DateTime(2026, 7, 26)),
      MapEntry(isAr ? 'عاشوراء' : 'Ashura', DateTime(2026, 8, 4)),
      MapEntry(isAr ? 'الإسراء والمعراج' : 'Isra & Miraj', DateTime(2027, 1, 19)),
      MapEntry(isAr ? 'ليلة النصف من شعبان' : "Nisf Sha'ban", DateTime(2027, 3, 7)),
      MapEntry(isAr ? 'ليلة القدر' : 'Laylatul Qadr', DateTime(2027, 4, 21)),
      MapEntry(isAr ? 'عيد الفطر' : 'Eid al-Fitr', DateTime(2027, 4, 22)),
      MapEntry(isAr ? 'يوم عرفة' : 'Day of Arafah', DateTime(2027, 6, 26)),
      MapEntry(isAr ? 'عيد الأضحى' : 'Eid al-Adha', DateTime(2027, 6, 27)),
    ];

    int eventId = 9000;
    for (final entry in events) {
      if (entry.value.isBefore(now)) continue;
      final tzEventTime = tz.TZDateTime.from(
        DateTime(entry.value.year, entry.value.month, entry.value.day, 9, 0),
        tz.local,
      );
      try {
        _notificationsPlugin.zonedSchedule(
          id: eventId,
          title: entry.key,
          body: isAr ? 'ذكرى إسلامية مباركة' : 'Blessed Islamic occasion',
          scheduledDate: tzEventTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'islamic_events',
              'Islamic Events',
              channelDescription: 'Reminders for Islamic holidays and events',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'ic_notification',
              color: Color(0xFF0F766E),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'islamic_event',
        );
      } catch (_) {}
      eventId++;
    }
  }

  tz.TZDateTime _nextOccurrence(DateTime dt) {
    final now = DateTime.now();
    var scheduled = dt;
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }
}
