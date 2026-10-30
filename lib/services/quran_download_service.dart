import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'qdc_audio_service.dart';
import 'translation_cache_service.dart';
import '../models/quran_models.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

class SurahDownloadState {
  final int surahNum;
  final DownloadStatus status;
  final double progress;
  final String error;

  SurahDownloadState({
    required this.surahNum,
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0.0,
    this.error = '',
  });

  SurahDownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? error,
  }) {
    return SurahDownloadState(
      surahNum: surahNum,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

class QuranDownloadService extends ChangeNotifier {
  static final QuranDownloadService instance = QuranDownloadService._internal();
  QuranDownloadService._internal();

  /// Sanitizes reciter IDs (specifically URLs from mp3quran_server_*) so that
  /// directory paths on disk do not contain colons, slashes, or invalid characters.
  /// This prevents Android MediaPlayer from mistaking local file paths for remote URLs.
  static String safeReciterDir(String reciter) {
    if (reciter.startsWith('mp3quran_server_')) {
      return reciter.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    }
    return reciter;
  }

  final Map<int, SurahDownloadState> _downloadStates = {};
  final Map<int, http.Client> _activeClients = {};

  /// Cached per-reciter download counts — avoids scanning the filesystem
  /// every time the reciter picker opens.
  final Map<String, int> _countCache = {};

  int getCountForReciter(String reciterId) {
    return _countCache[reciterId] ?? 0;
  }

  Future<int> updateCountForReciter(String reciterId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeDir = safeReciterDir(reciterId);
      final reciterDir = Directory('${dir.path}/quran_audio/$safeDir');

      // Check legacy directory if safeDir differs and safe directory doesn't exist
      if (!await reciterDir.exists() && safeDir != reciterId) {
        final legacyDir = Directory('${dir.path}/quran_audio/$reciterId');
        if (await legacyDir.exists()) {
          int legacyCount = 0;
          await for (final entity in legacyDir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.mp3')) legacyCount++;
          }
          final safe = legacyCount > 114 ? 114 : legacyCount;
          _countCache[reciterId] = safe;
          return safe;
        }
      }

      if (!await reciterDir.exists()) {
        _countCache[reciterId] = 0;
        return 0;
      }
      int count = 0;
      await for (final entity in reciterDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp3')) count++;
      }
      final safe = count > 114 ? 114 : count;
      _countCache[reciterId] = safe;
      return safe;
    } catch (_) {
      _countCache[reciterId] = 0;
      return 0;
    }
  }

  void invalidateCountCache() => _countCache.clear();

  bool _isDownloadingAll = false;
  bool get isDownloadingAll => _isDownloadingAll;

  bool _isDownloadingText = false;
  double _textDownloadProgress = 0.0;
  int _downloadedTextCount = 0;
  int _downloadedTafsirCount = 0;

  bool get isDownloadingText => _isDownloadingText;
  double get textDownloadProgress => _textDownloadProgress;
  int get downloadedTextCount => _downloadedTextCount;
  int get downloadedTafsirCount => _downloadedTafsirCount;

  Map<int, SurahDownloadState> get downloadStates => _downloadStates;

  Future<void> initStates(String reciter) async {
    for (int i = 1; i <= 114; i++) {
      final downloaded = await isSurahDownloaded(i, reciter);
      _downloadStates[i] = SurahDownloadState(
        surahNum: i,
        status: downloaded
            ? DownloadStatus.downloaded
            : DownloadStatus.notDownloaded,
        progress: downloaded ? 1.0 : 0.0,
      );
    }
    notifyListeners();
  }

  SurahDownloadState getState(int surahNum) {
    return _downloadStates[surahNum] ?? SurahDownloadState(surahNum: surahNum);
  }

  Future<String> getLocalSurahPath(int surahNum, String reciter) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = QdcAudioService.getQdcReciterId(reciter) != null
        ? 'surah_${surahNum}_qdc_v2.mp3'
        : 'surah_$surahNum.mp3';
    final safeDir = safeReciterDir(reciter);
    final targetPath = '${dir.path}/quran_audio/$safeDir/$fileName';

    // Legacy migration: if file exists at legacy path with colons/slashes, migrate to safe path
    if (safeDir != reciter) {
      final legacyPath = '${dir.path}/quran_audio/$reciter/$fileName';
      final legacyFile = File(legacyPath);
      if (await legacyFile.exists() && !await File(targetPath).exists()) {
        try {
          await File(targetPath).parent.create(recursive: true);
          await legacyFile.rename(targetPath);
        } catch (_) {}
      }
    }

    return targetPath;
  }

  Future<bool> isSurahDownloaded(int surahNum, String reciter) async {
    final path = await getLocalSurahPath(surahNum, reciter);
    return File(path).exists();
  }

  Future<double> getSurahSizeMB(int surahNum, String reciter) async {
    try {
      final path = await getLocalSurahPath(surahNum, reciter);
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024);
      }
    } catch (_) {}
    return 0.0;
  }

  Future<double> getTotalSpaceMB(String reciter) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeDir = safeReciterDir(reciter);
      final audioDir = Directory('${dir.path}/quran_audio/$safeDir');
      int totalBytes = 0;
      if (await audioDir.exists()) {
        await for (final entity in audioDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.mp3')) {
            totalBytes += await entity.length();
          }
        }
      }
      if (safeDir != reciter) {
        final legacyDir = Directory('${dir.path}/quran_audio/$reciter');
        if (await legacyDir.exists()) {
          await for (final entity in legacyDir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.mp3')) {
              totalBytes += await entity.length();
            }
          }
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> deleteSurah(int surahNum, String reciter) async {
    try {
      final path = await getLocalSurahPath(surahNum, reciter);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _countCache.remove(reciter);
      _downloadStates[surahNum] = SurahDownloadState(
        surahNum: surahNum,
        status: DownloadStatus.notDownloaded,
        progress: 0.0,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteReciterCache(String reciter) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeDir = safeReciterDir(reciter);
      final audioDir = Directory('${dir.path}/quran_audio/$safeDir');
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
      if (safeDir != reciter) {
        final legacyDir = Directory('${dir.path}/quran_audio/$reciter');
        if (await legacyDir.exists()) {
          await legacyDir.delete(recursive: true);
        }
      }
      _countCache.remove(reciter);
      await initStates(reciter);
    } catch (_) {}
  }

  Future<void> downloadSurah(int surahNum, String reciter) async {
    final client = http.Client();
    _activeClients[surahNum] = client;
    _downloadStates[surahNum] = SurahDownloadState(
      surahNum: surahNum,
      status: DownloadStatus.downloading,
      progress: 0.0,
    );
    notifyListeners();

    try {
      String url = ApiService.buildSurahAudioUrl(surahNum, reciter: reciter);
      if (QdcAudioService.getQdcReciterId(reciter) != null) {
        await QdcAudioService.fetchSurahTimestamps(surahNum, reciter);
        final qdcUrl = await QdcAudioService.getAudioUrl(surahNum, reciter);
        if (qdcUrl != null) {
          url = qdcUrl;
        }
      }
      final localPath = await getLocalSurahPath(surahNum, reciter);
      final tempPath = '$localPath.tmp';

      final tempFile = File(tempPath);
      await tempFile.parent.create(recursive: true);

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int downloaded = 0;
        final sink = tempFile.openWrite();

        await response.stream
            .listen(
              (chunk) {
                sink.add(chunk);
                downloaded += chunk.length;
                if (contentLength > 0) {
                  final double p = (downloaded / contentLength).clamp(
                    0.0,
                    0.99,
                  );
                  _downloadStates[surahNum] = SurahDownloadState(
                    surahNum: surahNum,
                    status: DownloadStatus.downloading,
                    progress: p,
                  );
                  notifyListeners();
                }
              },
              onError: (e) {
                throw e;
              },
              cancelOnError: true,
            )
            .asFuture();

        await sink.flush();
        await sink.close();

        if (await tempFile.exists()) {
          await tempFile.rename(localPath);
        }

        // Cache timestamps for offline syncing if supported
        try {
          await QdcAudioService.fetchSurahTimestamps(surahNum, reciter);
        } catch (_) {}

        _downloadStates[surahNum] = SurahDownloadState(
          surahNum: surahNum,
          status: DownloadStatus.downloaded,
          progress: 1.0,
        );
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      try {
        final localPath = await getLocalSurahPath(surahNum, reciter);
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
        final tempFile = File('$localPath.tmp');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      if (_downloadStates[surahNum]?.status != DownloadStatus.notDownloaded) {
        _downloadStates[surahNum] = SurahDownloadState(
          surahNum: surahNum,
          status: DownloadStatus.error,
          progress: 0.0,
          error: e.toString(),
        );
      }
    } finally {
      client.close();
      _activeClients.remove(surahNum);
      notifyListeners();
    }
  }

  void cancelDownload(int surahNum) {
    final client = _activeClients[surahNum];
    if (client != null) {
      _activeClients.remove(surahNum);
      _downloadStates[surahNum] = SurahDownloadState(
        surahNum: surahNum,
        status: DownloadStatus.notDownloaded,
        progress: 0.0,
      );
      client.close();
      notifyListeners();
    }
  }

  Future<void> downloadAll(String reciter) async {
    _isDownloadingAll = true;
    notifyListeners();

    for (int i = 1; i <= 114; i++) {
      if (!_isDownloadingAll) break;
      final state = getState(i);
      if (state.status == DownloadStatus.notDownloaded ||
          state.status == DownloadStatus.error) {
        await downloadSurah(i, reciter);
      }
    }

    _isDownloadingAll = false;
    notifyListeners();
  }

  void cancelAll() {
    _isDownloadingAll = false;
    final keys = List<int>.from(_activeClients.keys);
    for (var key in keys) {
      cancelDownload(key);
    }
    notifyListeners();
  }

  Future<void> calculateCounts(StorageService storage) async {
    final dir = await getApplicationDocumentsDirectory();
    final tafsirEdition = storage.getString(
      'tafsir_edition',
      defaultValue: 'ar.muyassar',
    );
    int textCount = 0;
    int tafsirCount = 0;
    for (int i = 1; i <= 114; i++) {
      if (File(
            '${dir.path}/cached_surah_${i}_details_$tafsirEdition.json',
          ).existsSync() ||
          File(
            '${dir.path}/cached_surah_${i}_details_qurancom.json',
          ).existsSync()) {
        textCount++;
      }
      if (File(
            '${dir.path}/cached_tafsir_${tafsirEdition}_$i.json',
          ).existsSync() ||
          File('${dir.path}/cached_tafsir_$i.json').existsSync()) {
        tafsirCount++;
      }
    }
    _downloadedTextCount = textCount;
    _downloadedTafsirCount = tafsirCount;
    notifyListeners();
  }

  Future<void> downloadAllText(StorageService storage) async {
    if (_isDownloadingText) return;
    _isDownloadingText = true;
    _textDownloadProgress = 0.0;
    notifyListeners();

    int downloaded = 0;
    final tafsirEdition = storage.getString(
      'tafsir_edition',
      defaultValue: 'ar.muyassar',
    );
    for (int i = 1; i <= 114; i++) {
      if (!_isDownloadingText) break;
      final dir = await getApplicationDocumentsDirectory();
      bool hasCache =
          File(
            '${dir.path}/cached_surah_${i}_details_$tafsirEdition.json',
          ).existsSync() ||
          File(
            '${dir.path}/cached_surah_${i}_details_qurancom.json',
          ).existsSync();
      if (!hasCache) {
        try {
          await ApiService.fetchSurahDetails(i, tafsirEdition: tafsirEdition);
        } catch (_) {}
      }
      downloaded++;
      _downloadedTextCount = downloaded;
      _textDownloadProgress = downloaded / 114.0;
      notifyListeners();
    }

    _isDownloadingText = false;
    notifyListeners();
  }

  void cancelTextDownload() {
    _isDownloadingText = false;
    notifyListeners();
  }

  Future<void> deleteAllText(StorageService storage) async {
    _isDownloadingText = false;
    final tafsirEdition = storage.getString(
      'tafsir_edition',
      defaultValue: 'ar.muyassar',
    );
    final dir = await getApplicationDocumentsDirectory();
    for (int i = 1; i <= 114; i++) {
      final f1 = File(
        '${dir.path}/cached_surah_${i}_details_$tafsirEdition.json',
      );
      if (f1.existsSync()) f1.deleteSync();
      final f2 = File('${dir.path}/cached_surah_${i}_details_qurancom.json');
      if (f2.existsSync()) f2.deleteSync();
    }
    _downloadedTextCount = 0;
    _textDownloadProgress = 0.0;
    notifyListeners();
  }

  // --- Tafsir Download Logic ---
  bool _isDownloadingTafsir = false;
  double _tafsirDownloadProgress = 0.0;
  String? _downloadingTafsirEdition;
  bool get isDownloadingTafsir => _isDownloadingTafsir;
  double get tafsirDownloadProgress => _tafsirDownloadProgress;
  String? get downloadingTafsirEdition => _downloadingTafsirEdition;

  Future<void> downloadAllTafsir(
    StorageService storage,
    String tafsirEdition,
  ) async {
    final edition = availableTafsirs.firstWhere(
      (e) => e.identifier == tafsirEdition,
      orElse: () => TafsirEdition(tafsirEdition, '', '', '', isBundled: false),
    );
    if (edition.isBundled || tafsirEdition == 'ar.muyassar') {
      _isDownloadingTafsir = false;
      _downloadingTafsirEdition = null;
      _tafsirDownloadProgress = 1.0;
      notifyListeners();
      return;
    }
    _isDownloadingTafsir = true;
    _downloadingTafsirEdition = tafsirEdition;
    _tafsirDownloadProgress = 0.0;
    notifyListeners();

    try {
      await ApiService.downloadFullTafsirEdition(
        tafsirEdition,
        onProgress: (p) {
          if (!_isDownloadingTafsir) return;
          _tafsirDownloadProgress = p;
          notifyListeners();
        },
        isCancelled: () => !_isDownloadingTafsir,
      );
    } catch (_) {}

    _isDownloadingTafsir = false;
    _downloadingTafsirEdition = null;
    _tafsirDownloadProgress = 1.0;
    notifyListeners();
  }

  void cancelTafsirDownload() {
    _isDownloadingTafsir = false;
    _downloadingTafsirEdition = null;
    _tafsirDownloadProgress = 0.0;
    notifyListeners();
  }

  Future<int> getTafsirCountForEdition(String tafsirEdition) async {
    final edition = availableTafsirs.firstWhere(
      (e) => e.identifier == tafsirEdition,
      orElse: () => TafsirEdition(tafsirEdition, '', '', '', isBundled: false),
    );
    if (edition.isBundled || tafsirEdition == 'ar.muyassar') {
      return 114;
    }
    try {
      final db = await DatabaseService.getInstance();
      final downloaded = await db.isTafsirEditionDownloaded(tafsirEdition);
      return downloaded ? 114 : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteAllTafsir(
    StorageService storage,
    String tafsirEdition,
  ) async {
    final edition = availableTafsirs.firstWhere(
      (e) => e.identifier == tafsirEdition,
      orElse: () => TafsirEdition(tafsirEdition, '', '', '', isBundled: false),
    );
    if (!edition.isBundled && tafsirEdition != 'ar.muyassar') {
      try {
        final db = await DatabaseService.getInstance();
        await db.deleteTafsirEdition(tafsirEdition);
      } catch (_) {}
    }
    _isDownloadingTafsir = false;
    _downloadingTafsirEdition = null;
    _tafsirDownloadProgress = 0.0;
    notifyListeners();
  }

  // --- Translation Download Logic ---
  bool _isDownloadingTranslation = false;
  double _translationDownloadProgress = 0.0;
  String? _downloadingTranslationEdition;
  bool get isDownloadingTranslation => _isDownloadingTranslation;
  double get translationDownloadProgress => _translationDownloadProgress;
  String? get downloadingTranslationEdition => _downloadingTranslationEdition;

  Future<void> downloadAllTranslation(
    StorageService storage,
    String translationEdition,
  ) async {
    if (translationEdition == 'en.sahih') {
      _isDownloadingTranslation = false;
      _translationDownloadProgress = 1.0;
      notifyListeners();
      return;
    }
    _isDownloadingTranslation = true;
    _downloadingTranslationEdition = translationEdition;
    _translationDownloadProgress = 0.0;
    notifyListeners();

    try {
      await TranslationCacheService.instance.downloadFromCdn(
        translationEdition,
        onProgress: (p) {
          if (!_isDownloadingTranslation) return;
          _translationDownloadProgress = p;
          notifyListeners();
        },
        isCancelled: () => !_isDownloadingTranslation,
      );
    } catch (_) {}

    _isDownloadingTranslation = false;
    _downloadingTranslationEdition = null;
    _translationDownloadProgress = 1.0;
    notifyListeners();
  }

  void cancelTranslationDownload() {
    _isDownloadingTranslation = false;
    _downloadingTranslationEdition = null;
    _translationDownloadProgress = 0.0;
    notifyListeners();
  }

  Future<int> getTranslationCountForEdition(String translationEdition) async {
    if (translationEdition == 'en.sahih') {
      return 6236;
    }
    try {
      final db = await DatabaseService.getInstance();
      final downloaded =
          await db.isTranslationEditionDownloaded(translationEdition);
      return downloaded ? 6236 : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteTranslation(
    StorageService storage,
    String translationEdition,
  ) async {
    if (translationEdition != 'en.sahih') {
      try {
        final db = await DatabaseService.getInstance();
        await db.deleteTranslationEdition(translationEdition);
      } catch (_) {}
    }
    _isDownloadingTranslation = false;
    _translationDownloadProgress = 0.0;
    _downloadingTranslationEdition = null;
    notifyListeners();
  }
}
