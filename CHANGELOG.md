# Changelog

## [1.0.3] - 2026-07-13

### Added
- **Surah Pager Navigation**: Converted the Surah Reader architecture to an interactive `PageView`, enabling smooth, WhatsApp-style gesture peeking and native swipe-to-turn transitions between all 114 Surahs.
- **Animated Ayah Highlights**: Upgraded the active verse highlighting in List Mode to use `AnimatedContainer`, bringing smooth, seamless color transitions instead of harsh snapping.
- **Notification Toggles**: Added complete "Off" capabilities for Pre-Adhan alerts and all Adhan notifications within the onboarding sequence, respecting zero-alert user preferences.

### Fixed
- **Audio Engine Stability**: Clamped out-of-bounds positioning logic to resolve crashes when scrubbing (seeking forward/backward) through long local audio files.
- **Timestamp Caching Bug**: Fixed an issue where QDC JSON metadata missing the `audio_url` key would be permanently cached, causing timing sync drift.
- **Variable Bitrate (VBR) Audio Drift**: Implemented a Periodic Auto-Seek Syncing algorithm that silently micro-seeks the internal audio clock at every Ayah boundary, completely eliminating desync in massive audio files like Surah Al-Baqarah.
