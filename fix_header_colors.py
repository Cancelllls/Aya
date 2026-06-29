import re

with open('lib/screens/hadith_screen.dart', 'r') as f:
    text = f.read()

# Fix icon background
text = text.replace(
    "color: theme.primaryColor.withOpacity(0.12),",
    "color: Colors.white.withOpacity(0.15),"
)

# Fix Book Icon color
text = text.replace(
    "child: Icon(Icons.import_contacts, color: theme.primaryColor, size: 20),",
    "child: Icon(Icons.import_contacts, color: const Color(0xFFE5C158), size: 20),"
)

# Fix Dropdown arrow
text = text.replace(
    "icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),",
    "icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFFE5C158)),"
)

# Add selectedItemBuilder to DropdownButton
dropdown_start = "isExpanded: true,"
dropdown_with_builder = """isExpanded: true,
                            selectedItemBuilder: (BuildContext context) {
                              return hadithBooks.map((b) {
                                return Container(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    TranslationService.isArabic ? b.nameAr : b.nameEn,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5C158), fontSize: 15),
                                  ),
                                );
                              }).toList();
                            },"""
text = text.replace(dropdown_start, dropdown_with_builder, 1)

# Fix TextButton styling
text = text.replace(
    "style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.primaryColor),",
    "style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE5C158)),", 
    1 # only the first occurrence which is En|ع
)

# Fix download icon
text = text.replace(
    "icon: Icon(Icons.download_for_offline, color: theme.primaryColor),",
    "icon: const Icon(Icons.download_for_offline, color: Color(0xFFE5C158)),"
)

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.write(text)

print("Header colors fixed.")
