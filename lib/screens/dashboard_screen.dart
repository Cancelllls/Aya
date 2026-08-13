import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prayer_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../widgets/welcome_header.dart';
import '../widgets/grid_service_card.dart';
import '../widgets/prayer_bar_card.dart';
import '../widgets/quick_access_pill.dart';
import '../utils/text_helpers.dart';
import '../services/notification_service.dart';
import 'qibla_screen.dart';
import 'tasbih_screen.dart';
import '../services/quran_verses.dart';
import 'prayer_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  final StorageService storage;
  final Function(int, {int? subTab}) onTabChange;
  final VoidCallback onContinueReading;
  final Function(int) onStartFocusLock;

  const DashboardScreen({
    super.key,
    required this.storage,
    required this.onTabChange,
    required this.onContinueReading,
    required this.onStartFocusLock,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PrayerTimeData? _prayerData;
  bool _isLoading = true;
  bool _hasError = false;
  String _nextPrayerName = '-';
  Duration _nextPrayerCountdown = Duration.zero;
  DateTime? _nextPrayerTime;
  Timer? _timer;
  Map<String, dynamic>? _lastLoadedLocation;
  int? _lastLoadedCalcMethod;
  int? _lastLoadedAsrMethod;
  late PredefinedVerse _randomVerse;

  static const List<Map<String, String>> _versePresets = [
    {
      'text':
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
      'ref': 'سورة البقرة: ٢٥٥',
    },
    {'text': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'ref': 'سورة الشرح: ٦'},
    {
      'text': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'ref': 'سورة الرعد: ٢٨',
    },
    {'text': 'وَقُلْ رَبِّ زِدْنِي عِلْمًا', 'ref': 'سورة طه: ١١٤'},
    {
      'text':
          'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
      'ref': 'سورة الأحزاب: ٥٦',
    },
    {
      'text': 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
      'ref': 'سورة غافر: ٦٠',
    },
    {
      'text': 'وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا',
      'ref': 'سورة الطور: ٤٨',
    },
    {
      'text':
          'وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
      'ref': 'سورة الطلاق: ٢-٣',
    },
  ];

  static const List<String> _dhikrPresets = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ',
    'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    'حَسْبُنَا اللَّهَ وَنِعْمَ الْوَكِيلُ',
  ];

  static const List<Map<String, String>> _hadithPresets = [
    {
      'text': 'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى',
      'ref': 'رواه البخاري ومسلم',
    },
    {'text': 'الطهور شطر الإيمان، والحمد لله تملأ الميزان', 'ref': 'رواه مسلم'},
    {
      'text': 'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها',
      'ref': 'رواه الترمذي',
    },
    {'text': 'يسروا ولا تعسروا، وبشروا ولا تنفروا', 'ref': 'رواه البخاري'},
    {
      'text': 'من سلك طريقًا يلتمس فيه علمًا، سهل الله له به طريقًا إلى الجنة',
      'ref': 'رواه مسلم',
    },
    {'text': 'الدين النصيحة', 'ref': 'رواه مسلم'},
    {
      'text': 'من كان يؤمن بالله واليوم الآخر فليقل خيرًا أو ليصمت',
      'ref': 'رواه البخاري ومسلم',
    },
    {'text': 'تبسمك في وجه أخيك لك صدقة', 'ref': 'رواه الترمذي'},
  ];

  @override
  void initState() {
    super.initState();
    final randIndex =
        (DateTime.now().microsecondsSinceEpoch) % QuranVersesData.verses.length;
    _randomVerse = QuranVersesData.verses[randIndex];
    _loadPrayerTimes();
    _startCountdownTimer();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = widget.storage.getLocation();
    final method = widget.storage.getInt('calc_method', defaultValue: 2);
    final school = widget.storage.getInt('asr_method', defaultValue: 0);

    if (_lastLoadedLocation == null ||
        _lastLoadedLocation!['latitude'] != location['latitude'] ||
        _lastLoadedLocation!['longitude'] != location['longitude'] ||
        _lastLoadedLocation!['city'] != location['city'] ||
        _lastLoadedCalcMethod != method ||
        _lastLoadedAsrMethod != school) {
      _loadPrayerTimes();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getCurrentPrayerName() {
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

    final List<MapEntry<String, DateTime>> list = [];
    prayers.forEach((name, timeStr) {
      final cleanTime = timeStr.split(' ')[0];
      try {
        list.add(MapEntry(name, DateTime.parse("${todayStr}T$cleanTime:00")));
      } catch (_) {}
    });

    list.sort((a, b) => a.value.compareTo(b.value));

    for (int i = list.length - 1; i >= 0; i--) {
      if (now.isAfter(list[i].value)) {
        return list[i].key;
      }
    }
    return 'Isha';
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      final loc = widget.storage.getLocation();
      final method = widget.storage.getInt('calc_method', defaultValue: 2);
      final school = widget.storage.getInt('asr_method', defaultValue: 0);

      _lastLoadedLocation = loc;
      _lastLoadedCalcMethod = method;
      _lastLoadedAsrMethod = school;

      PrayerTimeData data = await ApiService.fetchPrayerTimes(
        latitude: loc['latitude'] ?? 30.0444,
        longitude: loc['longitude'] ?? 31.2357,
        method: method,
        school: school,
      );

      setState(() {
        _prayerData = data;
        _isLoading = false;
      });
      await NotificationService().schedulePrayerAlarms(data, widget.storage);
      _calculateNextPrayer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'فشل تحميل مواقيت الصلاة: $e'
                  : 'Failed to load prayer times: $e',
            ),
          ),
        );
      }
    }
  }

  void _startCountdownTimer() {
    // Fire immediately so the countdown never shows 00:00:00
    if (_prayerData != null) _calculateNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prayerData != null) {
        _calculateNextPrayer();
      }
    });
  }

  void _calculateNextPrayer() {
    if (_prayerData == null) return;

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

    DateTime? nextPrayerTime;
    String nextPrayerName = '-';

    // Parse times for today
    List<MapEntry<String, DateTime>> todayPrayers = [];
    prayers.forEach((name, timeStr) {
      // Remove any timezone tags like (EET)
      final cleanTime = timeStr.split(' ')[0];
      final parsed = DateTime.parse("${todayStr}T$cleanTime:00");
      todayPrayers.add(MapEntry(name, parsed));
    });

    // Sort chronologically
    todayPrayers.sort((a, b) => a.value.compareTo(b.value));

    // Find next prayer today
    for (var entry in todayPrayers) {
      if (entry.value.isAfter(now)) {
        nextPrayerTime = entry.value;
        nextPrayerName = entry.key;
        break;
      }
    }

    // If all prayers today have passed, next is Fajr tomorrow
    if (nextPrayerTime == null) {
      final tomorrowStr = now
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      final cleanFajr = prayers['Fajr']!.split(' ')[0];
      nextPrayerTime = DateTime.parse("${tomorrowStr}T$cleanFajr:00");
      nextPrayerName = 'Fajr';
    }

    setState(() {
      _nextPrayerName = nextPrayerName;
      _nextPrayerCountdown = nextPrayerTime!.difference(now);
      _nextPrayerTime = nextPrayerTime;
    });
    _updateWidgetPreferences();
  }

  String _formatWidgetNextDisplay(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return TranslationService.isArabic
          ? "بعد $hoursس و $minsد"
          : "in ${hours}h ${mins}m";
    } else {
      final mins = duration.inMinutes;
      return TranslationService.isArabic ? "بعد $minsد" : "in ${mins}m";
    }
  }

  Future<void> _updateWidgetPreferences() async {
    if (_prayerData == null) return;
    final prefs = widget.storage;

    Future<void> setStringIfChanged(String key, String val) async {
      if (prefs.getString(key) != val) {
        await prefs.setString(key, val);
      }
    }

    await setStringIfChanged('widget_prayer_fajr', _prayerData!.fajr);
    await setStringIfChanged('widget_prayer_dhuhr', _prayerData!.dhuhr);
    await setStringIfChanged('widget_prayer_asr', _prayerData!.asr);
    await setStringIfChanged('widget_prayer_maghrib', _prayerData!.maghrib);
    await setStringIfChanged('widget_prayer_isha', _prayerData!.isha);

    final currentActive = _getCurrentPrayerName();
    await setStringIfChanged('widget_active_prayer', currentActive);
    await prefs.setBool("widget_is_arabic", TranslationService.isArabic);
    await prefs.setBool("widget_is_dark", prefs.isDarkMode());
    await setStringIfChanged(
      "widget_app_name",
      TranslationService.isArabic ? "آية" : "Aya",
    );

    final localizedNextName = TranslationService.t(
      _nextPrayerName.toLowerCase(),
    );
    await setStringIfChanged('widget_next_prayer_name', localizedNextName);

    // Deterministic daily verse & dhikr selection
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;

    final verseIdx = dayOfYear % _versePresets.length;
    final dhikrIdx = dayOfYear % _dhikrPresets.length;
    final hadithIdx = dayOfYear % _hadithPresets.length;

    await setStringIfChanged(
      'widget_verse_text',
      _versePresets[verseIdx]['text']!,
    );
    await setStringIfChanged(
      'widget_verse_ref',
      _versePresets[verseIdx]['ref']!,
    );
    await setStringIfChanged('widget_dhikr_text', _dhikrPresets[dhikrIdx]);
    await setStringIfChanged(
      'widget_hadith_text',
      _hadithPresets[hadithIdx]['text']!,
    );
    await setStringIfChanged(
      'widget_hadith_ref',
      _hadithPresets[hadithIdx]['ref']!,
    );

    // Hijri date
    final hijriDateString =
        "${_prayerData!.hijriDate} ${_prayerData!.hijriMonth} ${_prayerData!.hijriYear}";
    await setStringIfChanged('widget_hijri_date', hijriDateString);

    // Asma ul Husna
    final asmaPresets = [
      {
        'arabic': 'الرَّحْمَنُ',
        'english': 'Ar-Rahman',
        'meaning': 'The Beneficent',
      },
      {
        'arabic': 'الرَّحِيمُ',
        'english': 'Ar-Raheem',
        'meaning': 'The Merciful',
      },
      {
        'arabic': 'الْمَلِكُ',
        'english': 'Al-Malik',
        'meaning': 'The King / Sovereign',
      },
      {
        'arabic': 'الْقُدُّوسُ',
        'english': 'Al-Quddus',
        'meaning': 'The Most Holy',
      },
      {
        'arabic': 'السَّلَامُ',
        'english': 'As-Salam',
        'meaning': 'The Source of Peace',
      },
      {
        'arabic': 'الْمُؤْمِنُ',
        'english': 'Al-Mu\'min',
        'meaning': 'The Infuser of Faith',
      },
      {
        'arabic': 'الْمُهَيْمِنُ',
        'english': 'Al-Muhaymin',
        'meaning': 'The Guardian',
      },
      {'arabic': 'الْعَزِيزُ', 'english': 'Al-Aziz', 'meaning': 'The Mighty'},
      {
        'arabic': 'الْجَبَّارُ',
        'english': 'Al-Jabbar',
        'meaning': 'The Compeller',
      },
      {
        'arabic': 'الْمُتَكَبِّرُ',
        'english': 'Al-Mutakabbir',
        'meaning': 'The Majestic',
      },
      {
        'arabic': 'الْخَالِقُ',
        'english': 'Al-Khaliq',
        'meaning': 'The Creator',
      },
      {
        'arabic': 'الْبَارِئُ',
        'english': 'Al-Bari\'',
        'meaning': 'The Evolver',
      },
      {
        'arabic': 'الْمُصَوِّرُ',
        'english': 'Al-Musawwir',
        'meaning': 'The Fashioner',
      },
      {
        'arabic': 'الْغَفَّارُ',
        'english': 'Al-Ghaffar',
        'meaning': 'The Great Forgiver',
      },
      {
        'arabic': 'الْوَهَّابُ',
        'english': 'Al-Wahhab',
        'meaning': 'The Supreme Bestower',
      },
      {
        'arabic': 'الرَّزَّاقُ',
        'english': 'Ar-Razzaq',
        'meaning': 'The Provider',
      },
      {
        'arabic': 'الْفَتَّاحُ',
        'english': 'Al-Fattah',
        'meaning': 'The Supreme Solver',
      },
      {
        'arabic': 'الْعَلِيمُ',
        'english': 'Al-Alim',
        'meaning': 'The All-Knowing',
      },
      {
        'arabic': 'الْحَكِيمُ',
        'english': 'Al-Hakim',
        'meaning': 'The Perfectly Wise',
      },
      {
        'arabic': 'الْوَدُودُ',
        'english': 'Al-Wadud',
        'meaning': 'The Loving One',
      },
    ];
    final asmaIdx = dayOfYear % asmaPresets.length;
    await setStringIfChanged(
      'widget_asma_arabic',
      asmaPresets[asmaIdx]['arabic']!,
    );
    await setStringIfChanged(
      'widget_asma_english',
      asmaPresets[asmaIdx]['english']!,
    );
    await setStringIfChanged(
      'widget_asma_meaning',
      asmaPresets[asmaIdx]['meaning']!,
    );

    final nextDisplay = _formatWidgetNextDisplay(_nextPrayerCountdown);
    final lastDisplay = prefs.getString('widget_widget_next_display');

    // Save next prayer epoch for combined countdown widget
    if (_nextPrayerTime != null) {
      await prefs.setInt(
        'widget_next_prayer_epoch',
        _nextPrayerTime!.millisecondsSinceEpoch,
      );
    }

    if (nextDisplay != lastDisplay) {
      await prefs.setString('widget_widget_next_display', nextDisplay);
      try {
        const platform = MethodChannel('com.quran.aya/system');
        await platform.invokeMethod('updateWidget');
      } catch (_) {}
    }
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  Widget _pill(ThemeData theme, String label, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFE5C158)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        Text(
          formatPrayerTime(time, use24h: widget.storage.getBool('use_24h_format', defaultValue: false)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.storage.getLocation();
    final isDark = widget.storage.isDarkMode();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Welcome Box
            WelcomeHeader(isDark: isDark, randomVerse: _randomVerse),
            const SizedBox(height: 24),

            if (NotificationService.timezoneFallbackToUtc) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        TranslationService.isArabic
                            ? "فشل تحديد المنطقة الزمنية تلقائياً. تم ضبطها افتراضياً على UTC. قد تكون مواقيت التنبيهات غير دقيقة."
                            : "Auto timezone detection failed. Defaulted to UTC. Alarms might be offset.",
                        style: TextStyle(
                          color: isDark
                              ? Colors.orange[200]
                              : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live Countdown + Prayer Times (self-contained widget)
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFE5C158),
                      ),
                    ),
                  )
                : _hasError
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          TranslationService.isArabic
                              ? "فشل في تحميل مواقيت الصلاة"
                              : "Failed to load prayer times",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5C158),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _loadPrayerTimes,
                          child: Text(
                            TranslationService.isArabic
                                ? "إعادة المحاولة"
                                : "Retry",
                          ),
                        ),
                      ],
                    ),
                  )
                : _prayerData == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border.all(
                        color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor
                              .withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            TranslationService.t('live_countdown'),
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${TranslationService.t('time_until')} ${TranslationService.t(_nextPrayerName.toLowerCase())}",
                          style: TextStyle(
                            color: theme.textTheme.titleMedium?.color
                                ?.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_pad(_nextPrayerCountdown.inHours)}:${_pad(_nextPrayerCountdown.inMinutes.remainder(60))}:${_pad(_nextPrayerCountdown.inSeconds.remainder(60))}',
                          style: const TextStyle(
                            color: Color(0xFFE5C158),
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: theme.dividerColor),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _pill(theme, TranslationService.t('sunrise'), _prayerData!.sunrise, Icons.wb_sunny_outlined),
                            _pill(theme, TranslationService.t('fajr'), _prayerData!.fajr, Icons.cloud_queue),
                            _pill(theme, TranslationService.t('sunset'), _prayerData!.sunset, Icons.wb_twilight),
                          ],
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // Quick Actions Title
            Text(
              TranslationService.t('quick_actions'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Quick Actions Grid/List
            Column(
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: widget.storage.getBookmarks(),
                  builder: (context, snapshot) {
                    final bookmarks = snapshot.data ?? [];
                    final lastBookmark = bookmarks.isNotEmpty
                        ? bookmarks.first
                        : <String, dynamic>{};

                    return QuickAccessPill(
                      theme: theme,
                      icon: Icons.bookmark_outline,
                      title: TranslationService.t('continue_reading'),
                      subtitle: lastBookmark.isEmpty
                          ? TranslationService.t('no_active_bookmark')
                          : "${TranslationService.isArabic ? 'سورة' : 'Surah'} ${lastBookmark['surahName']} : ${TranslationService.isArabic ? 'الآية' : 'Ayah'} ${lastBookmark['ayahNumber']}",
                      onTap: () {
                        if (lastBookmark.isNotEmpty) {
                          widget.onContinueReading();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                TranslationService.isArabic
                                    ? "لا توجد علامة مرجعية بعد. ابدأ القراءة أولاً."
                                    : "No bookmark saved yet. Start reading first.",
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: [
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.menu_book,
                      title: TranslationService.t('quran'),
                      onTap: () => widget.onTabChange(1),
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.access_time_filled,
                      title: TranslationService.t('prayer'),
                      onTap: () => widget.onTabChange(2, subTab: 0),
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.explore,
                      title: TranslationService.t('qibla'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                QiblaScreen(storage: widget.storage),
                          ),
                        );
                      },
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.fingerprint,
                      title: TranslationService.t('tasbih'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TasbihScreen(storage: widget.storage),
                          ),
                        );
                      },
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.wb_sunny_outlined,
                      title: TranslationService.t('morning_azkar'),
                      onTap: () => widget.onTabChange(3, subTab: 0),
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.nights_stay_outlined,
                      title: TranslationService.t('evening_azkar'),
                      onTap: () => widget.onTabChange(3, subTab: 1),
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.track_changes,
                      title: TranslationService.isArabic
                          ? 'متتبع الصلاة'
                          : 'Prayer Tracker',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrayerTrackerScreen(),
                          ),
                        );
                      },
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.calendar_month,
                      title: TranslationService.t('hijri_calendar'),
                      onTap: () => widget.onTabChange(2, subTab: 2),
                    ),
                    GridServiceCard(
                      theme: theme,
                      icon: Icons.date_range,
                      title: TranslationService.isArabic
                          ? 'جدول الصلوات'
                          : 'Prayer Calendar',
                      onTap: () => widget.onTabChange(2, subTab: 1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's schedule Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationService.t('today_schedule'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(start: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      "${location['city']}, ${location['country']}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
                          0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Prayer Grid
            _isLoading
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        PrayerBarCard(
                          theme,
                          TranslationService.t('fajr'),
                          _prayerData?.fajr ?? "--:--",
                          _getCurrentPrayerName() == 'Fajr',
                          Icons.cloud_queue,
                        ),
                        PrayerBarCard(
                          theme,
                          TranslationService.t('sunrise'),
                          _prayerData?.sunrise ?? "--:--",
                          _getCurrentPrayerName() == 'Sunrise',
                          Icons.wb_sunny_outlined,
                        ),
                        PrayerBarCard(
                          theme,
                          TranslationService.t('dhuhr'),
                          _prayerData?.dhuhr ?? "--:--",
                          _getCurrentPrayerName() == 'Dhuhr',
                          Icons.wb_sunny,
                        ),
                        PrayerBarCard(
                          theme,
                          TranslationService.t('asr'),
                          _prayerData?.asr ?? "--:--",
                          _getCurrentPrayerName() == 'Asr',
                          Icons.wb_twilight,
                        ),
                        PrayerBarCard(
                          theme,
                          TranslationService.t('maghrib'),
                          _prayerData?.maghrib ?? "--:--",
                          _getCurrentPrayerName() == 'Maghrib',
                          Icons.wb_cloudy_outlined,
                        ),
                        PrayerBarCard(
                          theme,
                          TranslationService.t('isha'),
                          _prayerData?.isha ?? "--:--",
                          _getCurrentPrayerName() == 'Isha',
                          Icons.nights_stay,
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 85),
          ],
        ),
      ),
    );
  }
}
