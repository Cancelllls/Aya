import os
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    orig = content

    # If it contains Theme.of(context), it cannot be const!
    # Let's remove `const ` before `Text(` if that Text contains Theme.of
    content = re.sub(r'const\s+Text\((.*?Theme\.of\(context\).*?)\)', r'Text(\1)', content, flags=re.DOTALL)
    
    # Also remove `const ` before `[` if the array contains Theme.of
    content = re.sub(r'const\s+\[(.*?)Theme\.of\(context\)(.*?)\]', r'[\1Theme.of(context)\2]', content, flags=re.DOTALL)
    
    # Check for `Theme.of(context)` inside `CompassDialPainter`
    if 'CompassDialPainter' in content:
        content = content.replace('Theme.of(context)', 'theme')

    if orig != content:
        with open(filepath, 'w') as f:
            f.write(content)

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
