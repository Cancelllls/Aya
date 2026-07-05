import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

# Replace padding
content = content.replace("vertical: 10.0,", "vertical: 6.0,\n                              horizontal: 12.0,")
content = content.replace("horizontal: 16.0,", "")

# Replace the row with buttons
buttons = """
                            IconButton(
                              icon: Icon(
                                Icons.replay_10,
                                color: isDark ? Colors.white70 : Colors.black87,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => AudioManager.instance.seekBy(const Duration(seconds: -10)),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                audioState.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: isDark ? const Color(0xFFE5C158) : theme.primaryColor,
                                size: 26,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  AudioManager.instance.togglePlayPause(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                Icons.forward_10,
                                color: isDark ? Colors.white70 : Colors.black87,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => AudioManager.instance.seekBy(const Duration(seconds: 10)),
                            ),
                            const SizedBox(width: 12),
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
"""

# Find where the old buttons are
old_buttons_regex = r"IconButton\(\s*icon:\s*Icon\(\s*audioState\.isPlaying[\s\S]*?onPressed:\s*\(\)\s*=>\s*AudioManager\.instance\.stop\(\),\s*\),"
content = re.sub(old_buttons_regex, buttons, content)

# Change Icon Box size to 36x36
content = content.replace("width: 40,\n                              height: 40,", "width: 36,\n                              height: 36,")
content = content.replace("size: 20,\n                              ),", "size: 18,\n                              ),")

with open('lib/main.dart', 'w') as f:
    f.write(content)
