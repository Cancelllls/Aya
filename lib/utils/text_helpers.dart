import '../services/translation_service.dart';

/// Remove Arabic diacritics and normalize alef variants for search.
///
/// Normalizes:  أ إ آ → ا   (hamza variants)
///              ٱ      → ا   (alef wasla)
///              ة      → ه   (teh marbuta)
///              ى      → ي   (alef maksura, end-of-word)
String stripTashkeel(String input) {
  return input
      .replaceAll(RegExp(r'[ً-ٰٟ]'), '') // diacritics (fatha, damma, kasra, etc.)
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا') // alef normalization
      .replaceAll('ة', 'ه') // teh marbuta → hah
      .replaceAll('ى', 'ي'); // alef maksura → yeh
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
