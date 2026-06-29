import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    text = f.read()

def inject_glassmorphism(text):
    # Find all occurrences of "Card(\n            color: theme.cardColor,"
    # Wait, the exact string is:
    # Card(
    #   color: theme.cardColor,
    #   child: Column(
    
    parts = text.split("Card(\n            color: theme.cardColor,\n            child: Column(")
    if len(parts) == 1:
        return text
    
    new_text = parts[0]
    
    # We replace the starting with the glassmorphism
    glass_start = """Card(
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
                child: Column("""
                
    for part in parts[1:]:
        # We need to find the matching closing bracket for the Column(
        # Then we add two more brackets "))" for BackdropFilter and ClipRRect
        
        stack = 1 # for Column(
        idx = 0
        in_string = False
        escape = False
        
        while idx < len(part) and stack > 0:
            c = part[idx]
            if escape:
                escape = False
            elif c == '\\':
                escape = True
            elif c == "'" or c == '"':
                if not in_string:
                    in_string = c
                elif in_string == c:
                    in_string = False
            elif not in_string:
                if c == '(':
                    stack += 1
                elif c == ')':
                    stack -= 1
            idx += 1
            
        # Insert "))" right after idx
        fixed_part = part[:idx] + "\n              ),\n            )" + part[idx:]
        new_text += glass_start + fixed_part
        
    return new_text

res = inject_glassmorphism(text)
# add import dart:ui
if "import 'dart:ui';" not in res:
    res = "import 'dart:ui';\n" + res

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(res)
    
print("Glassmorphism applied.")
