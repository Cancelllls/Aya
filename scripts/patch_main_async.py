import re

with open('lib/main.dart', 'r') as f:
    text = f.read()

# Make onPressed async for bookmarks
text = re.sub(r"tooltip: TranslationService\.isArabic \? 'العلامات المرجعية' : 'Bookmarks',\s*onPressed: \(\) {", r"tooltip: TranslationService.isArabic ? 'العلامات المرجعية' : 'Bookmarks',\n              onPressed: () async {", text)

with open('lib/main.dart', 'w') as f:
    f.write(text)
