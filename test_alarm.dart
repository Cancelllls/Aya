import 'package:flutter/material.dart';
import 'package:aya_app/services/notification_service.dart';
import 'package:aya_app/models/prayer_models.dart';
import 'package:aya_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  
  final data = PrayerTimeData(
    fajr: '04:30',
    sunrise: '05:30',
    dhuhr: '12:30',
    asr: '15:30',
    maghrib: '18:30',
    isha: '20:30',
  );
  
  try {
    print('Calling schedulePrayerAlarms');
    await NotificationService().init();
    await NotificationService().schedulePrayerAlarms(data, storage);
    print('Success');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
