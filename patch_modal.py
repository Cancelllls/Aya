import json

with open('lib/screens/hadith_screen.dart', 'r') as f:
    lines = f.readlines()

new_modal = [
    '              ListTile(\n',
    '                leading: const Icon(Icons.fact_check, color: Color(0xFFE5C158)),\n',
    '                title: Text(TranslationService.isArabic ? "تخريج الحديث (إنترنت)" : "Hadith Grading (Online)"),\n',
    '                subtitle: Text(TranslationService.isArabic ? "البحث عن تخريج الحديث وحكمه في موقع الدرر السنية" : "Search for authenticity grading on Dorar.net"),\n',
    '                onTap: () async {\n',
    '                  Navigator.pop(context);\n',
    '                  final text = h[\'arabic\'].toString();\n',
    '                  final queryWords = _buildHadithQuery(text);\n',
    '                  await Navigator.push(\n',
    '                    context,\n',
    '                    MaterialPageRoute(\n',
    '                      builder: (context) => HadithExplanationScreen(\n',
    '                        query: queryWords,\n',
    '                        displayLang: _displayLang,\n',
    '                      ),\n',
    '                    ),\n',
    '                  );\n',
    '                },\n',
    '              ),\n',
    '              ListTile(\n',
    '                leading: const Icon(Icons.menu_book, color: Color(0xFFE5C158)),\n',
    '                title: Text(TranslationService.isArabic ? "قراءة الشرح (إنترنت)" : "Read Explanation (Online)"),\n',
    '                subtitle: Text(TranslationService.isArabic ? "البحث عن شروحات الحديث في الموسوعة الحديثية" : "Search for scholarly explanations on Dorar.net"),\n',
    '                onTap: () async {\n',
    '                  Navigator.pop(context);\n',
    '                  final text = h[\'arabic\'].toString();\n',
    '                  final queryWords = _buildHadithQuery(text);\n',
    '                  await Navigator.push(\n',
    '                    context,\n',
    '                    MaterialPageRoute(\n',
    '                      builder: (context) => HadithExplanationScreen(\n',
    '                        query: queryWords,\n',
    '                        displayLang: _displayLang,\n',
    '                        isSharh: true,\n',
    '                      ),\n',
    '                    ),\n',
    '                  );\n',
    '                },\n',
    '              ),\n',
    '              StatefulBuilder(\n',
    '                builder: (context, setModalState) {\n',
    '                  final List<String> current = widget.storage.getStringList(\'hadith_bookmarks\') ?? [];\n',
    '                  final data = jsonEncode({\n',
    '                    \'bookId\': _selectedBook.id,\n',
    '                    \'book\': _selectedBook.nameEn,\n',
    '                    \'bookAr\': _selectedBook.nameAr,\n',
    '                    \'number\': h[\'number\'],\n',
    '                    \'text\': _displayLang == \'ara\' ? h[\'arabic\'] : h[\'english\']\n',
    '                  });\n',
    '                  final isSaved = current.contains(data);\n',
    '\n',
    '                  return ListTile(\n',
    '                    leading: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFE5C158)),\n',
    '                    title: Text(isSaved \n',
    '                        ? (TranslationService.isArabic ? "إزالة العلامة المرجعية" : "Remove Bookmark")\n',
    '                        : (TranslationService.isArabic ? "حفظ كعلامة مرجعية" : "Add to Bookmarks")),\n',
    '                    subtitle: Text(TranslationService.isArabic ? "المفضلة للأحاديث" : "Hadith favorites"),\n',
    '                    onTap: () async {\n',
    '                      if (isSaved) {\n',
    '                        current.remove(data);\n',
    '                      } else {\n',
    '                        current.add(data);\n',
    '                      }\n',
    '                      await widget.storage.setStringList(\'hadith_bookmarks\', current);\n',
    '                      setModalState(() {});\n',
    '                      final messenger = ScaffoldMessenger.of(this.context);\n',
    '                      messenger.showSnackBar(SnackBar(\n',
    '                        content: Text(isSaved \n',
    '                            ? (TranslationService.isArabic ? "تم الإزالة بنجاح" : "Removed successfully") \n',
    '                            : (TranslationService.isArabic ? "تم الحفظ بنجاح" : "Saved successfully!")),\n',
    '                        duration: const Duration(seconds: 1),\n',
    '                      ));\n',
    '                    },\n',
    '                  );\n',
    '                },\n',
    '              ),\n'
]

# find start and end
start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if "ListTile(" in line and "Icons.menu_book" in lines[i+1]:
        start_idx = i
        break

if start_idx != -1:
    for i in range(start_idx, len(lines)):
        if "              )," in lines[i] and "const SizedBox(height: 12)," in lines[i+1]:
            end_idx = i
            break

if start_idx != -1 and end_idx != -1:
    lines[start_idx:end_idx+1] = new_modal
    with open('lib/screens/hadith_screen.dart', 'w') as f:
        f.writelines(lines)
    print("Replaced!")
else:
    print("Could not find bounds")
