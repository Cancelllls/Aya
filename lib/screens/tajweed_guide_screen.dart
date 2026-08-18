import 'package:flutter/material.dart';
import '../services/tajweed_service.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';

class TajweedGuideScreen extends StatelessWidget {
  final StorageService storage;

  const TajweedGuideScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = storage.isDarkMode();
    final isArabic = TranslationService.isArabic;

    final rulesList = TajweedRuleInfo.rules.values.toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isArabic ? 'دليل أحكام التجويد' : 'Tajweed Rules Guide',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF042F1A), const Color(0xFF02170D)]
                    : [const Color(0xFF0D9488), const Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Color(0xFFE5C158),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'أحكام تلاوة القرآن الكريم' : 'Rules of Quranic Recitation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'تعرّف على دلالات الألوان المستخدمة في المصحف الملون'
                            : 'Understand color codes used in Tajweed highlighted Quran',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Header
          Text(
            isArabic ? 'الأحكام الأساسية' : 'Core Tajweed Rules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),

          // Tajweed Rules Cards
          ...rulesList.map((info) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: info.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: info.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: info.color.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isArabic ? info.nameAr : info.nameEn,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isArabic ? info.nameEn : info.nameAr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: info.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic ? info.descriptionAr : info.descriptionEn,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
