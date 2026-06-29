import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    content = f.read()

def replace_listtile(match):
    full_match = match.group(0)
    title = match.group(1)
    subtitle = match.group(2)
    dropdown = match.group(3)
    
    # We want to replace:
    # trailing: DropdownButton<String>(...)
    # with it inside the subtitle
    
    # We need to add isExpanded: true to DropdownButton to fill the container
    dropdown = dropdown.replace('DropdownButton<', 'DropdownButton<')
    
    if 'isExpanded:' not in dropdown:
        dropdown = dropdown.replace('value:', 'isExpanded: true,\n                                          value:')
        
    replacement = f"""                  title: {title},
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      {subtitle},
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: {dropdown},
                      ),
                    ],
                  ),"""
    return replacement

# Regex to match ListTile with title, subtitle, and trailing DropdownButton
# This regex relies on the specific formatting of the file
pattern = re.compile(r'                  title: (Text\([^)]+\)),\n                  subtitle: (Text\([^)]+\)),\n                  trailing: (DropdownButton<[^>]+>\([\s\S]*?,\n                  \)),')

new_content = pattern.sub(replace_listtile, content)

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(new_content)

print("Done replacing.")
