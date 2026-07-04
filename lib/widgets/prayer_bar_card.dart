import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerBarCard extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final String time;
  final bool isCurrent;
  final IconData icon;

  const PrayerBarCard(
    this.theme,
    this.name,
    this.time,
    this.isCurrent,
    this.icon, {
    Key? key,
  }) : super(key: key);

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFFE5C158).withOpacity(0.12)
            : theme.cardColor,
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFE5C158).withOpacity(0.5)
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
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
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
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
