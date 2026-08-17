import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../../services/adhan_audio_service.dart';
import '../../services/alarm_health_service.dart';
import '../../core/adhan_native_controller.dart';

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

  final Map<String, String> _standardRecitersAr = {
    'mishary': 'مشاري العفاسي (الكويت)',
    'abdul_basit': 'عبد الباسط عبد الصمد (مصر)',
    'manssour': 'منصور الزهراني (السعودية)',
    'maghriby': 'نور الدين الهذيوي (القدس)',
    'kazabri': 'عمر القزابري (المغرب)',
    'riad': 'رياض الجزائري (الجزائر)',
    'nakshabandi': 'سيد النقشبندي (مصر)',
  };

  final Map<String, String> _standardRecitersEn = {
    'mishary': 'Mishary Al-Afasy (Kuwait)',
    'abdul_basit': 'Abdul Basit (Egypt)',
    'manssour': 'Manssour Al-Zahrani (Saudi Arabia)',
    'maghriby': 'Nurdin Al-Maghriby (Al-Quds)',
    'kazabri': 'Omar Al-Kazabri (Morocco)',
    'riad': 'Riad Al-Djazairi (Algeria)',
    'nakshabandi': 'Sayed Al-Nakshabandi (Egypt)',
  };

  final Map<String, String> _fajrRecitersAr = {
    'mishary': 'مشاري العفاسي - الفجر (الكويت)',
    'abdul_basit': 'عبد الباسط عبد الصمد - الفجر (مصر)',
    'madinah': 'أذان المسجد النبوي (المدينة المنورة)',
    'nurdin': 'نور الدين الهذيوي - الفجر (المغرب)',
  };

  final Map<String, String> _fajrRecitersEn = {
    'mishary': 'Mishary Al-Afasy - Fajr (Kuwait)',
    'abdul_basit': 'Abdul Basit - Fajr (Egypt)',
    'madinah': 'Madinah Prophet\'s Mosque Adhan',
    'nurdin': 'Nurdin Al-Haddiwi - Fajr (Morocco)',
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
      final fileName = map[reciterKey] ?? (isFajr ? 'adhan_fajr_meshary_al_fasy_kuwait.mp3' : 'adhan_meshary_al_fasy_kuwait.mp3');
      await _previewPlayer?.stop();
      await _previewPlayer?.setAsset('assets/audio/adhan/$fileName');
      await _previewPlayer?.play();
    } catch (e) {
      debugPrint('Error playing preview: $e');
    }

    if (mounted) {
      setState(() {
        _previewingReciter = null;
      });
    }
  }

  Future<void> _setAllAdhansMode(String mode) async {
    for (final p in _prayers) {
      await _storage?.setString('adhan_mode_$p', mode);
    }
    setState(() {});
  }

  Future<void> _setAllPreAdhansMode(String mode) async {
    for (final p in _prayers) {
      await _storage?.setString('pre_adhan_${p}_mode', mode);
    }
    setState(() {});
  }

  String _getAllAdhansCurrentMode() {
    final modes = _prayers
        .map((p) => _storage?.getString('adhan_mode_$p', defaultValue: 'real_reciter') ?? 'real_reciter')
        .toSet();
    if (modes.length == 1) {
      return modes.first;
    }
    return 'custom';
  }

  String _getAllPreAdhansCurrentMode() {
    final modes = _prayers
        .map((p) => _storage?.getString('pre_adhan_${p}_mode', defaultValue: 'vibrate') ?? 'vibrate')
        .toSet();
    if (modes.length == 1) {
      return modes.first;
    }
    return 'custom';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تخصيص الأذان والتنبيهات' : 'Adhan & Alert Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Status Card
                  _buildHealthCard(isAr, primaryColor, theme),
                  const SizedBox(height: 12),

                  // Quick Batch Presets Card (All Sound / All Vibrate / Custom)
                  _buildQuickBatchCard(isAr, primaryColor, theme),
                  const SizedBox(height: 12),

                  // Live Test Card
                  _buildTestCard(isAr, primaryColor, theme),
                  const SizedBox(height: 20),

                  // Per-Prayer Settings Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      isAr ? 'تخصيص الصلوات الفردية' : 'Per-Prayer Customization',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._prayers.map((prayer) => _buildPrayerCard(prayer, isAr, primaryColor, theme)),

                  const SizedBox(height: 24),

                  // Global Preferences Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      isAr ? 'إعدادات الأذان العامة' : 'Global Adhan Options',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildGlobalOptions(isAr, primaryColor, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickBatchCard(bool isAr, Color primaryColor, ThemeData theme) {
    final allAdhansMode = _getAllAdhansCurrentMode();
    final allPreMode = _getAllPreAdhansCurrentMode();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
      ),
      color: primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'الضبط السريع لجميع الصلوات' : 'Quick Batch Presets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isAr
                  ? 'تعيين النمط لجميع الصلوات دفعة واحدة (صوت، اهتزاز فقط، أو تخصيص يدوي)'
                  : 'Set alert mode for all 5 prayers at once (Sound, Vibrate only, Off, or Manual).',
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),

            // All Adhans Selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'جميع الأذانات:' : 'All Adhans Preset:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: allAdhansMode,
                      items: [
                        DropdownMenuItem(
                          value: 'real_reciter',
                          child: Text(isAr ? '🔊 صوت المؤذن للكل' : '🔊 Sound (All)'),
                        ),
                        DropdownMenuItem(
                          value: 'vibrate',
                          child: Text(isAr ? '📳 اهتزاز فقط للكل' : '📳 Vibrate (All)'),
                        ),
                        DropdownMenuItem(
                          value: 'off',
                          child: Text(isAr ? '🔇 مغلق / صامت للكل' : '🔇 Off (All)'),
                        ),
                        if (allAdhansMode == 'custom')
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text(isAr ? '⚙️ تخصيص يدوي' : '⚙️ Custom / Manual'),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null && val != 'custom') {
                          _setAllAdhansMode(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // All Pre-Adhans Selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'جميع التنبيهات المسبقة:' : 'All Pre-Alerts Preset:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: allPreMode,
                      items: [
                        DropdownMenuItem(
                          value: 'sound',
                          child: Text(isAr ? '🔔 نغمة تنبيه للكل' : '🔔 Sound (All)'),
                        ),
                        DropdownMenuItem(
                          value: 'vibrate',
                          child: Text(isAr ? '📳 اهتزاز فقط للكل' : '📳 Vibrate (All)'),
                        ),
                        DropdownMenuItem(
                          value: 'off',
                          child: Text(isAr ? '🔇 مغلق للكل' : '🔇 Off (All)'),
                        ),
                        if (allPreMode == 'custom')
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text(isAr ? '⚙️ تخصيص يدوي' : '⚙️ Custom / Manual'),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null && val != 'custom') {
                          _setAllPreAdhansMode(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(bool isAr, Color primaryColor, ThemeData theme) {
    final bool isHealthy = _healthStatus['isHealthy'] as bool? ?? false;
    final int active = _healthStatus['active'] as int? ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHealthy
              ? Colors.teal.withValues(alpha: 0.3)
              : Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      color: isHealthy ? Colors.teal.withValues(alpha: 0.08) : Colors.amber.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: isHealthy ? Colors.teal : Colors.amber.shade800,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHealthy
                        ? (isAr ? 'منبهات الأذان نشطة وفعالة' : 'Adhan System Healthy')
                        : (isAr ? 'تحذير حالة التنبيهات' : 'Alarm Status Warning'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isHealthy
                          ? (theme.brightness == Brightness.dark ? Colors.teal.shade200 : Colors.teal.shade900)
                          : (theme.brightness == Brightness.dark ? Colors.amber.shade200 : Colors.amber.shade900),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAr
                        ? 'عدد التنبيهات المجدولة حالياً: $active'
                        : 'Active scheduled system alarms: $active',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isHealthy
                          ? (theme.brightness == Brightness.dark ? Colors.teal.shade300 : Colors.teal.shade800)
                          : (theme.brightness == Brightness.dark ? Colors.amber.shade300 : Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: isAr ? 'تحديث' : 'Refresh',
              onPressed: () async {
                await _loadHealthStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(bool isAr, Color primaryColor, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: primaryColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  isAr ? 'تجربة المنبهات والتنبيهات المباشرة' : 'Test Live Alarms & Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'جدولة منبه تجريبي يعمل بعد ٥ ثوانٍ لاختبار صوت الأذان والتنبيه المسبق'
                  : 'Schedule a test alarm that fires in 5 seconds to test background audio.',
              style: TextStyle(fontSize: 12.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: Text(
                      isAr ? 'تجربة الأذان (٥ث)' : 'Test Adhan (5s)',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final testTime = DateTime.now().add(const Duration(seconds: 5));
                      final selectedReciter = _storage?.getString('adhan_reciter', defaultValue: 'mishary') ?? 'mishary';
                      final rawName = AdhanAudioService.standardReciterUrls[selectedReciter]
                          ?.replaceAll('.mp3', '') ?? 'adhan_meshary_al_fasy_kuwait';
                      await AdhanNativeController.instance.schedulePrayerAlarm(
                        id: 9999,
                        time: testTime,
                        mp3ResName: rawName,
                        prayerName: isAr ? 'الظهر' : 'Dhuhr',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تمت جدولة الأذان التجريبي! سيعمل خلال ٥ ثوانٍ...'
                                  : 'Test Adhan scheduled! It will ring in 5 seconds...',
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.alarm_on, size: 18),
                    label: Text(
                      isAr ? 'تنبيه مسبق (٥ث)' : 'Test Pre-Alert (5s)',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final testTime = DateTime.now().add(const Duration(seconds: 5));
                      await AdhanNativeController.instance.schedulePreAdhanAlarm(
                        id: 9998,
                        time: testTime,
                        prayerName: isAr ? 'الظهر' : 'Dhuhr',
                        minutesBefore: 15,
                        alertMode: 'sound',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تمت جدولة التنبيه المسبق التجريبي! سيعمل خلال ٥ ثوانٍ...'
                                  : 'Test Pre-Adhan alert scheduled! It will fire in 5 seconds...',
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String prayer, bool isAr, Color primaryColor, ThemeData theme) {
    final prayerName = isAr ? _prayerNamesAr[prayer]! : _prayerNamesEn[prayer]!;
    final String modeKey = 'adhan_mode_$prayer';
    final String offsetKey = 'pre_adhan_${prayer}_minutes';
    final String preModeKey = 'pre_adhan_${prayer}_mode';
    final String reciterKeyName = prayer == 'fajr' ? 'fajr_adhan_reciter' : 'adhan_reciter_$prayer';

    final currentMode = _storage?.getString(modeKey, defaultValue: 'real_reciter') ?? 'real_reciter';
    final currentOffset = _storage?.getInt(offsetKey, defaultValue: prayer == 'fajr' ? 20 : (prayer == 'maghrib' ? 10 : 15)) ?? 15;
    final currentPreMode = _storage?.getString(preModeKey, defaultValue: 'vibrate') ?? 'vibrate';
    final currentReciter = _storage?.getString(reciterKeyName) ?? _storage?.getString('adhan_reciter', defaultValue: 'mishary') ?? 'mishary';

    final reciterOptions = prayer == 'fajr'
        ? (isAr ? _fajrRecitersAr : _fajrRecitersEn)
        : (isAr ? _standardRecitersAr : _standardRecitersEn);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.12),
          child: Icon(Icons.mosque, color: primaryColor, size: 20),
        ),
        title: Text(
          prayerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          isAr
              ? '${_getModeLabel(currentMode, isAr)} • تنبيه مسبق: $currentOffset د'
              : '${_getModeLabel(currentMode, isAr)} • Pre-alert: ${currentOffset}m',
          style: TextStyle(fontSize: 12.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Adhan Alert Mode Dropdown
                Text(
                  isAr ? 'نمط تنبيه الأذان:' : 'Adhan Alert Mode:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
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
                  ),
                ),
                const SizedBox(height: 14),

                // Reciter Selection with Preview Button
                if (currentMode == 'real_reciter' || currentMode == 'takbeer_only') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'المؤذن المفضل:' : 'Preferred Reciter:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          _previewingReciter == currentReciter
                              ? Icons.stop_circle
                              : Icons.play_circle_fill,
                          color: primaryColor,
                          size: 20,
                        ),
                        label: Text(
                          _previewingReciter == currentReciter
                              ? (isAr ? 'إيقاف' : 'Stop')
                              : (isAr ? 'استماع' : 'Listen'),
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        onPressed: () {
                          _togglePreview(currentReciter, prayer == 'fajr');
                        },
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: reciterOptions.containsKey(currentReciter) ? currentReciter : 'mishary',
                        items: reciterOptions.entries.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(fontSize: 13.5)),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            await _storage?.setString(reciterKeyName, val);
                            await _storage?.setString('adhan_reciter', val);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Divider(height: 1),
                const SizedBox(height: 14),

                // Pre-Adhan Offset Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'وقت التنبيه المسبق:' : 'Pre-Adhan Alert Time:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$currentOffset ${isAr ? 'دقيقة قبل الأذان' : 'mins before'}',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
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
                  isAr ? 'صوت التنبيه المسبق:' : 'Pre-Adhan Alert Sound:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalOptions(bool isAr, Color primaryColor, ThemeData theme) {
    final bool volumeRamp = _storage?.getBool('volume_ramp_up', defaultValue: true) ?? true;
    final bool postDua = _storage?.getBool('post_adhan_dua', defaultValue: true) ?? true;
    final bool autoDnd = _storage?.getBool('auto_dnd_enabled', defaultValue: false) ?? false;
    final int dndMins = _storage?.getInt('auto_dnd_minutes', defaultValue: 20) ?? 20;
    final bool escalating = _storage?.getBool('escalating_reminders', defaultValue: false) ?? false;
    final bool jumuah = _storage?.getBool('jumuah_reminder', defaultValue: true) ?? true;
    final int jumuahMins = _storage?.getInt('jumuah_minutes_before', defaultValue: 60) ?? 60;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            activeColor: primaryColor,
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
            activeColor: primaryColor,
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
            activeColor: primaryColor,
            title: Text(isAr ? 'وضع عدم الإزعاج التلقائي أثناء الصلاة' : 'Auto Silence (DND) During Prayer'),
            subtitle: Text(isAr ? 'تفعيل الوضع الصامت تلقائياً عند وقت الصلاة واستعادته بعدها' : 'Automatically silences phone during prayer time and restores sound afterwards'),
            value: autoDnd,
            onChanged: (val) async {
              await _storage?.setBool('auto_dnd_enabled', val);
              setState(() {});
            },
          ),
          if (autoDnd)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'مدة الوضع الصامت:' : 'Silence Duration:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: [15, 20, 25, 30, 45].contains(dndMins) ? dndMins : 20,
                        items: [15, 20, 25, 30, 45].map((m) => DropdownMenuItem(value: m, child: Text('$m ${isAr ? 'دقيقة' : 'mins'}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            await _storage?.setInt('auto_dnd_minutes', val);
                            await _storage?.setInt('auto_dnd_duration', val);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          SwitchListTile(
            activeColor: primaryColor,
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
            activeColor: primaryColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'التنبيه قبل صلاة الجمعة بـ:' : 'Jumu\'ah Reminder Offset:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: [30, 45, 60, 90].contains(jumuahMins) ? jumuahMins : 60,
                        items: [30, 45, 60, 90].map((m) => DropdownMenuItem(value: m, child: Text('$m ${isAr ? 'دقيقة' : 'mins'}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            await _storage?.setInt('jumuah_minutes_before', val);
                            setState(() {});
                          }
                        },
                      ),
                    ),
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
