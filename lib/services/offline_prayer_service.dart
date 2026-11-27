import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_models.dart';
import 'storage/prayer_preferences.dart';

class OfflinePrayerService {
  static String _formatTime(DateTime? dt) {
    if (dt == null) return "00:00";
    // Round to nearest minute to match standard prayer time apps (e.g., Aladhan, Five Prayers)
    final rounded = dt.add(const Duration(seconds: 30));
    return "${rounded.hour.toString().padLeft(2, '0')}:${rounded.minute.toString().padLeft(2, '0')}";
  }

  /// Resolves `Auto` (0) into a concrete method ID using stored city/country and GPS coordinates.
  static Future<int> resolveEffectiveMethod({
    required int method,
    double? latitude,
    double? longitude,
  }) async {
    if (method != 0) return method;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prayerPrefs = PrayerPreferences(prefs);
      final loc = prayerPrefs.getLocation();
      return prayerPrefs.determineSmartCalculationMethod(
        loc['city']?.toString() ?? '',
        loc['country']?.toString() ?? '',
        latitude: latitude ?? (loc['latitude'] as num?)?.toDouble(),
        longitude: longitude ?? (loc['longitude'] as num?)?.toDouble(),
      );
    } catch (_) {
      return 3;
    }
  }

  /// Resolves CalculationParameters based on method, school, manual offsets, and optional custom angles.
  /// Method 0: Auto (determines best method based on stored user location / coordinates)
  /// Method -1: Custom (uses custom Fajr and Isha depression angles)
  static Future<CalculationParameters> resolveCalculationParameters({
    required int method,
    required int school,
    double? latitude,
    double? longitude,
    double? customFajr,
    double? customIsha,
  }) async {
    int effectiveMethod = method;
    double? fajrAngle = customFajr;
    double? ishaAngle = customIsha;
    PrayerAdjustments manualAdjustments = PrayerAdjustments();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (effectiveMethod == 0) {
        effectiveMethod = await resolveEffectiveMethod(
          method: effectiveMethod,
          latitude: latitude,
          longitude: longitude,
        );
      }
      if (effectiveMethod == -1 || method == -1) {
        fajrAngle ??= prefs.getDouble('custom_fajr_angle') ?? 18.0;
        ishaAngle ??= prefs.getDouble('custom_isha_angle') ?? 17.0;
      }
      manualAdjustments = PrayerAdjustments(
        fajr: prefs.getInt('fajr_offset') ?? 0,
        sunrise: prefs.getInt('sunrise_offset') ?? 0,
        dhuhr: prefs.getInt('dhuhr_offset') ?? 0,
        asr: prefs.getInt('asr_offset') ?? 0,
        maghrib: prefs.getInt('maghrib_offset') ?? 0,
        isha: prefs.getInt('isha_offset') ?? 0,
      );
    } catch (_) {}

    CalculationParameters params;
    if (effectiveMethod == -1 || method == -1) {
      params = CalculationParameters(
        fajrAngle: fajrAngle ?? 18.0,
        ishaAngle: ishaAngle ?? 17.0,
        method: CalculationMethod.other,
      );
    } else {
      switch (effectiveMethod) {
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
        case 6: // Sunni Endowment in Iraq (19.5° Fajr / 17.5° Isha)
          params = CalculationMethod.egyptian.getParameters();
          break;
        case 7:
          params = CalculationMethod.tehran.getParameters();
          break;
        case 8:
        case 16: // UAE (GAIAE) / Dubai
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
        case 12: // France (UOIF)
          params = CalculationParameters(
            fajrAngle: 12.0,
            ishaAngle: 12.0,
            method: CalculationMethod.other,
          );
          break;
        case 13: // Turkey (Diyanet)
          params = CalculationMethod.turkey.getParameters();
          break;
        case 14: // Russia (SAMR)
          params = CalculationParameters(
            fajrAngle: 16.0,
            ishaAngle: 15.0,
            method: CalculationMethod.other,
          );
          break;
        default:
          params = CalculationMethod.other.getParameters();
          break;
      }
    }

    params.madhab = school == 1 ? Madhab.hanafi : Madhab.shafi;
    params.adjustments = manualAdjustments;
    if (params.method != CalculationMethod.umm_al_qura &&
        params.method != CalculationMethod.qatar) {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    return params;
  }

  static Future<PrayerTimeData> getPrayerTimes({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
    DateTime? date,
    double? customFajr,
    double? customIsha,
  }) async {
    final now = date ?? DateTime.now();
    final coords = Coordinates(latitude, longitude);

    final params = await resolveCalculationParameters(
      method: method,
      school: school,
      latitude: latitude,
      longitude: longitude,
      customFajr: customFajr,
      customIsha: customIsha,
    );

    final dateComps = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coords, dateComps, params);

    int hijriOffset = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      hijriOffset = prefs.getInt('hijri_day_offset') ?? 0;
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
    double? customFajr,
    double? customIsha,
  }) async {
    final now = DateTime.now();
    final coords = Coordinates(latitude, longitude);

    final params = await resolveCalculationParameters(
      method: method,
      school: school,
      latitude: latitude,
      longitude: longitude,
      customFajr: customFajr,
      customIsha: customIsha,
    );

    final List<Map<String, dynamic>> schedule = [];
    for (int i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
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

  /// Syncs Android home-screen widget preferences and triggers a native refresh.
  static Future<void> syncHomeWidgets({
    PrayerTimeData? todayData,
    bool? isArabic,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loc = PrayerPreferences(prefs).getLocation();
      final lat = (loc['latitude'] as num?)?.toDouble() ?? 30.0444;
      final lng = (loc['longitude'] as num?)?.toDouble() ?? 31.2357;
      final rawMethod = prefs.getInt('calc_method') ?? 0;
      final effectiveMethod = await resolveEffectiveMethod(
        method: rawMethod,
        latitude: lat,
        longitude: lng,
      );
      final school = prefs.getInt('asr_method') ?? 0;
      final customFajr = prefs.getDouble('custom_fajr_angle') ?? 18.0;
      final customIsha = prefs.getDouble('custom_isha_angle') ?? 17.0;
      final use24h = prefs.getBool('time_format_24h') ?? false;
      final ar = isArabic ?? (prefs.getBool('widget_is_arabic') ?? true);

      final scheduleJson = await get30DaysScheduleJson(
        latitude: lat,
        longitude: lng,
        method: effectiveMethod,
        school: school,
        use24h: use24h,
        isArabic: ar,
        customFajr: customFajr,
        customIsha: customIsha,
      );
      final schedule = jsonDecode(scheduleJson) as List;
      if (schedule.isNotEmpty) {
        final today = schedule.first as Map<String, dynamic>;
        await prefs.setInt('widget_fajr_epoch', today['f_ms'] as int);
        await prefs.setInt('widget_dhuhr_epoch', today['d_ms'] as int);
        await prefs.setInt('widget_asr_epoch', today['a_ms'] as int);
        await prefs.setInt('widget_maghrib_epoch', today['m_ms'] as int);
        await prefs.setInt('widget_isha_epoch', today['i_ms'] as int);

        await prefs.setString('widget_prayer_fajr', today['f_str'] as String);
        await prefs.setString('widget_prayer_dhuhr', today['d_str'] as String);
        await prefs.setString('widget_prayer_asr', today['a_str'] as String);
        await prefs.setString('widget_prayer_maghrib', today['m_str'] as String);
        await prefs.setString('widget_prayer_isha', today['i_str'] as String);
      }

      await prefs.setString('widget_prayer_schedule_30d', scheduleJson);
      await prefs.setDouble('widget_user_latitude', lat);
      await prefs.setDouble('widget_user_longitude', lng);
      await prefs.setInt('widget_calc_method', effectiveMethod);
      await prefs.setDouble('widget_custom_fajr_angle', customFajr);
      await prefs.setDouble('widget_custom_isha_angle', customIsha);
      await prefs.setInt('widget_asr_method', school);
      await prefs.setBool('widget_time_format_24h', use24h);

      try {
        const platform = MethodChannel('com.quran.aya/system');
        await platform.invokeMethod('updateWidget');
      } catch (_) {}
    } catch (_) {}
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
    double? customFajr,
    double? customIsha,
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
        customFajr: customFajr,
        customIsha: customIsha,
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
