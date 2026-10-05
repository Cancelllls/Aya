import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/prayer_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/offline_prayer_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../utils/text_helpers.dart';
import 'package:hijri/hijri_calendar.dart';

part 'prayer_times_screen_ui.dart';

class PrayerTimesScreen extends StatefulWidget {
  final StorageService storage;
  final int initialSubTab;

  const PrayerTimesScreen({
    super.key,
    required this.storage,
    this.initialSubTab = 0,
  });

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTimeData? _prayerData;
  bool _isLoading = true;
  int _calcMethod = 0; // Auto
  int _asrMethod = 0; // Standard (Shafi'i)
  double _customFajr = 18.0;
  double _customIsha = 17.0;
  int _selectedSubTab = 0;
  List<dynamic>? _monthlyData;

  int _calendarMonth = DateTime.now().month;
  int _calendarYear = DateTime.now().year;
  bool _isCalendarLoading = false;
  DateTime _selectedCalendarDay = DateTime.now();
  bool _showRawPrayerTable = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _calcMethod = widget.storage.getInt('calc_method', defaultValue: 0);
    _asrMethod = widget.storage.getInt('asr_method', defaultValue: 0);
    _customFajr = widget.storage.getDouble(
      'custom_fajr_angle',
      defaultValue: 18.0,
    );
    _customIsha = widget.storage.getDouble(
      'custom_isha_angle',
      defaultValue: 17.0,
    );
    _calendarMonth = DateTime.now().month;
    _calendarYear = DateTime.now().year;
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _isLoading = true);
    try {
      final loc = widget.storage.getLocation();

      final PrayerTimeData data = await ApiService.fetchPrayerTimes(
        latitude: loc['latitude'] ?? 30.0444,
        longitude: loc['longitude'] ?? 31.2357,
        method: _calcMethod,
        school: _asrMethod,
        customFajr: _customFajr,
        customIsha: _customIsha,
      );

      final now = DateTime.now();
      List<dynamic> monthlyList = [];
      try {
        monthlyList = await OfflinePrayerService.getMonthlyCalendar(
          latitude: loc['latitude'] ?? 30.0444,
          longitude: loc['longitude'] ?? 31.2357,
          method: _calcMethod,
          school: _asrMethod,
          month: now.month,
          year: now.year,
          customFajr: _customFajr,
          customIsha: _customIsha,
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _prayerData = data;
          _monthlyData = monthlyList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'خطأ في تحميل مواقيت الصلاة: $e'
                  : 'Error loading prayer times: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isCalendarLoading = true);
    try {
      final loc = widget.storage.getLocation();
      final monthlyList = await OfflinePrayerService.getMonthlyCalendar(
        latitude: loc['latitude'] ?? 30.0444,
        longitude: loc['longitude'] ?? 31.2357,
        method: _calcMethod,
        school: _asrMethod,
        month: _calendarMonth,
        year: _calendarYear,
        customFajr: _customFajr,
        customIsha: _customIsha,
      );
      setState(() {
        _monthlyData = monthlyList;
        _isCalendarLoading = false;
      });
    } catch (_) {
      setState(() => _isCalendarLoading = false);
    }
  }

  void _prevCalendarMonth() {
    setState(() {
      if (_calendarMonth == 1) {
        _calendarMonth = 12;
        _calendarYear--;
      } else {
        _calendarMonth--;
      }
      final now = DateTime.now();
      if (_calendarYear == now.year && _calendarMonth == now.month) {
        _selectedCalendarDay = now;
      } else {
        _selectedCalendarDay = DateTime(_calendarYear, _calendarMonth, 1);
      }
    });
    _loadCalendarData();
  }

  void _nextCalendarMonth() {
    setState(() {
      if (_calendarMonth == 12) {
        _calendarMonth = 1;
        _calendarYear++;
      } else {
        _calendarMonth++;
      }
      final now = DateTime.now();
      if (_calendarYear == now.year && _calendarMonth == now.month) {
        _selectedCalendarDay = now;
      } else {
        _selectedCalendarDay = DateTime(_calendarYear, _calendarMonth, 1);
      }
    });
    _loadCalendarData();
  }

  List<Map<String, dynamic>> _getHijriEventsForMonth() {
    if (_monthlyData == null) return [];
    final List<Map<String, dynamic>> events = [];

    for (final day in _monthlyData!) {
      final hijri = day['date']['hijri'];
      final hDay = int.tryParse(hijri['day'].toString()) ?? 0;
      final hMonth = int.tryParse(hijri['month']['number'].toString()) ?? 0;
      final hMonthAr = hijri['month']['ar'] ?? '';
      final hYear = hijri['year'] ?? '';
      final gregDateStr = day['date']['gregorian']['date'] as String;

      String? eventNameAr;
      String? eventNameEn;

      if (hMonth == 1 && hDay == 1) {
        eventNameAr = "رأس السنة الهجرية";
        eventNameEn = "Islamic New Year";
      } else if (hMonth == 1 && hDay == 10) {
        eventNameAr = "يوم عاشوراء";
        eventNameEn = "Day of Ashura";
      } else if (hMonth == 3 && hDay == 12) {
        eventNameAr = "المولد النبوي الشريف";
        eventNameEn = "Mawlid al-Nabi";
      } else if (hMonth == 7 && hDay == 27) {
        eventNameAr = "ليلة الإسراء والمعراج";
        eventNameEn = "Isra' and Mi'raj";
      } else if (hMonth == 8 && hDay == 15) {
        eventNameAr = "ليلة النصف من شعبان";
        eventNameEn = "Mid-Sha'ban";
      } else if (hMonth == 9 && hDay == 1) {
        eventNameAr = "بداية شهر رمضان المبارك";
        eventNameEn = "Start of Ramadan";
      } else if (hMonth == 10 && hDay == 1) {
        eventNameAr = "عيد الفطر السعيد";
        eventNameEn = "Eid al-Fitr";
      } else if (hMonth == 12 && hDay == 9) {
        eventNameAr = "يوم عرفة";
        eventNameEn = "Day of Arafah";
      } else if (hMonth == 12 && hDay == 10) {
        eventNameAr = "عيد الأضحى المبارك";
        eventNameEn = "Eid al-Adha";
      }

      if (eventNameAr != null) {
        events.add({
          'hijriDate': "$hDay $hMonthAr $hYear",
          'title': TranslationService.isArabic ? eventNameAr : eventNameEn,
          'gregDate': gregDateStr,
          'key': "${hMonth}_$hDay",
        });
      }
    }
    return events;
  }

  void _showReminderDialog(Map<String, dynamic> event) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isArabic ? "ضبط تذكير بالحدث" : "Set Event Reminder",
          style: const TextStyle(
            color: Color(0xFFE5C158),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? "اختر متى تود تلقي إشعار التذكير لهذا الحدث الإسلامي:"
                  : "Choose when you would like to receive a notification alert for this Islamic event:",
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildReminderOption(
              dialogCtx,
              event,
              0,
              isArabic ? "في نفس اليوم" : "On the day",
            ),
            _buildReminderOption(
              dialogCtx,
              event,
              -1,
              isArabic ? "قبل بيوم واحد" : "1 day before",
            ),
            _buildReminderOption(
              dialogCtx,
              event,
              -3,
              isArabic ? "قبل ٣ أيام" : "3 days before",
            ),
            _buildReminderOption(
              dialogCtx,
              event,
              -5,
              isArabic ? "قبل ٥ أيام" : "5 days before",
            ),
            _buildReminderOption(
              dialogCtx,
              event,
              1,
              isArabic ? "بعد بيوم واحد" : "1 day after",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderOption(
    BuildContext dialogCtx,
    Map<String, dynamic> event,
    int offsetDays,
    String label,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.alarm_add, color: Color(0xFFE5C158), size: 20),
      onTap: () async {
        Navigator.pop(dialogCtx);

        final parts = event['gregDate'].split('-');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        var notifyDate = DateTime(year, month, day, 9, 0); // Remind at 9:00 AM
        if (offsetDays != 0) {
          notifyDate = notifyDate.add(Duration(days: offsetDays));
        }

        final id = event['key'].hashCode + offsetDays;

        final isArabic = TranslationService.isArabic;
        final notificationTitle = isArabic
            ? "تذكير بحدث إسلامي"
            : "Islamic Event Reminder";
        final notificationBody = isArabic
            ? "يقترب حدث: ${event['title']} (${event['hijriDate']})"
            : "Approaching event: ${event['title']} (${event['hijriDate']})";

        await NotificationService().scheduleHijriEventReminder(
          id: id,
          title: notificationTitle,
          body: notificationBody,
          scheduledDate: notifyDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? "تم ضبط التذكير بنجاح!"
                    : "Reminder configured successfully!",
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant PrayerTimesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab ||
        _selectedSubTab != widget.initialSubTab) {
      setState(() {
        _selectedSubTab = widget.initialSubTab;
      });
    }
    final newCalc = widget.storage.getInt('calc_method', defaultValue: 0);
    final newAsr = widget.storage.getInt('asr_method', defaultValue: 0);
    final newFajr = widget.storage.getDouble(
      'custom_fajr_angle',
      defaultValue: 18.0,
    );
    final newIsha = widget.storage.getDouble(
      'custom_isha_angle',
      defaultValue: 17.0,
    );
    if (newCalc != _calcMethod ||
        newAsr != _asrMethod ||
        newFajr != _customFajr ||
        newIsha != _customIsha) {
      setState(() {
        _calcMethod = newCalc;
        _asrMethod = newAsr;
        _customFajr = newFajr;
        _customIsha = newIsha;
      });
      _loadPrayerTimes();
    }
  }

  Future<void> _updateLocationWithGPS() async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final cardColor = Theme.of(context).cardColor;
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          TranslationService.isArabic
              ? 'خدمات الموقع معطلة.'
              : 'Location services are disabled.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            TranslationService.isArabic
                ? 'تم رفض إذن الوصول للموقع.'
                : 'Location permissions are denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          TranslationService.isArabic
              ? 'تم رفض إذن الموقع بشكل دائم.'
              : 'Location permissions are permanently denied.',
        );
      }

      if (!mounted) return;
      if (isAndroid && permission == LocationPermission.whileInUse) {
        final bool proceed =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogCtx) => AlertDialog(
                backgroundColor: cardColor,
                title: Text(
                  TranslationService.isArabic
                      ? "مطلوب إذن الموقع دائماً"
                      : "Location Permission 'Always' Required",
                  style: const TextStyle(
                    color: Color(0xFFE5C158),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  TranslationService.isArabic
                      ? "يتطلب التطبيق إذن الموقع 'سماح طوال الوقت' لتحديث مواقيت الصلاة تلقائياً في الخلفية بدون فتح التطبيق. يرجى الضغط على زر المتابعة لتغيير الإذن من إعدادات الهاتف إلى 'السماح طوال الوقت'."
                      : "The app requires the location permission set to 'Allow all the time' to update prayer times automatically in the background. Please click continue to change it to 'Allow all the time' in your settings.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: Text(
                      TranslationService.t('cancel'),
                      style: TextStyle(
                        color:
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                                    Colors.white)
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5C158),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    child: Text(
                      TranslationService.isArabic ? "متابعة" : "Continue",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (proceed) {
          await Geolocator.openAppSettings();
          await Future.delayed(const Duration(seconds: 3));
          if (!mounted) return;
          permission = await Geolocator.checkPermission();
        }
      }

      if (isAndroid && permission != LocationPermission.always) {
        throw Exception(
          TranslationService.isArabic
              ? "يرجى منح إذن الموقع 'السماح طوال الوقت' للاستمرار."
              : "Please grant 'Allow all the time' location permission to proceed.",
        );
      }

      Position? position = await ApiService.getBestLocation();
      double lat;
      double lon;
      String city;
      String country;

      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
        final address = await ApiService.reverseGeocode(lat, lon);
        city =
            address['city'] ??
            (TranslationService.isArabic ? 'موقعي' : 'My Location');
        country = address['country'] ?? 'GPS';
      } else {
        city = 'Cairo';
        country = 'Egypt';
        lat = 30.0444;
        lon = 31.2357;
      }

      await widget.storage.setLocation(city, country, lat, lon, 'gps');

      await _loadPrayerTimes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'تم تحديث الموقع إلى $city، $country!'
                  : 'Location updated to $city, $country!',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'خطأ في تحديد الموقع (GPS): $e'
                  : 'GPS Error: $e',
            ),
          ),
        );
      }
    }
  }

  void _showManualLocationDialog() {
    final cityController = TextEditingController();
    final countryController = TextEditingController();

    // Load current values
    final currentLoc = widget.storage.getLocation();
    cityController.text = currentLoc['city'] ?? '';
    countryController.text = currentLoc['country'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            TranslationService.t('set_manual_loc'),
            style: const TextStyle(
              color: Color(0xFFE5C158),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: TranslationService.t('city_name'),
                  hintText: TranslationService.isArabic
                      ? 'مثال: القاهرة'
                      : 'e.g. London',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryController,
                decoration: InputDecoration(
                  labelText: TranslationService.t('country_name'),
                  hintText: TranslationService.isArabic
                      ? 'مثال: مصر'
                      : 'e.g. United Kingdom',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                TranslationService.t('cancel'),
                style: TextStyle(
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.white)
                          .withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5C158),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final city = cityController.text.trim();
                final country = countryController.text.trim();
                if (city.isNotEmpty && country.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  // Fetch actual coordinates for the entered city using the native geocoder
                  double? fetchLat;
                  double? fetchLon;
                  try {
                    List<Location> locations = await locationFromAddress(
                      '$city, $country',
                    );
                    if (locations.isNotEmpty) {
                      fetchLat = locations.first.latitude;
                      fetchLon = locations.first.longitude;
                    }
                  } catch (_) {}

                  await widget.storage.setLocation(
                    city,
                    country,
                    fetchLat ?? 30.0444,
                    fetchLon ?? 31.2357,
                    'manual',
                  );
                  navigator.pop();
                  unawaited(_loadPrayerTimes());
                }
              },
              child: Text(TranslationService.t('get_times')),
            ),
          ],
        );
      },
    );
  }

  String _getNextPrayerName() {
    if (_prayerData == null) return '';
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    final prayers = {
      'Fajr': _prayerData!.fajr,
      'Sunrise': _prayerData!.sunrise,
      'Dhuhr': _prayerData!.dhuhr,
      'Asr': _prayerData!.asr,
      'Maghrib': _prayerData!.maghrib,
      'Isha': _prayerData!.isha,
    };

    final List<MapEntry<String, DateTime>> todayPrayers = [];
    prayers.forEach((name, timeStr) {
      final cleanTime = timeStr.split(' ')[0];
      try {
        final parsed = DateTime.parse("${todayStr}T$cleanTime:00");
        todayPrayers.add(MapEntry(name, parsed));
      } catch (_) {}
    });

    todayPrayers.sort((a, b) => a.value.compareTo(b.value));

    for (final entry in todayPrayers) {
      if (entry.value.isAfter(now)) {
        return entry.key;
      }
    }
    return 'Fajr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = widget.storage.getLocation();
    return _buildPrayerScreenBody(context, theme, loc);
  }

  Widget _buildSubTabButton(int index, String label, ThemeData theme) {
    final isSelected = _selectedSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSubTab = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5C158) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected
                  ? Colors.black
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(String raw) {
    return formatPrayerTime(
      raw,
      use24h: widget.storage.getBool('use_24h_format', defaultValue: false),
    );
  }

  String _getGregMonthName(int month, bool isArabic) {
    const en = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const ar = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month >= 1 && month <= 12) {
      return isArabic ? ar[month] : en[month];
    }
    return '';
  }

  String _getHijriMonthName(int month, bool isArabic) {
    const en = [
      '',
      'Muharram',
      'Safar',
      "Rabi' I",
      "Rabi' II",
      "Jumada I",
      "Jumada II",
      'Rajab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      "Dhu al-Qi'dah",
      "Dhu al-Hijjah",
    ];
    const ar = [
      '',
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    if (month >= 1 && month <= 12) {
      return isArabic ? ar[month] : en[month];
    }
    return '';
  }

  String _getHijriMonthShort(int month, bool isArabic) {
    const en = [
      '',
      'Muh.',
      'Saf.',
      'Rab. I',
      'Rab. II',
      'Jum. I',
      'Jum. II',
      'Raj.',
      'Sha.',
      'Ram.',
      'Shaw.',
      'Dhu Q.',
      'Dhu H.',
    ];
    const ar = [
      '',
      'محرم',
      'صفر',
      'ربيع ١',
      'ربيع ٢',
      'جمادى ١',
      'جمادى ٢',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    if (month >= 1 && month <= 12) {
      return isArabic ? ar[month] : en[month];
    }
    return '';
  }

  String _getSpanningHijriTitle(int year, int month) {
    final hStart = HijriCalendar.fromDate(DateTime(year, month, 1));
    final hEnd = HijriCalendar.fromDate(DateTime(year, month + 1, 0));
    final isArabic = TranslationService.isArabic;
    final startName = _getHijriMonthName(hStart.hMonth, isArabic);
    final endName = _getHijriMonthName(hEnd.hMonth, isArabic);

    if (hStart.hMonth == hEnd.hMonth) {
      return isArabic
          ? "$startName ${hStart.hYear} هـ"
          : "$startName ${hStart.hYear}";
    }
    if (hStart.hYear == hEnd.hYear) {
      return isArabic
          ? "$startName – $endName ${hEnd.hYear} هـ"
          : "$startName – $endName ${hEnd.hYear}";
    }
    return isArabic
        ? "$startName ${hStart.hYear} هـ – $endName ${hEnd.hYear} هـ"
        : "$startName ${hStart.hYear} – $endName ${hEnd.hYear}";
  }

  String _formatCountdownPill(int days, bool isArabic) {
    if (days == 0) return isArabic ? 'اليوم' : 'Today';
    if (days == 1) return isArabic ? 'غداً' : 'Tomorrow';
    if (days == 2) return isArabic ? 'بعد يومين' : 'in 2 days';
    if (days > 2 && days <= 10)
      return isArabic ? 'بعد $days أيام' : 'in $days days';
    if (days > 10) return isArabic ? 'بعد $days يوم' : 'in $days days';
    return isArabic ? 'انتهت' : 'Passed';
  }

  List<Map<String, dynamic>> _getUpcomingHolyDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hNow = HijriCalendar.fromDate(today);

    final holyEvents = [
      {
        'm': 1,
        'd': 1,
        'ar': 'رأس السنة الهجرية',
        'en': 'Islamic New Year',
        'icon': '🌙',
      },
      {'m': 1, 'd': 9, 'ar': 'تاسوعاء', 'en': "Tasu'a", 'icon': '🕌'},
      {
        'm': 1,
        'd': 10,
        'ar': 'يوم عاشوراء',
        'en': 'Day of Ashura',
        'icon': '🕌',
      },
      {
        'm': 3,
        'd': 12,
        'ar': 'المولد النبوي الشريف',
        'en': 'Mawlid al-Nabi',
        'icon': '🕌',
      },
      {
        'm': 7,
        'd': 1,
        'ar': 'أول شهر رجب',
        'en': 'First Day of Rajab',
        'icon': '🌙',
      },
      {
        'm': 7,
        'd': 2,
        'ar': 'ليلة الرغائب',
        'en': 'Laylat al-Raghaib',
        'icon': '🤲',
      },
      {
        'm': 7,
        'd': 27,
        'ar': 'ليلة الإسراء والمعراج',
        'en': "Isra' and Mi'raj",
        'icon': '🕌',
      },
      {
        'm': 8,
        'd': 1,
        'ar': 'أول شهر شعبان',
        'en': "First Day of Sha'ban",
        'icon': '🌙',
      },
      {
        'm': 8,
        'd': 15,
        'ar': 'ليلة النصف من شعبان',
        'en': "Mid-Sha'ban",
        'icon': '🌕',
      },
      {
        'm': 9,
        'd': 1,
        'ar': 'بداية شهر رمضان المبارك',
        'en': 'Start of Ramadan',
        'icon': '🌙',
      },
      {
        'm': 9,
        'd': 27,
        'ar': 'ليلة القدر (المتحراة)',
        'en': 'Laylat al-Qadr',
        'icon': '🤲',
      },
      {
        'm': 10,
        'd': 1,
        'ar': 'عيد الفطر المبارك',
        'en': 'Eid al-Fitr',
        'icon': '✨',
      },
      {
        'm': 12,
        'd': 1,
        'ar': 'أول ذي الحجة (العشر الأوائل)',
        'en': 'First Day of Dhu al-Hijjah',
        'icon': '🌙',
      },
      {'m': 12, 'd': 9, 'ar': 'يوم عرفة', 'en': 'Day of Arafah', 'icon': '🤲'},
      {
        'm': 12,
        'd': 10,
        'ar': 'عيد الأضحى المبارك',
        'en': 'Eid al-Adha',
        'icon': '🕌',
      },
    ];

    final upcoming = <Map<String, dynamic>>[];
    final isArabic = TranslationService.isArabic;

    for (final ev in holyEvents) {
      final m = ev['m'] as int;
      final d = ev['d'] as int;

      DateTime? gregDate;
      int targetHYear = hNow.hYear;

      for (int yearOffset = 0; yearOffset <= 1; yearOffset++) {
        final candidateHYear = hNow.hYear + yearOffset;
        final hCal = HijriCalendar();
        final candidateDate = hCal.hijriToGregorian(candidateHYear, m, d);
        if (!candidateDate.isBefore(today)) {
          gregDate = candidateDate;
          targetHYear = candidateHYear;
          break;
        }
      }

      if (gregDate != null) {
        final daysDiff = gregDate.difference(today).inDays;
        final hMonthName = _getHijriMonthName(m, isArabic);
        final gMonthName = _getGregMonthName(gregDate.month, isArabic);

        final String dateSubtitle = isArabic
            ? "${gregDate.day} $gMonthName ${gregDate.year} · $d $hMonthName $targetHYear هـ"
            : "${_getGregMonthName(gregDate.month, false)} ${gregDate.day}, ${gregDate.year} · $hMonthName $d, $targetHYear AH";

        final gregDateStr =
            "${gregDate.day.toString().padLeft(2, '0')}-${gregDate.month.toString().padLeft(2, '0')}-${gregDate.year}";

        upcoming.add({
          'title': isArabic ? ev['ar'] : ev['en'],
          'titleAr': ev['ar'],
          'titleEn': ev['en'],
          'icon': ev['icon'],
          'gregDateTime': gregDate,
          'gregDate': gregDateStr,
          'hijriDate': "$d $hMonthName $targetHYear",
          'subtitle': dateSubtitle,
          'key': "${m}_$d",
          'daysRemaining': daysDiff,
        });
      }
    }

    upcoming.sort(
      (a, b) =>
          (a['daysRemaining'] as int).compareTo(b['daysRemaining'] as int),
    );
    return upcoming;
  }

  Widget _buildModernCalendarGrid(ThemeData theme, {required bool forPrayer}) {
    if (_monthlyData == null || _monthlyData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            TranslationService.isArabic
                ? 'جاري تحميل التقويم...'
                : 'Loading calendar...',
          ),
        ),
      );
    }

    final isArabic = TranslationService.isArabic;
    final gregMonthName = _getGregMonthName(_calendarMonth, isArabic);
    final spanningHijri = _getSpanningHijriTitle(_calendarYear, _calendarMonth);

    final firstDayOfMonth = DateTime(_calendarYear, _calendarMonth, 1);
    final daysInCurrentMonth = DateTime(
      _calendarYear,
      _calendarMonth + 1,
      0,
    ).day;
    final leadingPadding = firstDayOfMonth.weekday % 7; // Sunday = 0
    final prevMonthLastDay = DateTime(_calendarYear, _calendarMonth, 0);
    final daysInPrevMonth = prevMonthLastDay.day;

    final List<Map<String, dynamic>> gridCells = [];

    // 1. Leading days (adjacent previous month)
    for (int i = leadingPadding - 1; i >= 0; i--) {
      final dayNum = daysInPrevMonth - i;
      final date = DateTime(
        prevMonthLastDay.year,
        prevMonthLastDay.month,
        dayNum,
      );
      final hijri = HijriCalendar.fromDate(date);
      gridCells.add({
        'date': date,
        'hijri': hijri,
        'gregDay': dayNum.toString(),
        'hijriDay': hijri.hDay.toString(),
        'isCurrentMonth': false,
        'isFirstOfHijriMonth': hijri.hDay == 1,
      });
    }

    // 2. Current month days
    for (int d = 1; d <= daysInCurrentMonth; d++) {
      final date = DateTime(_calendarYear, _calendarMonth, d);
      final hijri = HijriCalendar.fromDate(date);
      gridCells.add({
        'date': date,
        'hijri': hijri,
        'gregDay': d.toString(),
        'hijriDay': hijri.hDay.toString(),
        'isCurrentMonth': true,
        'isFirstOfHijriMonth': hijri.hDay == 1,
      });
    }

    // 3. Trailing days (adjacent next month)
    final remainder = gridCells.length % 7;
    final trailingCount = remainder == 0 ? 0 : 7 - remainder;
    final nextMonth = DateTime(_calendarYear, _calendarMonth + 1, 1);
    for (int d = 1; d <= trailingCount; d++) {
      final date = DateTime(nextMonth.year, nextMonth.month, d);
      final hijri = HijriCalendar.fromDate(date);
      gridCells.add({
        'date': date,
        'hijri': hijri,
        'gregDay': d.toString(),
        'hijriDay': hijri.hDay.toString(),
        'isCurrentMonth': false,
        'isFirstOfHijriMonth': hijri.hDay == 1,
      });
    }

    final weekdayHeadersEn = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final weekdayHeadersAr = [
      'أحد',
      'اثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
      'سبت',
    ];
    final weekdayHeaders = isArabic ? weekdayHeadersAr : weekdayHeadersEn;

    final now = DateTime.now();
    final events = _getHijriEventsForMonth();

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
        child: Column(
          children: [
            // Month Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFFE5C158),
                    size: 26,
                  ),
                  onPressed: _isCalendarLoading ? null : _prevCalendarMonth,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "$gregMonthName $_calendarYear",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spanningHijri,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFFE5C158),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFE5C158),
                    size: 26,
                  ),
                  onPressed: _isCalendarLoading ? null : _nextCalendarMonth,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isCalendarLoading)
              const SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5C158)),
                ),
              )
            else ...[
              // Weekday Headers
              Row(
                children: List.generate(7, (idx) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        weekdayHeaders[idx],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Divider(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
                height: 12,
              ),
              const SizedBox(height: 4),

              // Calendar 7-column Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.84,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 5,
                ),
                itemCount: gridCells.length,
                itemBuilder: (context, idx) {
                  final cell = gridCells[idx];
                  final DateTime date = cell['date'];
                  final HijriCalendar hijri = cell['hijri'];
                  final bool isCurrentMonth = cell['isCurrentMonth'];
                  final bool isFirstOfHijri = cell['isFirstOfHijriMonth'];

                  final bool isToday =
                      isCurrentMonth &&
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  final bool isSelected =
                      isCurrentMonth &&
                      date.year == _selectedCalendarDay.year &&
                      date.month == _selectedCalendarDay.month &&
                      date.day == _selectedCalendarDay.day;

                  final dayStr = date.day.toString().padLeft(2, '0');
                  final monthStr = date.month.toString().padLeft(2, '0');
                  final fullDateFormatted = "$dayStr-$monthStr-${date.year}";
                  final hasEvent = events.any(
                    (e) => e['gregDate'] == fullDateFormatted,
                  );

                  final hijriShortName = _getHijriMonthShort(
                    hijri.hMonth,
                    isArabic,
                  );

                  if (!isCurrentMonth) {
                    return Opacity(
                      opacity: 0.28,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cell['gregDay'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cell['hijriDay'],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedCalendarDay = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE5C158).withValues(alpha: 0.22)
                            : isToday
                            ? const Color(0xFFE5C158).withValues(alpha: 0.10)
                            : (hasEvent
                                  ? const Color(
                                      0xFFE5C158,
                                    ).withValues(alpha: 0.04)
                                  : theme.cardColor.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE5C158)
                              : isToday
                              ? const Color(0xFFE5C158).withValues(alpha: 0.7)
                              : Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.10),
                          width: isSelected ? 2.0 : (isToday ? 1.5 : 1.0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cell['gregDay'],
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isSelected || isToday
                                  ? const Color(0xFFE5C158)
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 1),
                          if (isFirstOfHijri)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                hijriShortName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.0,
                                  color: Color(0xFFE5C158),
                                ),
                              ),
                            )
                          else
                            Text(
                              cell['hijriDay'],
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isSelected || isToday
                                    ? const Color(0xFFE5C158)
                                    : theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.55),
                              ),
                            ),
                          if (hasEvent)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5C158),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayPrayerTimes(ThemeData theme) {
    final isArabic = TranslationService.isArabic;
    final selectedDayStr = _selectedCalendarDay.day.toString().padLeft(2, '0');
    final selectedMonthStr = _selectedCalendarDay.month.toString().padLeft(
      2,
      '0',
    );
    final selectedFullDate =
        "$selectedDayStr-$selectedMonthStr-${_selectedCalendarDay.year}";

    Map<String, dynamic>? selectedDayData;
    if (_monthlyData != null) {
      for (final item in _monthlyData!) {
        final g = item['date']?['gregorian'];
        if (g != null && g['day'] == selectedDayStr) {
          selectedDayData = item;
          break;
        }
      }
    }

    final now = DateTime.now();
    final isToday =
        _selectedCalendarDay.year == now.year &&
        _selectedCalendarDay.month == now.month &&
        _selectedCalendarDay.day == now.day;

    final hijri = HijriCalendar.fromDate(_selectedCalendarDay);
    final hijriMonthName = _getHijriMonthName(hijri.hMonth, isArabic);
    final gregMonthName = _getGregMonthName(
      _selectedCalendarDay.month,
      isArabic,
    );

    final String dateTitle = isArabic
        ? "${_selectedCalendarDay.day} $gregMonthName ${_selectedCalendarDay.year} · ${hijri.hDay} $hijriMonthName ${hijri.hYear} هـ"
        : "${_getGregMonthName(_selectedCalendarDay.month, false)} ${_selectedCalendarDay.day}, ${_selectedCalendarDay.year} · $hijriMonthName ${hijri.hDay}, ${hijri.hYear} AH";

    final events = _getHijriEventsForMonth();
    final dayEvents = events
        .where((e) => e['gregDate'] == selectedFullDate)
        .toList();
    final hasEvent = dayEvents.isNotEmpty;
    final eventTitle = hasEvent ? dayEvents.first['title'] as String : '';

    final timings = selectedDayData?['timings'];

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              children: [
                const Icon(Icons.event, color: Color(0xFFE5C158), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE5C158).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isArabic ? "اليوم" : "Today",
                      style: const TextStyle(
                        color: Color(0xFFE5C158),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),

            if (hasEvent) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE5C158).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🕌', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        eventTitle,
                        style: const TextStyle(
                          color: Color(0xFFE5C158),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFE5C158),
                        size: 20,
                      ),
                      onPressed: () => _showReminderDialog(dayEvents.first),
                      tooltip: isArabic ? "ضبط تذكير" : "Set Reminder",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            if (timings == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    isArabic
                        ? "أوقات الصلاة غير متوفرة لهذا اليوم"
                        : "Prayer timings not loaded for this date",
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ),
              )
            else
              // 6 Prayer Times Strip
              Row(
                children: [
                  _buildMiniPrayerPill(
                    theme,
                    TranslationService.t('fajr'),
                    _fmt(timings['Fajr']),
                    Icons.cloud_queue,
                  ),
                  _buildMiniPrayerPill(
                    theme,
                    TranslationService.t('sunrise'),
                    _fmt(timings['Sunrise']),
                    Icons.wb_sunny_outlined,
                  ),
                  _buildMiniPrayerPill(
                    theme,
                    TranslationService.t('dhuhr'),
                    _fmt(timings['Dhuhr']),
                    Icons.wb_sunny,
                  ),
                  _buildMiniPrayerPill(
                    theme,
                    TranslationService.t('asr'),
                    _fmt(timings['Asr']),
                    Icons.wb_twilight,
                  ),
                  _buildMiniPrayerPill(
                    theme,
                    TranslationService.t('maghrib'),
                    _fmt(timings['Maghrib']),
                    Icons.wb_cloudy_outlined,
                  ),
                  _buildMiniPrayerPill(
                    theme,
                    TranslationService.t('isha'),
                    _fmt(timings['Isha']),
                    Icons.nights_stay,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPrayerPill(
    ThemeData theme,
    String name,
    String time,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
        decoration: BoxDecoration(
          color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
              .withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE5C158), size: 16),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingHolyDays(ThemeData theme) {
    final upcoming = _getUpcomingHolyDays();
    final isArabic = TranslationService.isArabic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              TranslationService.t('upcoming_holy_days'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                letterSpacing: 0.8,
                color: Color(0xFFE5C158),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                isArabic
                    ? "لا توجد مناسبات قادمة مسجلة"
                    : "No upcoming holy days found",
                style: TextStyle(color: theme.disabledColor),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcoming.length > 8 ? 8 : upcoming.length,
            itemBuilder: (context, idx) {
              final ev = upcoming[idx];
              final int days = ev['daysRemaining'];
              final String pillText = _formatCountdownPill(days, isArabic);

              return Card(
                color: theme.cardColor,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.10),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showReminderDialog(ev),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        // Event Emoji Icon Container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE5C158,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              ev['icon'] as String,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ev['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.60),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Countdown Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE5C158,
                            ).withValues(alpha: days == 0 ? 0.9 : 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE5C158),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            pillText,
                            style: TextStyle(
                              color: days == 0
                                  ? Colors.black
                                  : const Color(0xFFE5C158),
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Reminder button
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            color: Color(0xFFE5C158),
                            size: 20,
                          ),
                          onPressed: () => _showReminderDialog(ev),
                          tooltip: isArabic ? "ضبط تذكير" : "Set Reminder",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRawDataTable(ThemeData theme) {
    if (_monthlyData == null || _monthlyData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            TranslationService.isArabic
                ? 'جاري تحميل جدول الصلوات...'
                : 'Loading prayer calendar...',
          ),
        ),
      );
    }

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFE5C158).withValues(alpha: 0.1),
          ),
          columns: [
            DataColumn(
              label: Text(
                TranslationService.isArabic ? 'اليوم' : 'Date',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('fajr'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('sunrise'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('dhuhr'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('asr'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.isArabic ? 'الغروب' : 'Sunset',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('maghrib'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('isha'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: _monthlyData!.map<DataRow>((day) {
            final dateInfo = day['date']['gregorian'];
            final dateStr = dateInfo['day'] ?? '';
            final timings = day['timings'];

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    dateStr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(_fmt(timings['Fajr']))),
                DataCell(Text(_fmt(timings['Sunrise']))),
                DataCell(Text(_fmt(timings['Dhuhr']))),
                DataCell(Text(_fmt(timings['Asr']))),
                DataCell(Text(_fmt(timings['Sunset']))),
                DataCell(Text(_fmt(timings['Maghrib']))),
                DataCell(Text(_fmt(timings['Isha']))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPrayerCalendar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: Icon(
                _showRawPrayerTable
                    ? Icons.calendar_month
                    : Icons.table_chart_outlined,
                size: 18,
                color: const Color(0xFFE5C158),
              ),
              label: Text(
                _showRawPrayerTable
                    ? TranslationService.t('view_calendar')
                    : TranslationService.t('view_table'),
                style: const TextStyle(
                  color: Color(0xFFE5C158),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              onPressed: () {
                setState(() {
                  _showRawPrayerTable = !_showRawPrayerTable;
                });
              },
            ),
          ],
        ),
        if (_showRawPrayerTable)
          _buildRawDataTable(theme)
        else ...[
          _buildModernCalendarGrid(theme, forPrayer: true),
          const SizedBox(height: 14),
          _buildSelectedDayPrayerTimes(theme),
        ],
      ],
    );
  }

  Widget _buildHijriCalendar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernCalendarGrid(theme, forPrayer: false),
        const SizedBox(height: 16),
        _buildUpcomingHolyDays(theme),
      ],
    );
  }

  Widget _buildScheduleRow(
    ThemeData theme,
    String name,
    String time,
    IconData icon,
  ) {
    final cleanTime = _fmt(time);
    final alertKey = 'alert_${name.toLowerCase()}';
    final alertOn = widget.storage.getBool(alertKey, defaultValue: true);
    final displayName = TranslationService.t(name.toLowerCase());
    final isNext = name == _getNextPrayerName();
    final isSunriseOrSunset = name == 'Sunrise' || name == 'Sunset';

    return Card(
      color: isNext
          ? const Color(0xFFE5C158).withValues(alpha: 0.08)
          : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNext
              ? const Color(0xFFE5C158).withValues(alpha: 0.6)
              : Colors.transparent,
          width: isNext ? 1.8 : 0.0,
        ),
      ),
      elevation: isNext ? 4 : 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white)
                        .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFE5C158), size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              cleanTime,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            isSunriseOrSunset
                ? const SizedBox(width: 48)
                : IconButton(
                    icon: Icon(
                      alertOn
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: alertOn
                          ? const Color(0xFFE5C158)
                          : theme.disabledColor,
                      size: 20,
                    ),
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await widget.storage.setBool(alertKey, !alertOn);
                      setState(() {});
                      if (_prayerData != null) {
                        await NotificationService().schedulePrayerAlarms(
                          _prayerData!,
                          widget.storage,
                        );
                      }
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            alertOn
                                ? (TranslationService.isArabic
                                      ? 'تم كتم تنبيهات $displayName'
                                      : '$name notifications muted')
                                : (TranslationService.isArabic
                                      ? 'تم تفعيل تنبيهات $displayName'
                                      : '$name notifications activated'),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
