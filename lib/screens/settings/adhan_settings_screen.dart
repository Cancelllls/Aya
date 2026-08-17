import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/adhan_audio_service.dart';
import '../../services/alarm_health_service.dart';

class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key});

  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen> {
  StorageService? _storage;
  bool _loading = true;
  AudioPlayer? _previewPlayer;
  String? _previewingReciter;

  Map<String, dynamic> _healthStatus = {};

  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  final Map<String, String> _prayerNamesAr = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  final Map<String, String> _prayerNamesEn = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = await StorageService.getInstance();
    _previewPlayer = AudioPlayer();
    await _loadHealthStatus();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadHealthStatus() async {
    final health = await AlarmHealthService.checkHealth();
    if (mounted) {
      setState(() {
        _healthStatus = health;
      });
    }
  }

  @override
  void dispose() {
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(String reciterKey, bool isFajr) async {
    if (_previewingReciter == reciterKey) {
      await _previewPlayer?.stop();
      setState(() {
        _previewingReciter = null;
      });
      return;
    }

    setState(() {
      _previewingReciter = reciterKey;
    });

    try {
      final map = isFajr
          ? AdhanAudioService.fajrReciterUrls
          : AdhanAudioService.standardReciterUrls;
      final fileName = map[reciterKey];
      if (fileName != null) {
        final url = 'https://quran-audio-proxy.abdalraman-samir2001.workers.dev/audio/adhan/$fileName';
        await _previewPlayer?.setUrl(url);
        await _previewPlayer?.play();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _previewingReciter = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إعدادات الأذان والتنبيهات' : 'Adhan & Notification Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Status Card
                  _buildHealthCard(isAr, primaryColor),
                  const SizedBox(height: 16),

                  // Per-Prayer Settings Header
                  Text(
                    isAr ? 'إعدادات الصلوات (تخصيص لكل صلاة)' : 'Per-Prayer Customization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ..._prayers.map((prayer) => _buildPrayerCard(prayer, isAr, primaryColor)),

                  const SizedBox(height: 24),

                  // Global Preferences Header
                  Text(
                    isAr ? 'الخيارات العامة للأذان' : 'Global Adhan Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildGlobalOptions(isAr),
                ],
              ),
            ),
    );
  }

  Widget _buildHealthCard(bool isAr, Color primaryColor) {
    final bool isHealthy = _healthStatus['isHealthy'] as bool? ?? false;
    final int active = _healthStatus['active'] as int? ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isHealthy ? Colors.teal.shade50 : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isHealthy ? Colors.teal : Colors.amber.shade800,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHealthy
                        ? (isAr ? 'منبهات الأذان نشطة وفعالة 🟢' : 'Adhan Alarms Healthy 🟢')
                        : (isAr ? 'تنبيه المنبهات 🟡' : 'Alarm Status Warning 🟡'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isHealthy ? Colors.teal.shade900 : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'عدد التنبيهات المجدولة في النظام: $active'
                        : 'Active scheduled system alarms: $active',
                    style: TextStyle(
                      fontSize: 13,
                      color: isHealthy ? Colors.teal.shade800 : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadHealthStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String prayer, bool isAr, Color primaryColor) {
    final prayerName = isAr ? _prayerNamesAr[prayer]! : _prayerNamesEn[prayer]!;
    final String modeKey = 'adhan_mode_$prayer';
    final String offsetKey = 'pre_adhan_${prayer}_minutes';
    final String preModeKey = 'pre_adhan_${prayer}_mode';

    final currentMode = _storage?.getString(modeKey, defaultValue: 'real_reciter') ?? 'real_reciter';
    final currentOffset = _storage?.getInt(offsetKey, defaultValue: prayer == 'fajr' ? 20 : (prayer == 'maghrib' ? 10 : 15)) ?? 15;
    final currentPreMode = _storage?.getString(preModeKey, defaultValue: 'vibrate') ?? 'vibrate';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.mosque, color: primaryColor),
        title: Text(
          prayerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          isAr
              ? 'النمط: ${_getModeLabel(currentMode, isAr)} | التنبيه المسبق: $currentOffset د'
              : 'Mode: ${_getModeLabel(currentMode, isAr)} | Pre-alert: ${currentOffset}m',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adhan Alert Mode Dropdown
                Text(
                  isAr ? 'نمط تنبيه الأذان:' : 'Adhan Alert Mode:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: currentMode,
                  items: [
                    DropdownMenuItem(value: 'real_reciter', child: Text(isAr ? 'أذان كامل (صوت المؤذن)' : 'Full Adhan (Full Audio)')),
                    DropdownMenuItem(value: 'takbeer_only', child: Text(isAr ? 'التكبير فقط (١٥ ثانية)' : 'Takbeer Only (15s)')),
                    DropdownMenuItem(value: 'beep', child: Text(isAr ? 'نغمة تنبيه قصيرة' : 'Short Chime/Beep')),
                    DropdownMenuItem(value: 'vibrate', child: Text(isAr ? 'اهتزاز فقط' : 'Vibrate Only')),
                    DropdownMenuItem(value: 'silent', child: Text(isAr ? 'إشعار صامت' : 'Silent Notification')),
                    DropdownMenuItem(value: 'off', child: Text(isAr ? 'إيقاف التنبيه' : 'Off')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await _storage?.setString(modeKey, val);
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Reciter Selection with Preview Button
                if (currentMode == 'real_reciter' || currentMode == 'takbeer_only') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAr ? 'المؤذن المفضل:' : 'Preferred Reciter:',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _previewingReciter == (prayer == 'fajr' ? _storage?.getString('fajr_adhan_reciter', defaultValue: 'mishary') : _storage?.getString('adhan_reciter', defaultValue: 'mishary'))
                              ? Icons.stop_circle
                              : Icons.play_circle_fill,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          final reciterKey = prayer == 'fajr'
                              ? _storage?.getString('fajr_adhan_reciter', defaultValue: 'mishary') ?? 'mishary'
                              : _storage?.getString('adhan_reciter', defaultValue: 'mishary') ?? 'mishary';
                          _togglePreview(reciterKey, prayer == 'fajr');
                        },
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),

                // Pre-Adhan Offset Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'التنبيه قبل الأذان:' : 'Pre-Adhan Alert Offset:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$currentOffset ${isAr ? 'دقيقة' : 'min'}',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  min: 5,
                  max: 60,
                  divisions: 11,
                  value: currentOffset.toDouble(),
                  activeColor: primaryColor,
                  onChanged: (val) async {
                    await _storage?.setInt(offsetKey, val.toInt());
                    setState(() {});
                  },
                ),

                // Pre-Adhan Alert Mode
                Text(
                  isAr ? 'صوت التنبيه المسبق:' : 'Pre-Adhan Sound Mode:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: currentPreMode,
                  items: [
                    DropdownMenuItem(value: 'sound', child: Text(isAr ? 'نغمة تنبيه' : 'Chime Tone')),
                    DropdownMenuItem(value: 'vibrate', child: Text(isAr ? 'اهتزاز فقط' : 'Vibrate Only')),
                    DropdownMenuItem(value: 'silent', child: Text(isAr ? 'إشعار صامت' : 'Silent')),
                    DropdownMenuItem(value: 'off', child: Text(isAr ? 'إيقاف التنبيه المسبق' : 'Disabled')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await _storage?.setString(preModeKey, val);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalOptions(bool isAr) {
    final bool volumeRamp = _storage?.getBool('volume_ramp_up', defaultValue: true) ?? true;
    final bool postDua = _storage?.getBool('post_adhan_dua', defaultValue: true) ?? true;
    final bool autoDnd = _storage?.getBool('auto_dnd_enabled', defaultValue: false) ?? false;
    final int dndMins = _storage?.getInt('auto_dnd_minutes', defaultValue: 20) ?? 20;
    final bool escalating = _storage?.getBool('escalating_reminders', defaultValue: false) ?? false;
    final bool jumuah = _storage?.getBool('jumuah_reminder', defaultValue: true) ?? true;
    final int jumuahMins = _storage?.getInt('jumuah_minutes_before', defaultValue: 60) ?? 60;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(isAr ? 'التدرج في رفع الصوت' : 'Gradual Volume Ramp-Up'),
            subtitle: Text(isAr ? 'يبدأ الأذان بصوت خفيض ثم يرتفع تدريجياً' : 'Starts soft and ramps to full volume over 5 seconds'),
            value: volumeRamp,
            onChanged: (val) async {
              await _storage?.setBool('volume_ramp_up', val);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(isAr ? 'إشعار دعاء ما بعد الأذان' : 'Post-Adhan Dua Notification'),
            subtitle: Text(isAr ? 'عرض إشعار دعاء الوسيلة والفضيلة بعد انتهاء الأذان' : 'Shows Dua Al-Waseela text notification when adhan ends'),
            value: postDua,
            onChanged: (val) async {
              await _storage?.setBool('post_adhan_dua', val);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(isAr ? 'وضع عدم الإزعاج التلقائي أثناء الصلاة' : 'Auto DND Mode During Salah'),
            subtitle: Text(isAr ? 'تفعيل الصامت تلقائياً بعد الأذان واستعادته بعدها' : 'Automatically silences phone after adhan and restores it later'),
            value: autoDnd,
            onChanged: (val) async {
              await _storage?.setBool('auto_dnd_enabled', val);
              setState(() {});
            },
          ),
          if (autoDnd)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'مدة الصامت (بالدقائق):' : 'Silence duration:'),
                  DropdownButton<int>(
                    value: dndMins,
                    items: [15, 20, 25, 30].map((m) => DropdownMenuItem(value: m, child: Text('$m ${isAr ? 'دقيقة' : 'min'}'))).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await _storage?.setInt('auto_dnd_minutes', val);
                        await _storage?.setInt('auto_dnd_duration', val);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(isAr ? 'تنبيهات قرب انتهاء وقت الصلاة' : 'Escalating End-of-Window Alerts'),
            subtitle: Text(isAr ? 'تنبيه عاجل قبل ١٥ دقيقة من دخول الصلاة التالية' : 'Urgent notification 15 mins before prayer window closes'),
            value: escalating,
            onChanged: (val) async {
              await _storage?.setBool('escalating_reminders', val);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(isAr ? 'تنبيه خاص بصلاة الجمعة' : 'Special Jumu\'ah Reminder'),
            subtitle: Text(isAr ? 'تنبيه مبكر يوم الجمعة للاستعداد للصلاة' : 'Early reminder on Fridays before Dhuhr time'),
            value: jumuah,
            onChanged: (val) async {
              await _storage?.setBool('jumuah_reminder', val);
              setState(() {});
            },
          ),
          if (jumuah)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'التنبيه قبل الجمعة بـ:' : 'Jumu\'ah offset:'),
                  DropdownButton<int>(
                    value: jumuahMins,
                    items: [30, 45, 60, 90].map((m) => DropdownMenuItem(value: m, child: Text('$m ${isAr ? 'دقيقة' : 'min'}'))).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await _storage?.setInt('jumuah_minutes_before', val);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getModeLabel(String mode, bool isAr) {
    switch (mode) {
      case 'real_reciter':
        return isAr ? 'أذان كامل' : 'Full Adhan';
      case 'takbeer_only':
        return isAr ? 'تكبير فقط' : 'Takbeer Only';
      case 'beep':
        return isAr ? 'نغمة' : 'Chime';
      case 'vibrate':
        return isAr ? 'اهتزاز' : 'Vibrate';
      case 'silent':
        return isAr ? 'صامت' : 'Silent';
      case 'off':
        return isAr ? 'مغلق' : 'Off';
      default:
        return mode;
    }
  }
}
