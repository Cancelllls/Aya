with open('lib/screens/hadith_explanation_screen.dart', 'r') as f:
    text = f.read()

text = text.replace('TranslationService.isArabic ? TextDirection.rtl : TextDirection.ltr', "widget.displayLang == 'eng' ? TextDirection.ltr : TextDirection.rtl")

with open('lib/screens/hadith_explanation_screen.dart', 'w') as f:
    f.write(text)
