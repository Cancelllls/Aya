import re

with open('lib/screens/hadith_screen.dart', 'r') as f:
    text = f.read()

# Make sure dart:ui is imported
if "import 'dart:ui';" not in text:
    text = "import 'dart:ui';\n" + text

old_card = """return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: theme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: theme.primaryColor.withOpacity(0.15)),
                                  ),
                                  child: InkWell("""

new_card = """return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: theme.cardColor.withOpacity(0.7),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: InkWell("""

text = text.replace(old_card, new_card)

# Now we need to add '))' at the end of the return statement.
# The `Card` spans multiple lines. We need to find the `);` that matches `return Card(`.
# Actually, since I know the structure, let's find the matching `);` manually or use a regex for the end of the item builder block.
# The itemBuilder looks like:
# itemBuilder: (context, index) {
#   final h = pageHadiths[index];
#   return Card( ... );
# },
# Let's replace `                                );\n                              },` with `                                )));\n                              },`

old_end = """                                );
                              },"""
new_end = """                                )));
                              },"""

text = text.replace(old_end, new_end)

# Let's also style the "Book Selector Widget" container to look teal/gold gradient!
# Currently:
#             Container(
#               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
#               decoration: BoxDecoration(
#                 color: theme.cardColor,
#                 border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
#               ),

old_header = """            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
              ),"""

new_header = """            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark 
                    ? [const Color(0xFF042F1A), const Color(0xFF02170D)]
                    : [const Color(0xFF0D9488), const Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
              ),"""
              
text = text.replace(old_header, new_header)

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.write(text)

print("Applied UI/UX to Hadith Screen")
