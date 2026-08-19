import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/audio_manager.dart';
import '../models/prayer_models.dart';
import '../widgets/audio_player_overlay.dart';
import '../widgets/islamic_logo_painter.dart';
import 'dashboard_screen.dart';
import 'quran_screen.dart';
import 'hadith_screen.dart';
import 'prayer_times_screen.dart';
import 'azkar_screen.dart';
import 'settings/settings_screen.dart';
import 'surah_reader/surah_pager_screen.dart';
import 'quran_download_screen.dart';
import 'bookmarks_screen.dart';
import 'tajweed_guide_screen.dart';

class MainScaffold extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onThemeChanged;

  const MainScaffold({
    super.key,
    required this.storage,
    required this.onThemeChanged,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentTab = 0;
  int _azkarInitialTab = 0;
  int _prayerInitialTab = 0;
  int? _hadithInitialNumber;
  String? _hadithInitialBookId;
  Timer? _focusTimer;
  Timer? _autoLockTimer;
  int _focusTimeRemaining = 0;
  bool _isFocusOverlayShowing = false;
  late AnimationController _pulseController;
  DateTime? _lastPressedAt;
  StreamSubscription<String?>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastBookmark();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _autoLockTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkAutoStartFocusLock();
    });

    _applyWakeLockOnLaunch();

    _notificationSubscription = NotificationService
        .selectNotificationStream
        .stream
        .listen((payload) {
          if (payload == null) return;
          if (payload == 'prayer_times') {
            setState(() {
              _currentTab = 2;
            });
          } else if (payload == 'azkar_morning') {
            setState(() {
              _azkarInitialTab = 0;
              _currentTab = 3;
            });
          } else if (payload == 'azkar_evening') {
            setState(() {
              _azkarInitialTab = 1;
              _currentTab = 3;
            });
          } else if (payload.startsWith('quran_verse')) {
            setState(() {
              _currentTab = 1;
            });

            final parts = payload.split(':');
            if (parts.length >= 3) {
              final surahNum = int.tryParse(parts[1]);
              final ayahNum = int.tryParse(parts[2]);
              if (surahNum != null && ayahNum != null) {
                _navigateToSpecificVerse(surahNum, ayahNum);
              }
            }
          }
        });

    _rescheduleAllAlarms();
    _fetchLocationOnOpen();
  }

  Future<void> _fetchLocationOnOpen() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
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
          throw Exception('GPS position unavailable');
        }

        await widget.storage.setLocation(city, country, lat, lon, 'gps');
        final method = widget.storage.getInt('calc_method', defaultValue: 2);
        final school = widget.storage.getInt('asr_method', defaultValue: 0);
        final prayerData = await ApiService.fetchPrayerTimes(
          latitude: lat,
          longitude: lon,
          method: method,
          school: school,
        );
        await NotificationService().schedulePrayerAlarms(
          prayerData,
          widget.storage,
        );
      }
    } catch (_) {}
  }

  Future<void> _applyWakeLockOnLaunch() async {
    final keepAwake = widget.storage.getBool(
      'keep_screen_awake',
      defaultValue: false,
    );
    if (keepAwake) {
      try {
        const platform = MethodChannel('com.quran.aya/system');
        await platform.invokeMethod('setKeepScreenOn', {'enabled': true});
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    _autoLockTimer?.cancel();
    _pulseController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAlarmPermissionChange();
      _loadLastBookmark();
    }
  }

  Future<void> _checkAlarmPermissionChange() async {
    final wasJustGranted = widget.storage.getBool(
      'alarm_permission_just_granted',
      defaultValue: false,
    );
    if (wasJustGranted) {
      await widget.storage.setBool('alarm_permission_just_granted', false);
      await _rescheduleAllAlarms();
    }
  }

  Future<void> _rescheduleAllAlarms() async {
    try {
      final loc = widget.storage.getLocation();
      final method = widget.storage.getInt('calc_method', defaultValue: 2);
      final school = widget.storage.getInt('asr_method', defaultValue: 0);

      final PrayerTimeData data = await ApiService.fetchPrayerTimes(
        latitude: loc['latitude'] ?? 30.0444,
        longitude: loc['longitude'] ?? 31.2357,
        method: method,
        school: school,
      );
      await NotificationService().schedulePrayerAlarms(data, widget.storage);
    } catch (_) {}
  }

  Future<void> _loadLastBookmark() async {
    // DashboardScreen fetches it directly
  }

  void _checkAutoStartFocusLock() {
    final autoStart = widget.storage.getBool(
      'focus_auto_start',
      defaultValue: false,
    );
    final duration = widget.storage.getInt(
      'focus_lock_duration',
      defaultValue: 0,
    );
    if (!autoStart || duration <= 0 || _focusTimeRemaining > 0) return;

    final nowStr = DateTime.now().toIso8601String().substring(11, 16);

    for (final key in [
      'widget_prayer_fajr',
      'widget_prayer_dhuhr',
      'widget_prayer_asr',
      'widget_prayer_maghrib',
      'widget_prayer_isha',
    ]) {
      if (nowStr == widget.storage.getString(key).split(' ')[0]) {
        startFocusLock(duration);
        return;
      }
    }
  }

  void startFocusLock(int minutes) {
    if (minutes <= 0) return;
    _focusTimer?.cancel();
    _pulseController.repeat(reverse: true);
    setState(() {
      _focusTimeRemaining = minutes * 60;
      _isFocusOverlayShowing = true;
    });

    final lockType = widget.storage.getString(
      'focus_lock_type',
      defaultValue: 'app_only',
    );
    if (lockType == 'whole_phone') {
      try {
        const platform = MethodChannel('com.quran.aya/system');
        platform.invokeMethod('startLockTask');
      } catch (_) {}
    }

    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_focusTimeRemaining <= 1) {
        timer.cancel();
        _pulseController.stop();

        final lt = widget.storage.getString(
          'focus_lock_type',
          defaultValue: 'app_only',
        );
        if (lt == 'whole_phone') {
          try {
            const platform = MethodChannel('com.quran.aya/system');
            platform.invokeMethod('stopLockTask');
          } catch (_) {}
        }

        setState(() {
          _focusTimeRemaining = 0;
          _isFocusOverlayShowing = false;
        });
      } else {
        setState(() {
          _focusTimeRemaining--;
        });
      }
    });
  }

  String _formatFocusTime() {
    final minutes = (_focusTimeRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_focusTimeRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _bypassFocusLock() {
    _focusTimer?.cancel();
    _pulseController.stop();

    final lockType = widget.storage.getString(
      'focus_lock_type',
      defaultValue: 'app_only',
    );
    if (lockType == 'whole_phone') {
      try {
        const platform = MethodChannel('com.quran.aya/system');
        platform.invokeMethod('stopLockTask');
      } catch (_) {}
    }

    setState(() {
      _focusTimeRemaining = 0;
      _isFocusOverlayShowing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationService.isArabic
              ? "تم تجاوز قفل التركيز"
              : "Focus Lock Bypassed",
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _navigateToSpecificVerse(int surahNum, int ayahNum) async {
    try {
      final surahs = await ApiService.fetchSurahList();
      final surah = surahs.firstWhere((s) => s.number == surahNum);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahPagerScreen(
              initialSurah: surah,
              storage: widget.storage,
              initialAyahNumber: ayahNum,
            ),
          ),
        );
        await _loadLastBookmark();
      }
    } catch (_) {}
  }

  void _navigateToBookmark() async {
    final bookmarks = await widget.storage.getBookmarks();
    if (bookmarks.isEmpty) return;

    final lastBookmark = bookmarks.first;
    final surahNum = lastBookmark['surahNumber'] as int;
    final ayahNum = lastBookmark['ayahNumber'] as int;

    setState(() {
      _currentTab = 1;
    });

    try {
      final surahs = await ApiService.fetchSurahList();
      final surah = surahs.firstWhere((s) => s.number == surahNum);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahPagerScreen(
              initialSurah: surah,
              storage: widget.storage,
              initialAyahNumber: ayahNum,
            ),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? 'فشل تحميل الإشارة المرجعية: $e'
                  : 'Failed to load bookmark: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();
    final theme = Theme.of(context);
    final bottomNavbarStyle = widget.storage.getString(
      'bottom_navbar_style',
      defaultValue: 'floating',
    );

    final List<Widget> screens = [
      DashboardScreen(
        storage: widget.storage,
        onTabChange: (index, {subTab}) {
          int targetTab = index;
          if (index == 2) {
            targetTab = 3;
          } else if (index == 3) {
            targetTab = 4;
          }
          setState(() {
            _currentTab = targetTab;
            if (targetTab == 4 && subTab != null) {
              _azkarInitialTab = subTab;
            } else if (targetTab == 3 && subTab != null) {
              _prayerInitialTab = subTab;
            }
          });
        },
        onContinueReading: _navigateToBookmark,
        onStartFocusLock: (mins) => startFocusLock(mins),
      ),
      QuranScreen(storage: widget.storage),
      HadithScreen(
        storage: widget.storage,
        initialHadithNumber: _hadithInitialNumber,
        initialBookId: _hadithInitialBookId,
      ),
      PrayerTimesScreen(
        storage: widget.storage,
        initialSubTab: _prayerInitialTab,
      ),
      AzkarScreen(storage: widget.storage, initialTabIndex: _azkarInitialTab),
    ];

    final List<String> tabTitles = [
      TranslationService.t('app_title'),
      TranslationService.t('quran'),
      TranslationService.isArabic ? "الحديث الشريف" : "Holy Hadith",
      TranslationService.t('prayer'),
      TranslationService.t('azkar'),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentTab != 0) {
          setState(() {
            _currentTab = 0;
          });
          return;
        }
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                TranslationService.isArabic
                    ? "اضغط مرتين للخروج من التطبيق"
                    : "Press back again to exit",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        await SystemNavigator.pop();
      },
      child: Scaffold(
        extendBody: bottomNavbarStyle == 'floating',
        appBar: AppBar(
          title: Text(
            tabTitles[_currentTab],
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 18,
            ),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          actions: [
            if (_currentTab == 1)
              IconButton(
                icon: const Icon(Icons.download_for_offline),
                tooltip: TranslationService.isArabic
                    ? 'إدارة التحميلات'
                    : 'Downloads',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QuranDownloadScreen(storage: widget.storage),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.bookmarks),
              tooltip: TranslationService.isArabic
                  ? 'العلامات المرجعية'
                  : 'Bookmarks',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookmarksScreen(storage: widget.storage),
                  ),
                );

                if (result != null && result is Map) {
                  if (result['tab'] != null) {
                    setState(() {
                      _currentTab = result['tab'];
                      if (result['tab'] == 2) {
                        _hadithInitialNumber = result['hadithNumber'];
                        _hadithInitialBookId = result['bookId'];
                      }
                    });
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      storage: widget.storage,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ValueListenableBuilder<AudioPlayState>(
          valueListenable: AudioManager.instance.playState,
          builder: (context, audioState, child) {
            return Stack(
              children: [
                IndexedStack(index: _currentTab, children: screens),
                if (_currentTab == 1)
                  AudioPlayerOverlay(
                    bottomPosition: bottomNavbarStyle == 'floating'
                        ? 16.0 + MediaQuery.of(context).padding.bottom
                        : kBottomNavigationBarHeight +
                            MediaQuery.of(context).padding.bottom +
                            8.0,
                    isDark: isDark,
                    theme: theme,
                  ),
                if (_isFocusOverlayShowing)
                  Positioned.fill(
                    child: PopScope(
                      canPop: false,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF041A16), Color(0xFF000806)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 32.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(),
                                ScaleTransition(
                                  scale: Tween<double>(begin: 0.92, end: 1.08)
                                      .animate(
                                        CurvedAnimation(
                                          parent: _pulseController,
                                          curve: Curves.easeInOutCubic,
                                        ),
                                      ),
                                  child: FadeTransition(
                                    opacity: Tween<double>(begin: 0.7, end: 1.0)
                                        .animate(
                                          CurvedAnimation(
                                            parent: _pulseController,
                                            curve: Curves.easeInOutCubic,
                                          ),
                                        ),
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE5C158)
                                                .withValues(alpha: 0.15),
                                            blurRadius: 40,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CustomPaint(
                                        painter: IslamicLogoPainter(
                                          animationValue:
                                              _pulseController.value,
                                          color: const Color(0xFFE5C158),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48),
                                Text(
                                  TranslationService.t('focus_active'),
                                  style: const TextStyle(
                                    color: Color(0xFFE5C158),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _formatFocusTime(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Text(
                                    TranslationService.t('focus_warning'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onDoubleTap: _bypassFocusLock,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      TranslationService.t('focus_bypass'),
                                      style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: () {
          final bottomBarWidget = BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) {
              setState(() {
                _currentTab = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            backgroundColor: bottomNavbarStyle == 'floating'
                ? Colors.transparent
                : theme.bottomNavigationBarTheme.backgroundColor,
            elevation: bottomNavbarStyle == 'floating' ? 0 : null,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: TranslationService.t('home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_outlined),
                activeIcon: const Icon(Icons.menu_book),
                label: TranslationService.t('quran'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.import_contacts_outlined),
                activeIcon: const Icon(Icons.import_contacts),
                label: TranslationService.isArabic ? "الحديث" : "Hadith",
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.access_time),
                activeIcon: const Icon(Icons.access_time_filled),
                label: TranslationService.t('prayer'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.volunteer_activism_outlined),
                activeIcon: const Icon(Icons.volunteer_activism),
                label: TranslationService.t('azkar'),
              ),
            ],
          );
          if (bottomNavbarStyle == 'floating') {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16.0,
                0.0,
                16.0,
                16.0 + MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(28.0),
                        border: Border.all(
                          color: const Color(0xFFE5C158).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Theme(
                        data: theme.copyWith(canvasColor: Colors.transparent),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeBottom: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28.0),
                            child: bottomBarWidget,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return bottomBarWidget;
        }(),
      ),
    );
  }
}
