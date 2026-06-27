import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prayer_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../services/quran_verses.dart';
import 'qibla_screen.dart';
import 'tasbih_screen.dart';

class DashboardScreen extends StatefulWidget {
  final StorageService storage;
  final Function(int, {int? subTab}) onTabChange;
  final Map<String, dynamic> lastBookmark;
  final VoidCallback onContinueReading;
  final Function(int) onStartFocusLock;

  const DashboardScreen({
    super.key,
    required this.storage,
    required this.onTabChange,
    required this.lastBookmark,
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
  Timer? _timer;
  Map<String, dynamic>? _lastLoadedLocation;
  int? _lastLoadedCalcMethod;
  int? _lastLoadedAsrMethod;
  late PredefinedVerse _randomVerse;

  static const List<Map<String, String>> _versePresets = [
    {'text': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ', 'ref': 'سورة البقرة: ٢٥٥'},
    {'text': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'ref': 'سورة الشرح: ٦'},
    {'text': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'ref': 'سورة الرعد: ٢٨'},
    {'text': 'وَقُلْ رَبِّ زِدْنِي عِلْمًا', 'ref': 'سورة طه: ١١٤'},
    {'text': 'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا', 'ref': 'سورة الأحزاب: ٥٦'},
    {'text': 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ', 'ref': 'سورة غافر: ٦٠'},
    {'text': 'وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا', 'ref': 'سورة الطور: ٤٨'},
    {'text': 'وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ', 'ref': 'سورة الطلاق: ٢-٣'}
  ];

  static const List<String> _dhikrPresets = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ',
    'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    'حَسْبُنَا اللَّهَ وَنِعْمَ الْوَكِيلُ'
  ];

  static const List<Map<String, String>> _hadithPresets = [
    {'text': 'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى', 'ref': 'رواه البخاري ومسلم'},
    {'text': 'الطهور شطر الإيمان، والحمد لله تملأ الميزان', 'ref': 'رواه مسلم'},
    {'text': 'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها', 'ref': 'رواه الترمذي'},
    {'text': 'يسروا ولا تعسروا، وبشروا ولا تنفروا', 'ref': 'رواه البخاري'},
    {'text': 'من سلك طريقًا يلتمس فيه علمًا، سهل الله له به طريقًا إلى الجنة', 'ref': 'رواه مسلم'},
    {'text': 'الدين النصيحة', 'ref': 'رواه مسلم'},
    {'text': 'من كان يؤمن بالله واليوم الآخر فليقل خيرًا أو ليصمت', 'ref': 'رواه البخاري ومسلم'},
    {'text': 'تبسمك في وجه أخيك لك صدقة', 'ref': 'رواه الترمذي'}
  ];

  @override
  void initState() {
    super.initState();
    final randIndex = (DateTime.now().microsecondsSinceEpoch) % QuranVersesData.verses.length;
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

  String _formatTime(String time24h) {
    final clean = time24h.split(' ')[0].trim();
    final use24h = widget.storage.getBool('use_24h_format', defaultValue: false);
    if (use24h) return clean;
    final parts = clean.split(':');
    if (parts.length < 2) return clean;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return clean;
    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    final suffix = isPm 
        ? (TranslationService.isArabic ? "م" : "PM") 
        : (TranslationService.isArabic ? "ص" : "AM");
    return "$displayHour:$displayMinute $suffix";
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

      PrayerTimeData data;
      if (loc['source'] == 'default' || loc['latitude'] == 30.0444) {
        data = await ApiService.fetchPrayerTimesByCity(
          city: loc['city'] ?? 'Cairo',
          country: loc['country'] ?? 'Egypt',
          method: method,
          school: school,
        );
      } else {
        data = await ApiService.fetchPrayerTimes(
          latitude: loc['latitude'],
          longitude: loc['longitude'],
          method: method,
          school: school,
        );
      }

      setState(() {
        _prayerData = data;
        _isLoading = false;
      });
      _calculateNextPrayer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.isArabic ? 'فشل تحميل مواقيت الصلاة: $e' : 'Failed to load prayer times: $e')),
        );
      }
    }
  }

  void _startCountdownTimer() {
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
      final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final cleanFajr = prayers['Fajr']!.split(' ')[0];
      nextPrayerTime = DateTime.parse("${tomorrowStr}T$cleanFajr:00");
      nextPrayerName = 'Fajr';
    }

    setState(() {
      _nextPrayerName = nextPrayerName;
      _nextPrayerCountdown = nextPrayerTime!.difference(now);
    });
    _updateWidgetPreferences();
  }

  String _formatWidgetNextDisplay(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return TranslationService.isArabic ? "بعد $hoursس و $minsد" : "in ${hours}h ${mins}m";
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

    final localizedNextName = TranslationService.t(_nextPrayerName.toLowerCase());
    await setStringIfChanged('widget_next_prayer_name', localizedNextName);

    // Deterministic daily verse & dhikr selection
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    
    final verseIdx = dayOfYear % _versePresets.length;
    final dhikrIdx = dayOfYear % _dhikrPresets.length;
    final hadithIdx = dayOfYear % _hadithPresets.length;

    await setStringIfChanged('widget_verse_text', _versePresets[verseIdx]['text']!);
    await setStringIfChanged('widget_verse_ref', _versePresets[verseIdx]['ref']!);
    await setStringIfChanged('widget_dhikr_text', _dhikrPresets[dhikrIdx]);
    await setStringIfChanged('widget_hadith_text', _hadithPresets[hadithIdx]['text']!);
    await setStringIfChanged('widget_hadith_ref', _hadithPresets[hadithIdx]['ref']!);

    final nextDisplay = _formatWidgetNextDisplay(_nextPrayerCountdown);
    final lastDisplay = prefs.getString('widget_widget_next_display');
    if (nextDisplay != lastDisplay) {
      await prefs.setString('widget_widget_next_display', nextDisplay);
      try {
        const platform = MethodChannel('com.quran.aya/system');
        await platform.invokeMethod('updateWidget');
      } catch (_) {}
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF042F1A), const Color(0xFF02170D)]
                    : [const Color(0xFF0D9488), const Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.t('welcome'),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE5C158) : Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    TranslationService.t('blessed_day'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _randomVerse.getDisplayString(TranslationService.isArabic),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (NotificationService.timezoneFallbackToUtc) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        TranslationService.isArabic
                            ? "فشل تحديد المنطقة الزمنية تلقائياً. تم ضبطها افتراضياً على UTC. قد تكون مواقيت التنبيهات غير دقيقة."
                            : "Auto timezone detection failed. Defaulted to UTC. Alarms might be offset.",
                        style: TextStyle(
                          color: isDark ? Colors.orange[200] : Colors.orange[800],
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

            // Live Countdown Card
            _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Color(0xFFE5C158)),
                  ))
                : _hasError
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
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
                              child: Text(TranslationService.isArabic ? "إعادة المحاولة" : "Retry"),
                            ),
                          ],
                        ),
                      )
                    : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
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
                            color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_nextPrayerCountdown),
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
                            _buildInfoColumn(theme, TranslationService.t('sunrise'), _prayerData?.sunrise ?? "--:--"),
                            _buildInfoColumn(theme, TranslationService.t('fajr'), _prayerData?.fajr ?? "--:--"),
                            _buildInfoColumn(theme, TranslationService.t('sunset'), _prayerData?.sunset ?? "--:--"),
                          ],
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // Quick Actions Title
            Text(
              TranslationService.t('quick_actions'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Quick Actions Grid/List
            Column(
              children: [
                _buildQuickCard(
                  context: context,
                  icon: Icons.bookmark_outline,
                  title: TranslationService.t('continue_reading'),
                  subtitle: widget.lastBookmark.isEmpty 
                      ? TranslationService.t('no_active_bookmark') 
                      : "${TranslationService.isArabic ? 'سورة' : 'Surah'} ${widget.lastBookmark['surahName']} : ${TranslationService.isArabic ? 'الآية' : 'Ayah'} ${widget.lastBookmark['ayahNumber']}",
                  onTap: () {
                    if (widget.lastBookmark.isNotEmpty) {
                      widget.onContinueReading();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(TranslationService.isArabic
                              ? "لا توجد علامة مرجعية بعد. ابدأ القراءة أولاً."
                              : "No bookmark saved yet. Start reading first."),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
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
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.menu_book,
                      title: TranslationService.t('quran'),
                      onTap: () => widget.onTabChange(1),
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.access_time_filled,
                      title: TranslationService.t('prayer'),
                      onTap: () => widget.onTabChange(2, subTab: 0),
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.explore,
                      title: TranslationService.t('qibla'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QiblaScreen(storage: widget.storage)),
                        );
                      },
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.fingerprint,
                      title: TranslationService.t('tasbih'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TasbihScreen(storage: widget.storage)),
                        );
                      },
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.wb_sunny_outlined,
                      title: TranslationService.t('morning_azkar'),
                      onTap: () => widget.onTabChange(3, subTab: 0),
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.nights_stay_outlined,
                      title: TranslationService.t('evening_azkar'),
                      onTap: () => widget.onTabChange(3, subTab: 1),
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.grid_view,
                      title: TranslationService.t('names_of_allah'),
                      onTap: () => widget.onTabChange(3, subTab: 4),
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.calendar_month,
                      title: TranslationService.t('hijri_calendar'),
                      onTap: () => widget.onTabChange(2, subTab: 2),
                    ),
                    _buildGridServiceCard(
                      theme: theme,
                      icon: Icons.table_chart,
                      title: TranslationService.t('prayer_calendar'),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    "${location['city']}, ${location['country']}",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
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
                        _buildPrayerBarCard(theme, TranslationService.t('fajr'), _prayerData?.fajr ?? "--:--", _getCurrentPrayerName() == 'Fajr', Icons.cloud_queue),
                        _buildPrayerBarCard(theme, TranslationService.t('sunrise'), _prayerData?.sunrise ?? "--:--", _getCurrentPrayerName() == 'Sunrise', Icons.wb_sunny_outlined),
                        _buildPrayerBarCard(theme, TranslationService.t('dhuhr'), _prayerData?.dhuhr ?? "--:--", _getCurrentPrayerName() == 'Dhuhr', Icons.wb_sunny),
                        _buildPrayerBarCard(theme, TranslationService.t('asr'), _prayerData?.asr ?? "--:--", _getCurrentPrayerName() == 'Asr', Icons.wb_twilight),
                        _buildPrayerBarCard(theme, TranslationService.t('maghrib'), _prayerData?.maghrib ?? "--:--", _getCurrentPrayerName() == 'Maghrib', Icons.wb_cloudy_outlined),
                        _buildPrayerBarCard(theme, TranslationService.t('isha'), _prayerData?.isha ?? "--:--", _getCurrentPrayerName() == 'Isha', Icons.nights_stay),
                      ],
                    ),
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(value),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFE5C158),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                TranslationService.isArabic ? Icons.chevron_left : Icons.chevron_right,
                size: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridServiceCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: theme.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.04),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFE5C158), size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerBarCard(ThemeData theme, String name, String time, bool isCurrent, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFE5C158).withOpacity(0.12) : theme.cardColor,
        border: Border.all(
          color: isCurrent ? const Color(0xFFE5C158).withOpacity(0.5) : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: isCurrent ? const Color(0xFFE5C158) : theme.textTheme.bodyMedium?.color?.withOpacity(0.5), 
            size: 18
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCurrent ? const Color(0xFFE5C158) : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
extension ColorsExtension on Colors {
  static const Color whitee70 = Color(0xB3FFFFFF);
}
