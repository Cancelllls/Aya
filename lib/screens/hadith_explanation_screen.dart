import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:translator/translator.dart';
import '../services/translation_service.dart';
class HadithExplanationScreen extends StatefulWidget {
  final String query;
  final String displayLang;

  const HadithExplanationScreen({super.key, required this.query, required this.displayLang});

  @override
  State<HadithExplanationScreen> createState() => _HadithExplanationScreenState();
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
    try {
      final encodedQuery = Uri.encodeComponent(widget.query);
      final url = 'https://dorar.net/dorar_api.json?skey=$encodedQuery';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final htmlString = decoded['ahadith']['result'] ?? '';
        
        final parsed = _parseDorarHtml(htmlString);
        
        if (widget.displayLang == 'eng' && parsed.isNotEmpty) {
          try {
            final translator = GoogleTranslator();
            final List<Map<String, String>> translatedParsed = [];
            for (var item in parsed) {
              final tText = await translator.translate(item['text'] ?? '', from: 'ar', to: 'en');
              final tInfo = await translator.translate(item['info'] ?? '', from: 'ar', to: 'en');
              translatedParsed.add({
                'text': tText.text,
                'info': tInfo.text,
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
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TranslationService.isArabic ? "لم يتم العثور على شروحات إضافية" : "No additional explanations found.";
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, String>> _parseDorarHtml(String htmlString) {
    final document = html_parser.parse(htmlString);
    final results = <Map<String, String>>[];
    
    // Each hadith entry seems to start after <br/> tags and typically has a .hadith class and .hadith-info class
    final hadithDivs = document.querySelectorAll('.hadith');
    final infoDivs = document.querySelectorAll('.hadith-info');
    
    for (int i = 0; i < hadithDivs.length; i++) {
      final hText = hadithDivs[i].text.trim();
      
      String infoText = '';
      if (i < infoDivs.length) {
        String rawText = infoDivs[i].text.replaceAll(RegExp(r'\s+'), ' ').trim();
        // Insert newlines before known labels to make it readable
        rawText = rawText.replaceAll('الراوي:', '\nالراوي:');
        rawText = rawText.replaceAll('المحدث:', '\nالمحدث:');
        rawText = rawText.replaceAll('المصدر:', '\nالمصدر:');
        rawText = rawText.replaceAll('الصفحة أو الرقم:', '\nالصفحة أو الرقم:');
        rawText = rawText.replaceAll('خلاصة حكم المحدث:', '\nخلاصة حكم المحدث:');
        rawText = rawText.replaceAll('التخريج:', '\nالتخريج:');
        infoText = rawText.trim();
      }
      
      if (hText.isNotEmpty) {
        results.add({
          'text': hText,
          'info': infoText.trim(),
        });
      }
    }
    
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.isArabic ? "شرح وتخريج الحديث" : "Hadith Explanation & Grading", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
              : _parsedExplanations.isEmpty
                  ? Center(child: Text(TranslationService.isArabic ? "لا توجد نتائج مطابقة" : "No exact matches found"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _parsedExplanations.length,
                      itemBuilder: (context, index) {
                        final item = _parsedExplanations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
                          color: theme.cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  textAlign: TextAlign.start,
                                  textDirection: widget.displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['info'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    textAlign: TextAlign.start,
                                    textDirection: widget.displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
