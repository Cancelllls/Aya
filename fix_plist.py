import re

with open('ios/Runner/Info.plist', 'r') as f:
    text = f.read()

# Check if it already has NSLocationWhenInUseUsageDescription
if '<key>NSLocationWhenInUseUsageDescription</key>' not in text:
    # Insert it before the last </dict>
    insert_str = """	<key>NSLocationWhenInUseUsageDescription</key>
	<string>This app requires access to your location to calculate accurate prayer times.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>This app requires access to your location to calculate accurate prayer times.</string>
"""
    # Find the last </dict>
    last_dict_idx = text.rfind('</dict>')
    if last_dict_idx != -1:
        text = text[:last_dict_idx] + insert_str + text[last_dict_idx:]
        with open('ios/Runner/Info.plist', 'w') as f:
            f.write(text)
        print("Added Location permissions to Info.plist")
    else:
        print("Failed to find </dict>")
else:
    print("Permissions already exist")
