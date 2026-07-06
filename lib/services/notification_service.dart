import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'translation_service.dart';
import 'quran_verses.dart';
import 'adhan_audio_service.dart';
import 'database_service.dart';
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
        final dateStr = parts[1];
        final prayerKey = parts[2];
        final db = await DatabaseService.getInstance();
        await db.updatePrayerTracker(
          dateStr,
          prayerKey,
          notificationResponse.actionId == 'action_prayed' ? 1 : 0,
        );
      }
    }
  } else if (notificationResponse.actionId == 'action_stop_adhan') {
    final sendPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
    if (sendPort != null) {
      sendPort.send('stop');
    }
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
          await NotificationService().schedulePrayerAlarms(offlineData, storage);
        }
      }
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error in background location prayer times update callback: $e');
  }
}

@pragma('vm:entry-point')
@pragma('vm:entry-point')
void backgroundPreAdhanCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await StorageService.getInstance();
    final alertMode = storage.getString(
      'pre_adhan_alert_mode',
      defaultValue: 'vibrate',
    );
    const platform = MethodChannel('com.quran.aya/system');

    if (alertMode == 'silent') {
      return;
    }

    // Vibration is now handled directly by AndroidNotificationDetails

    if (alertMode == 'voice' || alertMode == 'vibrate_and_voice') {
      final isAr = TranslationService.currentLanguage == 'ar';
      final lang = isAr ? 'ar' : 'en';
      final player = AudioPlayer();
      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
      
      final urls = AdhanAudioService.preAdhanVoiceUrls['standard'];
      if (urls != null) {
        final filename = urls[lang];
        if (filename != null) {
          await player.play(AssetSource('audio/adhan/$filename'));
        }
      }

      final receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping('adhan_stop_port');
      IsolateNameServer.registerPortWithName(
        receivePort.sendPort,
        'adhan_stop_port',
      );

      receivePort.listen((message) async {
        if (message == 'stop') {
          await player.stop();
          receivePort.close();
          IsolateNameServer.removePortNameMapping('adhan_stop_port');
        }
      });

      await player.onPlayerComplete.first;
      receivePort.close();
      IsolateNameServer.removePortNameMapping('adhan_stop_port');
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
    final adhanMode = storage.getString(
      'adhan_alert_mode',
      defaultValue: 'real_reciter',
    );
    const platform = MethodChannel('com.quran.aya/system');

    // Vibration is now handled directly by AndroidNotificationDetails

    if (adhanMode == 'real_reciter' || adhanMode == 'vibrate_and_voice') {
      final prayerIndex = (id - 4000) % 10;
      final isFajr = prayerIndex == 1;

      final reciterSetting = isFajr ? 'fajr_adhan_reciter' : 'adhan_reciter';
      final reciter = storage.getString(
        reciterSetting,
        defaultValue: isFajr ? 'mishary' : 'mishary',
      );

      String filename = '';

      if (isFajr) {
        filename =
            AdhanAudioService.fajrReciterUrls[reciter] ??
            AdhanAudioService.fajrReciterUrls['mishary']!;
      } else {
        filename =
            AdhanAudioService.standardReciterUrls[reciter] ??
            AdhanAudioService.standardReciterUrls['mishary']!;
      }

      final player = AudioPlayer();
      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );

      final receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping('adhan_stop_port');
      IsolateNameServer.registerPortWithName(
        receivePort.sendPort,
        'adhan_stop_port',
      );

      final completer = Completer<void>();

      receivePort.listen((message) {
        if (message == 'stop') {
          player.stop();
          receivePort.close();
          IsolateNameServer.removePortNameMapping('adhan_stop_port');
          if (!completer.isCompleted) completer.complete();
        }
      });

      player.onPlayerComplete.listen((_) {
        receivePort.close();
        IsolateNameServer.removePortNameMapping('adhan_stop_port');
        if (!completer.isCompleted) completer.complete();
      });

      // Fail-safe: Also show an immediate notification in case zonedSchedule failed
      final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
      try {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('ic_notification');
        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );
        await _notificationsPlugin.initialize(settings: initializationSettings);

        await _notificationsPlugin.show(
          id: id,
          title: 'حان وقت الصلاة',
          body: 'الصلاة خير من النوم - اضغط لإيقاف الأذان',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'adhan_v5_sound',
              'Athan Alarms',
              importance: Importance.max,
              priority: Priority.high,
              playSound: false,
              enableVibration: true,
              actions: [
                AndroidNotificationAction(
                  'action_stop_adhan',
                  'إيقاف / Stop',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ],
            ),
          ),
          payload: 'prayer_times',
        );
      } catch (_) {}

      await player.play(AssetSource('audio/adhan/$filename'));

      await completer.future;
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
    final sendPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
    if (sendPort != null) {
      sendPort.send('stop');
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
  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      // ponytail: YAGNI external dependency for this simple string check
      final String timeZoneName =
          await const MethodChannel('com.quran.aya/system').invokeMethod<String>('getTimeZoneName') ?? 'UTC';
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
              final dateStr = parts[1];
              final prayerKey = parts[2];
              final db = await DatabaseService.getInstance();
              await db.updatePrayerTracker(
                dateStr,
                prayerKey,
                response.actionId == 'action_prayed' ? 1 : 0,
              );
            }
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

  Future<void> schedulePrayerAlarms(
    PrayerTimeData prayerData,
    StorageService storage,
  ) async {
    // Validate prayer data
    final isValid = prayerData.fajr.isNotEmpty &&
        prayerData.dhuhr.isNotEmpty &&
        prayerData.asr.isNotEmpty &&
        prayerData.maghrib.isNotEmpty &&
        prayerData.isha.isNotEmpty;
    if (!isValid) return;

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
    if (alertFajr && prayerData.fajr.isNotEmpty)
      prayersToSchedule['Fajr'] = prayerData.fajr;
    if (alertDhuhr && prayerData.dhuhr.isNotEmpty)
      prayersToSchedule['Dhuhr'] = prayerData.dhuhr;
    if (alertAsr && prayerData.asr.isNotEmpty)
      prayersToSchedule['Asr'] = prayerData.asr;
    if (alertMaghrib && prayerData.maghrib.isNotEmpty)
      prayersToSchedule['Maghrib'] = prayerData.maghrib;
    if (alertIsha && prayerData.isha.isNotEmpty)
      prayersToSchedule['Isha'] = prayerData.isha;

    final now = DateTime.now();

    // Adhan notification details — sound played by Android OS via notification channel
    // This is exactly how FivePrayers does it: the notification itself carries the sound
    final adhanMode = storage.getString(
      'adhan_alert_mode',
      defaultValue: 'real_reciter',
    );

    // For adhan notifications: always use notification channel sound
    // Android OS plays the sound natively — no background Dart isolate needed
    final AndroidNotificationDetails adhanAndroidDetails =
        AndroidNotificationDetails(
          'adhan_native_v1',
          'Athan Alarms',
          channelDescription: 'Prayer time athan alerts with sound',
          importance: Importance.max,
          priority: Priority.high,
          playSound: adhanMode != 'silent' && adhanMode != 'vibrate',
          sound: (adhanMode != 'silent' && adhanMode != 'vibrate')
              ? const RawResourceAndroidNotificationSound('default_adhan')
              : null,
          enableVibration: adhanMode != 'silent',
          vibrationPattern: adhanMode != 'silent'
              ? Int64List.fromList([0, 1000, 500, 1000, 500, 500])
              : null,
          icon: 'ic_notification',
          color: const Color(0xFF0F766E),
          visibility: NotificationVisibility.public,
          fullScreenIntent: adhanMode != 'silent',
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

    final NotificationDetails adhanNotificationDetails = NotificationDetails(
      android: adhanAndroidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

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
          now.year, now.month, now.day, hour, minute,
        ).add(Duration(days: dayOffset));

        if (!scheduledDate.isAfter(now)) continue;

        final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
        final notificationId = id + (dayOffset * 10);

        // === ADHAN NOTIFICATION (sound played by Android OS natively) ===
        try {
          await _notificationsPlugin.zonedSchedule(
            id: notificationId,
            title: isAr
                ? 'حان الآن موعد صلاة $localizedName'
                : 'Time for $localizedName',
            body: isAr
                ? 'حان الآن موعد صلاة $localizedName حسب التوقيت المحلي لمدينتك.'
                : 'It is time for the $localizedName prayer.',
            scheduledDate: tzDateTime,
            notificationDetails: adhanNotificationDetails,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            payload: 'prayer_times',
          );
        } catch (_) {
          // Fallback: inexact if exact alarm permission revoked
          try {
            await _notificationsPlugin.zonedSchedule(
              id: notificationId,
              title: isAr
                  ? 'حان الآن موعد صلاة $localizedName'
                  : 'Time for $localizedName',
              body: isAr
                  ? 'حان الآن موعد صلاة $localizedName حسب التوقيت المحلي لمدينتك.'
                  : 'It is time for the $localizedName prayer.',
              scheduledDate: tzDateTime,
              notificationDetails: adhanNotificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: 'prayer_times',
            );
          } catch (_) {}
        }

        // === PRE-ADHAN NOTIFICATION ===
        if (preAdhanMins > 0) {
          final preAzanTime = scheduledDate.subtract(
            Duration(minutes: preAdhanMins),
          );
          if (preAzanTime.isAfter(now)) {
            final tzPreDateTime = tz.TZDateTime.from(preAzanTime, tz.local);
            final preNotificationId = notificationId + 2000;

            final preAndroidDetails = AndroidNotificationDetails(
              'pre_adhan_native_v1',
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
                title: isAr
                    ? 'اقترب موعد الأذان'
                    : 'Athan is approaching',
                body: isAr
                    ? 'بقي $preAdhanMins دقائق على أذان الـ $localizedName.'
                    : '$preAdhanMins minutes remaining until $localizedName Athan.',
                scheduledDate: tzPreDateTime,
                notificationDetails: preDetails,
                androidScheduleMode: AndroidScheduleMode.alarmClock,
                payload: 'prayer_times',
              );
            } catch (_) {
              try {
                await _notificationsPlugin.zonedSchedule(
                  id: preNotificationId,
                  title: isAr
                      ? 'اقترب موعد الأذان'
                      : 'Athan is approaching',
                  body: isAr
                      ? 'بقي $preAdhanMins دقائق على أذان الـ $localizedName.'
                      : '$preAdhanMins minutes remaining until $localizedName Athan.',
                  scheduledDate: tzPreDateTime,
                  notificationDetails: preDetails,
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  payload: 'prayer_times',
                );
              } catch (_) {}
            }
          }
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
            final dateStr = DateFormat('yyyy-MM-dd').format(targetDateForTracker);

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
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

    // 1. Morning Azkar
    if (storage.getBool('morning_azkar_reminder', defaultValue: true)) {
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        7,
        0,
      ); // 7:00 AM
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
          androidScheduleMode: AndroidScheduleMode.alarmClock,
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

    // 2. Evening Azkar
    if (storage.getBool('evening_azkar_reminder', defaultValue: true)) {
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        17,
        0,
      ); // 5:00 PM
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
          androidScheduleMode: AndroidScheduleMode.alarmClock,
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
