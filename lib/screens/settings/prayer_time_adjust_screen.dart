import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/notification_service.dart';

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
    setState(() {
      _offsets[prayer] = val;
    });
    await widget.storage.setInt('${prayer}_offset', val);
    NotificationService().schedulePrayerAlarms();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تعديل مواقيت الصلاة (بالدقائق)' : 'Fine-Tune Prayer Times'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 0,
            color: primaryColor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'يمكنك إضافة أو إنقاص دقائق على أي صلاة لضبط موعدها حسب مسجدك المحلي.'
                          : 'Add or subtract minutes for any prayer to align with your local mosque.',
                      style: const TextStyle(fontSize: 13),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          currentVal == 0
                              ? (isAr ? 'بدون تعديل' : 'No offset')
                              : '${currentVal > 0 ? "+$currentVal" : currentVal} ${isAr ? "دقيقة" : "mins"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentVal == 0 ? Colors.grey : primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: -30,
                      max: 30,
                      divisions: 60,
                      value: currentVal.toDouble(),
                      activeColor: primaryColor,
                      onChanged: (v) => _updateOffset(prayer, v.toInt()),
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
