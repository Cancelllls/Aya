import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

# We need to wrap the Row inside a Column that also contains the Slider.
# First, let's find the Expanded(child: Column(...)) part and add the slider under the text.
slider_code = """
                                    const SizedBox(height: 4),
                                    ValueListenableBuilder<Duration>(
                                      valueListenable: AudioManager.instance.durationNotifier,
                                      builder: (context, duration, child) {
                                        return ValueListenableBuilder<Duration>(
                                          valueListenable: AudioManager.instance.positionNotifier,
                                          builder: (context, position, child) {
                                            final pos = position.inMilliseconds.toDouble();
                                            final dur = duration.inMilliseconds.toDouble();
                                            final maxVal = dur > 0 ? dur : 1.0;
                                            final safePos = pos > maxVal ? maxVal : pos;
                                            
                                            String _format(Duration d) {
                                              String twoDigits(int n) => n.toString().padLeft(2, "0");
                                              String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
                                              String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
                                              if (d.inHours > 0) return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
                                              return "$twoDigitMinutes:$twoDigitSeconds";
                                            }

                                            return Row(
                                              children: [
                                                Text(
                                                  _format(position),
                                                  style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                                ),
                                                Expanded(
                                                  child: SliderTheme(
                                                    data: SliderTheme.of(context).copyWith(
                                                      trackHeight: 2.0,
                                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                                                    ),
                                                    child: Slider(
                                                      value: safePos,
                                                      min: 0,
                                                      max: maxVal,
                                                      activeColor: const Color(0xFFE5C158),
                                                      inactiveColor: const Color(0xFFE5C158).withOpacity(0.3),
                                                      onChanged: (val) {
                                                        AudioManager.instance.positionNotifier.value = Duration(milliseconds: val.toInt());
                                                      },
                                                      onChangeEnd: (val) {
                                                        AudioManager.instance.seekTo(Duration(milliseconds: val.toInt()));
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _format(duration),
                                                  style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
"""

regex = r"(overflow: TextOverflow\.ellipsis,\s*\),\s*\])"
content = re.sub(regex, r"\1" + "\n" + slider_code, content)

with open('lib/main.dart', 'w') as f:
    f.write(content)
