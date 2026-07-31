import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../services/sharh_cache_service.dart';
import '../version.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _downloadingBook;
  String _downloadStatus = '';

  static const _bookLabels = {
    'bukhari': 'Sahih al-Bukhari / صحيح البخاري',
    'muslim': 'Sahih Muslim / صحيح مسلم',
    'abudawud': 'Sunan Abu Dawud / سنن أبي داود',
    'tirmidhi': "Jami' at-Tirmidhi / جامع الترمذي",
    'nasai': "Sunan an-Nasa'i / سنن النسائي",
  };

  Future<void> _downloadCdnBook(String bookId) async {
    setState(() {
      _downloadingBook = bookId;
      _downloadStatus = 'Downloading $bookId...';
    });

    final service = SharhCacheService(
      onLog: (msg) {
        if (mounted) setState(() => _downloadStatus = msg);
      },
    );

    try {
      final added = await service.downloadFromCdn(bookId);
      if (mounted) {
        setState(() {
          _downloadingBook = null;
          _downloadStatus = '✓ $bookId: $added entries';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingBook = null;
          _downloadStatus = '✗ $bookId: $e';
        });
      }
    }
  }

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: Icon(Icons.mosque, size: 80, color: theme.primaryColor),
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isArabic
                          ? "تم تطوير هذا التطبيق كصدقة جارية، ليرافقك في رحلتك الإيمانية مع القرآن الكريم والأذكار اليومية ومواقيت الصلاة."
                          : "This application is developed as a continuous charity (Sadaqah Jariyah), to accompany you on your spiritual journey with the Holy Quran, daily supplications, and prayer times.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? "المطور" : "Developer",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: theme.primaryColor),
                ),
                title: const Text(
                  "Created specially for you",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isArabic
                      ? "صُنع بكل حب لخدمة الإسلام"
                      : "Made with love to serve Islam",
                ),
              ),
            ),

            // ── Offline Sharh Download Section ──
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              isArabic ? "تحميل الشروح" : "Download Hadith Explanations",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isArabic
                  ? 'حمل شروح الأحاديث الكلاسيكية للوصول دون اتصال'
                  : 'Download classical hadith explanations for offline access',
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 8),
            if (_downloadStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _downloadStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (var bookId in _bookLabels.keys)
                  ActionChip(
                    avatar: Icon(
                      _downloadingBook == bookId
                          ? Icons.hourglass_bottom
                          : Icons.cloud_download,
                      size: 14,
                    ),
                    label: Text(
                      _bookLabels[bookId]?.split(' / ').first ?? bookId,
                      style: const TextStyle(fontSize: 10),
                    ),
                    onPressed: _downloadingBook != null
                        ? null
                        : () => _downloadCdnBook(bookId),
                    backgroundColor:
                        const Color(0xFFE5C158).withOpacity(0.1),
                    side: const BorderSide(
                      color: Color(0xFFE5C158),
                      width: 0.5,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),
            Text(
              isArabic
                  ? "جميع الحقوق محفوظة © ٢٠٢٦"
                  : "All rights reserved © 2026",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
