import 'package:flutter/services.dart';

class AdhanNativeController {
  AdhanNativeController._();
  static final AdhanNativeController instance = AdhanNativeController._();

  final MethodChannel _channel = const MethodChannel('com.adhan.app/alarm');

  Future<void> schedulePrayerAlarm({
    required int id,
    required DateTime time,
    required String mp3ResName,
    required String prayerName,
    bool enableVibration = true,
  }) async {
    try {
      await _channel.invokeMethod('scheduleExactAlarm', {
        'id': id,
        'timestamp': time.millisecondsSinceEpoch,
        'mp3ResName': mp3ResName,
        'prayerName': prayerName,
        'enableVibration': enableVibration,
      });
    } on PlatformException catch (e) {
      print("Failed to schedule native alarm: '${e.message}'.");
    }
  }

  Future<void> schedulePreAdhanAlarm({
    required int id,
    required DateTime time,
    required String prayerName,
    required int minutesBefore,
    String alertMode = 'vibrate',
  }) async {
    try {
      await _channel.invokeMethod('schedulePreAdhanAlarm', {
        'id': id,
        'timestamp': time.millisecondsSinceEpoch,
        'prayerName': prayerName,
        'minutesBefore': minutesBefore,
        'alertMode': alertMode,
      });
    } on PlatformException catch (e) {
      print("Failed to schedule pre-adhan native alarm: '${e.message}'.");
    }
  }

  Future<void> cancelAlarm({required int id}) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
    } on PlatformException catch (e) {
      print("Failed to cancel native alarm: '${e.message}'.");
    }
  }

  Future<void> cancelAllAlarms() async {
    try {
      await _channel.invokeMethod('cancelAllAlarms');
    } on PlatformException catch (e) {
      print("Failed to cancel all native alarms: '${e.message}'.");
    }
  }

  Future<List<Map<dynamic, dynamic>>> getScheduledAlarms() async {
    try {
      final List<dynamic>? res = await _channel.invokeListMethod('getScheduledAlarms');
      if (res != null) {
        return res.cast<Map<dynamic, dynamic>>();
      }
    } on PlatformException catch (e) {
      print("Failed to get scheduled alarms: '${e.message}'.");
    }
    return [];
  }

  Future<void> requestOemAutostart() async {
    try {
      await _channel.invokeMethod('openOemAutoStartSettings');
    } on PlatformException catch (e) {
      print("Failed to open OEM autostart settings: '${e.message}'.");
    }
  }
}
