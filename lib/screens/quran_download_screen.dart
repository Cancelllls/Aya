import 'dart:async';
import 'package:flutter/material.dart';
import '../services/reciters_cache_service.dart';
import '../models/quran_models.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/quran_download_service.dart';
import '../models/offline_surahs.dart';

class QuranDownloadScreen extends StatefulWidget {
  final StorageService storage;

  const QuranDownloadScreen({super.key, required this.storage});

  @override
  State<QuranDownloadScreen> createState() => _QuranDownloadScreenState();
}

class _QuranDownloadScreenState extends State<QuranDownloadScreen> {
  List<Surah> _surahList = [];
  bool _isLoadingList = true;
  double _totalSpaceMB = 0.0;
  late String _reciter;
  String _cachedReciterLabel = '';

  @override
  void initState() {
    super.initState();
    _reciter = widget.storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    _loadReciterLabel();
    _loadSurahList();
    QuranDownloadService.instance.initStates(_reciter);
    QuranDownloadService.instance.calculateCounts(widget.storage);
    QuranDownloadService.instance.addListener(_onDownloadServiceUpdate);
  }

  Future<void> _loadReciterLabel() async {
    if (_reciter.startsWith('mp3quran_server_')) {
      final server = _reciter.substring(16);
      try {
        final list = await RecitersCacheService.getAllReciters();
        for (final r in list) {
          final moshafs = r['moshaf'] as List;
          for (final m in moshafs) {
            if (m['server'] == server) {
              _cachedReciterLabel = '${r['name']} (${m['name']})';
              if (mounted) setState(() {});
              return;
            }
          }
        }
      } catch (_) {}
      _cachedReciterLabel = TranslationService.isArabic
          ? 'تلاوة غير معروفة'
          : 'Unknown Reciter';
    } else {
      // Look up Hafs reciter name from the static list
      final rec = availableReciters
          .where((r) => r.id == _reciter)
          .firstOrNull;
      _cachedReciterLabel = rec != null
          ? (TranslationService.isArabic ? rec.nameAr : rec.nameEn)
          : _reciter;
    }
  }

  @override
  void dispose() {
    QuranDownloadService.instance.removeListener(_onDownloadServiceUpdate);
    super.dispose();
  }

  void _onDownloadServiceUpdate() {
    if (mounted) {
      unawaited(_updateTotalSpace());
      setState(() {});
    }
  }

  Future<void> _loadSurahList() async {
    if (mounted) {
      setState(() {
        _surahList = allOfflineSurahs;
        _isLoadingList = false;
      });
    }
    await _updateTotalSpace();
  }

  Future<void> _updateTotalSpace() async {
    final space = await QuranDownloadService.instance.getTotalSpaceMB(_reciter);
    if (mounted) {
      setState(() {
        _totalSpaceMB = space;
      });
    }
  }

  int _getDownloadedCount() {
    int count = 0;
    for (int i = 1; i <= 114; i++) {
      if (QuranDownloadService.instance.getState(i).status ==
          DownloadStatus.downloaded) {
        count++;
      }
    }
    return count;
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          TranslationService.isArabic
              ? "حذف جميع التحميلات؟"
              : "Delete all downloads?",
          style: const TextStyle(
            color: Color(0xFFE5C158),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          TranslationService.isArabic
              ? "سيتم إزالة جميع ملفات تلاوات السور المحملة من جهازك."
              : "This will remove all downloaded Surah recitations from your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              TranslationService.t('cancel'),
              style: TextStyle(
                color:
                    (Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.white)
                        .withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingList = true);
              await QuranDownloadService.instance.deleteReciterCache(_reciter);
              await _updateTotalSpace();
              if (context.mounted) {
                setState(() => _isLoadingList = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.isArabic
                          ? 'تم حذف جميع التحميلات بنجاح.'
                          : 'All downloads deleted.',
                    ),
                  ),
                );
              }
            },
            child: Text(
              TranslationService.isArabic ? "حذف الكل" : "Delete All",
            ),
          ),
        ],
      ),
    );
  }

  void _openTranslationPicker() {
    final currentTrans = widget.storage.getString(
      'default_translation',
      defaultValue: 'en.sahih',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => _TranslationPickerSheet(
        storage: widget.storage,
        currentEdition: currentTrans,
        onEditionChanged: (id) {
          widget.storage.setString('default_translation', id);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _openTafsirPicker() {
    final currentTafsir = widget.storage.getString(
      'default_tafsir',
      defaultValue: 'ar.muyassar',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => _TafsirPickerSheet(
        storage: widget.storage,
        currentEdition: currentTafsir,
        onEditionChanged: (id) {
          widget.storage.setString('default_tafsir', id);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadedCount = _getDownloadedCount();
    final overallProgress = downloadedCount / 114.0;
    final isDownloadingAll = QuranDownloadService.instance.isDownloadingAll;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          TranslationService.t('quran_downloads'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate, color: Color(0xFFE5C158)),
            tooltip: TranslationService.isArabic
                ? "ترجمات القرآن"
                : "Translations",
            onPressed: _openTranslationPicker,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book, color: Color(0xFFE5C158)),
            tooltip: TranslationService.isArabic ? "التفاسير" : "Tafsirs",
            onPressed: _openTafsirPicker,
          ),
        ],
      ),
      body: _isLoadingList
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _surahList.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5C158).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- QURAN AUDIO RECITATIONS SECTION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TranslationService.isArabic
                                      ? "التلاوات الصوتية للسور"
                                      : "Surah Audio Recitations",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFE5C158),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TranslationService.isArabic
                                      ? "تم تحميل تلاوة $downloadedCount من ١١٤ سورة"
                                      : "Downloaded $downloadedCount of 114 Surah recitations",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  TranslationService.isArabic
                                      ? "المساحة المستهلكة: ${_totalSpaceMB.toStringAsFixed(1)} ميجابايت"
                                      : "Space used: ${_totalSpaceMB.toStringAsFixed(1)} MB",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            if (isDownloadingAll)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE5C158,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "تحميل الكل...",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE5C158),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            backgroundColor: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.12),
                            color: const Color(0xFFE5C158),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: TranslationService.isArabic
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            if (isDownloadingAll)
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.cancel,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                label: Text(
                                  TranslationService.isArabic
                                      ? "إلغاء تحميل الكل"
                                      : "Cancel All Downloads",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                  ),
                                ),
                                onPressed: () =>
                                    QuranDownloadService.instance.cancelAll(),
                              )
                            else
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.library_music_outlined,
                                  size: 14,
                                  color: Color(0xFFE5C158),
                                ),
                                label: Text(
                                  TranslationService.isArabic
                                      ? "اختر وحمّل تلاوة"
                                      : "Choose & Download",
                                  style: const TextStyle(
                                    color: Color(0xFFE5C158),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    constraints: BoxConstraints(
                                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                                    ),
                                    builder: (ctx) => _ReciterPickerSheet(
                                      storage: widget.storage,
                                      currentReciter: _reciter,
                                      onReciterChanged: (id) {
                                        _reciter = id;
                                        setState(() {});
                                        widget.storage.setString(
                                          'default_reciter',
                                          id,
                                        );
                                        _loadReciterLabel();
                                        QuranDownloadService.instance
                                            .calculateCounts(widget.storage);
                                        QuranDownloadService.instance
                                            .initStates(id);
                                      },
                                    ),
                                  );
                                  QuranDownloadService.instance.calculateCounts(
                                    widget.storage,
                                  );
                                  await _updateTotalSpace();
                                },
                              ),
                            if (downloadedCount > 0 && !isDownloadingAll) ...[
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete_sweep,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                label: Text(
                                  TranslationService.isArabic
                                      ? "حذف التلاوات"
                                      : "Delete All Audio",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                  ),
                                ),
                                onPressed: _confirmDeleteAll,
                              ),
                            ],
                          ],
                        ),
                        Divider(
                          height: 24,
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFFE5C158)
                                        .withValues(alpha: 0.4),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.translate,
                                  size: 16,
                                  color: Color(0xFFE5C158),
                                ),
                                label: Text(
                                  TranslationService.isArabic
                                      ? "الترجمات (CDN)"
                                      : "Translations (CDN)",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE5C158),
                                  ),
                                ),
                                onPressed: _openTranslationPicker,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFFE5C158)
                                        .withValues(alpha: 0.4),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.menu_book,
                                  size: 16,
                                  color: Color(0xFFE5C158),
                                ),
                                label: Text(
                                  TranslationService.isArabic
                                      ? "التفاسير"
                                      : "Tafsirs",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE5C158),
                                  ),
                                ),
                                onPressed: _openTafsirPicker,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                if (index == 1) {
                  final reciterName = _cachedReciterLabel.isNotEmpty
                      ? _cachedReciterLabel
                      : (TranslationService.isArabic
                            ? 'تلاوة غير معروفة'
                            : 'Unknown Reciter');

                  return Card(
                    color: const Color(0xFFE5C158).withValues(alpha: 0.15),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: const Color(0xFFE5C158).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mic,
                            color: Color(0xFFE5C158),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TranslationService.isArabic
                                      ? 'القارئ الحالي'
                                      : 'Current Reciter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reciterName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE5C158),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Color(0xFFE5C158),
                            ),
                            onPressed: () {
                              QuranDownloadService.instance.downloadAll(
                                _reciter,
                              );
                            },
                            tooltip: TranslationService.isArabic
                                ? 'تحميل الكل'
                                : 'Download All',
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final surah = _surahList[index - 2];
                final state = QuranDownloadService.instance.getState(
                  surah.number,
                );

                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      "${surah.number}. ${surah.name}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${surah.englishName} • ${surah.numberOfAyahs} ${TranslationService.isArabic ? 'آية' : 'verses'} • ${TranslationService.t('juz')} ${surah.startingJuz} • ${TranslationService.t('hizb')} ${surah.startingHizb}",
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 
                          0.5,
                        ),
                      ),
                    ),
                    trailing: _buildTrailing(surah.number, state),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTrailing(int surahNum, SurahDownloadState state) {
    if (state.status == DownloadStatus.downloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              TranslationService.t('downloaded'),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Text(
                    TranslationService.t('delete'),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(TranslationService.t('delete_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        TranslationService.t('cancel'),
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.bodyMedium?.color ??
                                      Colors.white)
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        QuranDownloadService.instance.deleteSurah(
                          surahNum,
                          _reciter,
                        );
                      },
                      child: Text(TranslationService.t('delete')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    } else if (state.status == DownloadStatus.downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: state.progress,
              strokeWidth: 2.5,
              color: const Color(0xFFE5C158),
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${(state.progress * 100).toInt()}%",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.cancel,
              color:
                  (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.white)
                      .withValues(alpha: 0.3),
              size: 18,
            ),
            onPressed: () =>
                QuranDownloadService.instance.cancelDownload(surahNum),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.cloud_download, color: Color(0xFFE5C158)),
        onPressed: () =>
            QuranDownloadService.instance.downloadSurah(surahNum, _reciter),
      );
    }
  }
}

// ─── Tafsir Picker Bottom Sheet ───────────────────────────────────────────────
class _TafsirPickerSheet extends StatefulWidget {
  final StorageService storage;
  final String currentEdition;
  final ValueChanged<String> onEditionChanged;

  const _TafsirPickerSheet({
    required this.storage,
    required this.currentEdition,
    required this.onEditionChanged,
  });

  @override
  State<_TafsirPickerSheet> createState() => _TafsirPickerSheetState();
}

class _TafsirPickerSheetState extends State<_TafsirPickerSheet> {
  Map<String, int> _counts = {};
  bool _loading = true;
  String? _downloading;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    QuranDownloadService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    QuranDownloadService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCounts() async {
    final Map<String, int> counts = {};
    for (final t in availableTafsirs) {
      counts[t.identifier] = await QuranDownloadService.instance
          .getTafsirCountForEdition(t.identifier);
    }
    if (mounted) {
      setState(() {
        _counts = counts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = TranslationService.isArabic;
    final isDownloading = QuranDownloadService.instance.isDownloadingTafsir;
    final progress = QuranDownloadService.instance.tafsirDownloadProgress;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? "اختر تفسيراً للتحميل والقراءة" : "Choose a Tafsir for Reading",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? "جميع التفاسير المعتمدة مضمنة محلياً أو قابلة للتحميل للقراءة بدون إنترنت"
                : "All verified Tafsirs are bundled locally or downloadable for offline reading",
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: availableTafsirs.map((edition) {
                  final count = _counts[edition.identifier] ?? 0;
                  final isBundled = edition.isBundled || edition.identifier == 'ar.muyassar';
                  final isFull = isBundled || count >= 114;
                  final isActive = edition.identifier == widget.currentEdition;
                  final isThisDownloading =
                      _downloading == edition.identifier && isDownloading;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE5C158).withValues(alpha: 0.08)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFE5C158)
                            : theme.dividerColor.withValues(alpha: 0.15),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isFull
                                ? Colors.green.withValues(alpha: 0.15)
                                : const Color(0xFFE5C158).withValues(alpha: 0.1),
                            child: Icon(
                              isFull ? Icons.check_circle : Icons.book_outlined,
                              size: 18,
                              color: isFull
                                  ? Colors.green
                                  : const Color(0xFFE5C158),
                            ),
                          ),
                          title: Text(
                            edition.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? edition.mufassir : edition.mufassirEn,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: theme.primaryColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBundled
                                    ? (isAr
                                          ? "✓ مضمّن محلياً (كامل)"
                                          : "✓ Bundled locally (Complete)")
                                    : isFull
                                    ? (isAr
                                          ? "✓ مكتمل (١١٤ سورة)"
                                          : "✓ Complete (114 Surahs)")
                                    : count > 0
                                    ? (isAr
                                          ? "جزئي · $count من ١١٤ سورة"
                                          : "Partial · $count of 114 Surahs")
                                    : (isAr ? "غير محمّل" : "Not downloaded"),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isFull
                                      ? Colors.green
                                      : count > 0
                                      ? Colors.orange
                                      : theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                          trailing: isBundled
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAr ? "مضمّن" : "Bundled",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : isThisDownloading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: progress > 0 ? progress : null,
                                            strokeWidth: 2.5,
                                            color: const Color(0xFFE5C158),
                                          ),
                                          Text(
                                            "${(progress * 100).toInt()}%",
                                            style: const TextStyle(
                                              fontSize: 7,
                                              color: Color(0xFFE5C158),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 20,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: isAr ? "إلغاء" : "Cancel",
                                      onPressed: () {
                                        QuranDownloadService.instance.cancelTafsirDownload();
                                        setState(() => _downloading = null);
                                      },
                                    ),
                                  ],
                                )
                              : isFull
                              ? GestureDetector(
                                  onTap: () async {
                                    await QuranDownloadService.instance
                                        .deleteAllTafsir(
                                          widget.storage,
                                          edition.identifier,
                                        );
                                    await _loadCounts();
                                  },
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: isDownloading
                                      ? null
                                      : () async {
                                          widget.onEditionChanged(
                                            edition.identifier,
                                          );
                                          setState(
                                            () => _downloading = edition.identifier,
                                          );
                                          await QuranDownloadService.instance
                                              .downloadAllTafsir(
                                                widget.storage,
                                                edition.identifier,
                                              );
                                          await _loadCounts();
                                          setState(() => _downloading = null);
                                        },
                                  child: Icon(
                                    Icons.download_rounded,
                                    size: 22,
                                    color: isDownloading
                                        ? theme.disabledColor
                                        : const Color(0xFFE5C158),
                                  ),
                                ),
                          onTap: () {
                            widget.onEditionChanged(edition.identifier);
                            Navigator.pop(context);
                          },
                        ),
                        if (isThisDownloading)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              bottom: 8,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: const Color(
                                  0xFFE5C158,
                                ).withValues(alpha: 0.15),
                                color: const Color(0xFFE5C158),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: Text(
                  isAr ? "إلغاء التحميل" : "Cancel Download",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  QuranDownloadService.instance.cancelTafsirDownload();
                  setState(() => _downloading = null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Translation Picker Bottom Sheet ──────────────────────────────────────────
class _TranslationPickerSheet extends StatefulWidget {
  final StorageService storage;
  final String currentEdition;
  final ValueChanged<String> onEditionChanged;

  const _TranslationPickerSheet({
    required this.storage,
    required this.currentEdition,
    required this.onEditionChanged,
  });

  @override
  State<_TranslationPickerSheet> createState() => _TranslationPickerSheetState();
}

class _TranslationPickerSheetState extends State<_TranslationPickerSheet> {
  Map<String, int> _counts = {};
  bool _loading = true;
  String? _downloading;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    QuranDownloadService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    QuranDownloadService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCounts() async {
    final Map<String, int> counts = {};
    for (final t in availableTranslations) {
      counts[t.identifier] = await QuranDownloadService.instance
          .getTranslationCountForEdition(t.identifier);
    }
    if (mounted) {
      setState(() {
        _counts = counts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = TranslationService.isArabic;
    final isDownloading =
        QuranDownloadService.instance.isDownloadingTranslation;
    final progress =
        QuranDownloadService.instance.translationDownloadProgress;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? "تحميل ترجمات معاني القرآن" : "Download Quran Translations",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? "حزم ترجمة سريعة عبر CDN للقراءة بدون اتصال بالإنترنت"
                : "Fast CDN translation packs for 100% offline reading",
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: availableTranslations.map((edition) {
                  final count = _counts[edition.identifier] ?? 0;
                  final isFull = edition.isBundled || count >= 5000;
                  final isActive = edition.identifier == widget.currentEdition;
                  final isThisDownloading =
                      _downloading == edition.identifier && isDownloading;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE5C158).withValues(alpha: 0.08)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFE5C158)
                            : theme.dividerColor.withValues(alpha: 0.1),
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        edition.isBundled
                            ? Icons.verified_outlined
                            : (isFull ? Icons.check_circle : Icons.translate),
                        color: isActive
                            ? const Color(0xFFE5C158)
                            : (isFull ? Colors.green : theme.disabledColor),
                        size: 20,
                      ),
                      title: Text(
                        isAr ? edition.nameAr : edition.name,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${edition.language.toUpperCase()} • ${isAr ? edition.translatorAr : edition.translator}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (edition.isBundled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAr ? "مضمّن" : "Bundled",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (isThisDownloading)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    strokeWidth: 2,
                                    color: const Color(0xFFE5C158),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${(progress * 100).toInt()}%",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: isAr ? "إلغاء" : "Cancel",
                                  onPressed: () {
                                    QuranDownloadService.instance
                                        .cancelTranslationDownload();
                                    setState(() => _downloading = null);
                                  },
                                ),
                              ],
                            )
                          else if (isFull)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAr ? "مكتمل" : "Downloaded",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: isAr ? "حذف" : "Delete",
                                  onPressed: () async {
                                    await QuranDownloadService.instance
                                        .deleteTranslation(
                                          widget.storage,
                                          edition.identifier,
                                        );
                                    await _loadCounts();
                                  },
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5C158),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.cloud_download_outlined,
                                size: 14,
                              ),
                              label: Text(
                                isAr ? "تحميل (CDN)" : "Download",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: isDownloading
                                  ? null
                                  : () async {
                                      setState(
                                        () => _downloading = edition.identifier,
                                      );
                                      await QuranDownloadService.instance
                                          .downloadAllTranslation(
                                            widget.storage,
                                            edition.identifier,
                                          );
                                      await _loadCounts();
                                      setState(() => _downloading = null);
                                    },
                            ),
                        ],
                      ),
                      onTap: () {
                        widget.onEditionChanged(edition.identifier);
                        if (!edition.isBundled && (_counts[edition.identifier] ?? 0) < 5000) {
                          QuranDownloadService.instance.downloadAllTranslation(
                            widget.storage,
                            edition.identifier,
                          );
                        }
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.redAccent,
                  size: 16,
                ),
                label: Text(
                  isAr ? "إلغاء التحميل" : "Cancel Download",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
                onPressed: () {
                  QuranDownloadService.instance.cancelTranslationDownload();
                  setState(() => _downloading = null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Reciter Picker Bottom Sheet ──────────────────────────────────────────────
class _ReciterPickerSheet extends StatefulWidget {
  final StorageService storage;
  final String currentReciter;
  final ValueChanged<String> onReciterChanged;

  const _ReciterPickerSheet({
    required this.storage,
    required this.currentReciter,
    required this.onReciterChanged,
  });

  @override
  State<_ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<_ReciterPickerSheet> {
  Map<String, int> _counts = {};
  List<Map<String, String>> _allReciters = [];
  bool _loading = true;
  String? _downloading;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  /// Strip tartil/mujawwad suffixes so reciters group by Qira'ah only.
  static String canonicalQiraah(String name) {
    return name
        .replaceAll(RegExp(r'\s*-\s*المصحف المجود'), '')
        .replaceAll(RegExp(r'\s*-\s*المصحف المعلم'), '')
        .replaceAll(RegExp(r'\s*-\s*مرتل'), '')
        .replaceAll(RegExp(r'\s*-\s*رواية.*'), '')
        .replaceAll(RegExp(r'\s*-\s*Almusshaf.*'), '')
        .replaceAll(RegExp(r'\s*-\s*Murattal'), '')
        .replaceAll(RegExp(r'\s*-\s*Mujawwad'), '')
        .replaceAll(RegExp(r'\s*-\s*Muallim'), '')
        .replaceAll(RegExp(r'\s*-\s*Mojawwad'), '')
        .trim();
  }

  List<Map<String, String>> _filteredReciters() {
    if (_searchQuery.isEmpty) return _allReciters;
    final q = _searchQuery;
    final isAr = TranslationService.isArabic;
    return _allReciters.where((r) {
      return (isAr ? r['nameAr']! : r['nameEn']!).toLowerCase().contains(q) ||
          (isAr ? r['quraaAr']! : r['quraaEn']!).toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAndLoad();
    QuranDownloadService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    QuranDownloadService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<int> _countDownloadedSurahs(String reciter) async {
    // Use cached count when available; scan filesystem only on first lookup
    final svc = QuranDownloadService.instance;
    final cached = svc.getCountForReciter(reciter);
    if (cached > 0) return cached;
    return svc.updateCountForReciter(reciter);
  }

  Future<void> _fetchAndLoad() async {
    final List<Map<String, String>> reciters = [];

    // Add static reciters
    for (final r in availableReciters) {
      reciters.add({
        'id': r.id,
        'nameAr': r.nameAr,
        'nameEn': r.nameEn,
        'quraaAr': 'حفص عن عاصم',
        'quraaEn': "Hafs A'n Assem",
      });
    }

    // Fetch dynamic reciters — dedup by server URL since the
    // same reciter may appear in multiple riwayat from the API.
    try {
      final list = await RecitersCacheService.getAllReciters();
      final seenServers = <String>{};
      // Pre-populate with static reciter IDs so we don't duplicate them
      for (final r in availableReciters) {
        seenServers.add(r.id);
      }
      for (final r in list) {
        final moshafs = r['moshaf'] as List;
        for (final m in moshafs) {
          final server = m['server'] as String;
          final id = 'mp3quran_server_$server';
          if (seenServers.add(id)) {
            reciters.add({
              'id': id,
              'nameAr': r['name'] as String,
              'nameEn': r['name'] as String,
              'quraaAr': m['name'] as String,
              'quraaEn': m['name'] as String,
            });
          }
        }
      }
    } catch (e) {
      // Ignore errors, we still have static ones
    }

    final Map<String, int> counts = {};
    for (final r in reciters) {
      counts[r['id']!] = await _countDownloadedSurahs(r['id']!);
    }

    final isAr = TranslationService.isArabic;
    reciters.sort((a, b) {
      // Sort by Qira'ah first, then by reciter name — so the UI group
      // headers render cleanly.
      final quraaA = isAr ? a['quraaAr']! : a['quraaEn']!;
      final quraaB = isAr ? b['quraaAr']! : b['quraaEn']!;
      final cmp = quraaA.compareTo(quraaB);
      if (cmp != 0) return cmp;
      final nameA = isAr ? a['nameAr']! : a['nameEn']!;
      final nameB = isAr ? b['nameAr']! : b['nameEn']!;
      return nameA.compareTo(nameB);
    });

    if (mounted) {
      setState(() {
        _allReciters = reciters;
        _counts = counts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = TranslationService.isArabic;
    final isDownloading = QuranDownloadService.instance.isDownloadingAll;
    double progress = 0.0;
    if (_downloading != null && isDownloading) {
      final states = QuranDownloadService.instance.downloadStates;
      double p = 0;
      for (int i = 1; i <= 114; i++) {
        if (states[i]?.status == DownloadStatus.downloaded) {
          p += 1.0;
        } else if (states[i]?.status == DownloadStatus.downloading)
          p += states[i]?.progress ?? 0;
      }
      progress = p / 114.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? "اختر مقرئاً للتحميل" : "Choose a Reciter to Download",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? "يمكنك تحميل تلاوات القرآن الكريم للاستماع بدون إنترنت"
                : "Download Quran recitations to listen offline",
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: isAr ? "ابحث عن مقرئ..." : "Search reciters...",
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFE5C158)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                      )
                    : null,
                filled: true, fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5C158))),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          else if (_searchQuery.isNotEmpty && _filteredReciters().isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  isAr ? "لا توجد نتائج" : "No results",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _filteredReciters().length,
                itemBuilder: (context, index) {
                  final filtered = _filteredReciters();
                  final reciter = filtered[index];
                  final rId = reciter['id']!;
                  final rName = isAr ? reciter['nameAr']! : reciter['nameEn']!;
                  final rQuraa = isAr
                      ? reciter['quraaAr']!
                      : reciter['quraaEn']!;

                  // Group header: canonical Qira'ah name (no tartil/mujawwad)
                  final rQuraaClean = canonicalQiraah(rQuraa);
                  final prevQuraa = index > 0
                      ? canonicalQiraah(isAr ? filtered[index - 1]['quraaAr']! : filtered[index - 1]['quraaEn']!)
                      : '';
                  final showHeader = rQuraaClean != prevQuraa;

                  final count = _counts[rId] ?? 0;
                  final isFull = count >= 114;
                  final isActive = rId == widget.currentReciter;
                  final isThisDownloading =
                      _downloading == rId && isDownloading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                          child: Text(
                            rQuraaClean,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFE5C158),
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE5C158).withValues(alpha: 0.08)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFE5C158).withValues(alpha: 0.5)
                            : theme.dividerColor.withValues(alpha: 0.15),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isFull
                                ? Colors.green.withValues(alpha: 0.15)
                                : const Color(0xFFE5C158).withValues(alpha: 0.1),
                            child: Icon(
                              isFull ? Icons.check_circle : Icons.person,
                              size: 18,
                              color: isFull
                                  ? Colors.green
                                  : const Color(0xFFE5C158),
                            ),
                          ),
                          title: Text(
                            rName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rQuraa,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFull
                                    ? (isAr
                                          ? "✓ مكتمل (١١٤ سورة)"
                                          : "✓ Complete (114 Surahs)")
                                    : count > 0
                                    ? (isAr
                                          ? "جزئي · $count من ١١٤ سورة"
                                          : "Partial · $count of 114 Surahs")
                                    : (isAr ? "غير محمّل" : "Not downloaded"),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isFull
                                      ? Colors.green
                                      : count > 0
                                      ? Colors.orange
                                      : theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                          trailing: isFull
                              ? GestureDetector(
                                  onTap: () async {
                                    await QuranDownloadService.instance
                                        .deleteReciterCache(rId);
                                    _counts[rId] = await _countDownloadedSurahs(
                                      rId,
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                )
                              : null,
                          onTap: () {
                            widget.onReciterChanged(rId);
                            Navigator.of(context).pop();
                          },
                        ),
                        if (isThisDownloading)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              bottom: 8,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: const Color(
                                  0xFFE5C158,
                                ).withValues(alpha: 0.15),
                                color: const Color(0xFFE5C158),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
                },
              ),
            ),
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                  size: 16,
                ),
                label: Text(
                  isAr ? "إلغاء التحميل" : "Cancel Download",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
                onPressed: () {
                  QuranDownloadService.instance.cancelAll();
                  setState(() => _downloading = null);
                },
              ),
            ),
        ],
      ),
    );
  }
}
