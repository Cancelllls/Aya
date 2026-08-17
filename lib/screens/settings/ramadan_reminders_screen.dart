import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/notification_service.dart';

class RamadanRemindersScreen extends StatefulWidget {
  final StorageService storage;

  const RamadanRemindersScreen({super.key, required this.storage});

  @override
  State<RamadanRemindersScreen> createState() => _RamadanRemindersScreenState();
}

class _RamadanRemindersScreenState extends State<RamadanRemindersScreen> {
  late bool _imsakEnabled;
  late int _imsakOffset;
  late bool _iftarEnabled;

  @override
  void initState() {
    super.initState();
    _imsakEnabled = widget.storage.getBool('ramadan_imsak_enabled', defaultValue: true);
    _imsakOffset = widget.storage.getInt('ramadan_imsak_offset', defaultValue: 0);
    _iftarEnabled = widget.storage.getBool('ramadan_iftar_enabled', defaultValue: true);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تنبيهات شهر رمضان المبارك' : 'Ramadan Reminders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(isAr ? 'تنبيه الإمساك (السحور)' : 'Imsak / Suhoor Alert'),
                  subtitle: Text(isAr ? 'تنبيه عند اقتراب وقت الفجر للتوقف عن الطعام' : 'Alert before Fajr time to stop eating for the fast'),
                  value: _imsakEnabled,
                  onChanged: (val) async {
                    setState(() {
                      _imsakEnabled = val;
                    });
                    await widget.storage.setBool('ramadan_imsak_enabled', val);
                    NotificationService().schedulePrayerAlarms();
                  },
                ),
                if (_imsakEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAr ? 'وقت الإمساك قبل الفجر بـ:' : 'Imsak offset before Fajr:'),
                        DropdownButton<int>(
                          value: _imsakOffset,
                          items: [0, 5, 10, 15].map((m) {
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(m == 0 ? (isAr ? 'عند الفجر (0)' : 'At Fajr (0)') : '$m ${isAr ? "دقائق" : "mins"}'),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() {
                                _imsakOffset = val;
                              });
                              await widget.storage.setInt('ramadan_imsak_offset', val);
                              NotificationService().schedulePrayerAlarms();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(isAr ? 'تنبيه الإفطار' : 'Iftar Alert'),
                  subtitle: Text(isAr ? 'تنبيه ودعاء عند دخول وقت المغرب' : 'Alert and Dua at Maghrib time'),
                  value: _iftarEnabled,
                  onChanged: (val) async {
                    setState(() {
                      _iftarEnabled = val;
                    });
                    await widget.storage.setBool('ramadan_iftar_enabled', val);
                    NotificationService().schedulePrayerAlarms();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
