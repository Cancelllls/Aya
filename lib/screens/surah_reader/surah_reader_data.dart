part of 'surah_reader_screen.dart';

extension SurahReaderData on _SurahReaderScreenState {

  Future<void> _fetchDynamicReciters(String scriptType, {StateSetter? modalSetState}

  Future<void> _loadAllSurahs() async {
      try {
        final list = await ApiService.fetchSurahList();
        setState(() {
          _allSurahs = list;
        });
      } catch (_) {}
    }

  Future<void> _loadAyahs() async {
      setState(() => _isLoading = true);
      try {
        final tafsirEdition = widget.storage.getString(
          'default_tafsir',
          defaultValue: 'ar.muyassar',
        );
        
        List<Ayah> list;
        if (_quranScriptType == 'hafs') {
          list = await ApiService.fetchSurahDetails(
            _currentSurah.number,
            tafsirEdition: tafsirEdition,
          );
        } else {
          list = await LocalQuranService.getSurahAyahs(
            _currentSurah.number,
            _quranScriptType,
          );
          final dbList = await ApiService.fetchSurahDetails(
            _currentSurah.number,
            tafsirEdition: tafsirEdition,
          );
          for (int i = 0; i < list.length; i++) {
            if (i < dbList.length) {
              list[i].translation = dbList[i].translation;
              list[i].tafseer = dbList[i].tafseer;
            }
          }
        }
        setState(() {
          _ayahList = list;
          _isLoading = false;
        });
  
        if (widget.initialAyahNumber != null && widget.initialAyahNumber! > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAyah(widget.initialAyahNumber!);
          });
        } else {
          final lastAyahInSurah = widget.storage.getLastReadAyahForSurah(_currentSurah.number);
          if (lastAyahInSurah != null && lastAyahInSurah > 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToAyah(lastAyahInSurah);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${TranslationService.t('failed_load_verses')}: $e'),
            ),
          );
        }
      }
    }
}
