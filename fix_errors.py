import re
import os

def fix_nullable_color(content):
    # Change Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(...) to Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(...) ?? Colors.white
    # Actually, it's easier to regex replace `withOpacity([0-9\.]+)\)` with `withOpacity(\1) ?? Colors.white` but only if it has `Theme.of(context)`
    
    # Let's just fix the specific nullability errors:
    # 1. `Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.08)` -> `(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withOpacity(0.08)`
    content = re.sub(r'Theme\.of\(context\)\.textTheme\.(body[A-Za-z]+)\?\.color\?\.withOpacity\((.*?)\)', r'(Theme.of(context).textTheme.\1?.color ?? Colors.white).withOpacity(\2)', content)
    content = re.sub(r'Theme\.of\(context\)\.shadowColor\.withOpacity\((.*?)\)', r'Theme.of(context).shadowColor.withOpacity(\1)', content)
    content = re.sub(r'Theme\.of\(context\)\.dividerColor\.withOpacity\((.*?)\)', r'Theme.of(context).dividerColor.withOpacity(\1)', content)

    # For naked bodyLarge?.color without withOpacity:
    content = re.sub(r'(color:\s*)Theme\.of\(context\)\.textTheme\.(body[A-Za-z]+)\?\.color(?! \?\?)(?![\.\?])', r'\1(Theme.of(context).textTheme.\2?.color ?? Colors.white)', content)

    return content

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    orig = content

    content = fix_nullable_color(content)

    if orig != content:
        with open(filepath, 'w') as f:
            f.write(content)

for root, dirs, files in os.walk('lib/screens'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

for root, dirs, files in os.walk('lib/widgets'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
