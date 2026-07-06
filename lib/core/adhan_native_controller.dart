import 'package:flutter/services.dart';

class AdhanNativeController {
  AdhanNativeController._();
  static final AdhanNativeController instance = AdhanNativeController._();

  final MethodChannel _channel = const MethodChannel('com.adhan.app/alarm');

  Future<void> schedulePrayerAlarm({required int id, required DateTime time}) async {
    try {
      await _channel.invokeMethod('scheduleExactAlarm', {
        'id': id,
        'timestamp': time.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      print("Failed to schedule native alarm: '\${e.message}'.");
    }
  }

  Future<void> requestOemAutostart() async {
    try {
      await _channel.invokeMethod('openOemAutoStartSettings');
    } on PlatformException catch (e) {
      print("Failed to open OEM autostart settings: '\${e.message}'.");
    }
  }
}
