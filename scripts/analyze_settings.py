with open('lib/screens/settings_screen.dart', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'ListTile(' in line or 'Card(' in line or 'SwitchListTile(' in line or '_buildSectionHeader(' in line or 'if (_' in line:
        print(f"{i}: {line.strip()}")
