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

  static String _normalizeLoc(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  /// Automatically resolves best calculation method for a given city/country and optional GPS coordinates.
  int determineSmartCalculationMethod(
    String city,
    String country, {
    double? latitude,
    double? longitude,
  }) {
    final loc = _normalizeLoc('$city $country');
    if (loc.contains('iraq') ||
        loc.contains('عراق') ||
        loc.contains('baghdad') ||
        loc.contains('بغداد') ||
        loc.contains('mosul') ||
        loc.contains('الموصل') ||
        loc.contains('basra') ||
        loc.contains('البصره') ||
        loc.contains('erbil') ||
        loc.contains('اربيل') ||
        loc.contains('kirkuk') ||
        loc.contains('كركوك') ||
        loc.contains('sulaymaniyah') ||
        loc.contains('السليمانيه') ||
        loc.contains('anbar') ||
        loc.contains('الانبار') ||
        loc.contains('fallujah') ||
        loc.contains('الفلوجه') ||
        loc.contains('najaf') ||
        loc.contains('النجف') ||
        loc.contains('karbala') ||
        loc.contains('كربلاء')) {
      return 6; // Sunni Endowment (Iraq)
    } else if (loc.contains('egypt') ||
        loc.contains('مصر') ||
        loc.contains('cairo') ||
        loc.contains('القاهره') ||
        loc.contains('alexandria') ||
        loc.contains('الاسكندريه') ||
        loc.contains('giza') ||
        loc.contains('الجيزه') ||
        loc.contains('mansoura') ||
        loc.contains('المنصوره') ||
        loc.contains('tanta') ||
        loc.contains('طنطا') ||
        loc.contains('zagazig') ||
        loc.contains('الزقازيق') ||
        loc.contains('ismailia') ||
        loc.contains('الاسماعيليه') ||
        loc.contains('suez') ||
        loc.contains('السويس') ||
        loc.contains('port said') ||
        loc.contains('بورسعيد') ||
        loc.contains('luxor') ||
        loc.contains('الاقصر') ||
        loc.contains('aswan') ||
        loc.contains('اسوان') ||
        loc.contains('asyut') ||
        loc.contains('assiut') ||
        loc.contains('اسيوط') ||
        loc.contains('sohag') ||
        loc.contains('سوهاج') ||
        loc.contains('minya') ||
        loc.contains('المنيا') ||
        loc.contains('beni suef') ||
        loc.contains('بني سويف') ||
        loc.contains('faiyum') ||
        loc.contains('fayoum') ||
        loc.contains('الفيوم') ||
        loc.contains('damietta') ||
        loc.contains('دمياط') ||
        loc.contains('damanhur') ||
        loc.contains('دمنهور') ||
        loc.contains('qena') ||
        loc.contains('قنا') ||
        loc.contains('hurghada') ||
        loc.contains('الغردقه') ||
        loc.contains('sharm') ||
        loc.contains('شرم') ||
        loc.contains('matrouh') ||
        loc.contains('مطروح') ||
        loc.contains('sinai') ||
        loc.contains('سيناء') ||
        loc.contains('banha') ||
        loc.contains('بنها')) {
      return 5; // Egypt (Egyptian General Authority of Survey)
    } else if (loc.contains('saudi') ||
        loc.contains('سعوديه') ||
        loc.contains('makkah') ||
        loc.contains('mecca') ||
        loc.contains('مكه') ||
        loc.contains('riyadh') ||
        loc.contains('الرياض') ||
        loc.contains('madinah') ||
        loc.contains('المدينه')) {
      return 4; // Umm Al-Qura
    } else if (loc.contains('turkey') ||
        loc.contains('türkiye') ||
        loc.contains('turk') ||
        loc.contains('تركيا') ||
        loc.contains('istanbul') ||
        loc.contains('اسطنبول') ||
        loc.contains('ankara') ||
        loc.contains('انقره')) {
      return 13; // Turkey (Diyanet)
    } else if (loc.contains('iran') ||
        loc.contains('ايران') ||
        loc.contains('tehran') ||
        loc.contains('طهران')) {
      return 7; // Institute of Geophysics, Tehran
    } else if (loc.contains('kuwait') || loc.contains('الكويت')) {
      return 9; // Kuwait
    } else if (loc.contains('united states') ||
        loc.contains('usa') ||
        loc.contains('canada') ||
        loc.contains('america') ||
        loc.contains('امريكا') ||
        loc.contains('كندا')) {
      return 2; // ISNA
    } else if (loc.contains('singapore') || loc.contains('سنغافوره')) {
      return 11; // Singapore
    } else if (loc.contains('russia') || loc.contains('روسيا')) {
      return 14; // Russia
    } else if (loc.contains('uae') ||
        loc.contains('emirates') ||
        loc.contains('امارات') ||
        loc.contains('dubai') ||
        loc.contains('دبي') ||
        loc.contains('abu dhabi') ||
        loc.contains('ابوظبي')) {
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

    // Coordinate fallback for offline GPS ("My Location, GPS") or unmatched city names
    if (latitude != null &&
        longitude != null &&
        !(latitude == 0.0 && longitude == 0.0)) {
      if ((latitude >= 22.0 &&
              latitude <= 31.7 &&
              longitude >= 24.7 &&
              longitude <= 34.25) ||
          (latitude >= 27.5 &&
              latitude <= 31.35 &&
              longitude > 34.25 &&
              longitude <= 34.95) ||
          (latitude >= 22.0 &&
              latitude < 27.5 &&
              longitude > 34.25 &&
              longitude <= 36.9)) {
        return 5; // Egypt
      }
      const boxes = <(double minLat, double maxLat, double minLng, double maxLng, int method)>[
        (24.4, 26.2, 50.7, 51.7, 10), // Qatar
        (22.6, 26.1, 51.5, 56.4, 16), // UAE
        (28.5, 30.1, 46.5, 48.5, 9), // Kuwait
        (29.1, 37.4, 38.8, 48.6, 6), // Iraq
        (16.3, 32.2, 34.5, 55.7, 4), // Saudi Arabia
        (35.8, 42.1, 25.6, 44.8, 13), // Turkey
        (25.0, 39.8, 44.0, 63.3, 7), // Iran
        (8.0, 37.1, 60.8, 92.7, 1), // Karachi / South Asia
        (1.15, 1.48, 103.6, 104.1, 11), // Singapore
        (41.3, 51.1, -5.2, 9.6, 12), // France
        (41.2, 82.0, 27.0, 180.0, 14), // Russia
        (24.0, 72.0, -168.0, -52.0, 2), // North America (ISNA)
      ];
      for (final (minLat, maxLat, minLng, maxLng, method) in boxes) {
        if (latitude >= minLat &&
            latitude <= maxLat &&
            longitude >= minLng &&
            longitude <= maxLng) {
          return method;
        }
      }
    }

    return 3; // Muslim World League (MWL) as general fallback
  }

  /// Sets location coordinates and ensures calculation method defaults to Auto (0) if unset.
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

    final currentMethod = _prefs.getInt('calc_method');
    if (currentMethod == null) {
      await _prefs.setInt('calc_method', 0);
    }
    return await _prefs.setString('user_location', jsonEncode(data));
  }
}
