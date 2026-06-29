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
  DateTime _selectedWeek = DateTime.now();
  Map<String, Map<String, dynamic>> _weekData = {};
  bool _isLoading = true;

  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final List<String> _prayersAr = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
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

  List<DateTime> _getCurrentWeekDays() {
    final List<DateTime> days = [];
    final weekStart = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    for (int i = 0; i < 7; i++) {
      days.add(weekStart.add(Duration(days: i)));
    }
    return days;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.getInstance();

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

    final yearlyList = await db.getPrayerTrackerRange(
      _formatDate(yearStart),
      _formatDate(yearEnd),
    );

    // Build map for quick lookup
    _weekData.clear();
    for (var item in yearlyList) {
      _weekData[item['date'] as String] = item;
    }

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
      currentWeekStart,
      currentWeekEnd,
      yearlyList.where((e) {
        final d = DateTime.parse(e['date'] as String);
        return d.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
            d.isBefore(currentWeekEnd.add(const Duration(days: 1)));
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

  Future<void> _togglePrayerForDate(DateTime date, String prayer, int currentStatus) async {
    final db = await DatabaseService.getInstance();
    int nextStatus = (currentStatus + 1) % 3;
    await db.updatePrayerTracker(
      _formatDate(date),
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
          indicatorColor: theme.textTheme.bodyLarge?.color,
          indicatorWeight: 2,
          labelColor: theme.textTheme.bodyLarge?.color,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          tabs: [
            Tab(text: isAr ? 'هذا الأسبوع' : 'This Week'),
            Tab(text: isAr ? 'إحصائيات' : 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.grey),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildWeeklyPlannerView(isAr, theme), _buildStatsView(isAr, theme)],
            ),
    );
  }

  Widget _buildWeeklyPlannerView(bool isAr, ThemeData theme) {
    final weekDays = _getCurrentWeekDays();
    final weekStartStr = DateFormat('MMM d').format(weekDays.first);
    final weekEndStr = DateFormat('MMM d').format(weekDays.last);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: theme.textTheme.bodyLarge?.color),
                onPressed: () {
                  setState(
                    () => _selectedWeek = _selectedWeek.subtract(const Duration(days: 7)),
                  );
                  _loadData();
                },
              ),
              Text(
                "$weekStartStr - $weekEndStr",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _selectedWeek.isAfter(DateTime.now().subtract(const Duration(days: 7)))
                      ? Colors.grey.withOpacity(0.3)
                      : theme.textTheme.bodyLarge?.color,
                ),
                onPressed: _selectedWeek.isAfter(DateTime.now().subtract(const Duration(days: 7)))
                    ? null
                    : () {
                        setState(
                          () => _selectedWeek = _selectedWeek.add(const Duration(days: 7)),
                        );
                        _loadData();
                      },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 40),
            itemCount: weekDays.length,
            separatorBuilder: (context, index) => Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
            itemBuilder: (context, index) {
              final date = weekDays[index];
              final dateStr = _formatDate(date);
              final dayData = _weekData[dateStr] ?? {};
              return _buildPlannerDayBlock(date, dayData, isAr, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlannerDayBlock(DateTime date, Map<String, dynamic> data, bool isAr, ThemeData theme) {
    final isToday = _formatDate(date) == _formatDate(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: isToday ? theme.textTheme.bodyLarge?.color?.withOpacity(0.02) : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('EEEE', isAr ? 'ar' : 'en').format(date).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: isToday ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('d MMM', isAr ? 'ar' : 'en').format(date).toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
              ),
              if (isToday) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyLarge?.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAr ? 'اليوم' : 'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          ..._prayers.asMap().entries.map((e) {
            final idx = e.key;
            final pKey = e.value;
            final pName = isAr ? _prayersAr[idx] : _prayersEn[idx];
            final status = data[pKey] as int? ?? 0;
            return _buildPlannerChecklist(date, pKey, pName, status, isAr, theme);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPlannerChecklist(DateTime date, String prayerKey, String prayerName, int status, bool isAr, ThemeData theme) {
    final bool isCompleted = status > 0;
    final bool isJamaah = status == 2;
    
    return InkWell(
      onTap: () => _togglePrayerForDate(date, prayerKey, status),
      splashColor: Colors.transparent,
      highlightColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isCompleted ? (isJamaah ? Icons.people_outline : Icons.check) : Icons.circle_outlined,
              size: 20,
              color: isCompleted 
                  ? (isJamaah ? const Color(0xFFE5C158) : theme.textTheme.bodyLarge?.color?.withOpacity(0.7)) 
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                prayerName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
                  color: isCompleted 
                      ? theme.textTheme.bodyMedium?.color?.withOpacity(0.4) 
                      : theme.textTheme.bodyLarge?.color,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                ),
              ),
            ),
            if (isJamaah)
              Text(
                isAr ? 'جماعة' : 'Jamaah',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE5C158),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsView(bool isAr, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildMinimalistStatCard('weekly', isAr ? 'هذا الأسبوع' : 'This Week', isAr, theme),
        const SizedBox(height: 32),
        _buildMinimalistStatCard('monthly', isAr ? 'هذا الشهر' : 'This Month', isAr, theme),
        const SizedBox(height: 32),
        _buildMinimalistStatCard('yearly', isAr ? 'هذا العام' : 'This Year', isAr, theme),
      ],
    );
  }

  Widget _buildMinimalistStatCard(String period, String title, bool isAr, ThemeData theme) {
    final data = _stats[period]!;
    final total = data['total']!;
    if (total == 0) return const SizedBox.shrink();

    final prayed = data['prayed']!;
    final jamaah = data['jamaah']!;
    final missed = data['missed']!;
    final totalPrayed = prayed + jamaah;
    final prayedPct = total > 0 ? (totalPrayed / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            Text(
              "${(prayedPct * 100).toInt()}%",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w300,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: prayedPct,
            backgroundColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMinimalStatItem(isAr ? 'صُليت' : 'Prayed', prayed, theme),
            _buildMinimalStatItem(isAr ? 'جماعة' : 'Jamaah', jamaah, theme),
            _buildMinimalStatItem(isAr ? 'فائتة' : 'Missed', missed, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalStatItem(String label, int value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
