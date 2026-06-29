import json

with open('lib/screens/hadith_screen.dart', 'r') as f:
    lines = f.readlines()

# 1. Update offline parsing
for i, line in enumerate(lines):
    if "            'arabic': _displayLang == 'ara' ? text : ''," in line:
        lines.insert(i+1, "            'searchArText': _displayLang == 'ara' ? _normalizeArabic(text.toString()).toLowerCase() : '',\n")
        lines.insert(i+2, "            'searchEnText': _displayLang == 'eng' ? text.toString().toLowerCase() : '',\n")
        break

# 2. Update online parsing
for i, line in enumerate(lines):
    if "            'arabic': _displayLang == 'ara' ? (h['text'] ?? '') : ''," in line:
        lines.insert(i+1, "            'searchArText': _displayLang == 'ara' ? _normalizeArabic((h['text'] ?? '').toString()).toLowerCase() : '',\n")
        lines.insert(i+2, "            'searchEnText': _displayLang == 'eng' ? (h['text'] ?? '').toString().toLowerCase() : '',\n")
        break

# 3. Update _getFilteredHadiths
for i, line in enumerate(lines):
    if "final arText = _normalizeArabic(h['arabic'].toString()).toLowerCase();" in line:
        lines[i] = "      final arText = h['searchArText'];\n"
    elif "final enText = h['english'].toString().toLowerCase();" in line:
        lines[i] = "      final enText = h['searchEnText'];\n"

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.writelines(lines)
print("Updated hadith_screen.dart for faster search")
