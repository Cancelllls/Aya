import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/offline_prayer_service.dart';
import '../models/prayer_models.dart';
import '../services/translation_service.dart';
import '../services/prayer_tracker_stats_service.dart';

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final Map<String, Map<String, dynamic>> _trackerData = {};
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  PrayerTimeData? _selectedDatePrayerTimes;
  PrayerTimeData? _todayPrayerTimes;
  int _firstDayOfWeek = 1;

  final List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final List<String> _prayersAr = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];
  final List<String> _prayersEn = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  final Map<String, Map<String, int>> _stats = {
    'weekly': {'prayed': 0, 'missed': 0, 'total': 0},
    'monthly': {'prayed': 0, 'missed': 0, 'total': 0},
    'yearly': {'prayed': 0, 'missed': 0, 'total': 0},
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _loadPrayerTimesForSelectedDate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayPrayerTimes() async {
    try {
      final storage = await StorageService.getInstance();
      final location = storage.getLocation();
      final lat = location['lat'] as double? ?? 0.0;
      final lng = location['lng'] as double? ?? 0.0;
      final method = storage.getInt('prayer_method', defaultValue: 3);
      final school = storage.getInt('prayer_school', defaultValue: 0);

      if (lat != 0.0 && lng != 0.0) {
        final times = await OfflinePrayerService.getPrayerTimes(
          latitude: lat,
          longitude: lng,
          method: method,
          school: school,
          date: DateTime.now(),
        );
        _todayPrayerTimes = times;
      }
    } catch (_) {}
  }

  bool _isPrayerPassedToday(String prayerKey) {
    final now = DateTime.now();
    if (_todayPrayerTimes != null) {
      String timeStr = '';
      switch (prayerKey) {
        case 'fajr':
          timeStr = _todayPrayerTimes!.fajr;
          break;
        case 'dhuhr':
          timeStr = _todayPrayerTimes!.dhuhr;
          break;
        case 'asr':
          timeStr = _todayPrayerTimes!.asr;
          break;
        case 'maghrib':
          timeStr = _todayPrayerTimes!.maghrib;
          break;
        case 'isha':
          timeStr = _todayPrayerTimes!.isha;
          break;
      }
      if (timeStr.isNotEmpty) {
        try {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0].trim());
          final minute = int.parse(parts[1].trim());
          final pTime = DateTime(now.year, now.month, now.day, hour, minute);
          return now.isAfter(pTime);
        } catch (_) {}
      }
    }
    // Fallback if prayer times unavailable: standard rough hours
    switch (prayerKey) {
      case 'fajr':
        return now.hour >= 6;
      case 'dhuhr':
        return now.hour >= 13;
      case 'asr':
        return now.hour >= 16;
      case 'maghrib':
        return now.hour >= 19;
      case 'isha':
        return now.hour >= 21;
    }
    return false;
  }

  Map<String, DateTime> _getPeriodBounds(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (period == 'weekly') {
      int daysToSubtract = (today.weekday - _firstDayOfWeek) % 7;
      if (daysToSubtract < 0) daysToSubtract += 7;
      final weekStart = today.subtract(Duration(days: daysToSubtract));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return {'start': weekStart, 'end': weekEnd};
    } else if (period == 'monthly') {
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      return {'start': monthStart, 'end': monthEnd};
    } else {
      final yearStart = DateTime(_selectedYear, 1, 1);
      final yearEnd = DateTime(_selectedYear, 12, 31);
      return {'start': yearStart, 'end': yearEnd};
    }
  }

  void _recomputeAllStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final weeklyBounds = _getPeriodBounds('weekly');
    final monthlyBounds = _getPeriodBounds('monthly');
    final yearlyBounds = _getPeriodBounds('yearly');

    _stats['weekly'] = PrayerTrackerStatsCalculator.calculateStats(
      start: weeklyBounds['start']!,
      end: weeklyBounds['end']!,
      today: today,
      trackerData: _trackerData,
      isPrayerPassedToday: _isPrayerPassedToday,
    );

    _stats['monthly'] = PrayerTrackerStatsCalculator.calculateStats(
      start: monthlyBounds['start']!,
      end: monthlyBounds['end']!,
      today: today,
      trackerData: _trackerData,
      isPrayerPassedToday: _isPrayerPassedToday,
    );

    _stats['yearly'] = PrayerTrackerStatsCalculator.calculateStats(
      start: yearlyBounds['start']!,
      end: yearlyBounds['end']!,
      today: today,
      trackerData: _trackerData,
      isPrayerPassedToday: _isPrayerPassedToday,
    );
  }

  Future<void> _loadPrayerTimesForSelectedDate() async {
    try {
      final storage = await StorageService.getInstance();
      final location = storage.getLocation();
      final lat = location['lat'] as double? ?? 0.0;
      final lng = location['lng'] as double? ?? 0.0;
      final method = storage.getInt('prayer_method', defaultValue: 3);
      final school = storage.getInt('prayer_school', defaultValue: 0);

      if (lat != 0.0 && lng != 0.0) {
        final times = await OfflinePrayerService.getPrayerTimes(
          latitude: lat,
          longitude: lng,
          method: method,
          school: school,
          date: _selectedDate,
        );
        if (mounted) {
          setState(() {
            _selectedDatePrayerTimes = times;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  List<DateTime> _getDaysInMonth() {
    final int daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    return List.generate(
      daysInMonth,
      (i) => DateTime(_selectedMonth.year, _selectedMonth.month, i + 1),
    );
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    await _loadTodayPrayerTimes();
    final db = await DatabaseService.getInstance();

    final now = DateTime.now();
    final minYear = _selectedYear < now.year ? _selectedYear : now.year;
    final maxYear = _selectedYear > now.year ? _selectedYear : now.year;

    final storage = await StorageService.getInstance();
    _firstDayOfWeek = storage.getInt('first_day_of_week', defaultValue: 1);

    final yearlyList = await db.getPrayerTrackerRange(
      '$minYear-01-01',
      '$maxYear-12-31',
    );

    // Build map for quick lookup
    _trackerData.clear();
    for (var item in yearlyList) {
      _trackerData[item['date'] as String] = Map<String, dynamic>.from(item);
    }

    _recomputeAllStats();

    if (mounted) {
      if (showLoading) {
        setState(() => _isLoading = false);
      } else {
        setState(() {}); // Just rebuild
      }
    }
  }

  Future<void> _togglePrayerForDate(
    DateTime date,
    String prayer,
    int currentStatus,
  ) async {
    final db = await DatabaseService.getInstance();
    int nextStatus = currentStatus > 0 ? 0 : 1;
    final dateStr = _formatDate(date);

    setState(() {
      if (_trackerData[dateStr] == null) {
        _trackerData[dateStr] = {
          'date': dateStr,
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        };
      }
      _trackerData[dateStr]![prayer] = nextStatus;
      _recomputeAllStats();
    });

    await db.updatePrayerTracker(dateStr, prayer, nextStatus);
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
          indicatorColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
          indicatorWeight: 2,
          labelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
            0.5,
          ),
          tabs: [
            Tab(text: isAr ? 'التقويم' : 'Monthly'),
            Tab(text: isAr ? 'السنة' : 'Yearly'),
            Tab(text: isAr ? 'إحصائيات' : 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.grey))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarView(isAr, theme),
                _buildYearlyView(isAr, theme),
                _buildStatsView(isAr, theme),
              ],
            ),
    );
  }

  Widget _buildCalendarView(bool isAr, ThemeData theme) {
    final days = _getDaysInMonth();
    final monthStr = DateFormat(
      'MMMM yyyy',
      isAr ? 'ar' : 'en',
    ).format(_selectedMonth);

    return Column(
      children: [
        // Month Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                onPressed: () {
                  setState(
                    () => _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                      1,
                    ),
                  );
                },
              ),
              Text(
                monthStr.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                onPressed: () {
                  setState(
                    () => _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    ),
                  );
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
            children:
                (() {
                      final baseEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final baseAr = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
                      final base = TranslationService.isArabic
                          ? baseAr
                          : baseEn;
                      final rotate = _firstDayOfWeek - 1;
                      return [
                        ...base.sublist(rotate),
                        ...base.sublist(0, rotate),
                      ];
                    })()
                    .map(
                      (d) => SizedBox(
                        width: 30,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
            itemCount:
                days.length +
                ((days.first.weekday - _firstDayOfWeek) % 7 < 0
                    ? (days.first.weekday - _firstDayOfWeek) % 7 + 7
                    : (days.first.weekday - _firstDayOfWeek) % 7),
            itemBuilder: (context, index) {
              int emptySlots = (days.first.weekday - _firstDayOfWeek) % 7;
              if (emptySlots < 0) emptySlots += 7;

              if (index < emptySlots) {
                return const SizedBox.shrink();
              }

              final date = days[index - emptySlots];
              final dateStr = _formatDate(date);
              final dayData = _trackerData[dateStr] ?? {};

              List<bool> prayersDone = [];
              for (var p in _prayers) {
                prayersDone.add((dayData[p] as int? ?? 0) > 0);
              }

              final isSelected = _formatDate(_selectedDate) == dateStr;
              final isToday = _formatDate(DateTime.now()) == dateStr;

              Color completeColor = theme.primaryColor;
              Color incompleteColor = theme.dividerColor.withValues(alpha: 0.1);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  _loadPrayerTimesForSelectedDate();
                },
                child: CustomPaint(
                  painter: PrayerPiePainter(
                    prayers: prayersDone,
                    completeColor: completeColor,
                    incompleteColor: incompleteColor,
                    backgroundColor: theme.scaffoldBackgroundColor,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color:
                                  theme.textTheme.bodyLarge?.color ??
                                  Colors.white,
                              width: 2.0,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday && !isSelected
                              ? theme.primaryColor
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Selected Day Details
        Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: _buildPlannerDayBlock(
              _selectedDate,
              _trackerData[_formatDate(_selectedDate)] ?? {},
              isAr,
              theme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlannerDayBlock(
    DateTime date,
    Map<String, dynamic> data,
    bool isAr,
    ThemeData theme,
  ) {
    final isToday = _formatDate(date) == _formatDate(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat(
                  'EEEE, d MMMM',
                  isAr ? 'ar' : 'en',
                ).format(date).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: isToday
                      ? theme.textTheme.bodyLarge?.color
                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
              if (isToday) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
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
              ] else ...[
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: theme.primaryColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _selectedDate = DateTime.now());
                    _loadPrayerTimesForSelectedDate();
                  },
                  child: Text(
                    isAr ? 'اليوم' : 'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          ..._prayers.asMap().entries.map((e) {
            final idx = e.key;
            final pKey = e.value;
            final pName = isAr ? _prayersAr[idx] : _prayersEn[idx];
            final status = data[pKey] as int? ?? 0;

            String supposedTime = '';
            if (_selectedDatePrayerTimes != null) {
              switch (pKey) {
                case 'fajr':
                  supposedTime = _selectedDatePrayerTimes!.fajr;
                  break;
                case 'dhuhr':
                  supposedTime = _selectedDatePrayerTimes!.dhuhr;
                  break;
                case 'asr':
                  supposedTime = _selectedDatePrayerTimes!.asr;
                  break;
                case 'maghrib':
                  supposedTime = _selectedDatePrayerTimes!.maghrib;
                  break;
                case 'isha':
                  supposedTime = _selectedDatePrayerTimes!.isha;
                  break;
              }
            }

            return _buildPlannerChecklist(
              date,
              pKey,
              pName,
              status,
              isAr,
              theme,
              supposedTime,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlannerChecklist(
    DateTime date,
    String prayerKey,
    String prayerName,
    int status,
    bool isAr,
    ThemeData theme,
    String supposedTime,
  ) {
    final bool isCompleted = status > 0;

    return InkWell(
      onTap: () => _togglePrayerForDate(date, prayerKey, status),
      splashColor: Colors.transparent,
      highlightColor: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check : Icons.circle_outlined,
              size: 20,
              color: isCompleted
                  ? theme.primaryColor
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                prayerName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? theme.primaryColor
                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                  decoration: null,
                  decorationColor: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (supposedTime.isNotEmpty)
              Text(
                supposedTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyView(bool isAr, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                onPressed: () {
                  setState(() => _selectedYear--);
                  _loadData();
                },
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                onPressed: () {
                  setState(() => _selectedYear++);
                  _loadData();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthDate = DateTime(_selectedYear, index + 1, 1);
              final monthStr = DateFormat(
                'MMMM yyyy',
                isAr ? 'ar' : 'en',
              ).format(monthDate);
              final int daysInMonth = DateTime(
                monthDate.year,
                monthDate.month + 1,
                0,
              ).day;
              final firstDayWeekday = monthDate.weekday;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      monthStr.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: daysInMonth + (firstDayWeekday - 1),
                    itemBuilder: (context, dayIndex) {
                      if (dayIndex < firstDayWeekday - 1) {
                        return const SizedBox.shrink();
                      }

                      final day = dayIndex - (firstDayWeekday - 1) + 1;
                      final date = DateTime(
                        monthDate.year,
                        monthDate.month,
                        day,
                      );
                      final dateStr = _formatDate(date);
                      final dayData = _trackerData[dateStr] ?? {};

                      List<bool> prayersDone = [];
                      for (var p in _prayers) {
                        prayersDone.add((dayData[p] as int? ?? 0) > 0);
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedMonth = DateTime(date.year, date.month, 1);
                            _tabController.animateTo(0);
                          });
                          _loadPrayerTimesForSelectedDate();
                        },
                        child: CustomPaint(
                          painter: PrayerPiePainter(
                            prayers: prayersDone,
                            completeColor: theme.primaryColor,
                            incompleteColor: theme.dividerColor.withValues(alpha: 
                              0.1,
                            ),
                            backgroundColor: theme.scaffoldBackgroundColor,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      (Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color ??
                                              Colors.white)
                                          .withValues(alpha: 0.9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView(bool isAr, ThemeData theme) {
    final allTotal = (_stats['weekly']?['total'] ?? 0) +
        (_stats['monthly']?['total'] ?? 0) +
        (_stats['yearly']?['total'] ?? 0);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (allTotal == 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAr
                        ? 'سجّل صلواتك في تبويب اليوم لبدء تتبّع إحصاءاتك وتقدمك.'
                        : 'Track your daily prayers in the Today tab to see your progress and statistics here.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _buildMinimalistStatCard(
          'weekly',
          isAr ? 'هذا الأسبوع' : 'This Week',
          isAr,
          theme,
        ),
        const SizedBox(height: 32),
        _buildMinimalistStatCard(
          'monthly',
          isAr ? 'هذا الشهر' : 'This Month',
          isAr,
          theme,
        ),
        const SizedBox(height: 32),
        _buildMinimalistStatCard(
          'yearly',
          isAr ? 'هذا العام' : 'This Year',
          isAr,
          theme,
        ),
      ],
    );
  }

  Widget _buildMinimalistStatCard(
    String period,
    String title,
    bool isAr,
    ThemeData theme,
  ) {
    final data = _stats[period] ?? {'prayed': 0, 'missed': 0, 'total': 0};
    final total = data['total'] ?? 0;
    final prayed = data['prayed'] ?? 0;
    final missed = data['missed'] ?? 0;
    final prayedPct = total > 0 ? (prayed / total).clamp(0.0, 1.0) : 0.0;

    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final errorColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

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
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            Text(
              total > 0 ? "${(prayedPct * 100).toInt()}%" : "—",
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
            backgroundColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.primaryColor,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMinimalStatItem(
              isAr ? 'صلوات صُليت' : 'Prayers Done',
              prayed,
              theme,
              color: prayed > 0 ? successColor : null,
            ),
            _buildMinimalStatItem(
              isAr ? 'صلوات فائتة' : 'Prayers Missed',
              missed,
              theme,
              color: missed > 0 ? errorColor : null,
            ),
            _buildMinimalStatItem(
              isAr ? 'إجمالي المطلوب' : 'Total Due',
              total,
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalStatItem(
    String label,
    int value,
    ThemeData theme, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color ?? theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class PrayerPiePainter extends CustomPainter {
  final List<bool> prayers;
  final Color completeColor;
  final Color incompleteColor;
  final Color backgroundColor;

  PrayerPiePainter({
    required this.prayers,
    required this.completeColor,
    required this.incompleteColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double sweepAngle = 2 * 3.141592653589793 / 5;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (int i = 0; i < 5; i++) {
      final Paint paint = Paint()
        ..color = prayers[i] ? completeColor : incompleteColor
        ..style = PaintingStyle.fill;

      final double startAngle = -3.141592653589793 / 2 + (i * sweepAngle);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      final Paint separatorPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, separatorPaint);
    }

    // Inner hole for donut chart
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 * 0.75,
      Paint()..color = backgroundColor,
    );
  }

  @override
  bool shouldRepaint(PrayerPiePainter oldDelegate) {
    return true;
  }
}
