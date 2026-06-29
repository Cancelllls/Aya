import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UiHelpers {
  // Breakpoints
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  // Responsive padding/font scaling
  static double responsiveScale(BuildContext context, {double base = 1.0}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return base * 0.85; // Scale down for tiny screens
    if (width >= 600) return base * 1.2; // Scale up for tablets
    return base;
  }

  // Common UI Layout Paddings
  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.all(responsiveScale(context, base: 16.0));
  }

  // Consistent Haptic Feedbacks
  static Future<void> hapticClick() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> hapticSelection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> hapticSuccess() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  static Future<void> hapticWarning() async {
    await HapticFeedback.heavyImpact();
  }
}
