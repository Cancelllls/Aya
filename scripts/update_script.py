import re
with open('lib/screens/hadith_screen.dart', 'r') as f:
    lines = f.readlines()

# 1. Imports
lines.insert(4, "import 'package:url_launcher/url_launcher.dart';\n")

# 2. state variable
for i, line in enumerate(lines):
    if 'bool _isLoading = false;' in line:
        lines.insert(i+1, "  int? _highlightedHadithNumber;\n")
        break

# 3. _jumpToHadithByNumber
for i, line in enumerate(lines):
    if 'void _jumpToHadithByNumber(int num) {' in line:
        for j in range(i, i+20):
            if '_jumpController.clear();' in lines[j]:
                lines.insert(j+1, "        _highlightedHadithNumber = num;\n")
                break
        
        # find jumpTo
        for j in range(i, i+30):
            if '_scrollController.jumpTo(0.0);' in lines[j]:
                insert_idx = j + 3 # after the if block and delay
                lines.insert(insert_idx, """      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _highlightedHadithNumber = null;
          });
        }
      });\n""")
                break
        break

# 4. _showHadithOptions
for i, line in enumerate(lines):
    if 'ListTile(' in line and 'قراءة الشرح' in lines[i+2]:
        # replace the whole modal
        pass

with open('lib/screens/hadith_screen.dart', 'w') as f:
    f.writelines(lines)
