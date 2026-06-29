import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    content = f.read()

# Replace Card( color: theme.cardColor, child: Column( ... ) )
# With the Glassmorphic version.
import sys

def replacer(match):
    inner = match.group(1)
    return """Card(
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
                child: Column(""" + inner

new_content = re.sub(r'Card\(\s*color:\s*theme\.cardColor,\s*child:\s*Column\((.*?)', replacer, content, flags=re.DOTALL)

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_content)

print("Replaced cards.")
