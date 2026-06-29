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
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Map<String, Map<String, dynamic>> _trackerData = {};
  bool _isLoading = true;

  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final List<String> _prayersAr = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  final List<String> _prayersEn = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  Map<String, Map<String, int>> _stats = {
    'weekly': {'prayed': 0, 'missed': 0, 'total': 0},
    'monthly': {'prayed': 0, 'missed': 0, 'total': 0},
    'yearly': {'prayed': 0, 'missed': 0, 'total': 0},
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

  List<DateTime> _getDaysInMonth() {
    final int daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    return List.generate(daysInMonth, (i) => DateTime(_selectedMonth.year, _selectedMonth.month, i + 1));
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
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
    _trackerData.clear();
    for (var item in yearlyList) {
      _trackerData[item['date'] as String] = item;
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

    if (mounted) {
      if (showLoading) {
        setState(() => _isLoading = false);
      } else {
        setState(() {}); // Just rebuild
      }
    }
  }

  void _calculateStats(
    String period,
    DateTime start,
    DateTime end,
    Iterable<Map<String, dynamic>> list,
  ) {
    int prayed = 0, missed = 0;

    for (var item in list) {
      for (var p in _prayers) {
        final val = item[p] as int? ?? 0;
        if (val == 1)
          prayed++;
        else
          missed++;
      }
    }

    final daysInPeriod = DateTime.now().difference(start).inDays + 1;
    final validDays = daysInPeriod > end.difference(start).inDays + 1
        ? end.difference(start).inDays + 1
        : daysInPeriod;
    final total = validDays * 5;

    missed = total - prayed;
    if (missed < 0) missed = 0;

    _stats[period] = {
      'prayed': prayed,
      'missed': missed,
      'total': total,
    };
  }

  Future<void> _togglePrayerForDate(DateTime date, String prayer, int currentStatus) async {
    final db = await DatabaseService.getInstance();
    int nextStatus = currentStatus == 1 ? 0 : 1;
    final dateStr = _formatDate(date);
    
    // ponytail: Optimistic UI update, no heavy DB reload
    setState(() {
      if (_trackerData[dateStr] == null) _trackerData[dateStr] = {};
      _trackerData[dateStr]![prayer] = nextStatus;
    });

    await db.updatePrayerTracker(
      dateStr,
      prayer,
      nextStatus,
    );
    
    // Silently reload stats in background
    _loadData(showLoading: false);
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
            Tab(text: isAr ? 'التقويم' : 'Calendar'),
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
              children: [_buildCalendarView(isAr, theme), _buildStatsView(isAr, theme)],
            ),
    );
  }

  Widget _buildCalendarView(bool isAr, ThemeData theme) {
    final days = _getDaysInMonth();
    final firstDayWeekday = days.first.weekday;
    final monthStr = DateFormat('MMMM yyyy', isAr ? 'ar' : 'en').format(_selectedMonth);
    
    return Column(
      children: [
        // Month Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: theme.textTheme.bodyLarge?.color),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
                },
              ),
              Text(
                monthStr.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: theme.textTheme.bodyLarge?.color),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
                },
              ),
            ],
          ),
        ),
        
        // Weekdays Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => 
              SizedBox(
                width: 30,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  ),
                ),
              )
            ).toList(),
          ),
        ),
        const SizedBox(height: 12),
        
        // Calendar Grid
        Expanded(
          flex: 4,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: days.length + (firstDayWeekday - 1),
            itemBuilder: (context, index) {
              if (index < firstDayWeekday - 1) {
                return const SizedBox.shrink();
              }
              
              final date = days[index - (firstDayWeekday - 1)];
              final dateStr = _formatDate(date);
              final dayData = _trackerData[dateStr] ?? {};
              
              int prayedCount = 0;
              for (var p in _prayers) {
                if ((dayData[p] as int? ?? 0) > 0) prayedCount++;
              }
              
              final isSelected = _formatDate(_selectedDate) == dateStr;
              final isToday = _formatDate(DateTime.now()) == dateStr;
              
              Color circleColor = Colors.transparent;
              Color borderColor = theme.dividerColor.withOpacity(0.2);
              
              if (prayedCount == 5) {
                circleColor = const Color(0xFFE5C158).withOpacity(0.2);
                borderColor = const Color(0xFFE5C158);
              } else if (prayedCount > 0) {
                circleColor = theme.primaryColor.withOpacity(0.1);
                borderColor = theme.primaryColor.withOpacity(0.5);
              }
              
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.textTheme.bodyLarge?.color : circleColor,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : borderColor,
                      width: isToday && !isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? theme.scaffoldBackgroundColor 
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Selected Day Details
        Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: _buildPlannerDayBlock(_selectedDate, _trackerData[_formatDate(_selectedDate)] ?? {}, isAr, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildPlannerDayBlock(DateTime date, Map<String, dynamic> data, bool isAr, ThemeData theme) {
    final isToday = _formatDate(date) == _formatDate(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('EEEE, d MMMM', isAr ? 'ar' : 'en').format(date).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: isToday ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
          const SizedBox(height: 24),
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
    
    return InkWell(
      onTap: () => _togglePrayerForDate(date, prayerKey, status),
      splashColor: Colors.transparent,
      highlightColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check : Icons.circle_outlined,
              size: 20,
              color: isCompleted 
                  ? theme.textTheme.bodyLarge?.color?.withOpacity(0.7) 
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
    final missed = data['missed']!;
    final prayedPct = total > 0 ? (prayed / total) : 0.0;

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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMinimalStatItem(isAr ? 'صُليت' : 'Prayed', prayed, theme),
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
