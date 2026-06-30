import os
import re

def remove_const(text):
    # Regex to find 'const ' before widgets/objects that will become non-const
    text = re.sub(r'const\s+(TextStyle|Divider|Icon|BorderSide|Border|SizedBox|Padding|Container)', r'\1', text)
    # Also handle 'const [' to '[' if there are elements inside that become dynamic
    return text

def process_dir(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                original = content
                
                # We need Theme.of(context)
                
                replacements = {
                    r'Colors\.white70': r'Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)',
                    r'Colors\.white38': r'Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.38)',
                    r'Colors\.white30': r'Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3)',
                    r'Colors\.white24': r'Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.24)',
                    r'Colors\.white12': r'Theme.of(context).dividerColor.withOpacity(0.12)',
                    r'Colors\.white10': r'Theme.of(context).dividerColor.withOpacity(0.1)',
                    r'Colors\.white\.withOpacity\((.*?)\)': r'Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(\1)',
                    r'Colors\.black\.withOpacity\((.*?)\)': r'Theme.of(context).shadowColor.withOpacity(\1)',
                }
                
                # Replace Colors.white (exact match, not followed by numbers or dot)
                content = re.sub(r'Colors\.white(?!\d|\.)', r'Theme.of(context).textTheme.bodyLarge?.color', content)
                
                for k, v in replacements.items():
                    content = re.sub(k, v, content)
                
                if original != content:
                    content = remove_const(content)
                    with open(filepath, 'w') as f:
                        f.write(content)

process_dir('lib/screens')
process_dir('lib/widgets')
