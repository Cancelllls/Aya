import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'storage_service.dart';

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

  final Map<int, SurahDownloadState> _downloadStates = {};
  final Map<int, http.Client> _activeClients = {};

  bool _isDownloadingAll = false;
  bool get isDownloadingAll => _isDownloadingAll;

  bool _isDownloadingText = false;
  double _textDownloadProgress = 0.0;
  bool get isDownloadingText => _isDownloadingText;
  double get textDownloadProgress => _textDownloadProgress;

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
    return '${dir.path}/quran_audio/$reciter/surah_$surahNum.mp3';
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
      final audioDir = Directory('${dir.path}/quran_audio/$reciter');
      if (!await audioDir.exists()) return 0.0;
      int totalBytes = 0;
      await for (final entity in audioDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          totalBytes += await entity.length();
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
      final audioDir = Directory('${dir.path}/quran_audio/$reciter');
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
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
      final url = ApiService.buildSurahAudioUrl(surahNum, reciter: reciter);
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

  int getDownloadedTextCount(StorageService storage) {
    int count = 0;
    for (int i = 1; i <= 114; i++) {
      final cached = storage.getString('cached_surah_${i}_details');
      final cachedQC = storage.getString('cached_surah_${i}_details_qurancom');
      if (cached.isNotEmpty || cachedQC.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  Future<void> downloadAllText(StorageService storage) async {
    if (_isDownloadingText) return;
    _isDownloadingText = true;
    _textDownloadProgress = 0.0;
    notifyListeners();

    int downloaded = 0;
    for (int i = 1; i <= 114; i++) {
      if (!_isDownloadingText) break;
      final cached = storage.getString('cached_surah_${i}_details');
      final cachedQC = storage.getString('cached_surah_${i}_details_qurancom');
      if (cached.isEmpty && cachedQC.isEmpty) {
        try {
          await ApiService.fetchSurahDetails(i);
        } catch (_) {}
      }
      downloaded++;
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
    for (int i = 1; i <= 114; i++) {
      await storage.remove('cached_surah_${i}_details');
      await storage.remove('cached_surah_${i}_details_qurancom');
    }
    _textDownloadProgress = 0.0;
    notifyListeners();
  }

  // --- Tafsir Download Logic ---
  bool _isDownloadingTafsir = false;
  double _tafsirDownloadProgress = 0.0;
  bool get isDownloadingTafsir => _isDownloadingTafsir;
  double get tafsirDownloadProgress => _tafsirDownloadProgress;

  int getDownloadedTafsirCount(StorageService storage, String tafsirEdition) {
    int count = 0;
    for (int i = 1; i <= 114; i++) {
      var cached = storage.getString('cached_tafsir_${tafsirEdition}_$i');
      if (cached.isEmpty && tafsirEdition == 'ar.muyassar') {
        cached = storage.getString('cached_tafsir_$i');
      }
      if (cached.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  Future<void> downloadAllTafsir(
    StorageService storage,
    String tafsirEdition,
  ) async {
    if (_isDownloadingTafsir) return;
    _isDownloadingTafsir = true;
    _tafsirDownloadProgress = 0.0;
    notifyListeners();

    int downloaded = 0;
    for (int i = 1; i <= 114; i++) {
      if (!_isDownloadingTafsir) break;
      var cached = storage.getString('cached_tafsir_${tafsirEdition}_$i');
      if (cached.isEmpty && tafsirEdition == 'ar.muyassar') {
        cached = storage.getString('cached_tafsir_$i');
      }
      if (cached.isEmpty) {
        try {
          final url = 'https://api.alquran.cloud/v1/surah/$i/$tafsirEdition';
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            await storage.setString(
              'cached_tafsir_${tafsirEdition}_$i',
              response.body,
            );
          }
        } catch (_) {}
      }
      downloaded++;
      _tafsirDownloadProgress = downloaded / 114.0;
      notifyListeners();
    }

    _isDownloadingTafsir = false;
    notifyListeners();
  }

  void cancelTafsirDownload() {
    _isDownloadingTafsir = false;
    notifyListeners();
  }

  Future<void> deleteAllTafsir(
    StorageService storage,
    String tafsirEdition,
  ) async {
    _isDownloadingTafsir = false;
    for (int i = 1; i <= 114; i++) {
      await storage.remove('cached_tafsir_${tafsirEdition}_$i');
      if (tafsirEdition == 'ar.muyassar') {
        await storage.remove('cached_tafsir_$i');
      }
    }
    _tafsirDownloadProgress = 0.0;
    notifyListeners();
  }
}
