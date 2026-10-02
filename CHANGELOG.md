# Changelog

## [1.3.5] - 2026-10-02

### Added
- **Multi-Edition Translations**: CDN-backed Quran translations for 8 global editions with instant offline caching and memory persistence.
- **Bundled Offline Tafsirs**: 8 complete Tafsir editions bundled offline with binary language filtering (Arabic / English) and quick preview sheets.

### Fixed
- **Clean Translation Text**: Stripped raw HTML tags (`<i>`, `<b>`, `<footnote>`, `<sup>`) and unescaped HTML entities across reader displays and ayah share dialogs.
- **Hadith Keyboard Avoidance**: Floating pagination capsule automatically hides when virtual keyboard opens to avoid obscuring search results.
- **Reader Performance**: Optimized reading mode selectors, database lookups, and memory footprint.

## [1.3.4] - 2026-10-02

### Added
- **15-Line Madinah Mushaf**: Added authentic 15-line Madinah Mushaf layout mode with dynamic Quran text scaling, pinch-to-zoom gestures, and quick Tafsir action sheets.
- **FTS5 Verse Search**: High-performance SQLite FTS5 Quranic verse search with query term highlighting.
- **Compact Hadith Navigation**: Floating pagination pill with direct jump-to-page dialog replacing oversized bottom bar.

### Fixed
- **Offline English Tafsir**: Resolved offline English Tafsir caching and offline storage initialization.
- **Hadith Reader View**: Fixed cutoff text and autoscroll pause/resume state machine.
- **Full-Text Visibility**: Added floating navigation bar bottom inset padding across all Hadith collections.

## [1.3.3] - 2026-09-29

### Changed
- **Hijri Calendar Streamlining**: Removed the redundant selected day prayer time strip from the Hijri Calendar view to give full focus to lunar days and Islamic holy events.
- **Redesigned Hijri Calendar**: Modern 7x6 month grid displaying dual Gregorian and Hijri dates with spanning Hijri month header titles.
- **Upcoming Holy Days**: Chronological listing of upcoming Islamic occasions with countdown pill badges and bilingual event titles.
- **Prayer Tracker Statistics Overhaul**: Time-aware prayer checks preventing premature false missed prayers for today's upcoming times and removing unfair pre-install penalties.

## [1.0.3] - 2026-07-13

### Added
- **Surah Pager Navigation**: Converted the Surah Reader architecture to an interactive `PageView`, enabling smooth, WhatsApp-style gesture peeking and native swipe-to-turn transitions between all 114 Surahs.
- **Animated Ayah Highlights**: Upgraded the active verse highlighting in List Mode to use `AnimatedContainer`, bringing smooth, seamless color transitions instead of harsh snapping.
- **Notification Toggles**: Added complete "Off" capabilities for Pre-Adhan alerts and all Adhan notifications within the onboarding sequence, respecting zero-alert user preferences.

### Fixed
- **Audio Engine Stability**: Clamped out-of-bounds positioning logic to resolve crashes when scrubbing (seeking forward/backward) through long local audio files.
- **Timestamp Caching Bug**: Fixed an issue where QDC JSON metadata missing the `audio_url` key would be permanently cached, causing timing sync drift.
- **Variable Bitrate (VBR) Audio Drift**: Implemented a Periodic Auto-Seek Syncing algorithm that silently micro-seeks the internal audio clock at every Ayah boundary, completely eliminating desync in massive audio files like Surah Al-Baqarah.
