import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/prayer_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';

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
  int _calcMethod = 2; // ISNA
  int _asrMethod = 0; // Standard (Shafi'i)
  int _selectedSubTab = 0;
  List<dynamic>? _monthlyData;

  int _calendarMonth = DateTime.now().month;
  int _calendarYear = DateTime.now().year;
  bool _isCalendarLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _calcMethod = widget.storage.getInt('calc_method', defaultValue: 2);
    _asrMethod = widget.storage.getInt('asr_method', defaultValue: 0);
    _calendarMonth = DateTime.now().month;
    _calendarYear = DateTime.now().year;
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final loc = widget.storage.getLocation();

      PrayerTimeData data;
      if (loc['source'] == 'default' || loc['latitude'] == 30.0444) {
        data = await ApiService.fetchPrayerTimesByCity(
          city: loc['city'] ?? 'Cairo',
          country: loc['country'] ?? 'Egypt',
          method: _calcMethod,
          school: _asrMethod,
        );
      } else {
        data = await ApiService.fetchPrayerTimes(
          latitude: loc['latitude'],
          longitude: loc['longitude'],
          method: _calcMethod,
          school: _asrMethod,
        );
      }

      final now = DateTime.now();
      List<dynamic> monthlyList = [];
      try {
        if (loc['source'] == 'default' || loc['latitude'] == 30.0444) {
          monthlyList = await ApiService.fetchMonthlyCalendarByCity(
            city: loc['city'] ?? 'Cairo',
            country: loc['country'] ?? 'Egypt',
            method: _calcMethod,
            school: _asrMethod,
            month: now.month,
            year: now.year,
          );
        } else {
          monthlyList = await ApiService.fetchMonthlyCalendar(
            latitude: loc['latitude'],
            longitude: loc['longitude'],
            method: _calcMethod,
            school: _asrMethod,
            month: now.month,
            year: now.year,
          );
        }
      } catch (_) {}

      setState(() {
        _prayerData = data;
        _monthlyData = monthlyList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
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

  Future<void> _loadCalendarData() async {
    setState(() => _isCalendarLoading = true);
    try {
      final loc = widget.storage.getLocation();
      List<dynamic> monthlyList = [];
      if (loc['source'] == 'default' || loc['latitude'] == 30.0444) {
        monthlyList = await ApiService.fetchMonthlyCalendarByCity(
          city: loc['city'] ?? 'Cairo',
          country: loc['country'] ?? 'Egypt',
          method: _calcMethod,
          school: _asrMethod,
          month: _calendarMonth,
          year: _calendarYear,
        );
      } else {
        monthlyList = await ApiService.fetchMonthlyCalendar(
          latitude: loc['latitude'],
          longitude: loc['longitude'],
          method: _calcMethod,
          school: _asrMethod,
          month: _calendarMonth,
          year: _calendarYear,
        );
      }
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
          style: TextStyle(
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              isArabic
                  ? "اختر متى تود تلقي إشعار التذكير لهذا الحدث الإسلامي:"
                  : "Choose when you would like to receive a notification alert for this Islamic event:",
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 16),
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
      title: Text(label, style: TextStyle(fontSize: 14)),
      trailing: Icon(Icons.alarm_add, color: Color(0xFFE5C158), size: 20),
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
    final newCalc = widget.storage.getInt('calc_method', defaultValue: 2);
    final newAsr = widget.storage.getInt('asr_method', defaultValue: 0);
    if (newCalc != _calcMethod || newAsr != _asrMethod) {
      setState(() {
        _calcMethod = newCalc;
        _asrMethod = newAsr;
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
                  style: TextStyle(
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
                      style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white).withOpacity(0.7)),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5C158),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    child: Text(
                      TranslationService.isArabic ? "متابعة" : "Continue",
                      style: TextStyle(color: Colors.black),
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
        final ipLoc = await ApiService.fetchLocationByIP();
        city = ipLoc['city']!;
        country = ipLoc['country']!;
        lat = double.parse(ipLoc['latitude']!);
        lon = double.parse(ipLoc['longitude']!);
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
            style: TextStyle(
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
              SizedBox(height: 12),
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
                style: TextStyle(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white).withOpacity(0.7)),
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
                  // Save coordinates as fallback or mock
                  // For manual inputs, we set fallback coordinates to Cairo or London coordinates,
                  // but the API timingsByCity handles the city name directly
                  await widget.storage.setLocation(
                    city,
                    country,
                    30.0444,
                    31.2357,
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

    return RefreshIndicator(
      onRefresh: _loadPrayerTimes,
      color: const Color(0xFFE5C158),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Settings Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFFE5C158)),
                        SizedBox(width: 8),
                        Text(
                          "Location Settings",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "${TranslationService.t('current_location')}: ${loc['city']}, ${loc['country']}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${TranslationService.isArabic ? 'الطريقة: الإحداثيات' : 'Method: Lat/Lng'} (${loc['latitude']?.toStringAsFixed(4) ?? '--'}, ${loc['longitude']?.toStringAsFixed(4) ?? '--'})",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5C158),
                              foregroundColor: Colors.black,
                            ),
                            icon: Icon(Icons.my_location, size: 18),
                            label: Text(TranslationService.t('use_gps')),
                            onPressed: _updateLocationWithGPS,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFFE5C158)),
                              foregroundColor: const Color(0xFFE5C158),
                            ),
                            icon: Icon(Icons.keyboard, size: 18),
                            label: Text(TranslationService.t('set_manually')),
                            onPressed: _showManualLocationDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Segmented sub-tab bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    _buildSubTabButton(
                      0,
                      TranslationService.isArabic ? 'اليوم' : 'Today',
                      theme,
                    ),
                    _buildSubTabButton(
                      1,
                      TranslationService.isArabic
                          ? 'جدول الصلوات'
                          : 'Prayer Calendar',
                      theme,
                    ),
                    _buildSubTabButton(
                      2,
                      TranslationService.isArabic
                          ? 'التقويم الهجري'
                          : 'Hijri Calendar',
                      theme,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              if (_selectedSubTab == 0) ...[
                // Today
                Text(
                  TranslationService.t('daily_schedule'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE5C158),
                        ),
                      )
                    : _prayerData == null
                    ? Center(
                        child: Text(
                          TranslationService.isArabic
                              ? "لم يتم تحميل مواقيت الصلاة بعد."
                              : "No schedule details loaded.",
                        ),
                      )
                    : Column(
                        children: [
                          _buildScheduleRow(
                            theme,
                            "Fajr",
                            _prayerData!.fajr,
                            Icons.cloud_queue,
                          ),
                          _buildScheduleRow(
                            theme,
                            "Sunrise",
                            _prayerData!.sunrise,
                            Icons.wb_sunny_outlined,
                          ),
                          _buildScheduleRow(
                            theme,
                            "Dhuhr",
                            _prayerData!.dhuhr,
                            Icons.wb_sunny,
                          ),
                          _buildScheduleRow(
                            theme,
                            "Asr",
                            _prayerData!.asr,
                            Icons.wb_twilight,
                          ),
                          _buildScheduleRow(
                            theme,
                            "Sunset",
                            _prayerData!.sunset,
                            Icons.wb_twilight,
                          ),
                          _buildScheduleRow(
                            theme,
                            "Maghrib",
                            _prayerData!.maghrib,
                            Icons.wb_cloudy_outlined,
                          ),
                          _buildScheduleRow(
                            theme,
                            "Isha",
                            _prayerData!.isha,
                            Icons.nights_stay,
                          ),
                        ],
                      ),
              ] else if (_selectedSubTab == 1) ...[
                // Calendar
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE5C158),
                        ),
                      )
                    : _buildPrayerCalendar(theme),
              ] else ...[
                // Hijri
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE5C158),
                        ),
                      )
                    : _buildHijriCalendar(theme),
              ],
            ],
          ),
        ),
      ),
    );
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
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return '--:--';
    final cleanTime = rawTime.split(' ')[0]; // Extract "HH:mm"
    final use24h = widget.storage.getBool(
      'use_24h_format',
      defaultValue: false,
    );
    if (use24h) {
      return cleanTime;
    }

    // Parse "HH:mm" to 12-hour format
    final parts = cleanTime.split(':');
    if (parts.length < 2) return cleanTime;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return cleanTime;

    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    final amPm = isPm
        ? (TranslationService.isArabic ? 'م' : 'PM')
        : (TranslationService.isArabic ? 'ص' : 'AM');
    return '$displayHour:$displayMinute $amPm';
  }

  Widget _buildPrayerCalendar(ThemeData theme) {
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
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFE5C158).withOpacity(0.1),
          ),
          columns: [
            DataColumn(
              label: Text(
                TranslationService.isArabic ? 'اليوم' : 'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('fajr'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('sunrise'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('dhuhr'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('asr'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.isArabic ? 'الغروب' : 'Sunset',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('maghrib'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                TranslationService.t('isha'),
                style: TextStyle(fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(_formatTime(timings['Fajr']))),
                DataCell(Text(_formatTime(timings['Sunrise']))),
                DataCell(Text(_formatTime(timings['Dhuhr']))),
                DataCell(Text(_formatTime(timings['Asr']))),
                DataCell(Text(_formatTime(timings['Sunset']))),
                DataCell(Text(_formatTime(timings['Maghrib']))),
                DataCell(Text(_formatTime(timings['Isha']))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHijriCalendar(ThemeData theme) {
    if (_monthlyData == null || _monthlyData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            TranslationService.isArabic
                ? 'جاري تحميل التقويم الهجري...'
                : 'Loading Hijri calendar...',
          ),
        ),
      );
    }

    final firstDay = _monthlyData!.first;

    final gregMonthName = firstDay['date']['gregorian']['month']['en'] ?? '';
    final gregYear = firstDay['date']['gregorian']['year'] ?? '';

    final hijriMonthName = TranslationService.isArabic
        ? (firstDay['date']['hijri']['month']['ar'] ?? '')
        : (firstDay['date']['hijri']['month']['en'] ?? '');
    final hijriYear = firstDay['date']['hijri']['year'] ?? '';

    final firstDayDateStr = firstDay['date']['gregorian']['date'] as String;
    final parts = firstDayDateStr.split('-');
    final fYear = int.parse(parts[2]);
    final fMonth = int.parse(parts[1]);
    final fDay = int.parse(parts[0]);
    final firstDayDateTime = DateTime(fYear, fMonth, fDay);
    final startWeekday = firstDayDateTime.weekday; // 1 = Mon, 7 = Sun

    final daysOfWeekAr = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final daysOfWeekEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayHeaders = TranslationService.isArabic
        ? daysOfWeekAr
        : daysOfWeekEn;

    final List<Widget> gridItems = [];

    final paddingCellsCount = startWeekday - 1;
    for (int i = 0; i < paddingCellsCount; i++) {
      gridItems.add(SizedBox.shrink());
    }

    final now = DateTime.now();
    final todayDayStr = now.day.toString().padLeft(2, '0');
    final todayMonthStr = now.month.toString().padLeft(2, '0');
    final todayYearStr = now.year.toString();
    final todayFormatted = "$todayDayStr-$todayMonthStr-$todayYearStr";

    final events = _getHijriEventsForMonth();

    for (final day in _monthlyData!) {
      final gregDay = day['date']['gregorian']['day'] ?? '';
      final hijriDay = day['date']['hijri']['day'] ?? '';
      final fullDate = day['date']['gregorian']['date'] as String;
      final isToday = fullDate == todayFormatted;

      final dayEvents = events.where((e) => e['gregDate'] == fullDate).toList();
      final hasEvent = dayEvents.isNotEmpty;
      final eventTitle = hasEvent ? dayEvents.first['title'] as String : '';

      gridItems.add(
        InkWell(
          onTap: hasEvent
              ? () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Color(0xFFE5C158)),
                      ),
                      title: Text(
                        TranslationService.isArabic ? 'حدث إسلامي' : 'Islamic Event',
                        style: TextStyle(color: Color(0xFFE5C158)),
                      ),
                      content: Text(
                        eventTitle,
                        style: TextStyle(fontSize: 18),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(TranslationService.isArabic ? 'حسناً' : 'OK', style: TextStyle(color: Color(0xFFE5C158))),
                        )
                      ],
                    ),
                  );
                }
              : null,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFFE5C158).withOpacity(0.15)
                  : (hasEvent ? const Color(0xFFE5C158).withOpacity(0.05) : theme.cardColor.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFE5C158)
                    : (hasEvent ? const Color(0xFFE5C158).withOpacity(0.5) : Theme.of(context).dividerColor.withOpacity(0.1)),
                width: isToday || hasEvent ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 4,
                  child: Text(
                    gregDay,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hijriDay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? const Color(0xFFE5C158)
                              : theme.textTheme.bodyLarge?.color,
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
              ],
            ),
          ),
        ),
      );
    }



    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: Color(0xFFE5C158),
                  ),
                  onPressed: _isCalendarLoading ? null : _prevCalendarMonth,
                ),
                Expanded(
                  child: Text(
                    "$gregMonthName $gregYear  /  $hijriMonthName $hijriYear",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFE5C158),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: Color(0xFFE5C158),
                  ),
                  onPressed: _isCalendarLoading ? null : _nextCalendarMonth,
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_isCalendarLoading)
              SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5C158)),
                ),
              )
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.5,
                ),
                itemCount: 7,
                itemBuilder: (context, idx) {
                  return Center(
                    child: Text(
                      weekdayHeaders[idx],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Divider(color: Theme.of(context).dividerColor.withOpacity(0.12), height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                ),
                itemCount: gridItems.length,
                itemBuilder: (context, idx) {
                  return gridItems[idx];
                },
              ),
              if (events.isNotEmpty) ...[
                SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor.withOpacity(0.12)),
                SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    TranslationService.isArabic
                        ? "المناسبات الهجرية"
                        : "Islamic Events",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C158),
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Column(
                  children: events.map((event) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        event['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        "${event['hijriDate']} (${event['gregDate']})",
                        style: TextStyle(
                          fontSize: 11,
                          color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white).withOpacity(0.38),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFFE5C158),
                          size: 20,
                        ),
                        onPressed: () => _showReminderDialog(event),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(
    ThemeData theme,
    String name,
    String time,
    IconData icon,
  ) {
    final cleanTime = _formatTime(time);
    final alertKey = 'alert_${name.toLowerCase()}';
    final alertOn = widget.storage.getBool(alertKey, defaultValue: true);
    final displayName = TranslationService.t(name.toLowerCase());
    final isNext = name == _getNextPrayerName();
    final isSunriseOrSunset = name == 'Sunrise' || name == 'Sunset';

    return Card(
      color: isNext
          ? const Color(0xFFE5C158).withOpacity(0.08)
          : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNext
              ? const Color(0xFFE5C158).withOpacity(0.6)
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
                color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFE5C158), size: 18),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              cleanTime,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 16),
            isSunriseOrSunset
                ? SizedBox(width: 48)
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
