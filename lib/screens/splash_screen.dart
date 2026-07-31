import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import 'welcome_screen.dart';
import '../main.dart';
import '../widgets/islamic_logo_painter.dart';

class SplashScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onThemeChanged;

  const SplashScreen({
    super.key,
    required this.storage,
    required this.onThemeChanged,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate to next screen after animation completes
    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;

      final isFirstTime = widget.storage.getBool(
        'first_time_v2',
        defaultValue: true,
      );
      if (isFirstTime && widget.storage.getString('lang_code').isEmpty) {
        // Auto-detect language
        final locale = Platform.localeName.toLowerCase();
        final detectedLang = locale.startsWith('ar') ? 'ar' : 'en';
        await widget.storage.setString('lang_code', detectedLang);
        TranslationService.setLanguage(detectedLang);
        widget.onThemeChanged(); // Update main directionality instantly
      }

      void navigateToDestination() {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => isFirstTime
                ? WelcomeScreen(
                    storage: widget.storage,
                    onThemeChanged: widget.onThemeChanged,
                    onComplete: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScaffold(
                            storage: widget.storage,
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                      );
                    },
                  )
                : MainScaffold(
                    storage: widget.storage,
                    onThemeChanged: widget.onThemeChanged,
                  ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1.02,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }

      navigateToDestination();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF07090E)
          : const Color(0xFFFAF9F5),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Animated Vector Logo
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5C158).withOpacity(
                            0.08 + 0.08 * sin(_controller.value * 2 * pi),
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: IslamicLogoPainter(
                        animationValue: _controller.value,
                        color: const Color(0xFFE5C158),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Animated App Name and Subtitle
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        "AYA",
                        style: TextStyle(fontFamily: 'Outfit',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: const Color(0xFFE5C158),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        TranslationService.isArabic
                            ? "رفيقك الإسلامي اليومي"
                            : "YOUR DAILY ISLAMIC COMPANION",
                        style: TextStyle(fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: isDark
                              ? (Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
                                        Colors.white)
                                    .withOpacity(0.3)
                              : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
