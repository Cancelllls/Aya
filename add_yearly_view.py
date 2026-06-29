import re

with open('lib/screens/prayer_tracker_screen.dart', 'r') as f:
    content = f.read()

# Change TabController length
content = content.replace(
    '_tabController = TabController(length: 2, vsync: this);',
    '_tabController = TabController(length: 3, vsync: this);'
)

# Add Yearly Tab
content = content.replace(
    """          tabs: [
            Tab(text: isAr ? 'التقويم' : 'Calendar'),
            Tab(text: isAr ? 'إحصائيات' : 'Statistics'),
          ],""",
    """          tabs: [
            Tab(text: isAr ? 'التقويم' : 'Monthly'),
            Tab(text: isAr ? 'السنة' : 'Yearly'),
            Tab(text: isAr ? 'إحصائيات' : 'Statistics'),
          ],"""
)

# Add Yearly View to TabBarView
content = content.replace(
    """              children: [_buildCalendarView(isAr, theme), _buildStatsView(isAr, theme)],""",
    """              children: [_buildCalendarView(isAr, theme), _buildYearlyView(isAr, theme), _buildStatsView(isAr, theme)],"""
)

yearly_view_code = """
  Widget _buildYearlyView(bool isAr, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthDate = DateTime(DateTime.now().year, index + 1, 1);
        final monthStr = DateFormat('MMMM yyyy', isAr ? 'ar' : 'en').format(monthDate);
        final int daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
        final firstDayWeekday = monthDate.weekday;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Text(
                monthStr.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                final date = DateTime(monthDate.year, monthDate.month, day);
                final dateStr = _formatDate(date);
                final dayData = _trackerData[dateStr] ?? {};
                
                List<bool> prayersDone = [];
                for (var p in _prayers) {
                  prayersDone.add((dayData[p] as int? ?? 0) > 0);
                }
                
                return CustomPaint(
                  painter: PrayerPiePainter(
                    prayers: prayersDone,
                    completeColor: const Color(0xFFE5C158),
                    incompleteColor: theme.dividerColor.withOpacity(0.1),
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
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
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
    );
  }
"""

if "_buildYearlyView" not in content:
    content = content.replace("  Widget _buildStatsView", yearly_view_code + "\n  Widget _buildStatsView")

with open('lib/screens/prayer_tracker_screen.dart', 'w') as f:
    f.write(content)
