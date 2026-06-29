with open('lib/screens/settings_screen.dart', 'r') as f:
    text = f.read()

text = text.replace('DropdownMenuItem(isExpanded: true,\n', 'DropdownMenuItem(')
text = text.replace('DropdownMenuItem<int>(isExpanded: true,\n', 'DropdownMenuItem<int>(')
text = text.replace('DropdownMenuItem<String>(isExpanded: true,\n', 'DropdownMenuItem<String>(')

# Actually, the replacement in the previous script was:
# 'DropdownMenuItem(isExpanded: true,\n                                          value:'
import re
text = re.sub(r'DropdownMenuItem(?:<[^>]+>)?\(\s*isExpanded:\s*true,', lambda m: m.group(0).replace('isExpanded: true,', ''), text)

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(text)

