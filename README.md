<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Kotlin-Native-purple?style=flat-square&logo=kotlin" alt="Kotlin">
  <img src="https://img.shields.io/badge/Platform-Android%207%E2%80%9316-brightgreen?style=flat-square&logo=android" alt="Android 7–16">
  <img src="https://img.shields.io/badge/Platform-iOS-lightgrey?style=flat-square&logo=apple" alt="iOS">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT">
</p>

<h1 align="center">Aya — Islamic Companion App</h1>
<p align="center"><strong>Quran · Hadith · Prayer Times · Adhan · Azkar · Qibla · Tracker</strong></p>
<p align="center">
  <a href="https://github.com/Cancelllls/Aya/releases">Download Latest</a>
</p>

---

## Features

### Prayer Times & Adhan
- **14 calculation methods** with offline fallback — works without internet
- **Native Kotlin alarm scheduling** using `setExactAndAllowWhileIdle()` — matches Five Prayers' reliable approach, survives Doze and OEM task killers without hijacking the system clock
- **Per-prayer adhan toggle** with 8 reciters (Mishary, Abdul Basit, Madinah, Kazabri, Riad, Manssour, Nakshabandi, Maghriby)
- **Pre-adhan reminders** (5/10/15/20 min before) with vibrate/voice/both modes
- **Fajr-specific reciter** — different adhan for Fajr vs. other prayers
- **Advanced stop gestures** — flip phone face-down or press volume keys to silence

### Quran Reader
- **10 Qira'at supported** — Hafs, Warsh, Qaloon, Shu'bah, Duri, Susi, Bazzi, Qunbul, Hisham, Ibn Dhakwan
- **12 Hafs reciters with per-ayah timestamp sync** — bundled offline, no API needed
- **Live reciter discovery** via mp3quran.net API v3, cached for 7 days
- **Continuous mushaf mode** or ayah-by-ayah with synced audio scrolling
- **6 tafsir editions** — Al-Muyassar, Al-Jalalayn, Al-Qurtubi, Ibn Abbas, Al-Waseet, Al-Baghawi (all offline in SQLite)
- **Auto-bookmarking** — remembers your last read position and last played audio timestamp
- **Immersive reading** — full-screen edge-to-edge with auto-hiding UI
- **Verse search** — instant full-text search in Arabic and English via local SQLite

### Hadith
- **13 collections** — Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah, Malik, Riyad as-Salihin, Adab al-Mufrad, Bulugh al-Maram, Mishkat, Shama'il, Musnad Ahmad
- **Offline-first** — Sahih al-Bukhari and Sahih Muslim bundled as assets, CDN fallback for others
- **Arabic & English** with grading badges (Sahih, Hasan, Da'if, Mawdu')
- **Hadith explanation (Sharh) and grading (Takhreej)** — offline cache → CDN → Dorar API fallback
- **FTS5 full-text search** across all books, no tashkeel needed
- **Lazy loading** with pre-fetch — first 20, then 20-40 pre-cached, rest on demand

### Azkar & Supplications
- **11 categories** — Morning, Evening, Post-Prayer, Daily Duas, Names of Allah, Sleep/Waking, Salah, Life Events, Protection/Ruqyah, Forgiveness/Tawbah, Custom
- **60+ authentic adhkar** with Arabic text, transliteration, English translation, and hadith references
- **Counter tracking** per dhikr with haptic feedback
- **Custom "My Azkar"** — add your own adhkar, persisted to storage
- **99 Names of Allah** with Arabic, transliteration, and meaning
- **Digital Tasbih** with 5 presets and custom targets

### Prayer Tracker
- **Daily/monthly/yearly views** with calendar and donut-chart indicators
- **"Log your prayer" notifications** with interactive "Prayed"/"Missed" action buttons
- **Statistics** — weekly, monthly, and yearly completion (counts only real tracked data)

### Qibla Compass
- **Smooth high-refresh-rate** compass using device magnetometer
- **Kaaba alignment detection** — vibrates and flashes gold within 5°
- **Manual fallback** for devices without compass sensor
- **Google Maps integration** for visual direction

### Home Screen Widgets
- **8 widget types** — Prayer Times, Verse of the Day, Dhikr, Hadith, Tasbih, Hijri Date, Next Prayer, Asma ul Husna
- **Bilingual** Arabic/English labels

### Downloads & Offline
- **Audio download manager** — per-surah download with progress tracking
- **Reciter browser** — 100+ reciters sorted by Qira'ah then name
- **Quran text & tafsir** — lazy-seeded SQLite (~130 MB avoided at cold start)
- **Bulk download all** with cancel support

### Design
- **6 theme presets** — Dark, Light, Sepia/Parchment, OLED Black, Dark Monet, White Monet
- **Glassmorphism cards** with real-time `BackdropFilter` blur
- **Floating pill navigation** — optional transparent pill over content
- **Amiri & Scheherazade New** Quranic fonts
- **Full RTL/LTR** — flawless Arabic and English alignment

---

## Architecture

```
lib/
├── main.dart                        # App entry point, locale, theming (~110 lines)
├── screens/
│   ├── dashboard_screen.dart        # Home: next-prayer countdown, quick actions
│   ├── main_scaffold.dart           # 5-tab shell, focus lock, navigation
│   ├── quran_screen.dart            # Surah list + verse search
│   ├── surah_reader/                # Quran reader (part-of pattern)
│   │   ├── surah_reader_screen.dart
│   │   ├── surah_reader_ui.dart     # Ayah cards, continuous layout, mini player
│   │   ├── surah_reader_audio.dart  # Playback with disclaimer handling
│   │   ├── surah_reader_autoscroll.dart
│   │   ├── surah_reader_bookmarks.dart
│   │   ├── surah_reader_data.dart   # Reciters + ayah loading
│   │   ├── surah_reader_navigation.dart
│   │   ├── surah_reader_actions.dart # Tafsir dialog, ayah sheet, scroll-to-verse
│   │   └── surah_pager_screen.dart  # 114-page PageView for swipe browsing
│   ├── hadith_screen.dart           # Hadith browser with lazy loading
│   ├── hadith_explanation_screen.dart # Sharh/grading (offline → CDN → Dorar)
│   ├── prayer_times_screen.dart     # Today/Calendar/Hijri tabs + location
│   ├── prayer_tracker_screen.dart   # Calendar/Yearly/Statistics tabs
│   ├── azkar_screen.dart            # 11-tab azkar with counter + custom
│   ├── bookmarks_screen.dart        # Quran + Hadith bookmarks
│   ├── quran_download_screen.dart   # Audio download manager + reciter picker
│   ├── qibla_screen.dart            # Compass with Kaaba alignment
│   ├── tasbih_screen.dart           # Digital counter with haptics
│   ├── qiraat_screen.dart           # Qira'at recitation browser
│   ├── about_screen.dart
│   ├── splash_screen.dart           # Animated splash with auto language detect
│   ├── welcome_screen.dart          # 3-page onboarding + permission flow
│   ├── permission_guard_screen.dart
│   └── settings/                    # Settings (part-of pattern)
│       ├── settings_screen.dart     # Master state + 8 part files
│       ├── settings_appearance.dart
│       ├── settings_language.dart
│       ├── settings_calculations.dart
│       ├── settings_notifications.dart
│       ├── settings_audio.dart
│       ├── settings_permissions.dart
│       ├── settings_focus_lock.dart
│       ├── settings_backup.dart
│       └── settings_app_preferences.dart
├── services/
│   ├── notification_service.dart    # Adhan/pre-adhan/tracker/reminder scheduling
│   ├── audio_manager.dart           # Singleton audio player with timestamp sync
│   ├── api_service.dart             # Prayer times + Quran data (offline-backed)
│   ├── offline_prayer_service.dart  # Adhan library + Hijri calendar
│   ├── database_service.dart        # SQLite: Quran, tracker, bookmarks (~500 lines)
│   ├── hadith_database_service.dart # Hadith-specific SQL — FTS5 search, CRUD
│   ├── storage_service.dart         # SharedPreferences + DB abstraction
│   ├── translation_service.dart     # ~430 AR/EN strings (no i18n packages)
│   ├── azkar_data.dart              # 60+ adhkar across 9 categories
│   ├── quran_download_service.dart  # Audio + text download manager
│   ├── qdc_audio_service.dart       # Per-ayah timestamps (bundled → cache → API)
│   ├── quran_verses.dart            # 30 curated verses for daily notifications
│   ├── local_quran_service.dart     # Bundled JSON for alternative Qira'at
│   ├── adhan_audio_service.dart     # Bundled adhan audio references
│   ├── sharh_cache_service.dart     # CDN sharh downloader + offline cache
│   ├── backup_service.dart          # Export/import bookmarks + settings + tracker
│   └── reciters_cache_service.dart  # mp3quran.net API v3 — cached 7 days
├── models/
│   ├── quran_models.dart            # Surah, Ayah, TafsirEdition, ReciterInfo
│   ├── prayer_models.dart           # PrayerTimeData (3 format factories)
│   └── offline_surahs.dart          # 114 surahs (compile-time fallback)
├── theme/
│   ├── app_colors.dart              # Gold, teal, green palette
│   ├── app_themes.dart              # 6 theme presets (extracted from main.dart)
│   └── ui_helpers.dart              # Responsive scaling, haptics
├── utils/
│   └── text_helpers.dart            # stripTashkeel(), formatPrayerTime()
├── widgets/                         # Reusable UI components (7 widgets)
└── core/                            # adhan_native_controller.dart

android/app/src/main/kotlin/com/quran/aya/
├── MainActivity.kt                  # Platform bridge: 15 MethodChannels, TTS, sensors
├── AdhanBroadcastReceiver.kt        # Native alarm receiver with wake lock
├── BootReceiver.kt                  # Post-reboot prayer rescheduling
├── ExactAlarmPermissionReceiver.kt  # Alarm permission state listener
└── AyaWidgetProvider.kt             # 8 home screen widget providers

assets/
├── timestamps/                      # 12 reciters × 114 surahs — per-ayah timing (5.7 MB)
├── quran/                           # Quran text (Hafs + 10 Qira'at JSON)
├── hadith/                          # 26 bundled collections (AR + EN)
├── audio/adhan/                     # Adhan MP3 assets
└── fonts/                           # Amiri, Inter, Outfit, Scheherazade New, Warsh, Qalun
```

---

## Defaults

| Category | Setting | Default |
|----------|---------|---------|
| Theme | Preset | Dark |
| Navigation | Bottom bar | Floating pill |
| Quran | Script | Hafs |
| Quran | Reading mode | Continuous (mushaf) |
| Quran | Font | Amiri |
| Quran | Font size | 100% |
| Prayer | Calculation method | ISNA |
| Prayer | Asr school | Standard (Shafi'i) |
| Prayer | Pre-adhan time | 10 min |
| Prayer | Pre-adhan alert | Vibrate |
| Prayer | Adhan alert | Real reciter (Mishary) |
| Prayer | Adhan stop gesture | Volume keys + flip |
| Reminders | Morning/evening azkar | On |
| Reminders | Today's verse | On |
| Ramadan | Imsak alert | On (at Fajr) |
| Ramadan | Iftar alert | On (at Maghrib) |
| System | Language | Auto-detect from device |
| System | Location | Cairo, Egypt (until GPS lock) |

**"I don't want Adhan" onboarding path:** All adhan, pre-adhan, and reminder settings are automatically set to Off.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x / Dart 3.10 |
| Native | Kotlin `BroadcastReceiver` + `AlarmManager` via `MethodChannel` |
| Notifications | `flutter_local_notifications` with `exactAllowWhileIdle` |
| Audio | `audioplayers` for Quran, `RawResourceAndroidNotificationSound` for adhan |
| Database | `sqflite` + `sqflite_common_ffi` (bundled FTS5 on all platforms) |
| Location | `geolocator` + `geocoding` for native reverse geocoding |
| Prayer calc | `adhan` Dart library (offline) + `hijri` calendar |
| Fonts | Amiri, Inter, Outfit, Scheherazade New, Warsh, Qalun |

---

## Build

```bash
git clone https://github.com/Cancelllls/Aya.git
cd Aya
flutter pub get

# Android
flutter build apk --release --target-platform=android-arm64

# iOS
flutter build ios --release --no-codesign
```

### Bundled Timestamps (One-Time)

The per-ayah audio timestamps for 12 Hafs reciters are bundled in `assets/timestamps/` (5.7 MB). To regenerate them after adding a new reciter:

```bash
dart run tools/generate_timestamps.dart
```

---

## License

MIT — see [LICENSE](LICENSE).

<p align="center"><strong>بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ</strong></p>
<p align="center">Made with 🤍 for the Muslim community</p>
