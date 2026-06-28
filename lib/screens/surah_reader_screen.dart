import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quran_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/audio_manager.dart';

class SurahReaderScreen extends StatefulWidget {
  final Surah surah;
  final StorageService storage;
  final int? initialAyahNumber;

  const SurahReaderScreen({
    super.key,
    required this.surah,
    required this.storage,
    this.initialAyahNumber,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> with SingleTickerProviderStateMixin {
  late Surah _currentSurah;
  List<Surah> _allSurahs = [];
  bool _swipeSurahNavigation = true;

  List<Ayah> _ayahList = [];
  bool _isLoading = true;
  double _fontSizeMultiplier = 1.0;
  String _readingMode = 'translation'; // 'translation', 'arabic_only', 'tafseer', 'continuous'
  bool _isBookmarked = false;
  int? _bookmarkedAyahNumber;
  int? _lastScrolledAyah;

  Ticker? _ticker;
  double _scrollSpeed = 1.0;
  int _speedLevel = 2;
  bool _isAutoScrolling = false;
  Timer? _resumeTimer;
  bool _isAutoScrollPaused = false;
  bool _hideContinuousBorders = false;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  final Map<int, GlobalKey> _pageKeys = {};
  final Map<int, List<TapGestureRecognizer>> _pageRecognizers = {};

  @override
  void initState() {
    super.initState();
    final bool immersive = widget.storage.getBool('setting_immersive_reader', defaultValue: false);
    if (immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    _currentSurah = widget.surah;
    _readingMode = widget.storage.getString('reading_mode', defaultValue: 'continuous');
    _hideContinuousBorders = widget.storage.getBool('setting_hide_continuous_borders', defaultValue: false);
    _swipeSurahNavigation = widget.storage.getBool('swipe_surah_navigation', defaultValue: true);
    _loadAyahs();
    _checkBookmarkStatus();
    _loadAllSurahs();
    AudioManager.instance.playState.addListener(_onPlayStateChanged);
  }

  Future<void> _loadAllSurahs() async {
    try {
      final list = await ApiService.fetchSurahList();
      setState(() {
        _allSurahs = list;
      });
    } catch (_) {}
  }

  void _navigateToSurah(Surah newSurah) {
    setState(() {
      _currentSurah = newSurah;
      _isLoading = true;
      _ayahList = [];
      _ayahKeys.clear();
      _pageKeys.clear();
      _pageRecognizers.clear();
    });
    _loadAyahs();
    _checkBookmarkStatus();
  }

  void _goToNextSurah() {
    if (_allSurahs.isEmpty) return;
    final currentIdx = _allSurahs.indexWhere((s) => s.number == _currentSurah.number);
    if (currentIdx != -1 && currentIdx < _allSurahs.length - 1) {
      _navigateToSurah(_allSurahs[currentIdx + 1]);
    }
  }

  void _goToPrevSurah() {
    if (_allSurahs.isEmpty) return;
    final currentIdx = _allSurahs.indexWhere((s) => s.number == _currentSurah.number);
    if (currentIdx != -1 && currentIdx > 0) {
      _navigateToSurah(_allSurahs[currentIdx - 1]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    AudioManager.instance.playState.removeListener(_onPlayStateChanged);
    _ticker?.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    for (var recs in _pageRecognizers.values) {
      for (var r in recs) {
        r.dispose();
      }
    }
    _pageRecognizers.clear();
    super.dispose();
  }

  void _showTafseerDialog(Ayah ayah) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_currentSurah.name} - ${TranslationService.isArabic ? 'آية' : 'Ayah'} ${ayah.numberInSurah}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                TranslationService.isArabic ? 'التفسير:' : 'Tafseer:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5C158),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    ayah.tafseer.isNotEmpty 
                        ? ayah.tafseer 
                        : (TranslationService.isArabic 
                            ? 'التفسير غير متوفر حالياً لهذه الآية.' 
                            : 'Tafseer is not available for this verse.'),
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      height: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  void _checkBookmarkStatus() async {
    final bookmarks = await widget.storage.getBookmarks();
    final b = bookmarks.firstWhere(
      (element) => element['surahNumber'] == _currentSurah.number,
      orElse: () => {},
    );
    if (mounted) {
      setState(() {
        _isBookmarked = b.isNotEmpty;
        _bookmarkedAyahNumber = b.isNotEmpty ? b['ayahNumber'] as int? : null;
      });
    }
  }

  Future<void> _loadAyahs() async {
    setState(() => _isLoading = true);
    try {
      final tafsirEdition = widget.storage.getString('default_tafsir', defaultValue: 'ar.muyassar');
      final list = await ApiService.fetchSurahDetails(_currentSurah.number, tafsirEdition: tafsirEdition);
      setState(() {
        _ayahList = list;
        _isLoading = false;
      });

      if (widget.initialAyahNumber != null && widget.initialAyahNumber! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(widget.initialAyahNumber!);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${TranslationService.t('failed_load_verses')}: $e')),
        );
      }
    }
  }

  void _bookmarkAyah(int ayahNum) async {
    if (_isBookmarked && _bookmarkedAyahNumber == ayahNum) {
      await widget.storage.removeBookmark(_currentSurah.number, ayahNumber: ayahNum);
      if (!mounted) return;
      setState(() {
        _isBookmarked = false;
        _bookmarkedAyahNumber = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationService.isArabic ? 'تم إزالة العلامة من الآية' : 'Removed Bookmark from Ayah'} $ayahNum'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    await widget.storage.addBookmark(_currentSurah.number, _currentSurah.englishName, ayahNum);
    if (!mounted) return;
    setState(() {
      _isBookmarked = true;
      _bookmarkedAyahNumber = ayahNum;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${TranslationService.isArabic ? 'تم حفظ علامة الآية' : 'Bookmarked Ayah'} $ayahNum'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleBookmark() async {
    if (_isBookmarked) {
      await widget.storage.removeBookmark(_currentSurah.number);
      if (!mounted) return;
      setState(() {
        _isBookmarked = false;
        _bookmarkedAyahNumber = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.t('bookmark_removed')), duration: const Duration(seconds: 1)),
      );
    } else {
      final targetAyah = _bookmarkedAyahNumber ?? 1;
      await widget.storage.addBookmark(_currentSurah.number, _currentSurah.englishName, targetAyah);
      if (!mounted) return;
      setState(() {
        _isBookmarked = true;
        _bookmarkedAyahNumber = targetAyah;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.t('bookmark_saved')), duration: const Duration(seconds: 1)),
      );
    }
  }

  void _scrollToAyah(int ayahNum) {
    if (!mounted) return;
    
    void performSearch(int attempt, double currentGuess) {
      if (!mounted || !_scrollController.hasClients) return;
      
      final key = _readingMode == 'continuous' 
          ? _pageKeys[(ayahNum - 1) ~/ 5]
          : _ayahKeys[ayahNum];
          
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration.zero,
          alignment: 0.0,
        );
      } else if (attempt < 20) {
        int maxRendered = -1;
        int minRendered = 99999;
        
        final keysToCheck = _readingMode == 'continuous' ? _pageKeys : _ayahKeys;
        for (final k in keysToCheck.keys) {
          if (keysToCheck[k]?.currentContext != null) {
            if (k > maxRendered) maxRendered = k;
            if (k < minRendered) minRendered = k;
          }
        }
        
        final targetIndex = _readingMode == 'continuous' ? ((ayahNum - 1) ~/ 5) : ayahNum;
        
        if (maxRendered != -1 && targetIndex > maxRendered) {
          currentGuess += 800;
          if (currentGuess > _scrollController.position.maxScrollExtent) {
            currentGuess = _scrollController.position.maxScrollExtent;
          }
          _scrollController.jumpTo(currentGuess);
        } else if (minRendered != 99999 && targetIndex < minRendered) {
          currentGuess -= 800;
          if (currentGuess < 0) currentGuess = 0;
          _scrollController.jumpTo(currentGuess);
        } else {
          currentGuess += 500;
          _scrollController.jumpTo(currentGuess);
        }
        
        Future.delayed(const Duration(milliseconds: 50), () => performSearch(attempt + 1, currentGuess));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      
      double initialGuess = 0;
      if (_readingMode == 'continuous') {
        initialGuess = ((ayahNum - 1) ~/ 5) * 400.0 * _fontSizeMultiplier;
      } else {
        initialGuess = (ayahNum - 1) * (_readingMode == 'translation' ? 400.0 : 200.0) * _fontSizeMultiplier;
      }
      
      _scrollController.jumpTo(initialGuess);
      Future.delayed(const Duration(milliseconds: 50), () => performSearch(0, initialGuess));
    });
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSizeMultiplier = (_fontSizeMultiplier + delta).clamp(0.8, 1.8);
    });
  }

  void _showAyahActionSheet(Ayah ayah) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TranslationService.isArabic
                    ? "${_currentSurah.name} : الآية ${ayah.numberInSurah}"
                    : "${_currentSurah.englishName} : Verse ${ayah.numberInSurah}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.play_circle_outline, color: Color(0xFFE5C158)),
                title: Text(TranslationService.t('play_recitation')),
                onTap: () {
                  Navigator.pop(context);
                  final idx = _ayahList.indexOf(ayah);
                  AudioManager.instance.playAyah(_currentSurah.number, _currentSurah.englishName, _ayahList, idx);
                },
              ),
              ListTile(
                leading: Icon(_isBookmarked && _bookmarkedAyahNumber == ayah.numberInSurah ? Icons.bookmark : Icons.bookmark_outline, color: const Color(0xFFE5C158)),
                title: Text(_isBookmarked && _bookmarkedAyahNumber == ayah.numberInSurah 
                   ? (TranslationService.isArabic ? "إزالة العلامة" : "Remove Bookmark") 
                   : TranslationService.t('bookmark_verse')),
                onTap: () {
                  Navigator.pop(context);
                  _bookmarkAyah(ayah.numberInSurah);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFFE5C158)),
                title: Text(TranslationService.t('copy_verse')),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: ayah.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(TranslationService.t('verse_copied')), duration: const Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getHizbRangeText() {
    if (_ayahList.isEmpty) {
      return "${TranslationService.t('juz')} ${_currentSurah.startingJuz} • ${TranslationService.t('hizb')} ${_currentSurah.startingHizb}";
    }
    final uniqueJuz = _ayahList.map((e) => e.juz).toSet().toList()..sort();
    final uniqueHizb = _ayahList.map((e) => e.hizb).toSet().toList()..sort();

    final String juzText;
    if (uniqueJuz.length == 1) {
      juzText = "${TranslationService.t('juz')} ${uniqueJuz.first}";
    } else {
      juzText = "${TranslationService.t('juz')} ${uniqueJuz.first}-${uniqueJuz.last}";
    }

    final String hizbText;
    if (uniqueHizb.length == 1) {
      hizbText = "${TranslationService.t('hizb')} ${uniqueHizb.first}";
    } else {
      hizbText = "${TranslationService.t('hizb')} ${uniqueHizb.first}-${uniqueHizb.last}";
    }

    return "$juzText • $hizbText";
  }

  Widget _buildHizbDivider(int hizb) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          // ignore: deprecated_member_use
Expanded(child: Divider(color: const Color(0xFFE5C158).withOpacity(0.3), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
color: const Color(0xFFE5C158).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                // ignore: deprecated_member_use
border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.4), width: 1),
              ),
              child: Text(
                "${TranslationService.t('hizb')} $hizb",
                style: const TextStyle(
                  color: Color(0xFFE5C158),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // ignore: deprecated_member_use
Expanded(child: Divider(color: const Color(0xFFE5C158).withOpacity(0.3), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildSurahHeaderBanner(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF142B28), const Color(0xFF0C1D1B)] 
              : [const Color(0xFFFDFBF7), const Color(0xFFF5EFE0)],
        ),
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            _currentSurah.name,
            style: GoogleFonts.amiri(
              color: const Color(0xFFE5C158),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentSurah.englishName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          Text(
            "${_currentSurah.englishNameTranslation} • ${_currentSurah.numberOfAyahs} ${TranslationService.t('verses')}",
            style: TextStyle(
              fontSize: 11,
              // ignore: deprecated_member_use
color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.storage.isDarkMode();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSurah.englishName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "${_currentSurah.name} • ${_getHizbRangeText()}",
              style: TextStyle(fontSize: 11, color: theme.appBarTheme.foregroundColor?.withOpacity(0.7)),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF0F766E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFE5C158)),
            onPressed: _toggleBookmark,
            tooltip: 'Bookmark Surah',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.chrome_reader_mode, color: Colors.white),
            tooltip: TranslationService.isArabic ? "تغيير نمط العرض" : "Change View Mode",
            color: theme.cardColor,
            onSelected: (mode) {
              setState(() {
                _readingMode = mode;
                widget.storage.setString('reading_mode', mode);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'continuous',
                child: Row(
                  children: [
                    Icon(Icons.menu_book, color: _readingMode == 'continuous' ? const Color(0xFFE5C158) : Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic ? "المصحف المتصل" : "Continuous",
                      style: TextStyle(
                        color: _readingMode == 'continuous' ? const Color(0xFFE5C158) : null,
                        fontWeight: _readingMode == 'continuous' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'arabic_only',
                child: Row(
                  children: [
                    Icon(Icons.text_format, color: _readingMode == 'arabic_only' ? const Color(0xFFE5C158) : Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic ? "العربية فقط" : "Arabic Only",
                      style: TextStyle(
                        color: _readingMode == 'arabic_only' ? const Color(0xFFE5C158) : null,
                        fontWeight: _readingMode == 'arabic_only' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'translation',
                child: Row(
                  children: [
                    Icon(Icons.translate, color: _readingMode == 'translation' ? const Color(0xFFE5C158) : Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic ? "الترجمة" : "Translation",
                      style: TextStyle(
                        color: _readingMode == 'translation' ? const Color(0xFFE5C158) : null,
                        fontWeight: _readingMode == 'translation' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tafseer',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _readingMode == 'tafseer' ? const Color(0xFFE5C158) : Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.isArabic ? "التفسير" : "Tafsir",
                      style: TextStyle(
                        color: _readingMode == 'tafseer' ? const Color(0xFFE5C158) : null,
                        fontWeight: _readingMode == 'tafseer' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => StatefulBuilder(
                  builder: (context, setModalState) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TranslationService.t('reading_settings'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          // Reading mode selection now via TabBar.
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TranslationService.t('arabic_font_size'),
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE5C158)),
                                    onPressed: () {
                                      _changeFontSize(-0.1);
                                      setModalState(() {});
                                    },
                                  ),
                                  Text(
                                    "${(_fontSizeMultiplier * 100).toInt()}%",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE5C158)),
                                    onPressed: () {
                                      _changeFontSize(0.1);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (!_swipeSurahNavigation) return;
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 150) {
            _goToNextSurah();
          } else if (details.primaryVelocity! < -150) {
            _goToPrevSurah();
          }
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE5C158)),
              )
            : Column(
                children: [
                  Expanded(
            child: ValueListenableBuilder<AudioPlayState>(
              valueListenable: AudioManager.instance.playState,
              builder: (context, playState, child) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        if (_readingMode != 'continuous')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFECEFF1),
                            child: Row(
                              children: [
                                const Icon(Icons.volume_up,
                                    color: Color(0xFFE5C158)),
                                const SizedBox(width: 12),
                                Text(
                                  TranslationService.t('listen_full_surah'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE5C158),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  icon: (playState.isLoading && playState.surahNum == _currentSurah.number && playState.ayahNum == 0)
                                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : (playState.isPlaying && playState.surahNum == _currentSurah.number)
                                          ? const Icon(Icons.pause, size: 16)
                                          : const Icon(Icons.play_arrow, size: 16),
                                  label: Text((playState.isLoading && playState.surahNum == _currentSurah.number && playState.ayahNum == 0)
                                      ? (TranslationService.isArabic ? 'تحميل...' : 'Loading...')
                                      : (playState.isPlaying && playState.surahNum == _currentSurah.number)
                                          ? (TranslationService.isArabic ? 'إيقاف' : 'Pause')
                                          : TranslationService.t('play')),
                                  onPressed: () {
                                    if (playState.isPlaying && playState.surahNum == _currentSurah.number) {
                                      AudioManager.instance.togglePlayPause();
                                    } else {
                                      AudioManager.instance.playSurah(_currentSurah.number, _currentSurah.englishName, _ayahList);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            TranslationService.isArabic
                                                ? 'جاري تشغيل سورة ${_currentSurah.name}...'
                                                : 'Streaming Surah ${_currentSurah.englishName}...',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                )
                              ],
                            ),
                          ),
                        Expanded(
                          child: _readingMode == 'continuous'
                              ? _buildContinuousLayout(playState)
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                      top: 8,
                                      bottom: 16.0 + MediaQuery.of(context).padding.bottom + 58.0 + 16.0),
                                  itemCount: _ayahList.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      if (_currentSurah.number == 9 ||
                                          _currentSurah.number == 1) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 24),
                                        child: Text(
                                          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                          style: GoogleFonts.amiri(
                                            fontSize: 30,
                                            color: const Color(0xFFE5C158),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    final ayah = _ayahList[index - 1];
                                    final showHizbHeader = index == 1 ||
                                        (index > 1 &&
                                            ayah.hizb !=
                                                _ayahList[index - 2].hizb);
                                    return Column(
                                      children: [
                                        if (showHizbHeader)
                                          _buildHizbDivider(ayah.hizb),
                                        _buildAyahCard(
                                            ayah, theme, playState),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    if (_readingMode == 'continuous')
                      _buildAutoScrollFloatingControls(isDark),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAyahCard(Ayah ayah, ThemeData theme, AudioPlayState playState) {
    final isDark = theme.brightness == Brightness.dark;
    final key = _ayahKeys.putIfAbsent(ayah.numberInSurah, () => GlobalKey());
    final isBookmarked = _bookmarkedAyahNumber == ayah.numberInSurah;
    final isPlaying = playState.isPlaying && playState.surahNum == _currentSurah.number && playState.ayahNum == ayah.numberInSurah;
    final isHighlighted = isBookmarked || isPlaying;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying 
            // ignore: deprecated_member_use
? const Color(0xFFE5C158).withOpacity(0.06) 
            : (isDark ? const Color(0xFF111716) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted 
              ? const Color(0xFFE5C158) 
              // ignore: deprecated_member_use
: const Color(0xFFE5C158).withOpacity(0.12),
          width: isHighlighted ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted 
                // ignore: deprecated_member_use
? const Color(0xFFE5C158).withOpacity(0.08) 
                // ignore: deprecated_member_use
: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 8,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: isHighlighted ? const Color(0xFFE5C158) : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBookmarked 
                          // ignore: deprecated_member_use
                          ? const Color(0xFFE5C158).withOpacity(0.15) 
                          : theme.dividerColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${_currentSurah.number}:${ayah.numberInSurah}",
                      style: TextStyle(
                        color: const Color(0xFFE5C158),
                        fontSize: 11,
                        fontWeight: isBookmarked ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFFE5C158)),
                        onPressed: () {
                          _showTafseerDialog(ayah);
                        },
                        tooltip: 'Read Tafseer',
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                          size: 20, 
                          color: const Color(0xFFE5C158)
                        ),
                        onPressed: () {
                          _bookmarkAyah(ayah.numberInSurah);
                        },
                        tooltip: 'Bookmark this Verse',
                      ),
                      IconButton(
                        icon: (playState.isLoading && playState.surahNum == _currentSurah.number && playState.ayahNum == ayah.numberInSurah)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5C158)),
                              )
                            : const Icon(Icons.play_circle_outline, size: 20, color: Color(0xFFE5C158)),
                        onPressed: () {
                          final idx = _ayahList.indexOf(ayah);
                          AudioManager.instance.playAyah(_currentSurah.number, _currentSurah.englishName, _ayahList, idx);
                        },
                        tooltip: 'Play Verse Audio',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ayah.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.amiri(
                    fontSize: 22 * _fontSizeMultiplier,
                    height: 2.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_readingMode == 'translation') ...[
                const SizedBox(height: 12),
                Divider(color: theme.dividerColor, height: 1),
                const SizedBox(height: 8),
                Text(
                  ayah.translation,
                  style: GoogleFonts.inter(
                    fontSize: 14 * _fontSizeMultiplier,
                    // ignore: deprecated_member_use
color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ] else if (_readingMode == 'tafseer') ...[
                const SizedBox(height: 12),
                Divider(color: theme.dividerColor, height: 1),
                const SizedBox(height: 8),
                Text(
                  ayah.tafseer.isNotEmpty ? ayah.tafseer : (TranslationService.isArabic ? 'التفسير غير متوفر حالياً لهذه الآية.' : 'Tafseer is not available for this verse.'),
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 16 * _fontSizeMultiplier,
                    height: 1.8,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinuousLayout(AudioPlayState playState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const int chunkSize = 5;
    final int pageCount = (_ayahList.length / chunkSize).ceil();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification && notification.dragDetails != null) {
          _pauseAutoScrollTemporarily();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
            top: 16,
            bottom: 16.0 + MediaQuery.of(context).padding.bottom + 58.0 + 16.0),
        itemCount: pageCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildSurahHeaderBanner(theme, isDark),
              if (_currentSurah.number != 9 && _currentSurah.number != 1)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                    style: GoogleFonts.amiri(
                      fontSize: 30,
                      color: const Color(0xFFE5C158),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        }

        final int pageIndex = index - 1;
        final int startIdx = pageIndex * chunkSize;
        final int endIdx = (startIdx + chunkSize).clamp(0, _ayahList.length);
        final List<Ayah> chunk = _ayahList.sublist(startIdx, endIdx);

        final key = _pageKeys.putIfAbsent(pageIndex, () => GlobalKey());

        final oldRecs = _pageRecognizers[pageIndex];
        if (oldRecs != null) {
          for (var r in oldRecs) {
            r.dispose();
          }
          oldRecs.clear();
        }
        final List<TapGestureRecognizer> pageRecs = [];
        _pageRecognizers[pageIndex] = pageRecs;

        final List<InlineSpan> spans = [];
        for (var ayah in chunk) {
          final isBookmarked = _bookmarkedAyahNumber == ayah.numberInSurah;
          final isPlaying = playState.isPlaying && playState.surahNum == _currentSurah.number && playState.ayahNum == ayah.numberInSurah;
          final isHighlighted = isBookmarked || isPlaying;

          final recognizer = TapGestureRecognizer()..onTap = () => _showAyahActionSheet(ayah);
          pageRecs.add(recognizer);

          spans.add(
            TextSpan(
              text: "${ayah.text} ",
              recognizer: recognizer,
              style: GoogleFonts.amiri(
                fontSize: 22 * _fontSizeMultiplier,
                height: 2.1,
                color: isHighlighted 
                    ? const Color(0xFFE5C158) 
                    : theme.textTheme.bodyLarge?.color,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                backgroundColor: isPlaying
                    // ignore: deprecated_member_use
? const Color(0xFFE5C158).withOpacity(0.18)
                    : isBookmarked 
                        // ignore: deprecated_member_use
? const Color(0xFFE5C158).withOpacity(0.1) 
                        : null,
              ),
            ),
          );

          spans.add(
            TextSpan(
              text: " ﴿${ayah.numberInSurah}﴾ ",
              style: GoogleFonts.amiri(
                fontSize: 20,
                color: const Color(0xFFE5C158),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final int firstHizb = chunk.isNotEmpty ? chunk.first.hizb : 0;
        final bool showHizbHeader = pageIndex == 0 || (pageIndex > 0 && firstHizb != _ayahList[(pageIndex * chunkSize) - 1].hizb);

        return Column(
          children: [
            if (showHizbHeader && firstHizb > 0)
              _buildHizbDivider(firstHizb),
            Container(
              key: key,
              margin: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: _hideContinuousBorders ? 2 : 8,
              ),
              decoration: _hideContinuousBorders
                  ? BoxDecoration(
                      color: isDark ? const Color(0xFF0F1E1B) : const Color(0xFFFDFBF7),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : BoxDecoration(
                      color: isDark ? const Color(0xFF0F1E1B) : const Color(0xFFFDFBF7),
                      borderRadius: BorderRadius.circular(16),
                      // ignore: deprecated_member_use
border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
              child: Container(
                margin: _hideContinuousBorders ? EdgeInsets.zero : const EdgeInsets.all(4),
                decoration: _hideContinuousBorders
                    ? null
                    : BoxDecoration(
                        // ignore: deprecated_member_use
border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.15), width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text.rich(
                  TextSpan(children: spans),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  }

  void _startAutoScroll() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    
    _isAutoScrolling = true;
    _isAutoScrollPaused = false;
    
    double step = 20.0; // pixels per second
    switch (_speedLevel) {
      case 1: step = 12.0; break;
      case 2: step = 25.0; break;
      case 3: step = 45.0; break;
      case 4: step = 75.0; break;
      case 5: step = 120.0; break;
    }
    _scrollSpeed = step;


    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final remaining = maxScroll - currentScroll;
      if (remaining <= 0) {
        _stopAutoScroll();
        return;
      }
      
      final durationMs = (remaining / _scrollSpeed * 1000).toInt();
      _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      ).then((_) {
        if (_isAutoScrolling && !_isAutoScrollPaused && _scrollController.hasClients && _scrollController.position.pixels >= maxScroll - 1) {
          _stopAutoScroll();
        }
      });
    }
    setState(() {});
  }

  void _stopAutoScroll() {
    _resumeTimer?.cancel();
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
    _isAutoScrolling = false;
    _isAutoScrollPaused = false;
    setState(() {});
  }

  void _pauseAutoScrollTemporarily() {
    if (!_isAutoScrolling || _isAutoScrollPaused) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.pixels);
    }
    setState(() {
      _isAutoScrollPaused = true;
    });
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isAutoScrolling) {
        setState(() {
          _isAutoScrollPaused = false;
        });
        _startAutoScroll();
      }
    });
  }

  void _changeSpeedLevel(int delta) {
    setState(() {
      _speedLevel = (_speedLevel + delta).clamp(1, 5);
    });
    if (_isAutoScrolling) {
      _startAutoScroll();
    }
  }

  Widget _buildAutoScrollFloatingControls(bool isDark) {
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    final double bottomOffset = 16.0 + safeBottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: bottomOffset,
      left: 16,
      right: 16,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
color: isDark ? const Color(0xFF0C1D1B).withOpacity(0.9) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // ignore: deprecated_member_use
color: const Color(0xFFE5C158).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
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
                    final maxScroll = _scrollController.position.maxScrollExtent;
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
                      const Icon(
                        Icons.swap_vertical_circle_outlined,
                        color: Color(0xFFE5C158),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _isAutoScrolling ? timeText : TranslationService.t('auto_scroll'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (_isAutoScrollPaused) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
color: const Color(0xFFE5C158).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            TranslationService.isArabic ? 'موقوف' : 'Paused',
                            style: const TextStyle(fontSize: 8, color: Color(0xFFE5C158), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            // Custom compact speed pill control
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
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
                      child: Icon(Icons.remove, size: 14, color: Color(0xFFE5C158)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "x$_speedLevel",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5C158)),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _changeSpeedLevel(1),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.add, size: 14, color: Color(0xFFE5C158)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Custom compact circular play/pause button
            GestureDetector(
              onTap: _isAutoScrolling ? _stopAutoScroll : _startAutoScroll,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5C158),
                ),
                child: Icon(
                  _isAutoScrolling && !_isAutoScrollPaused ? Icons.pause : Icons.play_arrow,
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
