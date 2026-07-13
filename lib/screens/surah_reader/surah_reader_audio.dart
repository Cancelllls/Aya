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

  void _playAudioWithDisclaimer({int? ayahIndex}) {
    final supportsAyahSync = _quranScriptType == 'hafs';
    final hideDisclaimer = widget.storage.getBool('hide_full_surah_disclaimer', defaultValue: false);
    
    if (supportsAyahSync || hideDisclaimer) {
      if (ayahIndex != null && supportsAyahSync) {
        AudioManager.instance.playAyah(
          _currentSurah.number,
          _currentSurah.englishName,
          _ayahList,
          ayahIndex,
        );
      } else {
        AudioManager.instance.playSurah(
          _currentSurah.number,
          _currentSurah.englishName,
          _ayahList,
        );
      }
      return;
    }
    
    bool dontShowAgain = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                TranslationService.isArabic ? 'تنبيه' : 'Notice',
                style: const TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.isArabic
                        ? 'هذه الرواية لا تدعم التزامن آية بآية وسيتم تشغيل السورة كاملة.'
                        : 'This Rewayah does not support Ayah-by-Ayah synchronization. The full Surah will be played.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) {
                          setModalState(() {
                            dontShowAgain = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFFE5C158),
                      ),
                      Expanded(
                        child: Text(
                          TranslationService.isArabic ? 'لا تظهر هذه الرسالة مرة أخرى' : 'Do not show this again',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    TranslationService.isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (dontShowAgain) {
                      widget.storage.setBool('hide_full_surah_disclaimer', true);
                    }
                    Navigator.pop(context);
                    if (ayahIndex != null && supportsAyahSync) {
                      AudioManager.instance.playAyah(
                        _currentSurah.number,
                        _currentSurah.englishName,
                        _ayahList,
                        ayahIndex,
                      );
                    } else {
                      AudioManager.instance.playSurah(
                        _currentSurah.number,
                        _currentSurah.englishName,
                        _ayahList,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
                  child: Text(
                    TranslationService.isArabic ? 'تشغيل' : 'Play',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
