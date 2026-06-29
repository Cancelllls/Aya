import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    text = f.read()

# We look for:
# DropdownMenuItem(
#   value: 'silent',
#   child: Text(...),
# )
# And replace `child: Text(` with `child: Align(alignment: AlignmentDirectional.centerStart, child: Text(`
# Wait, some already have Align.
# Let's replace ONLY those that don't have Align!

def replace_child(match):
    prefix = match.group(1)
    text_call = match.group(2)
    # Check if there's already an Align
    if 'Align(' in prefix:
        return match.group(0)
    
    # Replace `child:\s*Text(` with `child: Align(alignment: AlignmentDirectional.centerStart, child: Text(`
    return prefix + "Align(alignment: AlignmentDirectional.centerStart, child: " + text_call

new_text = re.sub(r'(DropdownMenuItem\s*(?:<[^>]+>)?\s*\([\s\S]*?child:\s*)(Text\()', replace_child, text)

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_text)
    
print("Alignment fixed.")
