part of 'prayer_times_screen.dart';

extension PrayerTimesScreenUi on _PrayerTimesScreenState {
  Widget _buildPrayerScreenBody(BuildContext context, ThemeData theme, Map<String, dynamic> loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeaderCard(theme, loc),
              const SizedBox(height: 16),
              _buildSubTabSelector(theme),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPrayerTimes,
            color: const Color(0xFFE5C158),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedSubTab == 0) ...[
                    Text(
                      TranslationService.t('daily_schedule'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFFE5C158),
                              ),
                            ),
                          )
                        : _prayerData == null
                        ? Center(
                            child: Text(
                              TranslationService.isArabic
                                  ? "لم يتم تحميل مواقيت الصلاة بعد."
                                  : "No schedule details loaded.",
                            ),
                          )
                        : Column(
                            children: [
                              _buildScheduleRow(
                                theme,
                                "Fajr",
                                _prayerData!.fajr,
                                Icons.cloud_queue,
                              ),
                              _buildScheduleRow(
                                theme,
                                "Sunrise",
                                _prayerData!.sunrise,
                                Icons.wb_sunny_outlined,
                              ),
                              _buildScheduleRow(
                                theme,
                                "Dhuhr",
                                _prayerData!.dhuhr,
                                Icons.wb_sunny,
                              ),
                              _buildScheduleRow(
                                theme,
                                "Asr",
                                _prayerData!.asr,
                                Icons.wb_twilight,
                              ),
                              _buildScheduleRow(
                                theme,
                                "Sunset",
                                _prayerData!.sunset,
                                Icons.wb_twilight,
                              ),
                              _buildScheduleRow(
                                theme,
                                "Maghrib",
                                _prayerData!.maghrib,
                                Icons.wb_cloudy_outlined,
                              ),
                              _buildScheduleRow(
                                theme,
                                "Isha",
                                _prayerData!.isha,
                                Icons.nights_stay,
                              ),
                            ],
                          ),
                  ] else if (_selectedSubTab == 1) ...[
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFFE5C158),
                              ),
                            ),
                          )
                        : _buildPrayerCalendar(theme),
                  ] else ...[
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFFE5C158),
                              ),
                            ),
                          )
                        : _buildHijriCalendar(theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeaderCard(ThemeData theme, Map<String, dynamic> loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE5C158)),
              const SizedBox(width: 8),
              Text(
                "Location Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${TranslationService.t('current_location')}: ${loc['city']}, ${loc['country']}",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${TranslationService.isArabic ? 'الطريقة: الإحداثيات' : 'Method: Lat/Lng'} (${loc['latitude']?.toStringAsFixed(4) ?? '--'}, ${loc['longitude']?.toStringAsFixed(4) ?? '--'})",
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C158),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(TranslationService.t('use_gps')),
                  onPressed: _updateLocationWithGPS,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5C158)),
                    foregroundColor: const Color(0xFFE5C158),
                  ),
                  icon: const Icon(Icons.keyboard, size: 18),
                  label: Text(TranslationService.t('set_manually')),
                  onPressed: _showManualLocationDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabSelector(ThemeData theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          _buildSubTabButton(
            0,
            TranslationService.isArabic ? 'اليوم' : 'Today',
            theme,
          ),
          _buildSubTabButton(
            1,
            TranslationService.isArabic ? 'جدول الصلوات' : 'Prayer Calendar',
            theme,
          ),
          _buildSubTabButton(
            2,
            TranslationService.isArabic ? 'التقويم الهجري' : 'Hijri Calendar',
            theme,
          ),
        ],
      ),
    );
  }
}
