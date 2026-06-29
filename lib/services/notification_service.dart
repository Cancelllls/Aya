import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/prayer_models.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'translation_service.dart';
import 'quran_verses.dart';
import 'adhan_audio_service.dart';

@pragma('vm:entry-point')
void backgroundPrayerTimesUpdateCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await StorageService.getInstance();
    final loc = storage.getLocation();
    if (loc['source'] == 'gps') {
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
        final ipLoc = await ApiService.fetchLocationByIP();
        city = ipLoc['city']!;
        country = ipLoc['country']!;
        lat = double.parse(ipLoc['latitude']!);
        lng = double.parse(ipLoc['longitude']!);
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
    const platform = MethodChannel('com.quran.aya/system');
    
    if (alertMode == 'silent') {
      return;
    }
    
    if (alertMode == 'vibrate' || alertMode == 'vibrate_and_voice') {
      await platform.invokeMethod('vibrate', {
        'pattern': NotificationService.islamicVibrationPattern,
        'amplitudes': NotificationService.islamicVibrationAmplitudes,
      });
    }
    
    if (alertMode == 'voice' || alertMode == 'vibrate_and_voice') {
      final isAr = TranslationService.currentLanguage == 'ar';
      final lang = isAr ? 'ar' : 'en';
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/pre_adhan_audio/pre_adhan_${lang}_v2.mp3';
      final localFile = File(localPath);
      final player = AudioPlayer();
      if (await localFile.exists()) {
        await player.play(DeviceFileSource(localPath));
      } else {
        final urls = AdhanAudioService.preAdhanVoiceUrls['standard'];
        if (urls != null) {
          final url = urls[lang];
          if (url != null) {
            await player.play(UrlSource(url));
          }
        }
      }
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
    const platform = MethodChannel('com.quran.aya/system');
    
    if (adhanMode == 'vibrate' || adhanMode == 'vibrate_and_voice') {
      await platform.invokeMethod('vibrate', {
        'pattern': NotificationService.islamicVibrationPattern,
        'amplitudes': NotificationService.islamicVibrationAmplitudes,
      });
    }
    
    if (adhanMode == 'real_reciter' || adhanMode == 'vibrate_and_voice') {
      final prayerIndex = (id - 4000) % 10;
      final isFajr = prayerIndex == 1;
      
      final reciterSetting = isFajr ? 'fajr_adhan_reciter' : 'adhan_reciter';
      final reciter = storage.getString(reciterSetting, defaultValue: isFajr ? 'mishary' : 'mishary');
      
      String url = '';

      if (isFajr) {
        url = AdhanAudioService.fajrReciterUrls[reciter] ?? AdhanAudioService.fajrReciterUrls['mishary']!;
      } else {
        url = AdhanAudioService.standardReciterUrls[reciter] ?? AdhanAudioService.standardReciterUrls['mishary']!;
      }
      
      final player = AudioPlayer();
      
      final receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping('adhan_stop_port');
      IsolateNameServer.registerPortWithName(receivePort.sendPort, 'adhan_stop_port');
      
      receivePort.listen((message) {
        if (message == 'stop') {
          player.stop();
          receivePort.close();
          IsolateNameServer.removePortNameMapping('adhan_stop_port');
        }
      });

      player.onPlayerComplete.listen((_) {
        receivePort.close();
        IsolateNameServer.removePortNameMapping('adhan_stop_port');
      });
      
      // Try playing offline first
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/adhan_audio/${reciter}_${isFajr ? 'fajr' : 'standard'}.mp3';
      final localFile = File(localPath);
      if (await localFile.exists()) {
        await player.play(DeviceFileSource(localPath));
      } else {
        await player.play(UrlSource(url));
        // Download it in the background for next time
        try {
          await localFile.parent.create(recursive: true);
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            await localFile.writeAsBytes(response.bodyBytes);
          }
        } catch (_) {}
      }
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

  static const List<int> islamicVibrationPattern = [
    0, 300, 150, 300, 150, 200, 150, 300, 150, 300, 150, 200, 150, 300, 150, 300, 150, 200
  ];

  static const List<int> islamicVibrationAmplitudes = [
    0, 200, 0, 200, 0, 100, 0, 200, 0, 200, 0, 100, 0, 200, 0, 200, 0, 100
  ];

  static void stopActiveAthan() {
    final sendPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
    if (sendPort != null) {
      sendPort.send('stop');
    }
  }

  static Future<void> downloadAllAthanFiles() async {
    final reciters = ['mishary', 'abdul_basit', 'madinah', 'kazabri', 'riad', 'manssour', 'nakshabandi', 'maghriby'];
    final client = http.Client();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/adhan_audio');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      for (final reciter in reciters) {
        for (final isFajr in [true, false]) {
          final localPath = '${folder.path}/${reciter}_${isFajr ? 'fajr' : 'standard'}.mp3';
          final localFile = File(localPath);
          if (await localFile.exists()) {
            continue;
          }

          String url = '';
          const String fpBase = 'https://raw.githubusercontent.com/Five-Prayers/five-prayers-android/main/app/src/main/res/raw';
          if (isFajr) {
            switch (reciter) {
              case 'mishary':
                url = '$fpBase/adhan_fajr_meshary_al_fasy_kuwait.mp3';
                break;
              case 'abdul_basit':
                url = '$fpBase/adhan_fajr_abdelbasset_abdessamad_egypte.mp3';
                break;
              case 'madinah':
                url = '$fpBase/adhan_fajr_al_haram_el_madani_saoudia.mp3';
                break;
              case 'kazabri':
                url = '$fpBase/adhan_omar_al_kazabri_morocco.mp3';
                break;
              case 'riad':
                url = '$fpBase/adhan_riad_al_djazairi_algeria.mp3';
                break;
              case 'manssour':
                url = '$fpBase/adhan_manssour_el_zahrani.mp3';
                break;
              case 'nakshabandi':
                url = '$fpBase/adhan_sayed_al_nakshabandi_egypte.mp3';
                break;
              case 'maghriby':
                url = '$fpBase/adhan_nurdin_hamza_al_maghriby_quds.mp3';
                break;
            }
          } else {
            switch (reciter) {
              case 'mishary':
                url = '$fpBase/adhan_meshary_al_fasy_kuwait.mp3';
                break;
              case 'abdul_basit':
                url = '$fpBase/adhan_abdelbasset_abdessamad_egypte.mp3';
                break;
              case 'madinah':
                url = '$fpBase/adhan_fajr_al_haram_el_madani_saoudia.mp3';
                break;
              case 'kazabri':
                url = '$fpBase/adhan_omar_al_kazabri_morocco.mp3';
                break;
              case 'riad':
                url = '$fpBase/adhan_riad_al_djazairi_algeria.mp3';
                break;
              case 'manssour':
                url = '$fpBase/adhan_manssour_el_zahrani.mp3';
                break;
              case 'nakshabandi':
                url = '$fpBase/adhan_sayed_al_nakshabandi_egypte.mp3';
                break;
              case 'maghriby':
                url = '$fpBase/adhan_nurdin_hamza_al_maghriby_quds.mp3';
                break;
            }
          }

          try {
            final response = await client.get(Uri.parse(url));
            if (response.statusCode == 200) {
              await localFile.writeAsBytes(response.bodyBytes);
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
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
        androidScheduleMode: AndroidScheduleMode.alarmClock,
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

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      try {
        final bool? enabled = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return enabled ?? false;
      } catch (_) {
        return false;
      }
    }
    return true;
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
    // Phase 6.1: Batch cancel using Future.wait
    final List<Future<void>> cancelFutures = [];
    for (int i = 1; i <= 70; i++) {
      cancelFutures.add(_notificationsPlugin.cancel(id: i));
      cancelFutures.add(_notificationsPlugin.cancel(id: i + 2000));
      if (Platform.isAndroid) {
        cancelFutures.add(Future.sync(() async {
          try {
            await AndroidAlarmManager.cancel(i + 1000); // GPS check
            await AndroidAlarmManager.cancel(i + 3000); // Pre-adhan alarm
            await AndroidAlarmManager.cancel(i + 4000); // Adhan alarm
          } catch (_) {}
        }));
      }
    }
    await Future.wait(cancelFutures);

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

    // Phase 2.1: Determine channelId based on adhanMode (silent if real_reciter/voice/vibrate_and_voice)
    final adhanMode = storage.getString('adhan_alert_mode', defaultValue: 'real_reciter');
    final channelId = (adhanMode == 'real_reciter' || adhanMode == 'voice' || adhanMode == 'vibrate_and_voice') 
        ? 'athan_channel_v2_silent' 
        : 'athan_channel_v2_sound';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'athan_channel_v2_silent' ? 'Athan Alarms (Silent)' : 'Athan Alarms',
      channelDescription: 'Notifications for prayer time athan alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: channelId == 'athan_channel_v2_sound',
      enableVibration: adhanMode == 'vibrate' || adhanMode == 'vibrate_and_voice',
      icon: 'ic_notification',
      color: const Color(0xFF0F766E),
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int id = 1;
    final List<Future<void>> scheduleFutures = [];

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
          final int preAdhanMins = storage.getInt('pre_adhan_duration', defaultValue: 10);
          final String preAdhanAlertMode = storage.getString('pre_adhan_alert_mode', defaultValue: 'vibrate');
          final isAr = TranslationService.isArabic;
          final localizedName = isAr ? _arabicPrayerName(name) : name;

          scheduleFutures.add(Future.sync(() async {
            try {
              await _notificationsPlugin.zonedSchedule(
                id: notificationId,
                title: isAr ? 'حان الآن موعد صلاة $localizedName' : 'Time for $localizedName',
                body: isAr 
                    ? 'حان الآن موعد صلاة $localizedName حسب التوقيت المحلي لمدينتك.' 
                    : 'It is time for the $localizedName prayer.',
                scheduledDate: tzDateTime,
                notificationDetails: notificationDetails,
                androidScheduleMode: AndroidScheduleMode.alarmClock,
                payload: 'prayer_times',
              );
            } catch (_) {
              // Fallback for Android 12+ if exact alarms permission is revoked
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: notificationId,
                  title: isAr ? 'حان الآن موعد صلاة $localizedName' : 'Time for $localizedName',
                  body: isAr 
                      ? 'حان الآن موعد صلاة $localizedName حسب التوقيت المحلي لمدينتك.' 
                      : 'It is time for the $localizedName prayer.',
                  scheduledDate: tzDateTime,
                  notificationDetails: notificationDetails,
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              } catch (_) {}
            }

            // Dynamic Pre-Adhan Timing and alerts
            if (preAdhanMins > 0 && preAdhanAlertMode != 'silent') {
              final preAzanTime = scheduledDate.subtract(Duration(minutes: preAdhanMins));
              if (preAzanTime.isAfter(now)) {
                final tzPreDateTime = tz.TZDateTime.from(preAzanTime, tz.local);
                final preNotificationId = notificationId + 2000;
                
                final preTitle = isAr ? 'اقترب موعد الأذان' : 'Athan is approaching';
                final preBody = isAr 
                    ? 'بقي $preAdhanMins دقائق على أذان الـ $localizedName.'
                    : '$preAdhanMins minutes remaining until $localizedName Athan.';

                try {
                  await _notificationsPlugin.zonedSchedule(
                    id: preNotificationId,
                    title: preTitle,
                    body: preBody,
                    scheduledDate: tzPreDateTime,
                    notificationDetails: notificationDetails,
                    androidScheduleMode: AndroidScheduleMode.alarmClock,
                    payload: 'prayer_times',
                  );
                } catch (_) {
                  try {
                    await _notificationsPlugin.zonedSchedule(
                      id: preNotificationId,
                      title: preTitle,
                      body: preBody,
                      scheduledDate: tzPreDateTime,
                      notificationDetails: notificationDetails,
                      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                      payload: 'prayer_times',
                    );
                  } catch (_) {}
                }
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
                      alarmClock: true,
                );
              } catch (_) {
                try {
                  await AndroidAlarmManager.oneShotAt(
                    scheduledDate,
                    adhanAlarmId,
                    backgroundAdhanCallback,
                    exact: false,
                    wakeup: true,
                  );
                } catch (_) {}
              }

              if (preAdhanMins > 0 && preAdhanAlertMode != 'silent') {
                final preAdhanTimeVal = scheduledDate.subtract(Duration(minutes: preAdhanMins));
                if (preAdhanTimeVal.isAfter(now)) {
                  final preAdhanAlarmId = notificationId + 3000;
                  try {
                    await AndroidAlarmManager.oneShotAt(
                      preAdhanTimeVal,
                      preAdhanAlarmId,
                      backgroundPreAdhanCallback,
                      exact: true,
                      wakeup: true,
                      alarmClock: true,
                    );
                  } catch (_) {
                    try {
                      await AndroidAlarmManager.oneShotAt(
                        preAdhanTimeVal,
                        preAdhanAlarmId,
                        backgroundPreAdhanCallback,
                        exact: false,
                        wakeup: true,
                      );
                    } catch (_) {}
                  }
                }
              }
            }

            // Cancel previous background alarm for this prayer time to prevent duplicates
            final alarmId = notificationId + 1000;
            if (Platform.isAndroid) {
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
                      alarmClock: true,
                    );
                  } catch (_) {
                    try {
                      await AndroidAlarmManager.oneShotAt(
                        checkTime,
                        alarmId,
                        backgroundPrayerTimesUpdateCallback,
                        exact: false,
                        wakeup: true,
                      );
                    } catch (_) {}
                  }
                }
              }
            }
          }));
        }
      }
      id++;
    }
  }

  String _arabicPrayerName(String englishName) {
    switch (englishName.toLowerCase()) {
      case 'fajr': return 'الفجر';
      case 'sunrise': return 'الشروق';
      case 'dhuhr': return 'الظهر';
      case 'asr': return 'العصر';
      case 'maghrib': return 'المغرب';
      case 'isha': return 'العشاء';
      default: return englishName;
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
          androidScheduleMode: AndroidScheduleMode.alarmClock,
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
          androidScheduleMode: AndroidScheduleMode.alarmClock,
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

        final versePayload = 'quran_verse:${verseObj.surahNumber}:${verseObj.ayahNumber}';
        try {
          await _notificationsPlugin.zonedSchedule(
            id: 3002 + i,
            title: isArabic ? 'آية اليوم 📖' : "Today's Verse 📖",
            body: verseBody,
            scheduledDate: tzDateTime,
            notificationDetails: verseNotificationDetails,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
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

  tz.TZDateTime _nextOccurrence(DateTime dt) {
    final now = DateTime.now();
    var scheduled = dt;
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }
}
