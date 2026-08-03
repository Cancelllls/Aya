import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../version.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? "حول التطبيق" : "About Aya",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? "تطبيق آية" : "Aya App",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic ? "الإصدار $appVersion" : "Version $appVersion",
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isArabic
                      ? "تم تطوير هذا التطبيق كصدقة جارية، ليرافقك في رحلتك الإيمانية مع القرآن الكريم والأحاديث النبوية والأذكار اليومية ومواقيت الصلاة."
                      : "This application is developed as a continuous charity (Sadaqah Jariyah), to accompany you on your spiritual journey with the Holy Quran, prophetic hadith, daily supplications, and prayer times.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(theme, isArabic ? "الميزات" : "Features"),
            const SizedBox(height: 12),
            _featureCard(
              theme,
              Icons.wifi_off,
              isArabic
                  ? "يعمل بالكامل بدون إنترنت — قرآن، حديث، أذكار، مواقيت، أذان"
                  : "100% Offline-First — Quran, Hadith, Azkar, Prayer Times, Adhan",
            ),
            _featureCard(
              theme,
              Icons.menu_book,
              isArabic
                  ? "١٠ قراءات قرآنية مع تلاوات من ١٧+ قارئاً"
                  : "10 Qira'at with recitations from 17+ reciters",
            ),
            _featureCard(
              theme,
              Icons.library_books,
              isArabic
                  ? "١٣ كتاب حديث مع التخريج والشرح"
                  : "13 Hadith books with grading and explanation",
            ),
            _featureCard(
              theme,
              Icons.access_alarm,
              isArabic
                  ? "أذان دقيق مع تنبيه قبل الأذان وتذكيرات ذكية"
                  : "Precise Adhan with pre-alerts, smart reminders, and gesture control",
            ),
            _featureCard(
              theme,
              Icons.widgets,
              isArabic
                  ? "٨ أدوات للشاشة الرئيسية — مواقيت، آية اليوم، ذكر، وغيرها"
                  : "8 Home Screen Widgets — Prayer Times, Verse of the Day, Dhikr, and more",
            ),

            const SizedBox(height: 32),
            _sectionHeader(theme, isArabic ? "المطور" : "Developer"),
            const SizedBox(height: 12),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                        child: Icon(Icons.person, color: theme.primaryColor),
                      ),
                      title: const Text(
                        "Abdalrahman Samir",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isArabic
                            ? "مطور تطبيق آية — صُنع بكل حب لخدمة الإسلام"
                            : "Developer of Aya — made with love to serve Islam",
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE5C158).withValues(alpha: 0.15),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFE5C158), size: 20),
                      ),
                      title: Text(
                        isArabic
                            ? "شكر خاص لـ AYA"
                            : "Special Thanks to AYA",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              isArabic
                  ? "جميع الحقوق محفوظة © ٢٠٢٦"
                  : "All rights reserved © 2026",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: const Color(0xFFE5C158).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _featureCard(ThemeData theme, IconData icon, String text) {
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE5C158).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE5C158), size: 20),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

}
