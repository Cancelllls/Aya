import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'services/storage_service.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/quran_screen.dart';
import 'widgets/quick_access_pill.dart';
import 'widgets/audio_player_overlay.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/hadith_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/surah_reader_screen.dart';
import 'screens/quran_download_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'package:dorar_hadith_flutter/dorar_hadith_flutter.dart';
import 'services/api_service.dart';
import 'services/audio_manager.dart';
import 'theme/app_colors.dart';
import 'widgets/islamic_logo_painter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'models/prayer_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDir = await getApplicationSupportDirectory();
  final dbDir = Directory('${supportDir.path}/dorar_databases');
  if (!dbDir.existsSync()) {
    dbDir.createSync(recursive: true);
  }

  // Workaround for dorar_hadith package bug where CacheDatabase tries to use Directory.current
  Directory.current = dbDir.path;

  await DorarHadithFlutter.ensureInitialized(databaseDirectory: dbDir);

  // Migrate huge caches from SharedPreferences to Files to fix startup memory lag
  await ApiService.migrateCacheToFiles();

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  final storage = await StorageService.getInstance();
  TranslationService.setLanguage(
    storage.getString('lang_code', defaultValue: 'ar'),
  );

  // Initialize Notification Service
  final notifications = NotificationService();
  await notifications.init();

  // Initialize Audio Manager
  AudioManager.instance.init(storage);

  // Preload fonts for faster rendering of Quran and Tafsir
  try {
    GoogleFonts.amiri();
    await GoogleFonts.pendingFonts();
  } catch (e) {
    // Ignore offline font loading errors
  }

  runApp(AyaApp(storage: storage));
}

class AyaApp extends StatefulWidget {
  final StorageService storage;

  const AyaApp({super.key, required this.storage});

  @override
  State<AyaApp> createState() => _AyaAppState();
}

class _AyaAppState extends State<AyaApp> {
  String _activeTheme = 'dark';
  String _langCode = 'ar';

  @override
  void initState() {
    super.initState();
    _activeTheme = widget.storage.getString(
      'theme_preset',
      defaultValue: 'dark',
    );
    _langCode = widget.storage.getString('lang_code', defaultValue: 'ar');
    TranslationService.setLanguage(_langCode);
  }

  void _updateTheme() {
    setState(() {
      _activeTheme = widget.storage.getString(
        'theme_preset',
        defaultValue: 'dark',
      );
      _langCode = widget.storage.getString('lang_code', defaultValue: 'ar');
      TranslationService.setLanguage(_langCode);
    });
  }

  ThemeData _getThemeData(String themeName) {
    switch (themeName) {
      case 'light':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAF9F5),
          primaryColor: AppColors.teal,
          cardColor: Colors.white,
          canvasColor: Colors.white,
          chipTheme: const ChipThemeData(backgroundColor: Color(0xFFF1F5F9)),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(color: Color(0xFF64748B)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.teal,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFFB45309)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFFB45309),
            unselectedItemColor: Color(0xFF94A3B8),
            elevation: 8,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          dividerColor: const Color(0xFFE2E8F0),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB45309), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      case 'sepia':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4ECD8),
          primaryColor: const Color(0xFF8C5A2B),
          cardColor: const Color(0xFFFDF6E3),
          canvasColor: const Color(0xFFFDF6E3),
          chipTheme: const ChipThemeData(backgroundColor: Color(0xFFEBE0C5)),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFF4A3B2C),
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(color: Color(0xFF7A6451)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4ECD8),
            foregroundColor: Color(0xFF8C5A2B),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF8C5A2B)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFDF6E3),
            selectedItemColor: Color(0xFF8C5A2B),
            unselectedItemColor: Color(0xFFB09D8A),
            elevation: 8,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFFFDF6E3),
          ),
          dividerColor: const Color(0xFFEBE0C5),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD3C5A8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD3C5A8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8C5A2B), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFDF6E3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      case 'black':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: AppColors.gold,
          cardColor: const Color(0xFF0D0D0D),
          canvasColor: const Color(0xFF0D0D0D),
          chipTheme: const ChipThemeData(backgroundColor: Color(0xFF262626)),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(color: Color(0xFFA3A3A3)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: AppColors.gold,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.gold),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: Color(0xFF525252),
            elevation: 8,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1A1A1A),
          ),
          dividerColor: const Color(0xFF262626),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      case 'dark_monet':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1211),
          primaryColor: const Color(0xFF14B8A6),
          cardColor: const Color(0xFF161F1E),
          canvasColor: const Color(0xFF161F1E),
          chipTheme: const ChipThemeData(backgroundColor: Color(0xFF233331)),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFFF2F4F3),
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(color: Color(0xFF869A96)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D1211),
            foregroundColor: Color(0xFF14B8A6),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF14B8A6)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0F1514),
            selectedItemColor: Color(0xFF14B8A6),
            unselectedItemColor: Color(0xFF4C5D5A),
            elevation: 8,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1D2927),
          ),
          dividerColor: const Color(0xFF233331),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D4341)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D4341)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF161F1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      case 'white_monet':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF2F6F4),
          primaryColor: AppColors.teal,
          cardColor: Colors.white,
          canvasColor: Colors.white,
          chipTheme: const ChipThemeData(backgroundColor: Color(0xFFE2E8F0)),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFF1F2927),
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(color: Color(0xFF5A7571)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF2F6F4),
            foregroundColor: AppColors.teal,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.teal),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.teal,
            unselectedItemColor: Color(0xFF94A3B8),
            elevation: 8,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          dividerColor: const Color(0xFFE2E8F0),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB2CFCA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB2CFCA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      case 'dark':
      default:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF07090E),
          primaryColor: AppColors.teal,
          cardColor: const Color(0xFF111520),
          canvasColor: const Color(0xFF111520),
          chipTheme: const ChipThemeData(backgroundColor: Color(0xFF1E293B)),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF07090E),
            foregroundColor: AppColors.gold,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.gold),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0D101A),
            selectedItemColor: AppColors.gold,
            unselectedItemColor: Color(0xFF475569),
            elevation: 8,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF161C2C),
          ),
          dividerColor: const Color(0xFF1E293B),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A3A55)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A3A55)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF111520),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeData(_activeTheme).copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
    return MaterialApp(
      title: 'Aya - Islamic App',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      locale: Locale(TranslationService.currentLanguage),
      supportedLocales: [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TranslationService.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SplashScreen(storage: widget.storage, onThemeChanged: _updateTheme),
    );
  }
}

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

    const platform = MethodChannel('com.quran.aya/system');
    platform.setMethodCallHandler((call) async {
      final gesture = widget.storage.getString(
        'athan_stop_gesture',
        defaultValue: 'both',
      );
      if (gesture == 'none') return;
      if (call.method == 'volumeKeyPressed') {
        if (gesture == 'both' || gesture == 'volume_only') {
          NotificationService.stopActiveAthan();
        }
      } else if (call.method == 'phoneFlippedFaceDown') {
        if (gesture == 'both' || gesture == 'flip_only') {
          NotificationService.stopActiveAthan();
        }
      }
    });

    _notificationSubscription = NotificationService
        .selectNotificationStream
        .stream
        .listen((payload) {
          if (payload == null) return;
          if (payload == 'prayer_times') {
            setState(() {
              _currentTab = 2; // Switch to Prayer Times tab
            });
          } else if (payload == 'azkar_morning') {
            setState(() {
              _azkarInitialTab = 0; // Morning sub-tab
              _currentTab = 3; // Azkar tab
            });
          } else if (payload == 'azkar_evening') {
            setState(() {
              _azkarInitialTab = 1; // Evening sub-tab
              _currentTab = 3; // Azkar tab
            });
          } else if (payload.startsWith('quran_verse')) {
            // Switch to Quran tab
            setState(() {
              _currentTab = 1;
            });

            // If payload contains specific surah:ayah (e.g. quran_verse:2:255)
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
    // Only used for initial load or debug if needed, no longer strictly necessary
    // to maintain _lastBookmark state as DashboardScreen fetches it directly.
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

    final nowStr = DateTime.now().toIso8601String().substring(
      11,
      16,
    ); // "HH:mm"

    final fajr = widget.storage.getString('widget_prayer_fajr').split(' ')[0];
    final dhuhr = widget.storage.getString('widget_prayer_dhuhr').split(' ')[0];
    final asr = widget.storage.getString('widget_prayer_asr').split(' ')[0];
    final maghrib = widget.storage
        .getString('widget_prayer_maghrib')
        .split(' ')[0];
    final isha = widget.storage.getString('widget_prayer_isha').split(' ')[0];

    if (nowStr == fajr ||
        nowStr == dhuhr ||
        nowStr == asr ||
        nowStr == maghrib ||
        nowStr == isha) {
      startFocusLock(duration);
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

        final lockTypeInner = widget.storage.getString(
          'focus_lock_type',
          defaultValue: 'app_only',
        );
        if (lockTypeInner == 'whole_phone') {
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
            builder: (context) => SurahReaderScreen(
              surah: surah,
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

    // Switch to Quran Tab
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
            builder: (context) => SurahReaderScreen(
              surah: surah,
              storage: widget.storage,
              initialAyahNumber: ayahNum,
            ),
          ),
        );
        setState(() {}); // Refresh bookmark after returning
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
      defaultValue: 'solid',
    );

    // Screens list mapping
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
                icon: Icon(
                  Icons.download_for_offline,
                  color:
                      theme.appBarTheme.iconTheme?.color ??
                      const Color(0xFFE5C158),
                ),
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
              icon: Icon(
                Icons.bookmarks,
                color:
                    theme.appBarTheme.iconTheme?.color ??
                    const Color(0xFFE5C158),
              ),
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
              icon: Icon(
                Icons.settings,
                color:
                    theme.appBarTheme.iconTheme?.color ??
                    const Color(0xFFE5C158),
              ),
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
            final hasPlayer = audioState.title.isNotEmpty;

            return Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '$_currentTab-$_azkarInitialTab-$_prayerInitialTab-$_hadithInitialNumber-$_hadithInitialBookId',
                    ),
                    child: screens[_currentTab],
                  ),
                ),
                AudioPlayerOverlay(
                  bottomPosition: bottomNavbarStyle == 'floating'
                      ? 82.0 + MediaQuery.of(context).padding.bottom
                      : 8.0,
                  isDark: isDark,
                  theme: theme,
                ),

                // Focus Lock Screen Overlay
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
                                // Pulsing Golden Vector Star
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
                                            color: const Color(
                                              0xFFE5C158,
                                            ).withOpacity(0.15),
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

                                // Focus Title
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

                                // Large Timer Display
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

                                // Quote / Warning text
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

                                // Emergency Bypass trigger (Double Tap)
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
                      color: theme.shadowColor.withOpacity(0.2),
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
                        color: theme.cardColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28.0),
                        border: Border.all(
                          color: const Color(0xFFE5C158).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      // Theme override forces the BottomNavigationBar to paint
                      // transparent — our container provides the background.
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
