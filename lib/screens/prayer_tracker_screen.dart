import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/translation_service.dart';
import '../theme/app_colors.dart';

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({Key? key}) : super(key: key);

  @override
  _PrayerTrackerScreenState createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _todayTracker;
  bool _isLoading = true;

  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final List<String> _prayersAr = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  final List<String> _prayersEn = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  Map<String, Map<String, int>> _stats = {
    'weekly': {'prayed': 0, 'missed': 0, 'jamaah': 0, 'total': 0},
    'monthly': {'prayed': 0, 'missed': 0, 'jamaah': 0, 'total': 0},
    'yearly': {'prayed': 0, 'missed': 0, 'jamaah': 0, 'total': 0},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.getInstance();

    // ponytail: One DB call for the whole year, filter in memory
    _todayTracker = await db.getPrayerTracker(_formatDate(_selectedDate));

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final yearlyList = await db.getPrayerTrackerRange(
      _formatDate(yearStart),
      _formatDate(yearEnd),
    );

    _calculateStats('yearly', yearStart, yearEnd, yearlyList);
    _calculateStats(
      'monthly',
      monthStart,
      monthEnd,
      yearlyList.where((e) {
        final d = DateTime.parse(e['date'] as String);
        return d.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            d.isBefore(monthEnd.add(const Duration(days: 1)));
      }),
    );
    _calculateStats(
      'weekly',
      weekStart,
      weekEnd,
      yearlyList.where((e) {
        final d = DateTime.parse(e['date'] as String);
        return d.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            d.isBefore(weekEnd.add(const Duration(days: 1)));
      }),
    );

    if (mounted) setState(() => _isLoading = false);
  }

  void _calculateStats(
    String period,
    DateTime start,
    DateTime end,
    Iterable<Map<String, dynamic>> list,
  ) {
    int prayed = 0, jamaah = 0, missed = 0;

    for (var item in list) {
      for (var p in _prayers) {
        final val = item[p] as int? ?? 0;
        if (val == 1)
          prayed++;
        else if (val == 2)
          jamaah++;
        else
          missed++;
      }
    }

    final daysInPeriod = DateTime.now().difference(start).inDays + 1;
    final validDays = daysInPeriod > end.difference(start).inDays + 1
        ? end.difference(start).inDays + 1
        : daysInPeriod;
    final total = validDays * 5;

    missed = total - (prayed + jamaah);
    if (missed < 0) missed = 0;

    _stats[period] = {
      'prayed': prayed,
      'jamaah': jamaah,
      'missed': missed,
      'total': total,
    };
  }

  Future<void> _togglePrayer(String prayer, int currentStatus) async {
    final db = await DatabaseService.getInstance();
    // 0 = Not set/Missed, 1 = Prayed Alone, 2 = Prayed in Jamaah
    int nextStatus = (currentStatus + 1) % 3;
    await db.updatePrayerTracker(
      _formatDate(_selectedDate),
      prayer,
      nextStatus,
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = TranslationService.isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'متتبع الصلوات' : 'Prayer Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isAr ? 'اليوم' : 'Today'),
            Tab(text: isAr ? 'إحصائيات' : 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildDailyView(isAr), _buildStatsView(isAr)],
            ),
    );
  }

  Widget _buildDailyView(bool isAr) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(
                    () => _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    ),
                  );
                  _loadData();
                },
              ),
              Text(
                DateFormat(
                  'EEEE, MMM d',
                  isAr ? 'ar' : 'en',
                ).format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    _formatDate(_selectedDate) == _formatDate(DateTime.now())
                    ? null
                    : () {
                        setState(
                          () => _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          ),
                        );
                        _loadData();
                      },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _prayers.length,
            itemBuilder: (context, index) {
              final prayerKey = _prayers[index];
              final prayerName = isAr ? _prayersAr[index] : _prayersEn[index];
              final status = _todayTracker?[prayerKey] as int? ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(prayerName, style: const TextStyle(fontSize: 18)),
                  subtitle: Text(_getStatusText(status, isAr)),
                  trailing: _getStatusIcon(status),
                  onTap: () => _togglePrayer(prayerKey, status),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            isAr
                ? 'اضغط على الصلاة لتغيير حالتها (لم تُصلى -> صُليت -> جماعة)'
                : 'Tap on a prayer to change its status (Missed -> Prayed -> Jamaah)',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _getStatusText(int status, bool isAr) {
    switch (status) {
      case 1:
        return isAr ? 'صُليت' : 'Prayed';
      case 2:
        return isAr ? 'جماعة' : 'Jamaah';
      default:
        return isAr ? 'لم تُصلى' : 'Not Prayed/Missed';
    }
  }

  Widget _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return const Icon(Icons.check_circle, color: Colors.green);
      case 2:
        return const Icon(Icons.people, color: AppColors.teal);
      default:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }

  Widget _buildStatsView(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('weekly', isAr ? 'هذا الأسبوع' : 'This Week', isAr),
        const SizedBox(height: 16),
        _buildStatCard('monthly', isAr ? 'هذا الشهر' : 'This Month', isAr),
        const SizedBox(height: 16),
        _buildStatCard('yearly', isAr ? 'هذا العام' : 'This Year', isAr),
      ],
    );
  }

  Widget _buildStatCard(String period, String title, bool isAr) {
    final data = _stats[period]!;
    final total = data['total']!;
    if (total == 0) return const SizedBox.shrink();

    final prayed = data['prayed']!;
    final jamaah = data['jamaah']!;
    final missed = data['missed']!;

    final prayedPct = ((prayed + jamaah) / total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: prayedPct,
              backgroundColor: Colors.red.withOpacity(0.3),
              color: AppColors.teal,
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(isAr ? 'صُليت' : 'Prayed', prayed, Colors.green),
                _buildStatItem(
                  isAr ? 'جماعة' : 'Jamaah',
                  jamaah,
                  AppColors.teal,
                ),
                _buildStatItem(isAr ? 'فائتة' : 'Missed', missed, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
