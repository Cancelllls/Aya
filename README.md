<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Kotlin-Native-purple?style=flat-square&logo=kotlin" alt="Kotlin">
  <img src="https://img.shields.io/badge/Platform-Android%207%E2%80%9316-brightgreen?style=flat-square&logo=android" alt="Android 7–16">
  <img src="https://img.shields.io/badge/Offline-100%25-success?style=flat-square" alt="100% Offline">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT">
</p>

<h1 align="center">Aya — Modern Islamic Companion App</h1>
<p align="center"><strong>Quran · 10 Pre-Bundled Offline Tafsirs · Tajweed Engine · Hadith · Prayer Times & Adhan · Azkar · Qibla · Widgets</strong></p>
<p align="center">
  <a href="https://github.com/Cancelllls/Aya/releases"><strong>Download Latest Release</strong></a>
</p>

---

## 🌟 Key Features

### 📖 Quran Reader & Tajweed Engine
- **10 Qira'at Supported** — Hafs, Warsh, Qaloon, Shu'bah, Duri, Susi, Bazzi, Qunbul, Hisham, and Ibn Dhakwan.
- **Interactive Tajweed Rules Engine** — Live color-coded pronunciation rules (Ghunnah, Qalqalah, Ikhfa, Idgham, Madd) with toggleable highlight layers.
- **Continuous Mushaf & Card Modes** — Seamless page scrolling or verse-by-verse card views with synchronized audio autoscroll.
- **12 Hafs Reciters with Ayah-Level Timestamp Sync** — Bundled timing assets for precise audio-visual highlight synchronization.
- **Hifz Memorization Mode** — Interactive Gaussian blur verse masking for self-testing in both card and continuous reader modes.
- **Share Verse as Image Card** — Custom horizontal landscape card generator with Black Frame slider (`0px – 36px`), verse numbers, and gold markers.

### 📚 100% Offline Pre-Bundled Tafsirs
- **10 Full Tafsir Editions Pre-Bundled** — 8 Arabic (*Al-Muyassar, Al-Jalalayn, Al-Qurtubi, Tanweer Al-Miqbas, Al-Waseet, Al-Baghawi, Ibn Kathir, Saadi*) and 2 Pure English (*Tafsir Ibn Kathir, Tafheem-ul-Quran* by Maududi).
- **100% Offline Access** — Zero network dependency or API delays when opening verse explanations.

### 🕌 Offline Prayer Times & Native Adhan
- **14 Calculation Methods & Offline GPS Math** — Complete local calculation engine via `OfflinePrayerService`.
- **Native Kotlin `AdhanBroadcastReceiver`** — Five-Prayers native media model using `MediaPlayer`, `MediaSessionCompat` (volume-key silence), and accelerometer flip-to-mute.
- **8 Adhan Reciters & Per-Prayer Toggles** — Mishary Al-Afasy, Abdul Basit, Madinah, Kazabri, Riad, Manssour, Nakshabandi, and Maghriby with Fajr-specific reciter support.

### 📜 Hadith & Sharh Engine
- **13 Complete Hadith Collections** — Sahih al-Bukhari, Sahih Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah, Malik, Riyad as-Salihin, Adab al-Mufrad, Bulugh al-Maram, Mishkat, Shama'il, Musnad Ahmad.
- **Full-Text FTS5 Search** — Diacritics-insensitive search across all books.
- **Hadith Explanation (Sharh) & Grading (Takhreej)** — Authentic grading badges with offline cached explanations.

### 📱 Material 3 Adaptive Home Screen Widgets
- **8 Dynamic AppWidget Types** — Full Prayer Bar, Verse of the Day, Daily Hadith, Daily Dhikr, Tasbih Counter, Hijri Date, Next Prayer Countdown, and 99 Names of Allah.
- **1-Line 5-Prayer Horizontal Layout** — All 5 daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) aligned in a single horizontal row.
- **Frozen-Free `HH:MM` Countdowns** — Battery-friendly, accurate time formatting.
- **Dynamic Light/Dark & AR/EN Adaptivity** — Automatically matches system theme colors and app language.

---

## 🏗️ Architecture & Optimizations

```
lib/
├── main.dart                         # Entry point, locale detection, Material 3 theming
├── version.dart                      # Auto-incremented semantic versioning
│
├── screens/
│   ├── dashboard_screen.dart         # Home dashboard, countdown, prayer bar, widget sync
│   ├── main_scaffold.dart            # 5-tab shell scaffold with navigation lock
│   ├── quran_screen.dart             # Surah directory + dual-tab full-text search
│   ├── surah_reader/                 # Modular Quran Reader
│   │   ├── surah_reader_screen.dart  # Reader state, Tajweed & Hifz modes
│   │   ├── surah_reader_ui.dart      # Continuous Mushaf & Ayah card layouts
│   │   ├── surah_reader_actions.dart # 100% Offline Tafsir dialog & verse action sheets
│   │   └── surah_pager_screen.dart   # 114-page PageView mushaf reader
│   ├── hadith_screen.dart            # 13-book Hadith browser + FTS5 search
│   ├── prayer_times_screen.dart      # Daily prayer schedule + Hijri calendar
│   ├── azkar_screen.dart             # 11-category Azkar, 99 Names of Allah, Custom Azkar
│   ├── qibla_screen.dart             # Magnetometer Qibla compass with Kaaba haptic alignment
│   └── settings/                     # Modular Settings Architecture
│
├── services/
│   ├── database_service.dart         # SQLite v9 with background isolate JSON seeding
│   ├── api_service.dart              # Offline Tafsir asset loader & LRU memory cache
│   ├── offline_prayer_service.dart   # Offline mathematical prayer calculator
│   └── notification_service.dart     # Native exact alarm & notification scheduler
│
└── models/
    ├── quran_models.dart             # Surah, Ayah, TafsirEdition, Qira'at models
    └── prayer_models.dart            # Local & API prayer time data models
```

---

## ⚡ Performance Optimizations

1. **Background Isolate Seeding**: Offloaded heavy SQLite JSON parsing (14.4MB Hafs data) to background isolates via Dart `compute()`.
2. **LRU Cache Limit**: Added a strict 3-entry LRU eviction cache for bundled Tafsir JSON assets to minimize RAM footprint.
3. **Modular Code Architecture**: Modularized large files using Dart `part` / `part of` state boundaries for enhanced maintainability.
4. **Gesture Life-cycle Cleanup**: Automatic disposal of `TapGestureRecognizer` instances across page transitions to prevent memory leaks.

---

## 🛠️ Build & CI/CD Pipeline

Aya features an automated GitHub Actions release workflow (`build-apk.yml`) with Gradle build caching and version bumping:

```bash
git clone https://github.com/Cancelllls/Aya.git
cd Aya
flutter pub get

# Build Release APK
flutter build apk --release --target-platform=android-arm64
```

---

## 📄 License & Credits

Released under the [MIT License](LICENSE).

<p align="center"><strong>بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ</strong></p>
<p align="center">Made with 🤍 for the Muslim community worldwide</p>
