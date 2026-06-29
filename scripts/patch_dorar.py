import json

# 1. Update main.dart
with open('lib/main.dart', 'r') as f:
    main_lines = f.readlines()

for i, line in enumerate(main_lines):
    if "import 'screens/bookmarks_screen.dart';" in line:
        main_lines.insert(i+1, "import 'package:dorar_hadith_flutter/dorar_hadith_flutter.dart';\n")
        break

for i, line in enumerate(main_lines):
    if "WidgetsFlutterBinding.ensureInitialized();" in line:
        main_lines.insert(i+1, "  await DorarHadithFlutter.ensureInitialized();\n")
        break

with open('lib/main.dart', 'w') as f:
    f.writelines(main_lines)

# 2. Update hadith_screen.dart to use native screen again
with open('lib/screens/hadith_screen.dart', 'r') as f:
    hadith_lines = f.readlines()

for i, line in enumerate(hadith_lines):
    if "final url = Uri.parse('https://dorar.net/hadith/search?q=$encoded&st=p2');" in line:
        # replace the whole block
        start_idx = i - 1
        end_idx = i + 3
        hadith_lines[start_idx:end_idx+1] = [
            "                  await Navigator.push(\n",
            "                    context,\n",
            "                    MaterialPageRoute(\n",
            "                      builder: (context) => HadithExplanationScreen(\n",
            "                        query: queryWords,\n",
            "                        displayLang: _displayLang,\n",
            "                        isSharh: true,\n",
            "                      ),\n",
            "                    ),\n",
            "                  );\n"
        ]
        break

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.writelines(hadith_lines)

# 3. Update hadith_explanation_screen.dart to use DorarClient
with open('lib/screens/hadith_explanation_screen.dart', 'r') as f:
    expl_lines = f.readlines()

# add import
for i, line in enumerate(expl_lines):
    if "import 'package:html/parser.dart" in line:
        expl_lines.insert(i+1, "import 'package:dorar_hadith/dorar_hadith.dart';\n")
        break

# rewrite _fetchExplanation and _parseDorarHtml
fetch_code = """  Future<void> _fetchExplanation() async {
    final client = DorarClient();
    try {
      List<Map<String, String>> parsed = [];
      if (widget.isSharh) {
        final sharhResults = await client.searchSharh(
          HadithSearchParams(value: widget.query, page: 1)
        );
        parsed = sharhResults.data.map((s) => {
          'text': (s.hadith ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim(),
          'info': (s.sharhText ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        }).toList();
      } else {
        final hadithResults = await client.searchHadith(
          HadithSearchParams(value: widget.query, page: 1)
        );
        parsed = hadithResults.data.map((h) => {
          'text': h.hadith.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
          'info': 'الراوي: ${h.rawi}\\nالمحدث: ${h.mohdith}\\nالمصدر: ${h.book}\\nخلاصة حكم المحدث: ${h.grade}'.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        }).toList();
      }
      
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TranslationService.isArabic ? "لم يتم العثور على نتائج" : "No results found.";
          _isLoading = false;
        });
      }
    } finally {
      await client.dispose();
    }
  }

"""

start_fetch = -1
end_parse = -1
for i, line in enumerate(expl_lines):
    if "Future<void> _fetchExplanation() async {" in line:
        start_fetch = i
    if "Widget build(BuildContext context) {" in line:
        end_parse = i
        break

if start_fetch != -1 and end_parse != -1:
    expl_lines[start_fetch:end_parse] = [fetch_code, "  @override\n", "  "]

with open('lib/screens/hadith_explanation_screen.dart', 'w') as f:
    f.writelines(expl_lines)

print("Updated everything to use dorar_hadith")
