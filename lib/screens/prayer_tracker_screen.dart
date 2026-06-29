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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAr ? 'متتبع الصلوات' : 'Prayer Tracker',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE5C158),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE5C158),
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          tabs: [
            Tab(text: isAr ? 'اليوم' : 'Today'),
            Tab(text: isAr ? 'إحصائيات' : 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildDailyView(isAr, theme), _buildStatsView(isAr, theme)],
            ),
    );
  }

  Widget _buildDailyView(bool isAr, ThemeData theme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFFE5C158)),
                onPressed: () {
                  setState(
                    () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
                  );
                  _loadData();
                },
              ),
              Text(
                DateFormat('EEEE, MMM d', isAr ? 'ar' : 'en').format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _formatDate(_selectedDate) == _formatDate(DateTime.now())
                      ? Colors.grey.withOpacity(0.3)
                      : const Color(0xFFE5C158),
                ),
                onPressed: _formatDate(_selectedDate) == _formatDate(DateTime.now())
                    ? null
                    : () {
                        setState(
                          () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
                        );
                        _loadData();
                      },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _prayers.length,
            itemBuilder: (context, index) {
              final prayerKey = _prayers[index];
              final prayerName = isAr ? _prayersAr[index] : _prayersEn[index];
              final status = _todayTracker?[prayerKey] as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _togglePrayer(prayerKey, status),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status, theme),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusBorderColor(status),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStatusText(status, isAr),
                              style: TextStyle(
                                fontSize: 13,
                                color: _getStatusTextColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusIconBgColor(status),
                            shape: BoxShape.circle,
                          ),
                          child: _getStatusIcon(status),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            isAr
                ? 'اضغط على الصلاة لتغيير حالتها'
                : 'Tap on a prayer to change its status',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getStatusBgColor(int status, ThemeData theme) {
    switch (status) {
      case 1:
        return const Color(0xFF4CAF50).withOpacity(0.05); // Green tint
      case 2:
        return const Color(0xFFE5C158).withOpacity(0.08); // Gold tint
      default:
        return theme.cardColor;
    }
  }

  Color _getStatusBorderColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF4CAF50).withOpacity(0.5);
      case 2:
        return const Color(0xFFE5C158).withOpacity(0.6);
      default:
        return Colors.white10;
    }
  }

  Color _getStatusTextColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFFE5C158);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusIconBgColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF4CAF50).withOpacity(0.15);
      case 2:
        return const Color(0xFFE5C158).withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  String _getStatusText(int status, bool isAr) {
    switch (status) {
      case 1:
        return isAr ? 'صُليت' : 'Prayed';
      case 2:
        return isAr ? 'صليت في جماعة' : 'Prayed in Jamaah';
      default:
        return isAr ? 'لم تُصلى' : 'Not Prayed';
    }
  }

  Widget _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return const Icon(Icons.check, color: Color(0xFF4CAF50), size: 24);
      case 2:
        return const Icon(Icons.people, color: Color(0xFFE5C158), size: 24);
      default:
        return const Icon(Icons.circle_outlined, color: Colors.grey, size: 24);
    }
  }

  Widget _buildStatsView(bool isAr, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('weekly', isAr ? 'هذا الأسبوع' : 'This Week', isAr, theme),
        const SizedBox(height: 16),
        _buildStatCard('monthly', isAr ? 'هذا الشهر' : 'This Month', isAr, theme),
        const SizedBox(height: 16),
        _buildStatCard('yearly', isAr ? 'هذا العام' : 'This Year', isAr, theme),
      ],
    );
  }

  Widget _buildStatCard(String period, String title, bool isAr, ThemeData theme) {
    final data = _stats[period]!;
    final total = data['total']!;
    if (total == 0) return const SizedBox.shrink();

    final prayed = data['prayed']!;
    final jamaah = data['jamaah']!;
    final missed = data['missed']!;
    final totalPrayed = prayed + jamaah;
    final prayedPct = total > 0 ? (totalPrayed / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(prayedPct * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE5C158),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: prayedPct,
              backgroundColor: theme.scaffoldBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                prayedPct > 0.8 ? const Color(0xFFE5C158) : const Color(0xFF4CAF50),
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(isAr ? 'صُليت' : 'Prayed', prayed, const Color(0xFF4CAF50), theme),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildStatItem(isAr ? 'جماعة' : 'Jamaah', jamaah, const Color(0xFFE5C158), theme),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildStatItem(isAr ? 'فائتة' : 'Missed', missed, Colors.redAccent, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
