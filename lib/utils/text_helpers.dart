import 'package:flutter/material.dart';
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

/// Converts Western numeric characters ('0'-'9') to Eastern Arabic digits ('٠'-'٩').
String toArabicDigits(dynamic input) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  String str = input.toString();
  for (int i = 0; i < western.length; i++) {
    str = str.replaceAll(western[i], eastern[i]);
  }
  return str;
}

/// Parses text containing `<mark>keyword</mark>` tags into a list of [TextSpan]s.
/// Marked tokens receive [highlightStyle] or bold gold color [highlightColor] (#E5C158).
List<InlineSpan> parseMarkedSpans(
  String text, {
  required TextStyle baseStyle,
  TextStyle? highlightStyle,
  Color highlightColor = const Color(0xFFE5C158),
}) {
  if (!text.contains('<mark>')) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final spans = <InlineSpan>[];
  final effectiveHighlightStyle = highlightStyle ??
      baseStyle.copyWith(
        color: highlightColor,
        fontWeight: FontWeight.bold,
      );

  final parts = text.split('<mark>');
  for (int i = 0; i < parts.length; i++) {
    if (i == 0) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: baseStyle));
      }
    } else {
      final subparts = parts[i].split('</mark>');
      if (subparts[0].isNotEmpty) {
        spans.add(TextSpan(text: subparts[0], style: effectiveHighlightStyle));
      }
      if (subparts.length > 1 && subparts[1].isNotEmpty) {
        spans.add(TextSpan(text: subparts[1], style: baseStyle));
      }
    }
  }
  return spans;
}

/// Cleans HTML tags (like <i>, </i>, <b>, </b>, <sup>...</sup>, <footnote>...</footnote>)
/// and common HTML entities from translation text (such as in The Clear Quran).
String cleanTranslationText(String text) {
  if (text.isEmpty) return text;
  return text
      .replaceAll(RegExp(r'<footnote\b[^>]*>.*?</footnote>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<sup\b[^>]*>.*?</sup>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

