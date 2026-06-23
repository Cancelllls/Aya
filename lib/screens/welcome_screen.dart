import 'package:flutter/material.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../widgets/islamic_logo_painter.dart';

class WelcomeScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onThemeChanged;
  final VoidCallback onComplete;

  const WelcomeScreen({
    super.key,
    required this.storage,
    required this.onThemeChanged,
    required this.onComplete,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _logoController;
  int _currentPage = 0;
  bool _isRequestingGPS = false;
  String _gpsStatusText = '';
  bool _gpsSetupSuccess = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setupGPS() async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final cardColor = Theme.of(context).cardColor;
    setState(() {
      _isRequestingGPS = true;
      _gpsStatusText = TranslationService.t('welcome_gps_status_checking');
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        throw Exception(TranslationService.t('welcome_gps_status_disabled'));
      }

      setState(() => _gpsStatusText = TranslationService.t('welcome_gps_status_requesting'));
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          throw Exception(TranslationService.t('welcome_gps_status_denied'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(TranslationService.t('welcome_gps_status_denied_forever'));
      }

      if (isAndroid && permission == LocationPermission.whileInUse) {
        final bool proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              TranslationService.isArabic ? "مطلوب إذن الموقع دائماً" : "Location Permission 'Always' Required",
              style: const TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold),
            ),
            content: Text(
              TranslationService.isArabic
                  ? "يتطلب التطبيق إذن الموقع 'سماح طوال الوقت' لتحديث مواقيت الصلاة تلقائياً في الخلفية بدون فتح التطبيق. يرجى الضغط على زر المتابعة لتغيير الإذن من إعدادات الهاتف إلى 'السماح طوال الوقت'."
                  : "The app requires the location permission set to 'Allow all the time' to update prayer times automatically in the background. Please click continue to change it to 'Allow all the time' in your settings.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(TranslationService.t('cancel'), style: const TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(TranslationService.isArabic ? "متابعة" : "Continue", style: const TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ) ?? false;

        if (proceed) {
          await Geolocator.openAppSettings();
          await Future.delayed(const Duration(seconds: 3));
          if (!mounted) return;
          permission = await Geolocator.checkPermission();
        }
      }

      if (isAndroid && permission != LocationPermission.always) {
        throw Exception(TranslationService.isArabic 
            ? "يرجى منح إذن الموقع 'السماح طوال الوقت' للاستمرار." 
            : "Please grant 'Allow all the time' location permission to proceed.");
      }

      setState(() => _gpsStatusText = TranslationService.t('welcome_gps_status_fetching'));
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      setState(() => _gpsStatusText = TranslationService.t('welcome_gps_status_geocoding'));
      final address = await ApiService.reverseGeocode(position.latitude, position.longitude);
      if (!mounted) return;

      await widget.storage.setLocation(
        address['city'] ?? (TranslationService.isArabic ? 'موقعي' : 'My Location'),
        address['country'] ?? 'GPS',
        position.latitude,
        position.longitude,
        'gps',
      );

      setState(() => _gpsStatusText = TranslationService.t('welcome_gps_status_notifications'));
      try {
        await NotificationService().requestPermissions();
      } catch (_) {}
      if (!mounted) return;

      setState(() {
        _gpsSetupSuccess = true;
        _gpsStatusText = '${TranslationService.t('welcome_gps_status_success')}${address['city']}، ${address['country']}!';
        _isRequestingGPS = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsSetupSuccess = false;
        final cleanErr = e.toString().replaceAll('Exception: ', '');
        _gpsStatusText = '${TranslationService.t('welcome_gps_status_failed')}$cleanErr${TranslationService.t('welcome_gps_manual_hint')}';
        _isRequestingGPS = false;
      });
    }
  }

  void _finishOnboarding() async {
    await widget.storage.setBool('first_time_v2', false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07090E) : const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildWelcomeSlide(isDark),
                      _buildFeaturesSlide(isDark),
                      _buildPermissionsSlide(isDark),
                    ],
                  ),
                ),
                _buildBottomControls(isDark),
              ],
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 16,
              top: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5C158).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    final newLang = TranslationService.isArabic ? 'en' : 'ar';
                    await widget.storage.setString('lang_code', newLang);
                    TranslationService.setLanguage(newLang);
                    widget.onThemeChanged();
                  },
                  icon: const Icon(Icons.language, size: 16, color: Color(0xFFE5C158)),
                  label: Text(
                    TranslationService.isArabic ? 'English' : 'العربية',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C158),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Glowing Animated Custom Vector Logo
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5C158).withOpacity(0.06 + 0.04 * sin(_logoController.value * 2 * pi)),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: CustomPaint(
                  painter: IslamicLogoPainter(
                    animationValue: _logoController.value,
                    color: const Color(0xFFE5C158),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            TranslationService.t('welcome_app_name'),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            TranslationService.t('welcome_spiritual_companion'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            TranslationService.t('welcome_intro_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white30 : Colors.black38,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFeaturesSlide(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            TranslationService.t('welcome_features_title'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.t('welcome_features_sub'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(
            icon: Icons.access_time_filled,
            title: TranslationService.t('welcome_feat_prayer_title'),
            description: TranslationService.t('welcome_feat_prayer_desc'),
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.menu_book,
            title: TranslationService.t('welcome_feat_quran_title'),
            description: TranslationService.t('welcome_feat_quran_desc'),
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.explore,
            title: TranslationService.t('welcome_feat_qibla_title'),
            description: TranslationService.t('welcome_feat_qibla_desc'),
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(
            icon: Icons.volunteer_activism,
            title: TranslationService.t('welcome_feat_tasbih_title'),
            description: TranslationService.t('welcome_feat_tasbih_desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = widget.storage.isDarkMode();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE5C158).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.2)),
          ),
          child: Icon(icon, color: const Color(0xFFE5C158), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPermissionsSlide(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFFE5C158),
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            TranslationService.t('welcome_gps_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            TranslationService.t('welcome_gps_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 36),
          // Status Box
          if (_gpsStatusText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _gpsSetupSuccess 
                    ? const Color(0xFF10B981).withOpacity(0.1) 
                    : const Color(0xFFE5C158).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gpsSetupSuccess 
                      ? const Color(0xFF10B981).withOpacity(0.3) 
                      : const Color(0xFFE5C158).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _gpsSetupSuccess ? Icons.check_circle : Icons.info,
                    color: _gpsSetupSuccess ? const Color(0xFF10B981) : const Color(0xFFE5C158),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _gpsStatusText,
                      style: TextStyle(
                        fontSize: 13,
                        color: _gpsSetupSuccess ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5C158),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: _isRequestingGPS 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.gps_fixed),
            label: Text(TranslationService.t('welcome_gps_btn')),
            onPressed: _isRequestingGPS ? null : _setupGPS,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicator Dots
          Row(
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsetsDirectional.only(end: 6),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? const Color(0xFFE5C158) 
                      : const Color(0xFFE5C158).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Next / Get Started Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5C158),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              } else {
                _finishOnboarding();
              }
            },
            child: Text(_currentPage == 2 
                ? TranslationService.t('welcome_start_now') 
                : TranslationService.t('welcome_next')),
          ),
        ],
      ),
    );
  }
}
