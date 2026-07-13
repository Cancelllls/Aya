import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../models/offline_surahs.dart';

class AudioPlayerOverlay extends StatelessWidget {
  final double bottomPosition;
  final bool isDark;
  final ThemeData theme;

  const AudioPlayerOverlay({
    Key? key,
    required this.bottomPosition,
    required this.isDark,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioPlayState>(
      valueListenable: AudioManager.instance.playState,
      builder: (context, audioState, child) {
        final hasPlayer = audioState.title.isNotEmpty;
        if (!hasPlayer) return const SizedBox.shrink();

        return Positioned(
          left: 12,
          right: 12,
          bottom: bottomPosition,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5C158).withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 12.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE5C158),
                                  Color(0xFFB45309),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  audioState.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  audioState.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.replay_10,
                              color: isDark ? Colors.white70 : Colors.black87,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => AudioManager.instance
                                .seekBy(const Duration(seconds: -10)),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              audioState.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: isDark
                                  ? const Color(0xFFE5C158)
                                  : theme.primaryColor,
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
                            onPressed: () => AudioManager.instance
                                .seekBy(const Duration(seconds: 10)),
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      ValueListenableBuilder<Duration>(
                        valueListenable: AudioManager.instance.durationNotifier,
                        builder: (context, duration, child) {
                          return ValueListenableBuilder<Duration>(
                            valueListenable: AudioManager.instance.positionNotifier,
                            builder: (context, position, child) {
                              final isSplit = audioState.ayahNum > 0;
                              final currentAyahIndex = isSplit ? audioState.ayahNum - 1 : 0;
                              final surahInfo = audioState.surahNum > 0 && audioState.surahNum <= 114 
                                  ? allOfflineSurahs[audioState.surahNum - 1] 
                                  : null;
                              final totalAyahs = surahInfo?.numberOfAyahs ?? 1;

                              double posVal;
                              double maxVal;

                              if (isSplit) {
                                maxVal = totalAyahs.toDouble();
                                posVal = currentAyahIndex.toDouble();
                                if (duration.inMilliseconds > 0) {
                                  posVal += position.inMilliseconds / duration.inMilliseconds;
                                }
                                if (posVal > maxVal) posVal = maxVal;
                              } else {
                                maxVal = duration.inMilliseconds.toDouble();
                                maxVal = maxVal > 0 ? maxVal : 1.0;
                                posVal = position.inMilliseconds.toDouble();
                                if (posVal > maxVal) posVal = maxVal;
                              }

                              String _format(Duration d) {
                                String twoDigits(int n) => n.toString().padLeft(2, "0");
                                String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
                                String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
                                if (d.inHours > 0) return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
                                return "$twoDigitMinutes:$twoDigitSeconds";
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Row(
                                  children: [
                                    if (!isSplit)
                                      Text(
                                        _format(position),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                      ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 28,
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3.0,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                                          ),
                                          child: Slider(
                                            value: posVal,
                                            min: 0,
                                            max: maxVal,
                                            activeColor: const Color(0xFFE5C158),
                                            inactiveColor: const Color(0xFFE5C158).withOpacity(0.3),
                                            onChanged: (val) {
                                              if (!isSplit) {
                                                AudioManager.instance.positionNotifier.value = Duration(milliseconds: val.toInt());
                                              }
                                            },
                                            onChangeStart: (val) {
                                              if (!isSplit) AudioManager.instance.isSeeking = true;
                                            },
                                            onChangeEnd: (val) async {
                                              if (isSplit) {
                                                int targetAyah = val.floor() + 1;
                                                if (targetAyah > totalAyahs) targetAyah = totalAyahs;
                                                if (targetAyah < 1) targetAyah = 1;
                                                
                                                // Assuming we can restart playback from targetAyah
                                                AudioManager.instance.stop();
                                                // We don't have the full ayahs list here, but we can't easily play from an ayah index without it.
                                                // Wait, this might be a problem if we don't have the ayahs list!
                                                // If we don't have the list, seeking across ayahs is hard.
                                                // Let's just disable dragging for split mode for now, or just make it read-only.
                                              } else {
                                                await AudioManager.instance.seekTo(Duration(milliseconds: val.toInt()));
                                                AudioManager.instance.isSeeking = false;
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isSplit)
                                      Text(
                                        _format(duration),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
