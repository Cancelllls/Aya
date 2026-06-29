import re

with open('lib/screens/prayer_tracker_screen.dart', 'r') as f:
    content = f.read()

# Replace checklist visual style
content = content.replace(
    'theme.textTheme.bodyMedium?.color?.withOpacity(0.4)',
    'theme.textTheme.bodyLarge?.color'
).replace(
    'theme.textTheme.bodyLarge?.color,',
    'theme.textTheme.bodyMedium?.color?.withOpacity(0.4),'
).replace(
    'decoration: isCompleted ? TextDecoration.lineThrough : null,',
    'decoration: null,'
).replace(
    'fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,',
    'fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,'
)

with open('lib/screens/prayer_tracker_screen.dart', 'w') as f:
    f.write(content)
