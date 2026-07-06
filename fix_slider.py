import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

# We need to extract the ValueListenableBuilder<Duration> that contains the slider.
# It starts at: ValueListenableBuilder<Duration>(
# and ends when the brackets match.
start_idx = content.find('ValueListenableBuilder<Duration>(')
if start_idx == -1:
    print("Could not find start")
    exit(1)

# Find the end of the ValueListenableBuilder
bracket_count = 0
end_idx = start_idx
for i in range(start_idx, len(content)):
    if content[i] == '{':
        bracket_count += 1
    elif content[i] == '}':
        bracket_count -= 1
    elif content[i] == '(':
        bracket_count += 1
    elif content[i] == ')':
        bracket_count -= 1
        
    if bracket_count == 0 and i > start_idx + 35:
        # Wait, the end is actually '),'
        if content[i+1] == ',':
            end_idx = i + 2
        else:
            end_idx = i + 1
        break

slider_block = content[start_idx:end_idx]

# We also need to remove 'const SizedBox(height: 4),' right before it.
before_slider = content.find('const SizedBox(height: 4),\n', 0, start_idx)
if before_slider != -1 and (start_idx - before_slider) < 100:
    # Remove it
    content = content[:before_slider] + content[end_idx:]
else:
    content = content[:start_idx] + content[end_idx:]

# Now we find the end of the Row
row_end_str = '''
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => AudioManager.instance.stop(),
                            ),

                          ],
                        ),'''

row_end_idx = content.find(row_end_str)
if row_end_idx == -1:
    print("Could not find row end")
    exit(1)

insert_idx = row_end_idx + len(row_end_str)

# Change child: Row( to child: Column( ... Row(
row_start_str = '''                        child: Row(
                          children: ['''
col_start_str = '''                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: ['''

content = content.replace(row_start_str, col_start_str)

# Insert the slider after the Row
slider_inserted = '\n' + ' ' * 28 + 'const SizedBox(height: 8),\n' + \
                  ' ' * 28 + 'Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: ' + \
                  slider_block.replace('\n', '\n' + ' ' * 4) + '),\n' + \
                  ' ' * 26 + '],\n' + ' ' * 24 + '),'

content = content[:insert_idx] + slider_inserted + content[insert_idx+28:] 
# wait, I should just replace row_end_str with row_end_str + slider_inserted + closing brackets?
# Let's write the file.

with open('lib/main.dart', 'w') as f:
    f.write(content)

print("Done")
