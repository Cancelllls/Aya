import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Focused store for location coordinates and prayer calculation parameters.
class PrayerPreferences {
  final SharedPreferences _prefs;

  PrayerPreferences(this._prefs);

  /// Retrieves cached user location, defaulting to Cairo, Egypt.
  Map<String, dynamic> getLocation() {
    final raw = _prefs.getString('user_location') ?? '';
    if (raw.isEmpty) {
      return {
        'city': 'Cairo',
        'country': 'Egypt',
        'latitude': 30.0444,
        'longitude': 31.2357,
        'source': 'default',
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Automatically resolves best calculation method for a given city and country.
  int determineSmartCalculationMethod(String city, String country) {
    final loc = '$city $country'.toLowerCase();
    if (loc.contains('egypt') ||
        loc.contains('مصر') ||
        loc.contains('alexandria') ||
        loc.contains('الإسكندرية') ||
        loc.contains('cairo') ||
        loc.contains('القاهرة')) {
      return 5; // Egypt (Egyptian General Authority of Survey)
    } else if (loc.contains('saudi') ||
        loc.contains('سعودية') ||
        loc.contains('makkah') ||
        loc.contains('mecca') ||
        loc.contains('مكة') ||
        loc.contains('riyadh') ||
        loc.contains('الرياض') ||
        loc.contains('madinah') ||
        loc.contains('المدينة')) {
      return 4; // Umm Al-Qura
    } else if (loc.contains('turkey') ||
        loc.contains('türkiye') ||
        loc.contains('turk') ||
        loc.contains('تركيا') ||
        loc.contains('istanbul') ||
        loc.contains('إسطنبول') ||
        loc.contains('ankara') ||
        loc.contains('أنقرة')) {
      return 13; // Turkey (Diyanet)
    } else if (loc.contains('united states') ||
        loc.contains('usa') ||
        loc.contains('canada') ||
        loc.contains('america') ||
        loc.contains('أمريكا') ||
        loc.contains('كندا')) {
      return 2; // ISNA
    } else if (loc.contains('singapore') || loc.contains('سنغافورة')) {
      return 11; // Singapore
    } else if (loc.contains('russia') || loc.contains('روسيا')) {
      return 14; // Russia
    } else if (loc.contains('uae') ||
        loc.contains('emirates') ||
        loc.contains('إمارات') ||
        loc.contains('dubai') ||
        loc.contains('دبي') ||
        loc.contains('abu dhabi') ||
        loc.contains('أبوظبي')) {
      return 16; // UAE
    } else if (loc.contains('qatar') || loc.contains('قطر')) {
      return 10; // Qatar
    } else if (loc.contains('france') ||
        loc.contains('فرنسا') ||
        loc.contains('paris') ||
        loc.contains('باريس')) {
      return 12; // France
    } else if (loc.contains('pakistan') ||
        loc.contains('باكستان') ||
        loc.contains('india') ||
        loc.contains('الهند') ||
        loc.contains('bangladesh') ||
        loc.contains('بنجلاديش') ||
        loc.contains('karachi') ||
        loc.contains('كاراتشي')) {
      return 1; // Karachi
    }
    return 3; // Muslim World League (MWL) as general fallback
  }

  /// Sets location coordinates and updates calculation method automatically.
  Future<bool> setLocation(
    String city,
    String country,
    double lat,
    double lng,
    String source,
  ) async {
    final data = {
      'city': city,
      'country': country,
      'latitude': lat,
      'longitude': lng,
      'source': source,
    };

    final smartMethod = determineSmartCalculationMethod(city, country);
    await _prefs.setInt('calc_method', smartMethod);
    return await _prefs.setString('user_location', jsonEncode(data));
  }
}
