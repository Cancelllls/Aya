import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../utils/text_helpers.dart';
import '../services/translation_service.dart';

/// A self-contained card showing live countdown to the next prayer,
/// all prayer times, and highlighting the current/next prayer.
///
/// Manages its own timer — dispose via [dispose] or use [StatefulWrapper].
class PrayersCountdownCard extends StatefulWidget {
  final PrayerTimeData data;
  final bool use24h;

  const PrayersCountdownCard({
    super.key,
    required this.data,
    this.use24h = false,
  });

  @override
  State<PrayersCountdownCard> createState() => _PrayersCountdownCardState();
}

class _PrayersCountdownCardState extends State<PrayersCountdownCard> {
  late Timer _timer;
  String _nextName = '';
  Duration _countdown = Duration.zero;
  String _currentName = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant PrayersCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _tick();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final prayers = _parsePrayers(todayStr);
    prayers.sort((a, b) => a.value.compareTo(b.value));

    // Current prayer = last one that has passed
    String current = '';
    for (int i = prayers.length - 1; i >= 0; i--) {
      if (now.isAfter(prayers[i].value)) {
        current = prayers[i].key;
        break;
      }
    }
    if (current.isEmpty) current = 'Isha';

    // Next prayer = first one still ahead, or Fajr tomorrow
    DateTime? nextTime;
    String nextName = '';
    for (final p in prayers) {
      if (p.value.isAfter(now)) {
        nextTime = p.value;
        nextName = p.key;
        break;
      }
    }
    if (nextTime == null) {
      final fajr = _parseTime(todayStr, widget.data.fajr);
      nextTime = fajr.add(const Duration(days: 1));
      nextName = 'Fajr';
    }

    setState(() {
      _currentName = current;
      _nextName = nextName;
      _countdown = nextTime!.difference(now);
    });
  }

  List<MapEntry<String, DateTime>> _parsePrayers(String todayStr) {
    return [
      MapEntry('Fajr', _parseTime(todayStr, widget.data.fajr)),
      MapEntry('Sunrise', _parseTime(todayStr, widget.data.sunrise)),
      MapEntry('Dhuhr', _parseTime(todayStr, widget.data.dhuhr)),
      MapEntry('Asr', _parseTime(todayStr, widget.data.asr)),
      MapEntry('Maghrib', _parseTime(todayStr, widget.data.maghrib)),
      MapEntry('Isha', _parseTime(todayStr, widget.data.isha)),
    ];
  }

  DateTime _parseTime(String todayStr, String timeStr) {
    final clean = timeStr.split(' ')[0];
    return DateTime.parse(
      '$todayStr${clean.isNotEmpty ? 'T$clean:00' : 'T00:00:00'}',
    );
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  static const _prayerIcons = {
    'Fajr': Icons.cloud_queue,
    'Sunrise': Icons.wb_sunny_outlined,
    'Dhuhr': Icons.wb_sunny,
    'Asr': Icons.wb_twilight,
    'Maghrib': Icons.wb_cloudy_outlined,
    'Isha': Icons.nights_stay,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = TranslationService.isArabic;

    final times = _parsePrayers(
      DateTime.now().toIso8601String().substring(0, 10),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: const Color(0xFFE5C158).withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Prayer times row — highlight current and next
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: times.map((e) {
              final isCurrent = e.key == _currentName;
              final isNext = e.key == _nextName;
              final highlight = isCurrent || isNext;
              final display = formatPrayerTime(
                '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}',
                use24h: widget.use24h,
              );

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: highlight
                      ? const Color(0xFFE5C158).withValues(alpha: 0.12)
                      : theme.cardColor,
                  border: Border.all(
                    color: highlight
                        ? const Color(0xFFE5C158).withValues(alpha: 0.6)
                        : theme.dividerColor,
                    width: highlight ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _prayerIcons[e.key] ?? Icons.access_time,
                      size: 14,
                      color: highlight
                          ? const Color(0xFFE5C158)
                          : theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TranslationService.t(e.key.toLowerCase()),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: highlight
                            ? const Color(0xFFE5C158)
                            : theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      display,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: highlight
                            ? const Color(0xFFE5C158)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 10),

          // "LIVE COUNTDOWN" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAr ? 'العد التنازلي' : 'Live Countdown',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Next prayer label
          Text(
            '${isAr ? 'الوقت المتبقي لـ' : 'Time until'} ${TranslationService.t(_nextName.toLowerCase())}',
            style: TextStyle(
              color: theme.textTheme.titleMedium?.color
                  ?.withValues(alpha: 0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Large countdown timer
          Text(
            '${_pad(_countdown.inHours)}:${_pad(_countdown.inMinutes.remainder(60))}:${_pad(_countdown.inSeconds.remainder(60))}',
            style: const TextStyle(
              color: Color(0xFFE5C158),
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
