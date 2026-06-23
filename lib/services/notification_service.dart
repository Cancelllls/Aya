import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'translation_service.dart';
import 'quran_verses.dart';

@pragma('vm:entry-point')
void backgroundPrayerTimesUpdateCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await StorageService.getInstance();
    final loc = storage.getLocation();
    if (loc['source'] == 'gps') {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final double lat = position.latitude;
      final double lng = position.longitude;
      final cityCountry = await ApiService.reverseGeocode(lat, lng);
      final String city = cityCountry['city'] ?? 'My Location';
      final String country = cityCountry['country'] ?? 'GPS';
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
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error in background location prayer times update callback: $e');
  }
}

@pragma('vm:entry-point')
void backgroundPreAdhanCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await StorageService.getInstance();
    final alertMode = storage.getString('pre_adhan_alert_mode', defaultValue: 'vibrate');
    const platform = MethodChannel('com.noor.noor_app/system');
    
    if (alertMode == 'vibrate') {
      await platform.invokeMethod('vibrate', {
        'pattern': [0, 200, 200, 500, 200, 1000]
      });
    } else if (alertMode == 'voice') {
      await platform.invokeMethod('speak', {
        'text': TranslationService.isArabic ? 'اقترب موعد الأذان' : 'Adhan is approaching',
        'lang': TranslationService.currentLanguage
      });
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error in backgroundPreAdhanCallback: $e');
  }
}

@pragma('vm:entry-point')
void backgroundAdhanCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await StorageService.getInstance();
    final adhanMode = storage.getString('adhan_alert_mode', defaultValue: 'real_reciter');
    const platform = MethodChannel('com.noor.noor_app/system');
    
    if (adhanMode == 'vibrate') {
      await platform.invokeMethod('vibrate', {
        'pattern': [0, 200, 200, 500, 200, 1000]
      });
    } else if (adhanMode == 'real_reciter') {
      final reciter = storage.getString('adhan_reciter', defaultValue: 'mishary');
      final prayerIndex = (id - 4000) % 10;
      final isFajr = prayerIndex == 1;
      
      String url = '';
      if (isFajr) {
        switch (reciter) {
          case 'mishary':
            url = 'https://www.islamcan.com/adhan/audio/fajr-azan-mishary.mp3';
            break;
          case 'abdul_basit':
            url = 'https://www.islamcan.com/adhan/audio/azan3.mp3';
            break;
          case 'makkah':
            url = 'https://www.islamcan.com/adhan/audio/azan2.mp3';
            break;
          case 'madinah':
            url = 'https://www.islamcan.com/adhan/audio/azan19.mp3';
            break;
          default:
            url = 'https://www.islamcan.com/adhan/audio/fajr-azan-mishary.mp3';
        }
      } else {
        switch (reciter) {
          case 'mishary':
            url = 'https://www.islamcan.com/adhan/audio/azan1.mp3';
            break;
          case 'abdul_basit':
            url = 'https://www.islamcan.com/adhan/audio/azan3.mp3';
            break;
          case 'makkah':
            url = 'https://www.islamcan.com/adhan/audio/azan20.mp3';
            break;
          case 'madinah':
            url = 'https://www.islamcan.com/adhan/audio/azan19.mp3';
            break;
          default:
            url = 'https://www.islamcan.com/adhan/audio/azan1.mp3';
        }
      }
      
      final player = AudioPlayer();
      await player.play(UrlSource(url));
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error in backgroundAdhanCallback: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static bool timezoneFallbackToUtc = false;
  static final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      timezoneFallbackToUtc = true;
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectNotificationStream.add(response.payload);
      },
    );

    try {
      final storage = await StorageService.getInstance();
      await scheduleDailyReminders(storage);
    } catch (_) {}
  }

  Future<bool> requestPermissions() async {
    final bool? androidGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final bool? iosGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  Future<void> schedulePrayerAlarms(PrayerTimeData prayerData, StorageService storage) async {
    // Cancel scheduled prayer notifications and alarms
    for (int i = 1; i <= 70; i++) {
      await _notificationsPlugin.cancel(id: i);
      await _notificationsPlugin.cancel(id: i + 2000);
      try {
        await AndroidAlarmManager.cancel(i + 1000); // GPS check
        await AndroidAlarmManager.cancel(i + 3000); // Pre-adhan alarm
        await AndroidAlarmManager.cancel(i + 4000); // Adhan alarm
      } catch (_) {}
    }

    final alertFajr = storage.getBool('alert_fajr', defaultValue: true);
    final alertDhuhr = storage.getBool('alert_dhuhr', defaultValue: true);
    final alertAsr = storage.getBool('alert_asr', defaultValue: true);
    final alertMaghrib = storage.getBool('alert_maghrib', defaultValue: true);
    final alertIsha = storage.getBool('alert_isha', defaultValue: true);

    final prayersToSchedule = <String, String>{};
    if (alertFajr && prayerData.fajr.isNotEmpty) prayersToSchedule['Fajr'] = prayerData.fajr;
    if (alertDhuhr && prayerData.dhuhr.isNotEmpty) prayersToSchedule['Dhuhr'] = prayerData.dhuhr;
    if (alertAsr && prayerData.asr.isNotEmpty) prayersToSchedule['Asr'] = prayerData.asr;
    if (alertMaghrib && prayerData.maghrib.isNotEmpty) prayersToSchedule['Maghrib'] = prayerData.maghrib;
    if (alertIsha && prayerData.isha.isNotEmpty) prayersToSchedule['Isha'] = prayerData.isha;

    final now = DateTime.now();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'athan_channel_id',
      'Athan Alarms',
      channelDescription: 'Notifications for prayer time athan alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: 'ic_notification',
      color: Color(0xFF0F766E),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int id = 1;
    for (final entry in prayersToSchedule.entries) {
      final name = entry.key;
      final timeStr = entry.value.trim().split(' ')[0]; // extract "HH:mm" from strings like "12:15 (EEST)"
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final scheduledDate = DateTime(now.year, now.month, now.day, hour, minute)
            .add(Duration(days: dayOffset));

        if (scheduledDate.isAfter(now)) {
          final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
          final notificationId = id + (dayOffset * 10);
          
          try {
            await _notificationsPlugin.zonedSchedule(
              id: notificationId,
              title: 'Time for $name',
              body: 'It is time for the $name prayer.',
              scheduledDate: tzDateTime,
              notificationDetails: notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: 'prayer_times',
            );
          } catch (_) {
            // Fallback for Android 12+ if exact alarms permission is revoked
            await _notificationsPlugin.zonedSchedule(
              id: notificationId,
              title: 'Time for $name',
              body: 'It is time for the $name prayer.',
              scheduledDate: tzDateTime,
              notificationDetails: notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: 'prayer_times',
            );
          }

          // Schedule pre-Athan notification
            final preAzanTime = scheduledDate.subtract(const Duration(minutes: 10));
            if (preAzanTime.isAfter(now)) {
              final tzPreDateTime = tz.TZDateTime.from(preAzanTime, tz.local);
              final preNotificationId = notificationId + 2000;
              
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: preNotificationId,
                  title: TranslationService.isArabic ? 'اقترب موعد الأذان' : 'Athan is approaching',
                  body: TranslationService.isArabic 
                      ? 'بقي ١٠ دقائق على أذان الـ $name.'
                      : '10 minutes remaining until $name Athan.',
                  scheduledDate: tzPreDateTime,
                  notificationDetails: notificationDetails,
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              } catch (_) {
                await _notificationsPlugin.zonedSchedule(
                  id: preNotificationId,
                  title: TranslationService.isArabic ? 'اقترب موعد الأذان' : 'Athan is approaching',
                  body: TranslationService.isArabic 
                      ? 'بقي ١٠ دقائق على أذان الـ $name.'
                      : '10 minutes remaining until $name Athan.',
                  scheduledDate: tzPreDateTime,
                  notificationDetails: notificationDetails,
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              }
            }

            // Schedule background alarms on Android
            if (Platform.isAndroid) {
              final adhanAlarmId = notificationId + 4000;
              try {
                await AndroidAlarmManager.oneShotAt(
                  scheduledDate,
                  adhanAlarmId,
                  backgroundAdhanCallback,
                  exact: true,
                  wakeup: true,
                );
              } catch (_) {}

              final preAdhanTimeVal = scheduledDate.subtract(const Duration(minutes: 10));
              if (preAdhanTimeVal.isAfter(now)) {
                final preAdhanAlarmId = notificationId + 3000;
                try {
                  await AndroidAlarmManager.oneShotAt(
                    preAdhanTimeVal,
                    preAdhanAlarmId,
                    backgroundPreAdhanCallback,
                    exact: true,
                    wakeup: true,
                  );
                } catch (_) {}
              }
            }

          // Cancel previous background alarm for this prayer time to prevent duplicates
          final alarmId = notificationId + 1000;
          try {
            await AndroidAlarmManager.cancel(alarmId);
          } catch (_) {}

          // Schedule background GPS check alarm 15 minutes before this prayer time
          if (dayOffset <= 1) {
            final checkTime = scheduledDate.subtract(const Duration(minutes: 15));
            if (checkTime.isAfter(now)) {
              try {
                await AndroidAlarmManager.oneShotAt(
                  checkTime,
                  alarmId,
                  backgroundPrayerTimesUpdateCallback,
                  exact: true,
                  wakeup: true,
                );
              } catch (_) {}
            }
          }
        }
      }
      id++;
    }
  }

  Future<void> scheduleDailyReminders(StorageService storage) async {
    // Cancel previous notifications
    await _notificationsPlugin.cancel(id: 3000); // Morning Azkar
    await _notificationsPlugin.cancel(id: 3001); // Evening Azkar
    for (int i = 0; i < 7; i++) {
      await _notificationsPlugin.cancel(id: 3002 + i); // Today's Verse (next 7 days)
    }

    final now = DateTime.now();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders_channel_id',
      'Daily Reminders',
      channelDescription: 'Notifications for daily Azkar and verse reminders',
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

    // 1. Morning Azkar
    if (storage.getBool('morning_azkar_reminder', defaultValue: true)) {
      final scheduledTime = DateTime(now.year, now.month, now.day, 7, 0); // 7:00 AM
      final tzDateTime = _nextOccurrence(scheduledTime);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: 3000,
          title: TranslationService.isArabic ? 'أذكار الصباح ☀️' : 'Morning Azkar ☀️',
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
          title: TranslationService.isArabic ? 'أذكار الصباح ☀️' : 'Morning Azkar ☀️',
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

    // 2. Evening Azkar
    if (storage.getBool('evening_azkar_reminder', defaultValue: true)) {
      final scheduledTime = DateTime(now.year, now.month, now.day, 17, 0); // 5:00 PM
      final tzDateTime = _nextOccurrence(scheduledTime);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: 3001,
          title: TranslationService.isArabic ? 'أذكار المساء 🌙' : 'Evening Azkar 🌙',
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
          title: TranslationService.isArabic ? 'أذكار المساء 🌙' : 'Evening Azkar 🌙',
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
        final scheduledTime = DateTime(now.year, now.month, now.day, 9, 0).add(Duration(days: i)); // 9:00 AM
        if (scheduledTime.isBefore(now)) continue;
        final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

        final index = (now.day + i) % QuranVersesData.verses.length;
        final verseObj = QuranVersesData.verses[index];
        final verseBody = verseObj.getDisplayString(isArabic);

        final AndroidNotificationDetails verseAndroidDetails = AndroidNotificationDetails(
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

        final NotificationDetails verseNotificationDetails = NotificationDetails(
          android: verseAndroidDetails,
          iOS: iosDetails,
        );

        try {
          await _notificationsPlugin.zonedSchedule(
            id: 3002 + i,
            title: isArabic ? 'آية اليوم 📖' : "Today's Verse 📖",
            body: verseBody,
            scheduledDate: tzDateTime,
            notificationDetails: verseNotificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'quran_verse',
          );
        } catch (_) {
          await _notificationsPlugin.zonedSchedule(
            id: 3002 + i,
            title: isArabic ? 'آية اليوم 📖' : "Today's Verse 📖",
            body: verseBody,
            scheduledDate: tzDateTime,
            notificationDetails: verseNotificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'quran_verse',
          );
        }
      }
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
