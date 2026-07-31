import 'package:flutter/material.dart';
import '../version.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';

/// Shows changelog on first launch after version bump.
class ChangelogDialog {
  static Future<void> showIfNew(BuildContext context) async {
    final storage = await StorageService.getInstance();
    final seen = storage.getString('seen_changelog', defaultValue: '');
    if (seen == appVersion) return;

    final isArabic = TranslationService.isArabic;
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            isArabic ? '!ما الجديد' : "What's New!",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItem(Icons.library_books, isArabic
                    ? '١٣ كتاب حديث مع شرح كلاسيكي دون اتصال'
                    : '13 Hadith books with classical sharh — offline'),
                _buildItem(Icons.search, isArabic
                    ? 'البحث في ٧٥ ألف حديث دفعة واحدة'
                    : 'Search 75K+ hadiths across all books at once'),
                _buildItem(Icons.download, isArabic
                    ? 'تحميل شروح الأحاديث للوصول دون اتصال'
                    : 'Download hadith explanations for offline access'),
                _buildItem(Icons.share, isArabic
                    ? 'مشاركة الأحاديث والآيات'
                    : 'Share hadith & Quran verses'),
                _buildItem(Icons.backup, isArabic
                    ? 'تصدير واستيراد الإشارات والإعدادات'
                    : 'Backup & restore bookmarks & settings'),
                _buildItem(Icons.data_usage, isArabic
                    ? 'إحصائيات متتبع الصلاة'
                    : 'Prayer tracker statistics'),
                _buildItem(Icons.speed, isArabic
                    ? 'تحسينات في الأداء وقاعدة البيانات'
                    : 'Performance & database optimizations'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                storage.setString('seen_changelog', appVersion);
              },
              child: Text(isArabic ? 'حسناً' : 'Got it!'),
            ),
          ],
        ),
      );
      await storage.setString('seen_changelog', appVersion);
    }
  }

  static Widget _buildItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE5C158)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
