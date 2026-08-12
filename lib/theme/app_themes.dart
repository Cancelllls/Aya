import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'app_colors.dart';

/// Returns authentic Material 3 ThemeData for [themeName], adopting
/// device wallpaper dynamic palettes ([lightDynamic] / [darkDynamic]) on Android 12+.
ThemeData buildThemeData(
  String themeName, {
  ColorScheme? lightDynamic,
  ColorScheme? darkDynamic,
}) {
  switch (themeName) {
    case 'light':
      return _buildM3LightTheme(dynamicScheme: lightDynamic);
    case 'sepia':
      return _buildM3SepiaTheme();
    case 'black':
      return _buildM3OledBlackTheme();
    case 'dark_monet':
      return _buildM3DarkMonetTheme(dynamicScheme: darkDynamic);
    case 'white_monet':
      return _buildM3WhiteMonetTheme(dynamicScheme: lightDynamic);
    case 'dark':
    default:
      return _buildM3DarkTheme(dynamicScheme: darkDynamic);
  }
}

// -----------------------------------------------------------------------------
// 1. Material 3 Adaptive Light Theme
// -----------------------------------------------------------------------------
ThemeData _buildM3LightTheme({ColorScheme? dynamicScheme}) {
  final colorScheme =
      (dynamicScheme != null && dynamicScheme.brightness == Brightness.light)
          ? dynamicScheme.harmonized()
          : ColorScheme.fromSeed(
              seedColor: AppColors.teal,
              brightness: Brightness.light,
              primary: AppColors.teal,
              onPrimary: Colors.white,
              secondary: const Color(0xFFB45309), // Amber accent
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
              surfaceContainerLowest: const Color(0xFFF8FAFC),
              surfaceContainerHigh: Colors.white,
              surfaceContainerHighest: const Color(0xFFF1F5F9),
              outline: const Color(0xFFCBD5E1),
              outlineVariant: const Color(0xFFE2E8F0),
            );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: colorScheme.primary,
    cardColor: Colors.white,
    canvasColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),

    // M3 Typography
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF475569),
        fontSize: 14,
      ),
      titleLarge: TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),

    // M3 AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xFFF8FAFC),
      foregroundColor: AppColors.teal,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.teal),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // M3 Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),

    // M3 Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),

    // M3 Bottom Sheets
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    // M3 Chips
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      disabledColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),

    // M3 Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),

    // M3 Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),

    // M3 Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// -----------------------------------------------------------------------------
// 2. Material 3 Adaptive Dark Theme (Default)
// -----------------------------------------------------------------------------
ThemeData _buildM3DarkTheme({ColorScheme? dynamicScheme}) {
  final colorScheme = (dynamicScheme != null)
      ? dynamicScheme.harmonized()
      : ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.dark,
          primary: AppColors.gold,
          onPrimary: Colors.black,
          secondary: AppColors.teal,
          onSecondary: Colors.white,
          surface: const Color(0xFF101622),
          onSurface: const Color(0xFFF8FAFC),
          surfaceContainerHighest: const Color(0xFF1E293B),
          outline: const Color(0xFF2A3A55),
        );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
    primaryColor: colorScheme.primary,
    cardColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    dividerColor: colorScheme.outlineVariant,

    // M3 Typography
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      titleLarge: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),

    // M3 AppBar
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      foregroundColor: colorScheme.primary,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: colorScheme.primary),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // M3 Cards
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
    ),

    // M3 Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),

    // M3 Bottom Sheets
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    // M3 Chips
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      disabledColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),

    // M3 Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),

    // M3 Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),

    // M3 Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// -----------------------------------------------------------------------------
// 3. Material 3 Sepia Theme (Warm Parchment / Paper)
// -----------------------------------------------------------------------------
ThemeData _buildM3SepiaTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8C5A2B),
    brightness: Brightness.light,
    primary: const Color(0xFF8C5A2B),
    onPrimary: Colors.white,
    surface: const Color(0xFFFDF6E3),
    onSurface: const Color(0xFF4A3B2C),
    surfaceContainerHighest: const Color(0xFFEBE0C5),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF4ECD8),
    primaryColor: const Color(0xFF8C5A2B),
    cardColor: const Color(0xFFFDF6E3),
    canvasColor: const Color(0xFFFDF6E3),
    dividerColor: const Color(0xFFE5DABF),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF4A3B2C), fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Color(0xFF7A6451)),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xFFF4ECD8),
      foregroundColor: Color(0xFF8C5A2B),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFF8C5A2B)),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFFFDF6E3),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5DABF), width: 1),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFFDF6E3),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFFDF6E3),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEBE0C5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      labelStyle: const TextStyle(color: Color(0xFF4A3B2C), fontWeight: FontWeight.w600),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFDF6E3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCD0B2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCD0B2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8C5A2B), width: 2),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFDF6E3),
      selectedItemColor: Color(0xFF8C5A2B),
      unselectedItemColor: Color(0xFFB09D8A),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// -----------------------------------------------------------------------------
// 4. Material 3 OLED Black Theme
// -----------------------------------------------------------------------------
ThemeData _buildM3OledBlackTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
    primary: AppColors.gold,
    onPrimary: Colors.black,
    surface: const Color(0xFF0D0D0D),
    onSurface: const Color(0xFFE5E5E5),
    surfaceContainerHighest: const Color(0xFF1F1F1F),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: AppColors.gold,
    cardColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF121212),
    dividerColor: const Color(0xFF262626),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Color(0xFFA3A3A3)),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.black,
      foregroundColor: AppColors.gold,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.gold),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF121212),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF262626), width: 1),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF171717),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF171717),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF262626),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      labelStyle: const TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w600),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF121212),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: Color(0xFF737373),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// -----------------------------------------------------------------------------
// 5. Material 3 Dark Monet (Emerald Teal) Theme
// -----------------------------------------------------------------------------
ThemeData _buildM3DarkMonetTheme({ColorScheme? dynamicScheme}) {
  final colorScheme = (dynamicScheme != null)
      ? dynamicScheme.harmonized()
      : ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
          primary: const Color(0xFF14B8A6),
          onPrimary: Colors.black,
          surface: const Color(0xFF101918),
          onSurface: const Color(0xFFF2F4F3),
          surfaceContainerHighest: const Color(0xFF1C2B29),
        );

  return _buildM3DarkTheme(dynamicScheme: colorScheme);
}

// -----------------------------------------------------------------------------
// 6. Material 3 Light Monet Theme
// -----------------------------------------------------------------------------
ThemeData _buildM3WhiteMonetTheme({ColorScheme? dynamicScheme}) {
  final colorScheme = (dynamicScheme != null)
      ? dynamicScheme.harmonized()
      : ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
          primary: AppColors.teal,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF1F2927),
          surfaceContainerHighest: const Color(0xFFE2ECE9),
        );

  return _buildM3LightTheme(dynamicScheme: colorScheme);
}
