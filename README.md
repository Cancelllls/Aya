<div align="center">

# ☽ Aya — Premium Islamic Companion App

**A masterfully crafted, ultra-resilient Islamic companion application designed for modern devices.**<br>
*Supports Android 7 (API 24) all the way up to Android 16 (API 36).*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-00B4AB?style=for-the-badge&logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-lightgrey?style=for-the-badge&logo=android)](https://github.com/Cancelllls/Islamic-App)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

### [⬇️ Download Latest APK (Android)](https://github.com/Cancelllls/Islamic-App/raw/main/app-release.apk)

</div>

---

## 🌙 About Aya

**Aya** is a premium, ultra-precise Islamic companion app engineered with a singular goal: **Zero Compromise.** 

Visually, Aya is built utilizing a state-of-the-art **Glassmorphism Design System** featuring deep obsidian backgrounds, vibrant teal gradients, and elegant golden accents. Under the hood, it utilizes native Android hardware-clock APIs to guarantee exact prayer time alerts—bypassing even the most aggressive OEM task killers (like Xiaomi, Samsung, and Oppo) without forcing the user to run a constant foreground service.

---

## ✨ Signature Features

### 🛡️ "Immortal" Background Alarms
Unlike standard apps that get killed when swiped away, Aya registers your Adhan using Android's highest-priority `setAlarmClock()` API (the same system your morning alarm uses). This ensures prayer notifications and Adhan audio fire **flawlessly and exactly on the minute**, surviving Doze mode and aggressive task killers.
- Automatically handles `USE_EXACT_ALARM` permissions to silently grant maximum privileges on Android 13+.
- Dual-path audio logic correctly identifies and plays specific reciters for **Fajr vs. Standard** prayers.

### 💎 UI/UX Pro Max Design
- **True Glassmorphism:** Real-time blurred backdrops (`BackdropFilter`) combined with semi-transparent frosted cards.
- **Dynamic Theming:** Deep, eye-soothing dark mode and a crisp, vibrant light mode carefully balanced for contrast and readability.
- **RTL / LTR Mastery:** Flawless alignment and typography for both Arabic and English interfaces.

### 📖 Advanced Quran Reader & Tafsir
- **Multi-lingual Tafsir:** Integrated offline Tafsir books (Al-Muyassar, Al-Jalalayn, Al-Qurtubi, etc.) clearly labeled in both Arabic and English.
- **Auto-Bookmarking & Sync:** Automatically updates your last read position. The reader smoothly scrolls down the page in perfect synchronization with the streaming audio.
- **Immersive Mode:** Auto-hides system status bars for a distraction-free, edge-to-edge reading experience.

### 📚 Hadith Library & Explanations
- Browse complete Hadith collections offline.
- Features dynamic "Sahih" / "Daif" authenticity badges colored natively within the glassmorphic UI.
- Gracefully handles missing scraping metadata with "Search Online" fallbacks.

### 🧭 Precision Qibla & 📿 Custom Tasbih
- **Live Qibla Tracking:** Smooth, high-refresh-rate compass utilizing native device magnetometers. Vibrates and flashes gold upon exact Kaaba alignment.
- **Haptic Tasbih Builder:** Create your own custom Dhikr targets with satisfying haptic feedback loops.

---

## 🏗 System Architecture

The project conforms to a clean, layered architecture separating UI layout, state logic, and services:

```text
lib/
├── main.dart                  # Root MaterialApp, locale bootstrapping & MainScaffold
├── models/                    # Typed data schemas (Prayer schedules, Quran structures)
├── screens/                   # Page layouts & interface views (Glassmorphism UI)
│   ├── dashboard_screen.dart  # Home tab with daily content & quick actions
│   ├── quran_screen.dart      # List of Surahs & search queries
│   ├── surah_reader_screen.dart # Main Quran reading panel with synced scrolling
│   ├── prayer_times_screen.dart # Prayer timetable & calculation settings
│   ├── hadith_screen.dart     # Hadith browser with multi-language filter
│   └── settings_screen.dart   # Calculations, alerts, widgets, and theme settings
├── services/                  # Platform, APIs & storage managers
│   ├── api_service.dart       # REST client for prayer schedules
│   ├── adhan_audio_service.dart # Background player controller & Five Prayers Integration
│   ├── notification_service.dart # Invincible setAlarmClock cron workers
│   ├── storage_service.dart   # Local preferences manager
│   └── translation_service.dart # Arabic / English localization keys
└── widgets/                   # Custom UI paint tools & components
```

---

## 🛠 Technology Stack

| Layer | Dependency | Description |
|-------|-----------|-------------|
| **Core** | `Flutter 3.x / Dart 3` | Native compilation, high performance |
| **Alarms** | `android_alarm_manager_plus` | Patched to utilize `AndroidScheduleMode.alarmClock` |
| **Audio** | `audioplayers` | Background hardware playback for Adhan |
| **Fonts** | `Google Fonts (Amiri, Inter)` | Classic Arabic Quranic script & modern clean UI |
| **Location** | `geolocator` | GPS coordinates extraction |
| **Storage** | `shared_preferences` | Key-value settings cache |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (version 3.19.0 or higher recommended)
- Java Development Kit (JDK 17)
- Android Studio

### Installation & Compilation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Cancelllls/Islamic-App.git
   cd Islamic-App
   ```

2. **Fetch project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Compile an optimized `arm64` Release APK (Recommended for stability and memory):**
   ```bash
   flutter build apk --release --target-platform=android-arm64
   ```
   *The compiled package will be located at `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<div align="center">

**Made with 🤍 for the Muslim community**

*بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ*

</div>
