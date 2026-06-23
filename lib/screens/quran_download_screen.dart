import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/quran_download_service.dart';

class QuranDownloadScreen extends StatefulWidget {
  final StorageService storage;

  const QuranDownloadScreen({
    super.key,
    required this.storage,
  });

  @override
  State<QuranDownloadScreen> createState() => _QuranDownloadScreenState();
}

class _QuranDownloadScreenState extends State<QuranDownloadScreen> {
  List<Surah> _surahList = [];
  bool _isLoadingList = true;
  double _totalSpaceMB = 0.0;
  late String _reciter;

  @override
  void initState() {
    super.initState();
    _reciter = widget.storage.getString('default_reciter', defaultValue: 'ar.alafasy');
    _loadSurahList();
    QuranDownloadService.instance.initStates(_reciter);
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
    }
  }

  Future<void> _loadSurahList() async {
    try {
      final list = await ApiService.fetchSurahList();
      if (mounted) {
        setState(() {
          _surahList = list;
          _isLoadingList = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingList = false);
      }
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
      if (QuranDownloadService.instance.getState(i).status == DownloadStatus.downloaded) {
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
          TranslationService.isArabic ? "حذف جميع التحميلات؟" : "Delete all downloads?",
          style: const TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold),
        ),
        content: Text(
          TranslationService.isArabic 
              ? "سيتم إزالة جميع ملفات تلاوات السور المحملة من جهازك." 
              : "This will remove all downloaded Surah recitations from your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationService.t('cancel'), style: const TextStyle(color: Colors.white70)),
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
                  SnackBar(content: Text(TranslationService.isArabic ? 'تم حذف جميع التحميلات بنجاح.' : 'All downloads deleted.')),
                );
              }
            },
            child: Text(TranslationService.isArabic ? "حذف الكل" : "Delete All"),
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
    
    final textCount = QuranDownloadService.instance.getDownloadedTextCount(widget.storage);
    final textProgress = textCount / 114.0;
    final isDownloadingText = QuranDownloadService.instance.isDownloadingText;
    final textDownloadProgress = QuranDownloadService.instance.textDownloadProgress;

    final tafsirCount = QuranDownloadService.instance.getDownloadedTafsirCount(widget.storage);
    final tafsirProgress = tafsirCount / 114.0;
    final isDownloadingTafsir = QuranDownloadService.instance.isDownloadingTafsir;
    final tafsirDownloadProgress = QuranDownloadService.instance.tafsirDownloadProgress;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          TranslationService.t('quran_downloads'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoadingList
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _surahList.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- QURAN TEXT SECTION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TranslationService.isArabic
                                      ? "نص القرآن الكريم (للقراءة أوفلاين)"
                                      : "Quran Text (For Offline Reading)",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE5C158)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TranslationService.isArabic
                                      ? "تم حفظ نص $textCount من ١١٤ سورة"
                                      : "Saved text for $textCount of 114 Surahs",
                                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                ),
                              ],
                            ),
                            if (isDownloadingText)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5C158).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${(textDownloadProgress * 100).toInt()}%",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5C158)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: isDownloadingText ? textDownloadProgress : textProgress,
                            backgroundColor: Colors.white12,
                            color: isDownloadingText ? const Color(0xFF10B981) : const Color(0xFFE5C158),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isDownloadingText)
                              TextButton.icon(
                                icon: const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                ),
                                label: Text(
                                  TranslationService.isArabic ? "إلغاء" : "Cancel",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                                onPressed: () => QuranDownloadService.instance.cancelTextDownload(),
                              )
                            else if (textCount < 114)
                              TextButton.icon(
                                icon: const Icon(Icons.download, size: 14, color: Color(0xFFE5C158)),
                                label: Text(
                                  TranslationService.isArabic ? "تحميل النص" : "Download Text Only",
                                  style: const TextStyle(color: Color(0xFFE5C158), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => QuranDownloadService.instance.downloadAllText(widget.storage),
                              )
                            else
                              Text(
                                TranslationService.isArabic ? "✓ النص جاهز بدون إنترنت" : "✓ Text ready offline",
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            if (textCount > 0 && !isDownloadingText) ...[
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                label: Text(
                                  TranslationService.isArabic ? "حذف النص" : "Delete Text Cache",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      title: Text(
                                        TranslationService.isArabic ? "حذف نص القرآن؟" : "Delete Quran Text?",
                                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                      ),
                                      content: Text(
                                        TranslationService.isArabic
                                            ? "هل أنت متأكد من حذف نصوص السور المخزنة أوفلاين؟"
                                            : "Are you sure you want to delete cached offline Surah texts?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(TranslationService.t('cancel'), style: const TextStyle(color: Colors.white70)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await QuranDownloadService.instance.deleteAllText(widget.storage);
                                          },
                                          child: Text(TranslationService.isArabic ? "حذف" : "Delete"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 16, color: Colors.white10),
                        
                        // --- QURAN TAFSIR SECTION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TranslationService.isArabic
                                      ? "تفسير الميسر (للقراءة أوفلاين)"
                                      : "Tafsir Al-Muyassar (For Offline Reading)",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE5C158)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TranslationService.isArabic
                                      ? "تم حفظ تفسير $tafsirCount من ١١٤ سورة"
                                      : "Saved Tafsir for $tafsirCount of 114 Surahs",
                                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                ),
                              ],
                            ),
                            if (isDownloadingTafsir)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5C158).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${(tafsirDownloadProgress * 100).toInt()}%",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5C158)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: isDownloadingTafsir ? tafsirDownloadProgress : tafsirProgress,
                            backgroundColor: Colors.white12,
                            color: isDownloadingTafsir ? const Color(0xFF10B981) : const Color(0xFFE5C158),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isDownloadingTafsir)
                              TextButton.icon(
                                icon: const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                ),
                                label: Text(
                                  TranslationService.isArabic ? "إلغاء" : "Cancel",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                                onPressed: () => QuranDownloadService.instance.cancelTafsirDownload(),
                              )
                            else if (tafsirCount < 114)
                              TextButton.icon(
                                icon: const Icon(Icons.download, size: 14, color: Color(0xFFE5C158)),
                                label: Text(
                                  TranslationService.isArabic ? "تحميل التفسير" : "Download Tafsir",
                                  style: const TextStyle(color: Color(0xFFE5C158), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => QuranDownloadService.instance.downloadAllTafsir(widget.storage),
                              )
                            else
                              Text(
                                TranslationService.isArabic ? "✓ التفسير جاهز بدون إنترنت" : "✓ Tafsir ready offline",
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            if (tafsirCount > 0 && !isDownloadingTafsir) ...[
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                label: Text(
                                  TranslationService.isArabic ? "حذف التفسير" : "Delete Tafsir Cache",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      title: Text(
                                        TranslationService.isArabic ? "حذف التفسير؟" : "Delete Tafsir?",
                                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                      ),
                                      content: Text(
                                        TranslationService.isArabic
                                            ? "هل أنت متأكد من حذف تفاسير السور المخزنة أوفلاين؟"
                                            : "Are you sure you want to delete cached offline Surah Tafsir?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(TranslationService.t('cancel'), style: const TextStyle(color: Colors.white70)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await QuranDownloadService.instance.deleteAllTafsir(widget.storage);
                                          },
                                          child: Text(TranslationService.isArabic ? "حذف" : "Delete"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 16, color: Colors.white10),

                        // --- QURAN VOICE AUDIO SECTION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TranslationService.isArabic
                                      ? "صوت التلاوة (للاستماع أوفلاين)"
                                      : "Recitation Voice Audio (For Offline Play)",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE5C158)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TranslationService.isArabic
                                      ? "تم تحميل صوت $downloadedCount من ١١٤ سورة"
                                      : "Downloaded audio for $downloadedCount of 114 Surahs",
                                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5C158).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${_totalSpaceMB.toStringAsFixed(1)} MB",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE5C158),
                                  fontSize: 11,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            backgroundColor: Colors.white12,
                            color: const Color(0xFFE5C158),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isDownloadingAll)
                              TextButton.icon(
                                icon: const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                ),
                                label: Text(
                                  TranslationService.t('cancel_all'),
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                                onPressed: () => QuranDownloadService.instance.cancelAll(),
                              )
                            else if (downloadedCount < 114)
                              TextButton.icon(
                                icon: const Icon(Icons.download, size: 14, color: Color(0xFFE5C158)),
                                label: Text(
                                  TranslationService.t('download_all'),
                                  style: const TextStyle(color: Color(0xFFE5C158), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => QuranDownloadService.instance.downloadAll(_reciter),
                              )
                            else
                              Text(
                                TranslationService.isArabic ? "✓ التلاوات جاهزة بدون إنترنت" : "✓ Audios ready offline",
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            if (downloadedCount > 0 && !isDownloadingAll) ...[
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                label: Text(
                                  TranslationService.isArabic ? "حذف التلاوات" : "Delete Audios",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
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
                final state = QuranDownloadService.instance.getState(surah.number);

                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      "${surah.number}. ${surah.name}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${surah.englishName} • ${surah.numberOfAyahs} ${TranslationService.isArabic ? 'آية' : 'verses'} • ${TranslationService.t('juz')} ${surah.startingJuz} • ${TranslationService.t('hizb')} ${surah.startingHizb}",
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              TranslationService.t('downloaded'),
              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  content: Text(TranslationService.t('delete_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(TranslationService.t('cancel'), style: const TextStyle(color: Colors.white70)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        QuranDownloadService.instance.deleteSurah(surahNum, _reciter);
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
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${(state.progress * 100).toInt()}%",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.white30, size: 18),
            onPressed: () => QuranDownloadService.instance.cancelDownload(surahNum),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.cloud_download, color: Color(0xFFE5C158)),
        onPressed: () => QuranDownloadService.instance.downloadSurah(surahNum, _reciter),
      );
    }
  }
}
