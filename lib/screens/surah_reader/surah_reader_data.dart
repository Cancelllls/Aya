part of 'surah_reader_screen.dart';

extension SurahReaderData on _SurahReaderScreenState {

  Future<void> _fetchDynamicReciters(String scriptType, {StateSetter? modalSetState} ) async {
    if (scriptType == 'hafs') {
      if (mounted) setState(() { _dynamicReciters = []; });
      if (modalSetState != null) modalSetState(() {});
      return;
    }
    
    // Map script type to mp3quran riwayah id
    int riwayahId = 1;
    switch (scriptType) {
      case 'warsh': riwayahId = 2; break;
      case 'qaloon': riwayahId = 5; break;
      case 'shuba': riwayahId = 15; break;
      case 'duri': riwayahId = 13; break;
      case 'susi': riwayahId = 7; break;
      case 'bazzi': riwayahId = 4; break;
      case 'qunbul': riwayahId = 6; break;
      case 'hisham': riwayahId = 19; break;
      case 'ibn-dhakwan': riwayahId = 16; break;
    }

    if (mounted) {
      setState(() => _isLoadingReciters = true);
      if (modalSetState != null) modalSetState(() {});
    }
    try {
      final isAr = TranslationService.isArabic;
      final data = isAr ? recitersDataAr : recitersDataEn;
      final allReciters = data['reciters'] as List;
      
      final filteredReciters = allReciters.map((r) {
        // Deep copy the reciter to avoid mutating the constant
        final newR = Map<String, dynamic>.from(r);
        final moshafs = (newR['moshaf'] as List).cast<Map<String, dynamic>>();
        newR['moshaf'] = moshafs.where((m) => m['rewaya_id'] == riwayahId).toList();
        return newR;
      }).where((r) => (r['moshaf'] as List).isNotEmpty).toList();

      if (mounted) {
        setState(() {
          _dynamicReciters = filteredReciters;
          _dynamicReciters.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
          _isLoadingReciters = false;
          
          // Set first dynamic reciter as default if none selected or if current is invalid
          final currentReciter = widget.storage.getString('default_reciter') ?? '';
          if (!currentReciter.startsWith('mp3quran_server_') && _dynamicReciters.isNotEmpty) {
            final moshaf = _dynamicReciters[0]['moshaf'] as List;
            if (moshaf.isNotEmpty) {
              final server = moshaf[0]['server'] as String;
              widget.storage.setString('default_reciter', 'mp3quran_server_$server');
            }
          }
        });
        if (modalSetState != null) modalSetState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReciters = false);
        if (modalSetState != null) modalSetState(() {});
      }
    }
  }


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
        } else if (!widget.isInsidePager) {
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
