import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Returns the ThemeData for the given [themeName].
/// Supported values: 'dark', 'light', 'sepia', 'black', 'dark_monet', 'white_monet'.
ThemeData buildThemeData(String themeName) {
  switch (themeName) {
    case 'light':
      return _buildLightTheme();
    case 'sepia':
      return _buildSepiaTheme();
    case 'black':
      return _buildBlackTheme();
    case 'dark_monet':
      return _buildDarkMonetTheme();
    case 'white_monet':
      return _buildWhiteMonetTheme();
    case 'dark':
    default:
      return _buildDarkTheme();
  }
}

ThemeData _buildLightTheme() {
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
}

ThemeData _buildSepiaTheme() {
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
}

ThemeData _buildBlackTheme() {
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
}

ThemeData _buildDarkMonetTheme() {
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
}

ThemeData _buildWhiteMonetTheme() {
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
}

ThemeData _buildDarkTheme() {
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
