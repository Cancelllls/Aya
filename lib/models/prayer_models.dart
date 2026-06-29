class PrayerTimeData {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String sunset;
  final String imsak;
  final String gregorianDate;
  final String hijriDate;
  final String hijriMonth;
  final String hijriYear;

  PrayerTimeData({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.sunset,
    required this.imsak,
    required this.gregorianDate,
    required this.hijriDate,
    required this.hijriMonth,
    required this.hijriYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'sunset': sunset,
      'imsak': imsak,
      'gregorianDate': gregorianDate,
      'hijriDate': hijriDate,
      'hijriMonth': hijriMonth,
      'hijriYear': hijriYear,
    };
  }

  factory PrayerTimeData.fromLocalJson(Map<String, dynamic> json) {
    return PrayerTimeData(
      fajr: json['fajr'] as String? ?? '',
      sunrise: json['sunrise'] as String? ?? '',
      dhuhr: json['dhuhr'] as String? ?? '',
      asr: json['asr'] as String? ?? '',
      maghrib: json['maghrib'] as String? ?? '',
      isha: json['isha'] as String? ?? '',
      sunset: json['sunset'] as String? ?? '',
      imsak: json['imsak'] as String? ?? '',
      gregorianDate: json['gregorianDate'] as String? ?? '',
      hijriDate: json['hijriDate'] as String? ?? '',
      hijriMonth: json['hijriMonth'] as String? ?? '',
      hijriYear: json['hijriYear'] as String? ?? '',
    );
  }

  /// Primary factory for AlAdhan API response
  factory PrayerTimeData.fromJson(Map<String, dynamic> json) {
    final timings = (json['timings'] as Map<String, dynamic>?) ?? {};
    final date = (json['date'] as Map<String, dynamic>?) ?? {};
    final hijri = (date['hijri'] as Map<String, dynamic>?) ?? {};
    final hijriMonthMap = (hijri['month'] as Map<String, dynamic>?) ?? {};

    return PrayerTimeData(
      fajr: timings['Fajr'] as String? ?? '',
      sunrise: timings['Sunrise'] as String? ?? '',
      dhuhr: timings['Dhuhr'] as String? ?? '',
      asr: timings['Asr'] as String? ?? '',
      maghrib: timings['Maghrib'] as String? ?? '',
      isha: timings['Isha'] as String? ?? '',
      sunset: timings['Sunset'] as String? ?? '',
      imsak: timings['Imsak'] as String? ?? '',
      gregorianDate: date['readable'] as String? ?? '',
      hijriDate:
          "${hijri['day'] ?? ''} ${hijriMonthMap['en'] ?? ''} ${hijri['year'] ?? ''}"
              .trim(),
      hijriMonth: hijriMonthMap['en'] as String? ?? '',
      hijriYear: hijri['year'] as String? ?? '',
    );
  }

  /// Fallback factory for Pray.zone response structure
  factory PrayerTimeData.fromPrayZone(Map<String, dynamic> timings) {
    return PrayerTimeData(
      fajr: timings['Fajr'] ?? timings['fajr'] ?? '',
      sunrise: timings['Sunrise'] ?? timings['sunrise'] ?? '',
      dhuhr: timings['Dhuhr'] ?? timings['dhuhr'] ?? '',
      asr: timings['Asr'] ?? timings['asr'] ?? '',
      maghrib: timings['Maghrib'] ?? timings['maghrib'] ?? '',
      isha: timings['Isha'] ?? timings['isha'] ?? '',
      sunset: timings['Sunset'] ?? timings['sunset'] ?? '',
      imsak: timings['Imsak'] ?? timings['imsak'] ?? '',
      gregorianDate: '',
      hijriDate: '',
      hijriMonth: '',
      hijriYear: '',
    );
  }
}
