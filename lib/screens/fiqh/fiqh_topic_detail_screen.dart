import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/fiqh_model.dart';
import '../../services/storage_service.dart';
import '../../services/translation_service.dart';
import '../full_book_reader_screen.dart';

class FiqhTopicDetailScreen extends StatelessWidget {
  final FiqhTopic topic;
  final StorageService? storage;

  const FiqhTopicDetailScreen({
    super.key,
    required this.topic,
    this.storage,
  });

  void _shareTopic(bool isArabic) {
    final title = topic.getTitle(isArabic);
    final summary = topic.getSummary(isArabic);
    final sectionsText = topic.sections.map((s) {
      final sTitle = s.getTitle(isArabic);
      final sContent = s.getContent(isArabic);
      final points = s.getBulletPoints(isArabic).map((p) => '• $p').join('\n');
      return '$sTitle\n$sContent\n$points';
    }).join('\n\n');

    final text = '''
$title
-------------------------
$summary

$sectionsText

-------------------------
تطبيق آية - رفيقك الإسلامي الشامل
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = TranslationService.isArabic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          topic.getTitle(isArabic),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: isArabic ? 'مشاركة' : 'Share',
            onPressed: () => _shareTopic(isArabic),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header summary banner
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: const Color(0xFFE5C158).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5C158).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Color(0xFFE5C158),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isArabic
                                  ? '${topic.readTimeMinutes} دقائق قراءة'
                                  : '${topic.readTimeMinutes} min read',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE5C158),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.getSummary(isArabic),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Sections
            ...topic.sections.map((section) => _buildSection(section, theme, isArabic)),

            // Evidences (الأدلة الشرعية)
            if (topic.evidences.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                isArabic ? 'الأدلة من القرآن والسنة' : 'Evidences from Quran & Sunnah',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5C158),
                ),
              ),
              const SizedBox(height: 12),
              ...topic.evidences.map((e) => _buildEvidenceCard(e, theme, isArabic)),
            ],

            // FAQs (مسائل شائعة)
            if (topic.faqs.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                isArabic ? 'مسائل وأسئلة شائعة' : 'Common Questions & Rulings',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...topic.faqs.map((faq) => _buildFaqTile(faq, theme, isArabic)),
            ],

            const SizedBox(height: 20),
            _buildBookReferenceCard(context, theme, isArabic),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildBookReferenceCard(BuildContext context, ThemeData theme, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5C158).withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final s = storage ?? await StorageService.getInstance();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullBookReaderScreen(
                bookKey: 'fiqh_muyassar',
                defaultTitleAr: 'كتاب الفقه الميسر في ضوء الكتاب والسنة',
                defaultTitleEn: 'Al-Fiqh Al-Muyassar (Simplified Fiqh)',
                storage: s,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFE5C158),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الاستزادة من كتاب الفقه الميسر' : 'Read in Al-Fiqh Al-Muyassar',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'تصفح نصوص الكتاب الكاملة (439 صفحة) مع البحث والفهرس'
                          : 'Browse full canonical text (439 pages) with search and index',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isArabic ? Icons.chevron_left : Icons.chevron_right,
                color: const Color(0xFFE5C158),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(FiqhSection section, ThemeData theme, bool isArabic) {
    final title = section.getTitle(isArabic);
    final content = section.getContent(isArabic);
    final points = section.getBulletPoints(isArabic);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (points.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5C158),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(FiqhEvidence evidence, ThemeData theme, bool isArabic) {
    final text = isArabic ? evidence.textAr : evidence.textEn;
    final isQuran = evidence.type == 'quran';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isQuran
            ? const Color(0xFF0F766E).withValues(alpha: 0.1)
            : const Color(0xFFE5C158).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isQuran ? const Color(0xFF0F766E) : const Color(0xFFE5C158),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isQuran ? Icons.menu_book_rounded : Icons.format_quote_rounded,
                size: 18,
                color: isQuran ? const Color(0xFF0F766E) : const Color(0xFFE5C158),
              ),
              const SizedBox(width: 6),
              Text(
                isQuran
                    ? (isArabic ? 'قرآن كريم' : 'Holy Quran')
                    : (isArabic ? 'حديث نبوي شريف' : 'Prophetic Hadith'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isQuran ? const Color(0xFF0F766E) : const Color(0xFFE5C158),
                ),
              ),
              const Spacer(),
              Text(
                evidence.reference,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              fontFamily: isQuran ? 'Amiri' : null,
              fontWeight: isQuran ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(FiqhFaq faq, ThemeData theme, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          faq.getQuestion(isArabic),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          Text(
            faq.getAnswer(isArabic),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
