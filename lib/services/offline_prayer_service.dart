import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/prayer_models.dart';
import 'storage_service.dart';

class OfflinePrayerService {
  static String _formatTime(DateTime? dt) {
    if (dt == null) return "00:00";
    // Round to nearest minute to match standard prayer time apps (e.g., Aladhan, Five Prayers)
    final rounded = dt.add(const Duration(seconds: 30));
    return "${rounded.hour.toString().padLeft(2, '0')}:${rounded.minute.toString().padLeft(2, '0')}";
  }

  static Future<PrayerTimeData> getPrayerTimes({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final coords = Coordinates(latitude, longitude);

    CalculationParameters params;
    switch (method) {
      case 0:
        params = CalculationMethod.other.getParameters();
        break;
      case 1:
        params = CalculationMethod.karachi.getParameters();
        break;
      case 2:
        params = CalculationMethod.north_america.getParameters();
        break;
      case 3:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 4:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 5:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 7:
        params = CalculationMethod.tehran.getParameters();
        break;
      case 8:
        params = CalculationMethod.dubai.getParameters();
        break;
      case 9:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 10:
        params = CalculationMethod.qatar.getParameters();
        break;
      case 11:
        params = CalculationMethod.singapore.getParameters();
        break;
      case 12:
        params = CalculationMethod.turkey.getParameters();
        break;
      case 13:
        params = CalculationMethod.other.getParameters();
        break;
      default:
        params = CalculationMethod.other.getParameters();
        break;
    }

    params.madhab = school == 1 ? Madhab.hanafi : Madhab.shafi;
    if (params.method != CalculationMethod.umm_al_qura && params.method != CalculationMethod.qatar) {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    final dateComps = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coords, dateComps, params);
    
    int hijriOffset = 0;
    try {
      final storage = await StorageService.getInstance();
      hijriOffset = storage.getInt('hijri_day_offset', defaultValue: 0);
    } catch (_) {}
    final adjustedDate = now.add(Duration(days: hijriOffset));
    final hijri = HijriCalendar.fromDate(adjustedDate);

    return PrayerTimeData(
      fajr: _formatTime(prayerTimes.fajr),
      sunrise: _formatTime(prayerTimes.sunrise),
      dhuhr: _formatTime(prayerTimes.dhuhr),
      asr: _formatTime(prayerTimes.asr),
      maghrib: _formatTime(prayerTimes.maghrib),
      isha: _formatTime(prayerTimes.isha),
      sunset: _formatTime(prayerTimes.maghrib), // close enough
      imsak: _formatTime(
        prayerTimes.fajr.subtract(const Duration(minutes: 10)),
      ),
      gregorianDate: "${now.day}-${now.month}-${now.year}",
      hijriDate: "${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear}",
      hijriMonth: hijri.getLongMonthName(),
      hijriYear: hijri.hYear.toString(),
    );
  }

  static Future<String> get30DaysScheduleJson({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    bool use24h = false,
    bool isArabic = true,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final coords = Coordinates(latitude, longitude);

    CalculationParameters params;
    switch (method) {
      case 0:
        params = CalculationMethod.other.getParameters();
        break;
      case 1:
        params = CalculationMethod.karachi.getParameters();
        break;
      case 2:
        params = CalculationMethod.north_america.getParameters();
        break;
      case 3:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 4:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 5:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 7:
        params = CalculationMethod.tehran.getParameters();
        break;
      case 8:
        params = CalculationMethod.dubai.getParameters();
        break;
      case 9:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 10:
        params = CalculationMethod.qatar.getParameters();
        break;
      case 11:
        params = CalculationMethod.singapore.getParameters();
        break;
      case 12:
        params = CalculationMethod.turkey.getParameters();
        break;
      default:
        params = CalculationMethod.other.getParameters();
        break;
    }

    params.madhab = school == 1 ? Madhab.hanafi : Madhab.shafi;
    if (params.method != CalculationMethod.umm_al_qura &&
        params.method != CalculationMethod.qatar) {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    final List<Map<String, dynamic>> schedule = [];
    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dateComps = DateComponents.from(date);
      final pt = PrayerTimes(coords, dateComps, params);

      schedule.add({
        'd':
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        'f_ms': pt.fajr.millisecondsSinceEpoch,
        'f_str': _formatTimeWithFormat(pt.fajr, use24h, isArabic),
        'd_ms': pt.dhuhr.millisecondsSinceEpoch,
        'd_str': _formatTimeWithFormat(pt.dhuhr, use24h, isArabic),
        'a_ms': pt.asr.millisecondsSinceEpoch,
        'a_str': _formatTimeWithFormat(pt.asr, use24h, isArabic),
        'm_ms': pt.maghrib.millisecondsSinceEpoch,
        'm_str': _formatTimeWithFormat(pt.maghrib, use24h, isArabic),
        'i_ms': pt.isha.millisecondsSinceEpoch,
        'i_str': _formatTimeWithFormat(pt.isha, use24h, isArabic),
      });
    }

    return jsonEncode(schedule);
  }

  static String _formatTimeWithFormat(DateTime dt, bool use24h, bool isArabic) {
    final rounded = dt.add(const Duration(seconds: 30));
    final hour = rounded.hour;
    final minute = rounded.minute.toString().padLeft(2, '0');
    if (use24h) {
      return "${hour.toString().padLeft(2, '0')}:$minute";
    }
    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = isPm ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
    return "$displayHour:$minute $suffix";
  }

  static Future<List<Map<String, dynamic>>> getMonthlyCalendar({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    required int month,
    required int year,
  }) async {
    final List<Map<String, dynamic>> monthData = [];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final pData = await getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        method: method,
        school: school,
        date: date,
      );
      final hijri = HijriCalendar.fromDate(date);

      final monthNamesEn = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ];

      monthData.add({
        "timings": {
          "Fajr": pData.fajr,
          "Sunrise": pData.sunrise,
          "Dhuhr": pData.dhuhr,
          "Asr": pData.asr,
          "Sunset": pData.sunset,
          "Maghrib": pData.maghrib,
          "Isha": pData.isha,
          "Imsak": pData.imsak,
        },
        "date": {
          "readable": pData.gregorianDate,
          "gregorian": {
            "date":
                "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year",
            "day": day.toString().padLeft(2, '0'),
            "year": year.toString(),
            "month": {"en": monthNamesEn[month - 1]},
          },
          "hijri": {
            "date": pData.hijriDate,
            "day": hijri.hDay.toString().padLeft(2, '0'),
            "year": hijri.hYear.toString(),
            "month": {
              "number": hijri.hMonth,
              "ar": hijri.getLongMonthName(),
              "en": hijri.getLongMonthName(),
            },
          },
        },
      });
    }
    return monthData;
  }
}
