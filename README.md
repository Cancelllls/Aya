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
- **Native Kotlin `AdhanBroadcastReceiver`** — Five-Prayers model: `MediaPlayer` + `MediaSessionCompat` (volume-key stop) + accelerometer (flip-to-silence) + silent notification card. No clock tile hijacking.
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
- **Hadith explanation (Sharh) and grading (Takhreej)** — grading always hits Dorar API fresh; sharh uses offline cache → CDN → Dorar
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
├── main.dart                         # App entry, locale detection, theming (~110 lines)
├── version.dart                      # Semantic version (auto-incremented)
│
├── screens/
│   ├── dashboard_screen.dart         # Home: countdown, quick actions, prayer bar
│   ├── main_scaffold.dart            # 5-tab shell, focus lock overlay, nav routing
│   ├── quran_screen.dart             # Surah list + dual-tab verse/surah search
│   ├── surah_reader/                 # Quran reader (6 part files)
│   │   ├── surah_reader_screen.dart  # Main state, rendering modes, gesture handling
│   │   ├── surah_reader_ui.dart      # Ayah cards + continuous mushaf layout
│   │   ├── surah_reader_audio.dart   # Playback with reciter/Qira'ah disclaimer
│   │   ├── surah_reader_autoscroll.dart # Scroll controller + speed management
│   │   ├── surah_reader_bookmarks.dart  # Per-surah & per-ayah bookmark toggle
│   │   ├── surah_reader_data.dart    # Dynamic reciters + ayah loading + tafsir lazy-load
│   │   ├── surah_reader_navigation.dart # Swipe-to-next/prev surah
│   │   ├── surah_reader_actions.dart # Tafsir dialog, ayah action sheet, scroll-to-verse
│   │   └── surah_pager_screen.dart   # 114-page PageView + fixed AppBar with reader settings
│   ├── hadith_screen.dart            # 13-book browser, FTS5 search, lazy loading
│   ├── hadith_explanation_screen.dart # Sharh/grading (grading: always Dorar; sharh: cache→CDN→Dorar)
│   ├── prayer_times_screen.dart      # Today / Prayer Calendar / Hijri Calendar tabs
│   ├── prayer_tracker_screen.dart    # Calendar / Yearly / Statistics with donut charts
│   ├── azkar_screen.dart             # 11-tab azkar: counter, 99 Names, custom "My Azkar"
│   ├── bookmarks_screen.dart         # Quran + Hadith dual-tab bookmarks
│   ├── quran_download_screen.dart    # Audio downloader + searchable reciter picker
│   ├── qibla_screen.dart             # Animated compass with Kaaba alignment detection
│   ├── tasbih_screen.dart            # Tap counter with presets, haptics, history
│   ├── qiraat_screen.dart            # Live mp3quran.net Qira'at + reciter browser
│   ├── about_screen.dart             # Features, developer, basmalah
│   ├── splash_screen.dart            # Animated Islamic logo + auto language detect
│   ├── permission_guard_screen.dart  # Runtime permission gate (mirrors onboarding)
│   ├── welcome_screen.dart           # 3-page onboarding: intro, features, permissions
│   └── settings/                     # 9 part files (glassmorphism cards)
│       ├── settings_screen.dart      # Master state, donation, reset, version display
│       ├── settings_appearance.dart  # Theme preset, nav style, Quran font
│       ├── settings_language.dart    # AR/EN toggle
│       ├── settings_calculations.dart # Prayer method, Asr school
│       ├── settings_app_preferences.dart # 24h format, immersive reader, swipe nav, focus lock
│       ├── settings_notifications.dart   # Adhan/pre-adhan, Ramadan, Islamic events
│       ├── settings_audio.dart       # Continuous play, auto-bookmark, refresh reciters
│       ├── settings_permissions.dart # Exact alarm, keep screen awake
│       ├── settings_focus_lock.dart  # About, Donate, Reset (bottom of settings)
│       └── settings_backup.dart      # Export/import via share sheet or file picker
│
├── services/
│   ├── notification_service.dart     # Adhan (native), pre-adhan, tracker, Ramadan, azkar, verse
│   ├── audio_manager.dart            # Singleton: surah playback, ayah sync, adhan playback
│   ├── api_service.dart              # Prayer times (offline), Quran data, reverse geocode
│   ├── offline_prayer_service.dart   # adhan library + hijri calendar (zero internet)
│   ├── database_service.dart         # SQLite v9: Quran, tracker, bookmarks (~500 lines)
│   ├── hadith_database_service.dart  # Hadith CRUD, FTS5 MATCH, LIKE fallback
│   ├── storage_service.dart          # SharedPreferences + DB migration + smart calc method
│   ├── translation_service.dart      # ~430 AR/EN key-value pairs (no i18n packages)
│   ├── azkar_data.dart               # 60+ adhkar, 99 Names, 9 categories
│   ├── quran_download_service.dart   # Per-surah MP3 download + progress tracking
│   ├── qdc_audio_service.dart       # Ayah timestamps: bundled asset → file cache → QDC API
│   ├── quran_verses.dart             # 30 curated verses for daily notifications
│   ├── local_quran_service.dart      # Bundled JSON for non-Hafs Qira'at
│   ├── adhan_audio_service.dart      # 8 adhan reciters (MP3 assets), preview playback
│   ├── sharh_cache_service.dart      # CDN sharh downloader + offline JSON cache
│   ├── backup_service.dart           # Full export/import: bookmarks, settings, tracker
│   └── reciters_cache_service.dart   # mp3quran.net API v3 aggregated + 7-day disk cache
│
├── models/
│   ├── quran_models.dart             # Surah, Ayah, TafsirEdition, ReciterInfo, juz/hizb maps
│   ├── prayer_models.dart            # PrayerTimeData (AlAdhan + Pray.zone + Local factories)
│   └── offline_surahs.dart           # 114 surahs — compile-time fallback
│
├── theme/
│   ├── app_colors.dart               # Gold (#E5C158), teal (#0F766E), green (#10B981)
│   ├── app_themes.dart               # 6 presets: dark, light, sepia, black, dark_monet, white_monet
│   └── ui_helpers.dart               # Responsive scaling, haptic feedback presets
│
├── utils/
│   └── text_helpers.dart             # stripTashkeel (full alef/hamza/teh/kashida normalization),
│                                     #   formatPrayerTime (12h/24h)
│
├── widgets/
│   ├── audio_player_overlay.dart     # Floating mini-player with seek bar
│   ├── changelog_dialog.dart         # Version-aware changelog from bundled JSON
│   ├── grid_service_card.dart        # Home screen quick-access grid tile
│   ├── islamic_logo_painter.dart     # CustomPaint 8-point star + crescent
│   ├── prayer_bar_card.dart          # Horizontal prayer time pill
│   ├── prayers_countdown_card.dart   # Self-contained countdown + prayer times widget
│   ├── quick_access_pill.dart        # Continue Reading / Azkar shortcut row
│   └── welcome_header.dart           # Dashboard greeting banner with random verse
│
└── core/
    └── adhan_native_controller.dart   # MethodChannel bridge: schedule alarm, OEM autostart

android/app/src/main/kotlin/com/quran/aya/
├── MainActivity.kt                   # Platform bridge: 12 MethodChannels (alarms, file
│                                     #   picker, permissions, vibrate, widgets, lock task)
├── AdhanBroadcastReceiver.kt         # Five-Prayers-model: native MediaPlayer +
│                                     #   MediaSessionCompat (volume-key stop) +
│                                     #   accelerometer (flip-to-silence) + wake lock
├── BootReceiver.kt                   # Post-reboot app launch for prayer rescheduling
└── ExactAlarmPermissionReceiver.kt   # Re-schedules alarms when permission is granted

assets/
├── timestamps/                       # 12 reciters × 114 surahs — per-ayah timing (5.7 MB)
├── quran/                            # Quran text: Hafs + 10 Qira'at JSON
├── hadith/                           # 26 bundled collections (AR + EN)
├── audio/adhan/                      # 14 adhan MP3 assets (raw/)
├── fonts/                            # Amiri, Inter, Outfit, Scheherazade New, Warsh, Qalun
├── changelog.json                    # Versioned bilingual changelog
└── icon.png                          # App icon source
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

---

## Credits & Data Sources

Aya is built on the shoulders of giants. All data is either bundled, cached, or fetched as a last-resort fallback:

| Source | Used for | Attribution |
|--------|----------|-------------|
| [mp3quran.net API v3](https://mp3quran.net) | Reciter discovery, Qira'at listings, surah audio | Reciter metadata and audio streams |
| [Quran.com CDN (QDC)](https://quran.com) | Per-ayah audio timestamps | 12 Hafs reciters — bundled as assets (5.7 MB) |
| [AlQuran.cloud / cdn.islamic.network](https://alquran.cloud) | Hafs reciter audio streaming | CDN fallback for Hafs reciters |
| [jsDelivr CDN](https://jsdelivr.com) | Hadith JSON + Sharh packages | Cancelllls/Islamic-Assets repository |
| [Dorar Hadith API](https://dorar.net) | Hadith grading (Takhreej), explanation (Sharh) | Live API — last-resort fallback |
| [adhan Dart library](https://pub.dev/packages/adhan) | Offline prayer time calculation | 14 methods, madhab support |
| [hijri Dart library](https://pub.dev/packages/hijri) | Hijri calendar conversion | Month names, events |
| [Five Prayers Android](https://github.com/Five-Prayers/five-prayers-android) | Adhan architecture reference | MediaPlayer + MediaSession + VolumeProvider pattern |
| [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) | Notification scheduling | Exact + inexact alarm scheduling |
| [Geolocator](https://pub.dev/packages/geolocator) | GPS location | Native Android location provider |
| [Audioplayers](https://pub.dev/packages/audioplayers) | Quran audio playback | Streaming + offline MP3 |
| [sqflite + sqflite_common_ffi](https://pub.dev/packages/sqflite) | SQLite with FTS5 on all platforms | Bundled SQLite binary |
| [Share Plus](https://pub.dev/packages/share_plus) | Backup export sharing | Android share sheet |
| [In-App Purchase](https://pub.dev/packages/in_app_purchase) | Google Play donations | Consumable IAP products |
| [Amiri Font](https://fonts.google.com/specimen/Amiri) | Quranic Arabic text rendering | Google Fonts |
| [Scheherazade New](https://fonts.google.com/specimen/Scheherazade+New) | Alternative Quran font | Google Fonts |

Quran text, hadith collections, tafsir, and azkar are compiled from classical sources into bundled JSON assets. All data remains in the public domain / open-access tradition of Islamic scholarship.

---

## License

MIT — see [LICENSE](LICENSE).

<p align="center"><strong>بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ</strong></p>
<p align="center">Made with 🤍 for the Muslim community</p>
