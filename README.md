<div align="center">

# ☽ Aya — Premium Islamic Companion App

**A beautifully crafted, feature-rich Islamic companion application designed for modern devices, supporting Android 7 up to Android 16.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-00B4AB?style=for-the-badge&logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge&logo=android)](https://github.com/Cancelllls/Islamic-App)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 🌙 About Aya

**Aya** is a premium, ultra-precise Islamic companion app. Built using a sleek glassmorphic design system, dark obsidian backgrounds, golden accents, and smooth micro-animations, it provides a visually stunning and spiritually immersive experience. It bridges the gap between ancient practice and modern technology with clean, robust, and backward-compatible architectures.

---

## ✨ Features

### 📖 Quran Reader
- **Multiple Reading Modes:** 
  - *Translation:* Read verses along with their English/Arabic translations.
  - *Arabic Only:* Immerse yourself in the pure Amiri Arabic typeface.
  - *Tafsir:* Access Al-Muyassar Tafsir overlay per Ayah via bottom sheet.
  - *Continuous Page:* Fluid layout mimicking physical Quran pages.
- **Auto-Scroll Assist:** Hands-free scrolling with 5 adjustable speed increments and active scroll timer.
- **Immersive Mode:** Auto-hides system bars (status and navigation) to minimize reading distractions.
- **Auto-Bookmarking:** Automatically updates your last read position on audio playback launch or manual tag.

### 🔊 Audio Player
- **High-Quality Streaming:** Clear, high-quality audio streaming from world-renowned Qaris (e.g., Mishary Alafasy, Maher Al-Muaiqly).
- **Synchronized Scrolling:** The reader automatically highlights and scrolls to keep the currently playing verse centered.
- **Continuous Playback:** Seamlessly advances from verse to verse and Surah to Surah in the background.

### 🕌 Prayer Times & Alerts
- **GPS Coordinates & Auto-City Detection:** Auto-determines coordinates and city names using local reverse geocoding.
- **Dynamic Pre-Adhan Reminders:** Get silent, vibrating, or vocal alerts up to 30 minutes before prayer enters.
- **Athan Stop Gestures:** Silence your Athan alarm effortlessly by pressing the volume key or flipping your device face down.
- **Multiple Calculation Standards:** Supports ISNA, Muslim World League, Umm Al-Qura, Egyptian Authority, and more.

### 🧭 Qibla Compass
- **Live Angle Detection:** Accurate angle calculations utilizing native device compass sensors.
- **Visual Alignments:** Vibrates and highlights golden markers the exact moment your device aligns with the Holy Kaaba.

### 📿 Tasbih & Custom Dhikr
- **Interactive Counter:** Circular progress indicator with haptic feedback vibrations.
- **Custom Dhikr Builder:** Write your own target counters, Arabic scripts, and custom titles.

### 🔒 Khushu Focus Lock
- **Distraction-Free Prayers:** Restricts app access or lock screen overlays during prayer periods to protect your focus.
- **Double-Tap Emergency Override:** Quickly bypass focus lock constraints in emergency situations.

### 🔌 Interactive Home Screen Widgets
- **Daily Verse Widget:** Promotes daily reminders with a curated "Verse of the Day".
- **Prayer Times Widget:** Displays current and upcoming prayer timings on your home screen launcher.

---

## 🏗 System Architecture & Project Structure

The project conforms to a clean, layered architecture separating UI layout, state logic, and services:

```
lib/
├── main.dart                  # Root MaterialApp, locale bootstrapping & MainScaffold
├── models/                    # Typed data schemas
│   ├── prayer_models.dart     # Prayer schedule & times structures
│   └── quran_models.dart      # Surah and Ayah structural objects
├── screens/                   # Page layouts & interface views
│   ├── dashboard_screen.dart  # Home tab with daily content & quick actions
│   ├── quran_screen.dart      # List of Surahs & search queries
│   ├── surah_reader_screen.dart # Main Quran reading panel
│   ├── prayer_times_screen.dart # Prayer timetable & calculation settings
│   ├── qibla_screen.dart      # Kaaba finder
│   ├── azkar_screen.dart      # Morning and evening litanies
│   ├── tasbih_screen.dart     # Custom counter interface
│   ├── hadith_screen.dart     # Hadith browser with language filter
│   ├── settings_screen.dart   # Calculations, alerts, widgets, and theme settings
│   └── permission_guard.dart  # Sequenced onboarding wizard
├── services/                  # Platform, APIs & storage managers
│   ├── api_service.dart       # REST client for prayer schedules
│   ├── audio_manager.dart     # Background player controller
│   ├── notification_service.dart # Cron alarms & push alerts
│   ├── storage_service.dart   # Local preferences manager
│   └── translation_service.dart # Arabic / English localization keys
└── widgets/                   # Custom UI paint tools & components
```

---

## 🛠 Technology Stack

| Layer | Dependency | Description |
|-------|-----------|-------------|
| **Core** | `Flutter 3.x / Dart 3` | Native compilation, high performance |
| **Fonts** | `Google Fonts (Amiri, Inter)` | Classic Arabic Quranic script & modern clean UI |
| **Audio** | `just_audio` | Stream player, background execution |
| **Billing** | `in_app_purchase` | Premium in-app donations / project support |
| **Alarms** | `android_alarm_manager_plus` | Robust background exact alarm workers |
| **Location** | `geolocator` | GPS coordinates extraction |
| **Preferences** | `shared_preferences` | Key-value settings cache |
| **Sensors** | `flutter_compass` | Built-in device magnetometers |
| **Networking** | `http` | External prayer data sync |

---

## 🔐 Permissions & Backward Compatibility

Aya is optimized to run reliably from **Android 7 (API 24) up to Android 16 (API 36)**. Permissions are requested sequentially in an onboarding wizard:

1. **Location Access:** Required to obtain latitude/longitude for prayer calculation equations.
2. **Notification Alerts:** Sends prayer athan calls and daily reminder notifications.
3. **Exact Alarms (`SCHEDULE_EXACT_ALARM`):** Required on Android 12+ (API 31+) to trigger Athan calls precisely at the minute.
4. **Ignore Battery Optimization:** Disables Doze mode constraints to prevent background processes from sleeping.

All system permissions and intent requests use version check blocks (`Build.VERSION.SDK_INT >= API_LEVEL`) to avoid compatibility errors on legacy devices.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (version 3.19.0 or higher recommended)
- Java Development Kit (JDK 17)
- Android Studio / Xcode

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/Cancelllls/Islamic-App.git
   cd Islamic-App
   ```

2. Fetch project dependencies:
   ```bash
   flutter pub get
   ```

3. Launch on a connected device:
   ```bash
   flutter run
   ```

### Compile Release APK (Android)
To compile a optimized release build:
```bash
flutter build apk --release --target-platform=android-arm64
```
The compiled package will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<div align="center">

**Made with 🤍 for the Muslim community**

*بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ*

</div>
