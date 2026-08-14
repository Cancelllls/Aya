import 'package:intl/intl.dart';

class TimeFormatter {
  /// Formats a raw time string (e.g. "05:15", "15:30", "15:30:00", "15:30 (EET)")
  /// into 12-hour or 24-hour time string based on user preference and language.
  static String formatTime(
    String rawTime, {
    required bool is24Hour,
    required bool isArabic,
  }) {
    if (rawTime.isEmpty || rawTime == '--:--') return '--:--';

    try {
      // Strip any timezone tags like (EET) or seconds
      final cleanTime = rawTime.split(' ')[0];
      final parts = cleanTime.split(':');
      if (parts.length < 2) return rawTime;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (is24Hour) {
        final formattedHour = hour.toString().padLeft(2, '0');
        final formattedMinute = minute.toString().padLeft(2, '0');
        final timeStr = "$formattedHour:$formattedMinute";
        return isArabic ? _toArabicDigits(timeStr) : timeStr;
      } else {
        // 12-Hour format
        final period = hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
        final displayHour = (hour % 12 == 0) ? 12 : (hour % 12);
        final formattedMinute = minute.toString().padLeft(2, '0');
        final timeStr = "$displayHour:$formattedMinute $period";
        return isArabic ? _toArabicDigits(timeStr) : timeStr;
      }
    } catch (_) {
      return rawTime;
    }
  }

  static String _toArabicDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}
