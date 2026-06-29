import sys

with open('lib/screens/hadith_screen.dart', 'r') as f:
    lines = f.readlines()

def replace_block(start_marker, end_marker, replacement_lines):
    start_idx = -1
    end_idx = -1
    for i, line in enumerate(lines):
        if start_marker in line:
            start_idx = i
            break
    if start_idx != -1:
        for i in range(start_idx, len(lines)):
            if end_marker in lines[i]:
                end_idx = i
                break
    if start_idx != -1 and end_idx != -1:
        lines[start_idx:end_idx+1] = replacement_lines
        return True
    return False

# 1. Add url_launcher
lines.insert(4, "import 'package:url_launcher/url_launcher.dart';\n")

# 2. Add _highlightedHadithNumber
for i, line in enumerate(lines):
    if 'bool _isLoading = false;' in line:
        lines.insert(i+1, "  int? _highlightedHadithNumber;\n")
        break

# 3. Replace _jumpToHadithByNumber
jump_start = "  void _jumpToHadithByNumber(int num) {"
jump_end = "    } else if (mounted) {"
jump_replacement = [
    "  void _jumpToHadithByNumber(int num) {\n",
    "    final idx = _hadithList.indexWhere((element) => element['number'] == num);\n",
    "    if (idx != -1) {\n",
    "      setState(() {\n",
    "        _currentPage = (idx / _pageSize).floor() + 1;\n",
    "        _jumpController.clear();\n",
    "        _highlightedHadithNumber = num;\n",
    "      });\n",
    "      Future.delayed(const Duration(milliseconds: 200), () {\n",
    "        if (_scrollController.hasClients) {\n",
    "          _scrollController.jumpTo(0.0);\n",
    "        }\n",
    "      });\n",
    "      Future.delayed(const Duration(seconds: 4), () {\n",
    "        if (mounted) {\n",
    "          setState(() {\n",
    "            _highlightedHadithNumber = null;\n",
    "          });\n",
    "        }\n",
    "      });\n",
    "    } else if (mounted) {\n"
]
replace_block(jump_start, jump_end, jump_replacement)

# 4. Replace Modal Options
modal_start = "              ListTile("
modal_end = "              ),"
modal_search_start = -1
for i, line in enumerate(lines):
    if "void _showHadithOptions" in line:
        modal_search_start = i
        break

modal_start_idx = -1
modal_end_idx = -1
for i in range(modal_search_start, len(lines)):
    if "ListTile(" in lines[i] and "Icons.menu_book" in lines[i+1]:
        modal_start_idx = i
        break

if modal_start_idx != -1:
    # Find the end of the second ListTile
    for i in range(modal_start_idx, len(lines)):
        if "              )," in lines[i] and "}, // showModalBottomSheet" in lines[i+2]:
            modal_end_idx = i
            break

if modal_start_idx != -1 and modal_end_idx != -1:
    modal_replacement = [
        '              ListTile(\n',
        '                leading: const Icon(Icons.fact_check, color: Color(0xFFE5C158)),\n',
        '                title: Text(TranslationService.isArabic ? "تخريج الحديث (إنترنت)" : "Hadith Grading (Online)"),\n',
        '                subtitle: Text(TranslationService.isArabic ? "البحث عن تخريج الحديث وحكمه في موقع الدرر السنية" : "Search for authenticity grading on Dorar.net"),\n',
        '                onTap: () async {\n',
        '                  Navigator.pop(context);\n',
        '                  final text = h[\'arabic\'].toString();\n',
        '                  final queryWords = _buildHadithQuery(text);\n',
        '                  Navigator.push(\n',
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
        '                  final encoded = Uri.encodeComponent(queryWords);\n',
        '                  final url = Uri.parse("https://dorar.net/hadith/search?q=$encoded&st=p2");\n',
        '                  if (await canLaunchUrl(url)) {\n',
        '                    await launchUrl(url, mode: LaunchMode.externalApplication);\n',
        '                  }\n',
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
    lines[modal_start_idx:modal_end_idx+1] = modal_replacement

# 5. Replace Card
card_start_idx = -1
card_end_idx = -1
for i, line in enumerate(lines):
    if "itemBuilder: (context, index) {" in line:
        card_start_idx = i
        break

if card_start_idx != -1:
    for i in range(card_start_idx, len(lines)):
        if "                                    side: BorderSide(color: Colors.white.withOpacity(0.1))," in lines[i]:
            card_end_idx = i + 1
            break

if card_start_idx != -1 and card_end_idx != -1:
    card_replacement = [
        '                                  itemBuilder: (context, index) {\n',
        '                                    final h = pageHadiths[index];\n',
        '                                    final isHighlighted = _highlightedHadithNumber == h[\'number\'];\n',
        '                                    return AnimatedContainer(\n',
        '                                      duration: const Duration(milliseconds: 500),\n',
        '                                      margin: const EdgeInsets.only(bottom: 12),\n',
        '                                      decoration: BoxDecoration(\n',
        '                                        color: isHighlighted ? const Color(0xFFE5C158).withOpacity(0.15) : theme.cardColor.withOpacity(0.7),\n',
        '                                        borderRadius: BorderRadius.circular(16),\n',
        '                                        border: Border.all(\n',
        '                                          color: isHighlighted ? const Color(0xFFE5C158) : Colors.white.withOpacity(0.1),\n',
        '                                          width: isHighlighted ? 2.0 : 1.0,\n',
        '                                        ),\n',
        '                                      ),\n',
        '                                      child: Card(\n',
        '                                        margin: EdgeInsets.zero,\n',
        '                                        color: Colors.transparent,\n',
        '                                        elevation: isHighlighted ? 8 : 0,\n',
        '                                        shape: RoundedRectangleBorder(\n',
        '                                          borderRadius: BorderRadius.circular(16),\n',
        '                                        ),\n'
    ]
    lines[card_start_idx:card_end_idx] = card_replacement

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.writelines(lines)
