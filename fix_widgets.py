import os
import re

def process_kt(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace hardcoded "نور" with appName
    if 'val appName = if (isArabic) "آية" else "Aya"' not in content:
        # We need to add it!
        # Find where prefs are retrieved
        prefs_match = re.search(r'val prefs = .*?', content)
        if prefs_match:
            insert_pos = content.find('\n', prefs_match.end()) + 1
            content = content[:insert_pos] + '            val isArabic = prefs.getBoolean("flutter.widget_is_arabic", true)\n            val appName = if (isArabic) "آية" else "Aya"\n' + content[insert_pos:]
    
    # Replace "نور" with appName
    content = content.replace('setTextViewText(R.id.widget_title, "نور")', 'setTextViewText(R.id.widget_title, appName)')
    content = content.replace('setTextViewText(R.id.widget_subtitle, "نور")', 'setTextViewText(R.id.widget_subtitle, appName)')
    content = content.replace('setTextViewText(R.id.widget_next_prayer, "نور")', 'setTextViewText(R.id.widget_next_prayer, appName)')

    with open(filepath, 'w') as f:
        f.write(content)

def process_xml(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace android:text="نور" with android:text="Aya"
    content = content.replace('android:text="نور"', 'android:text="Aya"')

    with open(filepath, 'w') as f:
        f.write(content)

kt_dir = 'android/app/src/main/kotlin/com/quran/aya'
for file in os.listdir(kt_dir):
    if file.endswith('WidgetProvider.kt'):
        process_kt(os.path.join(kt_dir, file))

xml_dir = 'android/app/src/main/res/layout'
for file in os.listdir(xml_dir):
    if file.endswith('widget.xml'):
        process_xml(os.path.join(xml_dir, file))
