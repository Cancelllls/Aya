part of 'surah_reader_screen.dart';

extension SurahReaderAutoscroll on _SurahReaderScreenState {
  void _startAutoScroll({double? customSpeed}) {
    _resumeTimer?.cancel();
    _resumeTimer = null;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;

    if (customSpeed != null) {
      _scrollSpeed = customSpeed;
    } else {
      double step = 20.0; // pixels per second
      switch (_speedLevel) {
        case 1:
          step = 12.0;
          break;
        case 2:
          step = 25.0;
          break;
        case 3:
          step = 45.0;
          break;
        case 4:
          step = 75.0;
          break;
        case 5:
          step = 120.0;
          break;
      }
      _scrollSpeed = step;
    }

    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final remaining = maxScroll - currentScroll;
    if (remaining <= 0) {
      _stopAutoScroll();
      return;
    }

    _updateReaderState(() {
      _isAutoScrolling = true;
      _isAutoScrollPaused = false;
    });

    final durationMs = (remaining / _scrollSpeed * 1000).toInt();
    _scrollController
        .animateTo(
          maxScroll,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        )
        .catchError((_) {})
        .then((_) {
          if (mounted &&
              _isAutoScrolling &&
              !_isAutoScrollPaused &&
              _scrollController.hasClients &&
              _scrollController.position.pixels >= maxScroll - 1) {
            _stopAutoScroll();
          }
        });
  }

  void _pauseAutoScroll() {
    _resumeTimer?.cancel();
    _resumeTimer = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
    _updateReaderState(() {
      _isAutoScrollPaused = true;
    });
  }

  void _resumeAutoScroll() {
    _resumeTimer?.cancel();
    _resumeTimer = null;
    _startAutoScroll();
  }

  void _toggleAutoScroll() {
    if (!_isAutoScrolling) {
      _startAutoScroll();
    } else if (_isAutoScrollPaused) {
      _resumeAutoScroll();
    } else {
      _pauseAutoScroll();
    }
  }

  void _syncAutoScrollWithAudio() async {
    if (_isAutoScrolling) {
      _stopAutoScroll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? 'تم إيقاف المزامنة والتمرير التلقائي'
                : 'Auto-scroll & Sync disabled',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final player = AudioManager.instance.activePlayer;
    final duration = await player.getDuration();
    final position = await player.getCurrentPosition();

    if (duration != null && position != null && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Calculate target scroll position based on audio progress
      double progress = position.inMilliseconds / duration.inMilliseconds;
      if (progress < 0) progress = 0;
      if (progress > 1) progress = 1;

      final targetScrollPixels = maxScroll * progress;

      // Pull user to correct position
      _scrollController.jumpTo(targetScrollPixels);

      final remainingDistance = maxScroll - targetScrollPixels;
      final remainingAudioMs =
          duration.inMilliseconds - position.inMilliseconds;

      if (remainingAudioMs > 0 && remainingDistance > 0) {
        final speed = remainingDistance / (remainingAudioMs / 1000.0);
        _startAutoScroll(customSpeed: speed);
      }
    }
  }

  void _stopAutoScroll() {
    _resumeTimer?.cancel();
    _resumeTimer = null;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
    _updateReaderState(() {
      _isAutoScrolling = false;
      _isAutoScrollPaused = false;
    });
  }

  void _pauseAutoScrollTemporarily() {
    if (!_isAutoScrolling || _isAutoScrollPaused) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
    _updateReaderState(() {
      _isAutoScrollPaused = true;
    });
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isAutoScrolling && _isAutoScrollPaused) {
        _resumeAutoScroll();
      }
    });
  }

  void _changeSpeedLevel(int delta) {
    _updateReaderState(() {
      _speedLevel = (_speedLevel + delta).clamp(1, 5);
    });
    if (_isAutoScrolling && !_isAutoScrollPaused) {
      _startAutoScroll();
    }
  }

  Widget _buildAutoScrollFloatingControls(
    bool isDark,
    AudioPlayState playState,
  ) {
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    final String bottomNavbarStyle = widget.storage.getString(
      'bottom_navbar_style',
      defaultValue: 'floating',
    );
    // Match floating pill bottom padding from main.dart exactly
    final double bottomOffset = bottomNavbarStyle == 'floating'
        ? 16.0 + safeBottom
        : safeBottom + 8.0;

    final quranScriptType = widget.storage.getString(
      'quran_script_type',
      defaultValue: 'hafs',
    );
    final reciter = widget.storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    final isFullSurahAudio =
        quranScriptType != 'hafs' || reciter.startsWith('mp3quran_server_');
    final isAudioActiveForThisSurah =
        playState.surahNum == _currentSurah.number;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: bottomOffset,
      left: 16,
      right: 16,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // ignore: deprecated_member_use
            color: const Color(0xFFE5C158).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  double remainingSeconds = 0;
                  if (_scrollController.hasClients && _isAutoScrolling) {
                    final maxScroll =
                        _scrollController.position.maxScrollExtent;
                    final currentScroll = _scrollController.position.pixels;
                    final remainingDistance = maxScroll - currentScroll;
                    if (remainingDistance > 0 && _scrollSpeed > 0) {
                      remainingSeconds = remainingDistance / _scrollSpeed;
                    }
                  }
                  final int min = remainingSeconds ~/ 60;
                  final int sec = (remainingSeconds % 60).toInt();
                  final timeText = TranslationService.isArabic
                      ? "باقي $min د $sec ث"
                      : "$min m $sec s left";

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: _isAutoScrolling ? _stopAutoScroll : null,
                        child: Icon(
                          _isAutoScrolling
                              ? Icons.stop_circle_outlined
                              : Icons.swap_vertical_circle_outlined,
                          color: const Color(0xFFE5C158),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _isAutoScrolling
                              ? timeText
                              : TranslationService.t('auto_scroll'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (_isAutoScrollPaused) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            TranslationService.isArabic ? 'موقوف' : 'Paused',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFFE5C158),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            if (isFullSurahAudio && isAudioActiveForThisSurah) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _syncAutoScrollWithAudio,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5C158).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync,
                        size: 14,
                        color: Color(0xFFE5C158),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TranslationService.isArabic ? "مزامنة" : "Sync",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5C158),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            // Custom compact speed pill control
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: isDark
                    ? (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white)
                          .withValues(alpha: 0.06)
                    : Theme.of(context).shadowColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _changeSpeedLevel(-1),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.remove,
                        size: 14,
                        color: Color(0xFFE5C158),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "x$_speedLevel",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C158),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _changeSpeedLevel(1),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: Color(0xFFE5C158),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Custom compact circular play/pause button
            GestureDetector(
              onTap: _toggleAutoScroll,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5C158),
                ),
                child: Icon(
                  _isAutoScrolling && !_isAutoScrollPaused
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
