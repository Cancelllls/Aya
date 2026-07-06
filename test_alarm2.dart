import 'package:flutter/material.dart';
import 'package:aya_app/services/notification_service.dart';
import 'package:aya_app/models/prayer_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final data = PrayerTimeData(
    fajr: '04:30',
    sunrise: '05:30',
    dhuhr: '12:30',
    asr: '15:30',
    sunset: '18:15',
    maghrib: '18:30',
    isha: '20:30',
  );
  
  print('Data created');
}
