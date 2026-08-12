part of 'surah_reader_screen.dart';

extension SurahReaderData on _SurahReaderScreenState {
  Future<void> _fetchDynamicReciters(
    String scriptType, {
    StateSetter? modalSetState,
  }) async {
    if (scriptType == 'hafs') {
      if (mounted)
        setState(() {
          _dynamicReciters = [];
        });
      if (modalSetState != null) modalSetState(() {});
      return;
    }

    // Map script type to mp3quran riwayah id
    int riwayahId = 1;
    switch (scriptType) {
      case 'warsh':
        riwayahId = 2;
        break;
      case 'qaloon':
        riwayahId = 5;
        break;
      case 'shuba':
        riwayahId = 15;
        break;
      case 'duri':
        riwayahId = 13;
        break;
      case 'susi':
        riwayahId = 7;
        break;
      case 'bazzi':
        riwayahId = 4;
        break;
      case 'qunbul':
        riwayahId = 6;
        break;
      case 'hisham':
        riwayahId = 19;
        break;
      case 'ibn-dhakwan':
        riwayahId = 16;
        break;
    }

    if (mounted) {
      setState(() => _isLoadingReciters = true);
      if (modalSetState != null) modalSetState(() {});
    }
    try {
      final filteredReciters = await RecitersCacheService.getRecitersForRiwayah(
        riwayahId,
      );

      if (mounted) {
        setState(() {
          _dynamicReciters = filteredReciters;
          _dynamicReciters.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
          _isLoadingReciters = false;

          // Set first dynamic reciter as default if none selected or if current is invalid
          final currentReciter =
              widget.storage.getString('default_reciter');
          if (!currentReciter.startsWith('mp3quran_server_') &&
              _dynamicReciters.isNotEmpty) {
            final moshaf = _dynamicReciters[0]['moshaf'] as List;
            if (moshaf.isNotEmpty) {
              final server = moshaf[0]['server'] as String;
              widget.storage.setString(
                'default_reciter',
                'mp3quran_server_$server',
              );
            }
          }
        });
        if (modalSetState != null) modalSetState(() {});
      }
    } catch (e) {
      if (mounted) {
        updateState(() => _isLoadingReciters = false);
        if (modalSetState != null) modalSetState(() {});
      }
    }
  }

  Future<void> _loadAllSurahs() async {
    try {
      final list = await ApiService.fetchSurahList();
      updateState(() {
        _allSurahs = list;
      });
    } catch (_) {}
  }

  Future<void> _ensureTafsirLoaded() async {
    if (_tafsirLoaded) return;
    final hasContent = _ayahList.any((a) => a.tafseer.isNotEmpty);
    if (hasContent) return;

    try {
      await ApiService.fetchTafsirForSurah(_currentSurah.number, _ayahList);
    } catch (_) {}
    _tafsirLoaded = true;
    updateState(() {});
  }

  Future<void> _loadAyahs() async {
    updateState(() {
      _isLoading = true;
      _tafsirLoaded = false;
    });
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
      updateState(() {
        _ayahList = list;
        _isLoading = false;
      });

      if (widget.initialAyahNumber != null && widget.initialAyahNumber! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(widget.initialAyahNumber!);
        });
      } else if (!widget.isInsidePager) {
        final lastAyahInSurah = widget.storage.getLastReadAyahForSurah(
          _currentSurah.number,
        );
        if (lastAyahInSurah != null && lastAyahInSurah > 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAyah(lastAyahInSurah);
          });
        }
      }
      // If user is already in tafsir mode, lazy-load it now
      if (_readingMode == 'tafseer') {
        unawaited(_ensureTafsirLoaded());
      }
    } catch (e) {
      if (mounted) {
        updateState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationService.t('failed_load_verses')}: $e'),
          ),
        );
      }
    }
  }
}
