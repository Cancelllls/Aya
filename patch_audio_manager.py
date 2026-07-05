import re

with open('lib/services/audio_manager.dart', 'r') as f:
    content = f.read()

# Add ValueNotifiers
notifiers = """  final ValueNotifier<AudioPlayState> playState = ValueNotifier(
    AudioPlayState(),
  );
  
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
"""
content = content.replace("  final ValueNotifier<AudioPlayState> playState = ValueNotifier(\n    AudioPlayState(),\n  );", notifiers)

# Update duration
content = content.replace("p.onDurationChanged.listen((d) {\n      if (p == activePlayer) {\n        _currentDuration = d;\n      }", "p.onDurationChanged.listen((d) {\n      if (p == activePlayer) {\n        _currentDuration = d;\n        durationNotifier.value = d;\n      }")

# Update position
content = content.replace("p.onPositionChanged.listen((pos) {\n      if (p != activePlayer || _isTransitioning) return;", "p.onPositionChanged.listen((pos) {\n      if (p == activePlayer) positionNotifier.value = pos;\n      if (p != activePlayer || _isTransitioning) return;")

# Reset on stop
content = content.replace("playState.value = AudioPlayState();", "playState.value = AudioPlayState();\n    positionNotifier.value = Duration.zero;\n    durationNotifier.value = Duration.zero;")

# Reset on load
content = content.replace("await _playerB.setVolume(1.0);", "await _playerB.setVolume(1.0);\n      positionNotifier.value = Duration.zero;\n      durationNotifier.value = Duration.zero;")

# Add seekTo
seekTo = """  Future<void> seekTo(Duration position) async {
    await activePlayer.seek(position);
  }

  Future<void> seekBy(Duration offset) async {"""
content = content.replace("  Future<void> seekBy(Duration offset) async {", seekTo)

with open('lib/services/audio_manager.dart', 'w') as f:
    f.write(content)
