import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/quran_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/quran_download_service.dart';
import '../models/offline_surahs.dart';
import 'hadith_screen.dart';

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
  late String _tafsirEdition;
  Map<String, Map<String, bool>> _hadithDownloadedStates = {};

  @override
  void initState() {
    super.initState();
    _reciter = widget.storage.getString(
      'default_reciter',
      defaultValue: 'ar.alafasy',
    );
    _tafsirEdition = widget.storage.getString(
      'default_tafsir',
      defaultValue: 'ar.muyassar',
    );
    _loadSurahList();
    _checkHadithStates();
    QuranDownloadService.instance.initStates(_reciter);
    QuranDownloadService.instance.calculateCounts(widget.storage);
    QuranDownloadService.instance.addListener(_onDownloadServiceUpdate);
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

  Future<void> _checkHadithStates() async {
    final Map<String, Map<String, bool>> states = {};
    for (final book in hadithBooks) {
      states[book.id] = await _getHadithBookDownloadState(book.id);
    }
    if (mounted) {
      setState(() {
        _hadithDownloadedStates = states;
      });
    }
  }

  Future<Map<String, bool>> _getHadithBookDownloadState(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final pathAr = '${dir.path}/hadiths/ara_$bookId.json';
    final pathEn = '${dir.path}/hadiths/eng_$bookId.json';
    return {
      'ara': await File(pathAr).exists(),
      'eng': await File(pathEn).exists(),
    };
  }

  Future<void> _deleteHadithBook(String bookId, String lang) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/hadiths/${lang}_$bookId.json');
      if (await file.exists()) await file.delete();
      await _checkHadithStates();
    } catch (_) {}
  }

  Future<void> _downloadHadithBook(String bookId, String lang) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? "بدء تحميل كتاب الحديث..."
                : "Starting Hadith book download...",
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final url =
          'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/$lang-$bookId.min.json';
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/hadiths/${lang}_$bookId.json';

        await File(path).parent.create(recursive: true);
        await File(path).writeAsString(res.body);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.isArabic
                  ? "تم التحميل بنجاح!"
                  : "Downloaded successfully!",
            ),
            backgroundColor: const Color(0xFFE5C158),
          ),
        );
        await _checkHadithStates();
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.isArabic
                ? "فشل التحميل. حاول مجدداً."
                : "Download failed. Try again.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          style: TextStyle(
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
                        .withOpacity(0.7),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadedCount = _getDownloadedCount();
    final overallProgress = downloadedCount / 114.0;
    final isDownloadingAll = QuranDownloadService.instance.isDownloadingAll;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            TranslationService.t('quran_downloads'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5C158),
            labelColor: const Color(0xFFE5C158),
            unselectedLabelColor: theme.textTheme.bodyMedium?.color
                ?.withOpacity(0.6),
            tabs: [
              Tab(
                text: TranslationService.isArabic
                    ? "تلاوات وقرآن"
                    : "Quran & Recitations",
              ),
              Tab(
                text: TranslationService.isArabic
                    ? "كتب الحديث"
                    : "Hadith Books",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Quran Downloads
            _isLoadingList
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE5C158)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _surahList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE5C158).withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withOpacity(0.1),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        TranslationService.isArabic
                                            ? "التلاوات الصوتية للسور"
                                            : "Surah Audio Recitations",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFFE5C158),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        TranslationService.isArabic
                                            ? "تم تحميل تلاوة $downloadedCount من ١١٤ سورة"
                                            : "Downloaded $downloadedCount of 114 Surah recitations",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.6),
                                        ),
                                      ),
                                      Text(
                                        TranslationService.isArabic
                                            ? "المساحة المستهلكة: ${_totalSpaceMB.toStringAsFixed(1)} ميجابايت"
                                            : "Space used: ${_totalSpaceMB.toStringAsFixed(1)} MB",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.5),
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
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
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
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: overallProgress,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.12),
                                  color: const Color(0xFFE5C158),
                                  minHeight: 6,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: TranslationService.isArabic
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  if (isDownloadingAll)
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.cancel,
                                        size: 14,
                                        color: Colors.redAccent,
                                      ),
                                      label: Text(
                                        TranslationService.isArabic
                                            ? "إلغاء تحميل الكل"
                                            : "Cancel All Downloads",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                      onPressed: () => QuranDownloadService
                                          .instance
                                          .cancelAll(),
                                    )
                                  else
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.library_music_outlined,
                                        size: 14,
                                        color: Color(0xFFE5C158),
                                      ),
                                      label: Text(
                                        TranslationService.isArabic
                                            ? "اختر وحمّل تلاوة"
                                            : "Choose & Download",
                                        style: TextStyle(
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
                                          builder: (ctx) => _ReciterPickerSheet(
                                            storage: widget.storage,
                                            currentReciter: _reciter,
                                            onReciterChanged: (id) {
                                              setState(() => _reciter = id);
                                              widget.storage.setString('default_reciter', id);
                                              QuranDownloadService.instance.calculateCounts(widget.storage);
                                              QuranDownloadService.instance.initStates(_reciter);
                                            },
                                          ),
                                        );
                                        QuranDownloadService.instance.calculateCounts(widget.storage);
                                        await _updateTotalSpace();
                                      },
                                    ),
                                  if (downloadedCount > 0 &&
                                      !isDownloadingAll) ...[
                                    SizedBox(width: 12),
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.delete_sweep,
                                        size: 14,
                                        color: Colors.redAccent,
                                      ),
                                      label: Text(
                                        TranslationService.isArabic
                                            ? "حذف التلاوات"
                                            : "Delete All Audio",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                      onPressed: _confirmDeleteAll,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      final surah = _surahList[index - 1];
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${surah.englishName} • ${surah.numberOfAyahs} ${TranslationService.isArabic ? 'آية' : 'verses'} • ${TranslationService.t('juz')} ${surah.startingJuz} • ${TranslationService.t('hizb')} ${surah.startingHizb}",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.5),
                            ),
                          ),
                          trailing: _buildTrailing(surah.number, state),
                        ),
                      );
                    },
                  ),

            // Tab 2: Hadith Books Downloads
            ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: hadithBooks.length,
              itemBuilder: (context, index) {
                final book = hadithBooks[index];
                final states =
                    _hadithDownloadedStates[book.id] ??
                    {'ara': false, 'eng': false};

                Widget buildLangRow(String lang, String title) {
                  final isDownloaded = states[lang] == true;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      isDownloaded
                          ? Row(
                              children: [
                                Text(
                                  TranslationService.isArabic
                                      ? "أوفلاين"
                                      : "Offline",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: theme.cardColor,
                                        title: Text(
                                          TranslationService.isArabic
                                              ? "حذف كتاب الحديث؟"
                                              : "Delete Hadith Book?",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          TranslationService.isArabic
                                              ? "هل أنت متأكد من حذف هذا الكتاب المخزن أوفلاين؟"
                                              : "Are you sure you want to delete this cached offline book?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              TranslationService.t('cancel'),
                                              style: TextStyle(
                                                color:
                                                    (Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.color ??
                                                            Colors.white)
                                                        .withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteHadithBook(book.id, lang);
                                            },
                                            child: Text(
                                              TranslationService.isArabic
                                                  ? "حذف"
                                                  : "Delete",
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.cloud_download,
                                color: Color(0xFFE5C158),
                                size: 18,
                              ),
                              onPressed: () =>
                                  _downloadHadithBook(book.id, lang),
                            ),
                    ],
                  );
                }

                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: const Color(0xFFE5C158).withOpacity(0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationService.isArabic
                              ? book.nameAr
                              : book.nameEn,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${book.totalHadiths} ${TranslationService.isArabic ? 'حديث شريف' : 'Hadiths'}",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(height: 12),
                        Divider(height: 1),
                        buildLangRow('ara', 'عربي (Arabic)'),
                        Divider(height: 1),
                        buildLangRow('eng', 'English'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              TranslationService.t('downloaded'),
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Text(
                    TranslationService.t('delete'),
                    style: TextStyle(
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
                                  .withOpacity(0.7),
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
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.12),
            ),
          ),
          SizedBox(width: 12),
          Text(
            "${(state.progress * 100).toInt()}%",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.cancel,
              color:
                  (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.white)
                      .withOpacity(0.3),
              size: 18,
            ),
            onPressed: () =>
                QuranDownloadService.instance.cancelDownload(surahNum),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: Icon(Icons.cloud_download, color: Color(0xFFE5C158)),
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
    if (mounted)
      setState(() {
        _counts = counts;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = TranslationService.isArabic;
    final isDownloading = QuranDownloadService.instance.isDownloadingTafsir;
    final progress = QuranDownloadService.instance.tafsirDownloadProgress;

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
              color: theme.dividerColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? "اختر تفسيراً للتحميل" : "Choose a Tafsir to Download",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? "يمكنك تحميل تفسير كامل للقراءة بدون إنترنت"
                : "Download any full Tafsir for offline reading",
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
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
            ...availableTafsirs.map((edition) {
              final count = _counts[edition.identifier] ?? 0;
              final isFull = count >= 114;
              final isActive = edition.identifier == widget.currentEdition;
              final isThisDownloading =
                  _downloading == edition.identifier && isDownloading;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE5C158).withOpacity(0.08)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFE5C158).withOpacity(0.5)
                        : theme.dividerColor.withOpacity(0.15),
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
                            ? Colors.green.withOpacity(0.15)
                            : const Color(0xFFE5C158).withOpacity(0.1),
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
                              color: theme.primaryColor.withOpacity(0.7),
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
                                        ?.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                      trailing: isThisDownloading
                          ? SizedBox(
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3,
                                    color: const Color(0xFFE5C158),
                                  ),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFFE5C158),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
                      onTap: () => widget.onEditionChanged(edition.identifier),
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
                            ).withOpacity(0.15),
                            color: const Color(0xFFE5C158),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
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
    for (final r in availableReciters) {
      int count = 0;
      for (int i = 1; i <= 114; i++) {
        final downloaded = await QuranDownloadService.instance.isSurahDownloaded(i, r.id);
        if (downloaded) count++;
      }
      counts[r.id] = count;
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
    final isDownloading = QuranDownloadService.instance.isDownloadingAll;
    double progress = 0.0;
    if (_downloading != null && isDownloading) {
      final states = QuranDownloadService.instance.downloadStates;
      double p = 0;
      for (int i = 1; i <= 114; i++) {
        if (states[i]?.status == DownloadStatus.downloaded) p += 1.0;
        else if (states[i]?.status == DownloadStatus.downloading) p += states[i]?.progress ?? 0;
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
              color: theme.dividerColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? "اختر مقرئاً للتحميل" : "Choose a Reciter to Download",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFE5C158),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? "يمكنك تحميل تلاوات القرآن الكريم للاستماع بدون إنترنت"
                : "Download Quran recitations to listen offline",
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
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
            ...availableReciters.map((reciter) {
              final count = _counts[reciter.id] ?? 0;
              final isFull = count >= 114;
              final isActive = reciter.id == widget.currentReciter;
              final isThisDownloading = _downloading == reciter.id && isDownloading;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE5C158).withOpacity(0.08)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFE5C158).withOpacity(0.5)
                        : theme.dividerColor.withOpacity(0.15),
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
                            ? Colors.green.withOpacity(0.15)
                            : const Color(0xFFE5C158).withOpacity(0.1),
                        child: Icon(
                          isFull ? Icons.check_circle : Icons.person,
                          size: 18,
                          color: isFull ? Colors.green : const Color(0xFFE5C158),
                        ),
                      ),
                      title: Text(
                        isAr ? reciter.nameAr : reciter.nameEn,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: Text(
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
                                    ?.withOpacity(0.45),
                        ),
                      ),
                      trailing: isThisDownloading
                          ? SizedBox(
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3,
                                    color: const Color(0xFFE5C158),
                                  ),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFFE5C158),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : isFull
                          ? GestureDetector(
                              onTap: () async {
                                await QuranDownloadService.instance
                                    .deleteReciterCache(reciter.id);
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
                                      widget.onReciterChanged(reciter.id);
                                      setState(() => _downloading = reciter.id);
                                      QuranDownloadService.instance
                                          .downloadAll(reciter.id);
                                      await _loadCounts();
                                    },
                              child: Icon(
                                Icons.download_rounded,
                                size: 22,
                                color: isDownloading
                                    ? theme.disabledColor
                                    : const Color(0xFFE5C158),
                              ),
                            ),
                      onTap: () => widget.onReciterChanged(reciter.id),
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
                            backgroundColor: const Color(0xFFE5C158).withOpacity(0.15),
                            color: const Color(0xFFE5C158),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
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
