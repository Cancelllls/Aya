import re

with open('lib/screens/prayer_tracker_screen.dart', 'r') as f:
    content = f.read()

old_code = """    _trackerData.clear();
    for (var item in yearlyList) {
      _trackerData[item['date'] as String] = item;
    }"""

new_code = """    _trackerData.clear();
    for (var item in yearlyList) {
      _trackerData[item['date'] as String] = Map<String, dynamic>.from(item);
    }"""

if old_code in content:
    content = content.replace(old_code, new_code)
    with open('lib/screens/prayer_tracker_screen.dart', 'w') as f:
        f.write(content)
else:
    print("Code not found")
