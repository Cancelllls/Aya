import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../models/prayer_models.dart';

class PrayerTimeAdjustScreen extends StatefulWidget {
  final StorageService storage;

  const PrayerTimeAdjustScreen({super.key, required this.storage});

  @override
  State<PrayerTimeAdjustScreen> createState() => _PrayerTimeAdjustScreenState();
}

class _PrayerTimeAdjustScreenState extends State<PrayerTimeAdjustScreen> {
  final Map<String, int> _offsets = {};

  final List<String> _prayers = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

  final Map<String, String> _prayerNamesAr = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  final Map<String, String> _prayerNamesEn = {
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  @override
  void initState() {
    super.initState();
    _loadOffsets();
  }

  void _loadOffsets() {
    for (final p in _prayers) {
      _offsets[p] = widget.storage.getInt('${p}_offset', defaultValue: 0);
    }
  }

  Future<void> _updateOffset(String prayer, int val) async {
    final clamped = val.clamp(-30, 30);
    setState(() {
      _offsets[prayer] = clamped;
    });
    await widget.storage.setInt('${prayer}_offset', clamped);
    _rescheduleAlarms();
  }

  Future<void> _resetAll() async {
    for (final p in _prayers) {
      setState(() {
        _offsets[p] = 0;
      });
      await widget.storage.setInt('${p}_offset', 0);
    }
    _rescheduleAlarms();
  }

  Future<void> _rescheduleAlarms() async {
    try {
      final loc = widget.storage.getLocation();
      final method = widget.storage.getInt('calc_method', defaultValue: 2);
      final school = widget.storage.getInt('asr_method', defaultValue: 0);

      final PrayerTimeData data = await ApiService.fetchPrayerTimes(
        latitude: loc['latitude'] ?? 30.0444,
        longitude: loc['longitude'] ?? 31.2357,
        method: method,
        school: school,
      );
      await NotificationService().schedulePrayerAlarms(data, widget.storage);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تعديل مواقيت الصلاة' : 'Fine-Tune Prayer Times'),
        actions: [
          IconButton(
            tooltip: isAr ? 'إعادة ضبط الكل' : 'Reset All',
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(isAr ? 'إعادة الضبط' : 'Reset Offsets'),
                  content: Text(
                    isAr
                        ? 'هل تريد إعادة ضبط جميع تعديلات المواقيت إلى الصفر؟'
                        : 'Do you want to reset all prayer time offsets back to 0?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isAr ? 'إلغاء' : 'Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetAll();
                      },
                      child: Text(isAr ? 'تأكيد' : 'Confirm'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Info banner
          Card(
            elevation: 0,
            color: primaryColor.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.tune, color: primaryColor, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'يمكنك ضبط مواقيت الصلاة بالزيادة أو النقصان حتى ٣٠ دقيقة لتتوافق تماماً مع توقيت مسجدك المحلي.'
                          : 'Adjust prayer times by +/- 30 minutes to match your local mosque precisely.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ..._prayers.map((prayer) {
            final name = isAr ? _prayerNamesAr[prayer]! : _prayerNamesEn[prayer]!;
            final currentVal = _offsets[prayer] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.access_time_filled, size: 20, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: currentVal == 0
                                ? theme.disabledColor.withValues(alpha: 0.1)
                                : primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentVal == 0
                                ? (isAr ? 'بدون تعديل' : 'Exact Time')
                                : '${currentVal > 0 ? "+$currentVal" : currentVal} ${isAr ? "دقيقة" : "mins"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: currentVal == 0
                                  ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                                  : primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: primaryColor,
                          onPressed: () => _updateOffset(prayer, currentVal - 1),
                        ),
                        Expanded(
                          child: Slider(
                            min: -30,
                            max: 30,
                            divisions: 60,
                            value: currentVal.toDouble(),
                            activeColor: primaryColor,
                            onChanged: (v) => _updateOffset(prayer, v.toInt()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: primaryColor,
                          onPressed: () => _updateOffset(prayer, currentVal + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
