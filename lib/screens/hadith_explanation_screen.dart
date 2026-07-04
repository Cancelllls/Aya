import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:translator/translator.dart';
import '../services/translation_service.dart';

class HadithExplanationScreen extends StatefulWidget {
  final String query;
  final String displayLang;
  final bool isSharh;

  const HadithExplanationScreen({
    super.key,
    required this.query,
    required this.displayLang,
    this.isSharh = false,
  });

  @override
  State<HadithExplanationScreen> createState() =>
      _HadithExplanationScreenState();
}

class _HadithExplanationScreenState extends State<HadithExplanationScreen> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, String>> _parsedExplanations = [];

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    final client = DorarClient();
    try {
      List<Map<String, String>> parsed = [];
      if (widget.isSharh) {
        final sharhResults = await client.searchSharh(
          HadithSearchParams(value: widget.query, page: 1),
        );
        parsed = sharhResults.data.map((s) {
          final sharhFull = (s.sharhText ?? '')
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          String explanation = '';
          String grading = '';

          int rawiIndex = sharhFull.indexOf('الراوي');
          int takhreejIndex = sharhFull.indexOf('التخريج');

          if (rawiIndex != -1 && takhreejIndex != -1) {
            int doubleNewline = sharhFull.indexOf('\n\n', takhreejIndex);
            if (doubleNewline != -1) {
              grading = sharhFull.substring(rawiIndex, doubleNewline).trim();
              explanation = sharhFull.substring(doubleNewline).trim();
            } else {
              int endOfTakhreej = sharhFull.indexOf('\n', takhreejIndex);
              if (endOfTakhreej == -1) endOfTakhreej = sharhFull.length;
              grading = sharhFull.substring(rawiIndex, endOfTakhreej).trim();
              explanation = sharhFull.substring(endOfTakhreej).trim();
            }
          } else {
            explanation = sharhFull;
          }

          return {
            'text': (s.hadithText).replaceAll(RegExp(r'<[^>]*>'), '').trim(),
            'explanation': explanation,
            'grading': grading,
          };
        }).toList();
      } else {
        final hadithResults = await client.searchHadith(
          HadithSearchParams(value: widget.query, page: 1),
        );
        parsed = hadithResults.data
            .map(
              (h) => {
                'text': h.hadith.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                'explanation': '',
                'grading':
                    'الراوي: ${h.rawi}\nالمحدث: ${h.mohdith}\nالمصدر: ${h.book}\nخلاصة حكم المحدث: ${h.grade}'
                        .replaceAll(RegExp(r'<[^>]*>'), '')
                        .trim(),
              },
            )
            .toList();
      }

      if (widget.displayLang == 'eng' && parsed.isNotEmpty) {
        try {
          final translator = GoogleTranslator();
          final List<Map<String, String>> translatedParsed = [];
          for (var item in parsed) {
            final tText = await translator.translate(
              item['text'] ?? '',
              from: 'ar',
              to: 'en',
            );
            final tExplanation = await translator.translate(
              item['explanation'] ?? '',
              from: 'ar',
              to: 'en',
            );
            final tGrading = await translator.translate(
              item['grading'] ?? '',
              from: 'ar',
              to: 'en',
            );
            translatedParsed.add({
              'text': tText.text,
              'explanation': tExplanation.text,
              'grading': tGrading.text,
            });
          }
          if (mounted) {
            setState(() {
              _parsedExplanations = translatedParsed;
              _isLoading = false;
            });
          }
          return;
        } catch (e) {
          // Fallback to Arabic if translation fails
        }
      }

      if (mounted) {
        setState(() {
          _parsedExplanations = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TranslationService.isArabic
              ? "تعذر جلب النتائج. (${e.toString()})"
              : "No results found. (${e.toString()})";
          _isLoading = false;
        });
      }
    } finally {
      await client.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSharh
              ? (TranslationService.isArabic
                    ? "شرح الحديث"
                    : "Hadith Explanation")
              : (TranslationService.isArabic
                    ? "تخريج الحديث"
                    : "Hadith Grading"),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          : _error.isNotEmpty
          ? Center(
              child: Text(
                _error,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            )
          : _parsedExplanations.isEmpty
          ? Center(
              child: Text(
                TranslationService.isArabic
                    ? "لا توجد نتائج مطابقة"
                    : "No exact matches found",
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _parsedExplanations.length,
              itemBuilder: (context, index) {
                final item = _parsedExplanations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Main Text (Hadith)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            item['text'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            textAlign: TextAlign.start,
                            textDirection: widget.displayLang == 'eng'
                                ? TextDirection.ltr
                                : TextDirection.rtl,
                          ),
                        ),

                        // 2. Explanation Text (Main Box)
                        if ((item['explanation'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              item['explanation']!,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              textAlign: TextAlign.start,
                              textDirection: widget.displayLang == 'eng'
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                            ),
                          ),
                        ],

                        // 3. Grading Details (Linked Box)
                        if ((item['grading'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.05),
                              border: Border(
                                left: widget.displayLang == 'eng'
                                    ? BorderSide(
                                        color: theme.primaryColor,
                                        width: 4,
                                      )
                                    : BorderSide.none,
                                right: widget.displayLang != 'eng'
                                    ? BorderSide(
                                        color: theme.primaryColor,
                                        width: 4,
                                      )
                                    : BorderSide.none,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['grading']!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.start,
                              textDirection: widget.displayLang == 'eng'
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
