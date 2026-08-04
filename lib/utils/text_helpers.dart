import '../services/translation_service.dart';

/// Remove Arabic diacritics and normalize for search.
///
/// Normalizes:  أ إ آ ٱ ء → ا   (hamza variants, alef wasla, bare hamza)
///              َ ً ُ ٌ ِ ٍ ْ ّ   → removed (diacritics)
///              ۖ ۗ ۘ ۙ ۚ ۛ ۜ ۢ ۣ ۤ ۥ ۦ ۧ ۨ ۩ → removed (Quran annotation marks)
///              ة               → ه   (teh marbuta)
///              ى               → ي   (alef maksura)
///
/// Consecutive alefs are collapsed (ءَا → اا → ا).
String stripTashkeel(String input) {
  var result = input
      .replaceAll(RegExp(r'[ً-ٰٟۖ-ۭ]'), '')
      .replaceAll(RegExp(r'[أإآٱء]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '') // tatweel (kashida)
      .replaceAll('﻿', ''); // BOM (byte-order mark from JSON)
  // Collapse consecutive alefs (e.g. ءَا → اا → ا)
  while (result.contains('اا')) {
    result = result.replaceAll('اا', 'ا');
  }
  return result;
}

/// Format a "HH:mm (TZ)" prayer-time string to 12h or 24h display.
String formatPrayerTime(String rawTime, {bool use24h = false}) {
  if (rawTime.isEmpty) return '--:--';
  // Strip timezone suffix like " (EET)"
  final clean = rawTime.split(' ')[0].trim();
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
      ? (TranslationService.isArabic ? 'م' : 'PM')
      : (TranslationService.isArabic ? 'ص' : 'AM');
  return '$displayHour:$displayMinute $suffix';
}
