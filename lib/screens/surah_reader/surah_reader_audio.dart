part of 'surah_reader_screen.dart';

extension SurahReaderAudio on _SurahReaderScreenState {

  void _onPlayStateChanged() {
      final playState = AudioManager.instance.playState.value;
      if (playState.isPlaying &&
          playState.surahNum == _currentSurah.number &&
          playState.ayahNum > 0 &&
          playState.ayahNum != _lastScrolledAyah) {
        _lastScrolledAyah = playState.ayahNum;
        _scrollToAyah(playState.ayahNum);
      }
    }

  void _playAudioWithDisclaimer({int? ayahIndex}
}
