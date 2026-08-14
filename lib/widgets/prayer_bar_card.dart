import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../utils/time_formatter.dart';

class PrayerBarCard extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final String time;
  final bool isCurrent;
  final IconData icon;
  final bool is24Hour;

  const PrayerBarCard(
    this.theme,
    this.name,
    this.time,
    this.isCurrent,
    this.icon, {
    super.key,
    this.is24Hour = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = TimeFormatter.formatTime(
      time,
      is24Hour: is24Hour,
      isArabic: TranslationService.isArabic,
    );

    return Container(
      width: 100,
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFFE5C158).withValues(alpha: 0.12)
            : theme.cardColor,
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFE5C158).withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isCurrent
                ? const Color(0xFFE5C158)
                : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCurrent
                  ? const Color(0xFFE5C158)
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedTime,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
