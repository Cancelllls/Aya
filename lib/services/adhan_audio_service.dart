import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded }

class AdhanAudioService {
  AdhanAudioService._();
  static final AdhanAudioService instance = AdhanAudioService._();

  static const Map<String, Map<String, String>> reciterUrls = {
    'mishary': {
      'fajr': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan_fajr.mp3',
      'standard': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
    },
    'abdul_basit': {
      'fajr': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan_fajr.mp3',
      'standard': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
    },
    'makkah': {
      'fajr': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan_fajr.mp3',
      'standard': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
    },
    'madinah': {
      'fajr': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan_fajr.mp3',
      'standard': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
    },
  };

  // Pre-Adhan voice files
  static const Map<String, Map<String, String>> preAdhanVoiceUrls = {
    'standard': {
      'ar': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
      'en': 'https://raw.githubusercontent.com/AalianKhan/adhans/master/adhan.mp3',
    }
  };

  final ValueNotifier<Map<String, DownloadStatus>> downloadStates = ValueNotifier({});
  AudioPlayer? _previewPlayer;

  Future<void> init() async {
    final Map<String, DownloadStatus> states = {};
    for (final reciterId in reciterUrls.keys) {
      final hasFajr = await _fileExists(reciterId, true);
      final hasStandard = await _fileExists(reciterId, false);
      states[reciterId] = (hasFajr && hasStandard) ? DownloadStatus.downloaded : DownloadStatus.notDownloaded;
    }
    final hasPreAr = await _preAdhanFileExists('ar');
    final hasPreEn = await _preAdhanFileExists('en');
    states['pre_adhan'] = (hasPreAr && hasPreEn) ? DownloadStatus.downloaded : DownloadStatus.notDownloaded;

    downloadStates.value = states;
  }

  Future<bool> _fileExists(String reciterId, bool isFajr) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _preAdhanFileExists(String lang) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pre_adhan_audio/pre_adhan_$lang.mp3');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<bool> downloadReciterAudio(String reciterId) async {
    _updateState(reciterId, DownloadStatus.downloading);
    final urls = reciterUrls[reciterId];
    if (urls == null) {
      _updateState(reciterId, DownloadStatus.notDownloaded);
      return false;
    }

    try {
      final fajrSuccess = await _downloadFile(urls['fajr']!, reciterId, true);
      final standardSuccess = await _downloadFile(urls['standard']!, reciterId, false);
      if (fajrSuccess && standardSuccess) {
        _updateState(reciterId, DownloadStatus.downloaded);
        return true;
      }
    } catch (_) {}

    _updateState(reciterId, DownloadStatus.notDownloaded);
    return false;
  }

  Future<bool> downloadPreAdhanVoice() async {
    _updateState('pre_adhan', DownloadStatus.downloading);
    try {
      final urls = preAdhanVoiceUrls['standard']!;
      final arSuccess = await _downloadPreAdhanFile(urls['ar']!, 'ar');
      final enSuccess = await _downloadPreAdhanFile(urls['en']!, 'en');
      if (arSuccess && enSuccess) {
        _updateState('pre_adhan', DownloadStatus.downloaded);
        return true;
      }
    } catch (_) {}

    _updateState('pre_adhan', DownloadStatus.notDownloaded);
    return false;
  }

  void _updateState(String id, DownloadStatus status) {
    final copy = Map<String, DownloadStatus>.from(downloadStates.value);
    copy[id] = status;
    downloadStates.value = copy;
  }

  Future<bool> _downloadFile(String url, String reciterId, bool isFajr) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3');
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _downloadPreAdhanFile(String url, String lang) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pre_adhan_audio/pre_adhan_$lang.mp3');
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> isReciterDownloaded(String reciterId) async {
    return (await _fileExists(reciterId, true)) && (await _fileExists(reciterId, false));
  }

  Future<bool> isPreAdhanDownloaded() async {
    return (await _preAdhanFileExists('ar')) && (await _preAdhanFileExists('en'));
  }

  Future<void> playPreview(String reciterId, {bool isFajr = false}) async {
    await stopPreview();
    _previewPlayer = AudioPlayer();
    
    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3';
    final localFile = File(localPath);
    if (await localFile.exists()) {
      await _previewPlayer!.play(DeviceFileSource(localPath));
    } else {
      final urls = reciterUrls[reciterId];
      if (urls != null) {
        final url = isFajr ? urls['fajr'] : urls['standard'];
        if (url != null) {
          await _previewPlayer!.play(UrlSource(url));
        }
      }
    }
  }

  Future<void> playPreAdhanPreview(String lang) async {
    await stopPreview();
    _previewPlayer = AudioPlayer();

    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/pre_adhan_audio/pre_adhan_$lang.mp3';
    final localFile = File(localPath);
    if (await localFile.exists()) {
      await _previewPlayer!.play(DeviceFileSource(localPath));
    } else {
      final urls = preAdhanVoiceUrls['standard'];
      if (urls != null) {
        final url = urls[lang];
        if (url != null) {
          await _previewPlayer!.play(UrlSource(url));
        }
      }
    }
  }

  Future<void> stopPreview() async {
    if (_previewPlayer != null) {
      try {
        await _previewPlayer!.stop();
        await _previewPlayer!.dispose();
      } catch (_) {}
      _previewPlayer = null;
    }
  }

  Future<String> getLocalPath(String reciterId, bool isFajr) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3';
  }

  Future<String> getPreAdhanLocalPath(String lang) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/pre_adhan_audio/pre_adhan_$lang.mp3';
  }
}
