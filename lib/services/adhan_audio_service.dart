import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded }

class AdhanAudioService {
  AdhanAudioService._();
  static final AdhanAudioService instance = AdhanAudioService._();

  static const String _fpBase =
      'https://raw.githubusercontent.com/Five-Prayers/five-prayers-android/main/app/src/main/res/raw';

  static const Map<String, String> fajrReciterUrls = {
    'mishary': '$_fpBase/adhan_fajr_meshary_al_fasy_kuwait.mp3',
    'abdul_basit': '$_fpBase/adhan_fajr_abdelbasset_abdessamad_egypte.mp3',
    'madinah': '$_fpBase/adhan_fajr_al_haram_el_madani_saoudia.mp3',
    'nurdin': '$_fpBase/adhan_fajr_nurdin_al_haddiwi_fajr_morocco.mp3',
  };

  static const Map<String, String> standardReciterUrls = {
    'mishary': '$_fpBase/adhan_meshary_al_fasy_kuwait.mp3',
    'abdul_basit': '$_fpBase/adhan_abdelbasset_abdessamad_egypte.mp3',
    'manssour': '$_fpBase/adhan_manssour_el_zahrani.mp3',
    'maghriby': '$_fpBase/adhan_nurdin_hamza_al_maghriby_quds.mp3',
    'kazabri': '$_fpBase/adhan_omar_al_kazabri_morocco.mp3',
    'riad': '$_fpBase/adhan_riad_al_djazairi_algeria.mp3',
    'nakshabandi': '$_fpBase/adhan_sayed_al_nakshabandi_egypte.mp3',
  };

  // Pre-Adhan voice files
  static const Map<String, Map<String, String>> preAdhanVoiceUrls = {
    'standard': {
      'ar': '$_fpBase/prayer_reminder_call.mp3',
      'en': '$_fpBase/prayer_reminder_call.mp3',
    },
  };

  final ValueNotifier<Map<String, DownloadStatus>> downloadStates =
      ValueNotifier({});
  AudioPlayer? _previewPlayer;

  Future<void> init() async {
    final Map<String, DownloadStatus> states = {};
    for (final reciterId in fajrReciterUrls.keys) {
      final hasFajr = await _fileExists(reciterId, true);
      states['fajr_$reciterId'] = hasFajr
          ? DownloadStatus.downloaded
          : DownloadStatus.notDownloaded;
    }
    for (final reciterId in standardReciterUrls.keys) {
      final hasStandard = await _fileExists(reciterId, false);
      states['standard_$reciterId'] = hasStandard
          ? DownloadStatus.downloaded
          : DownloadStatus.notDownloaded;
    }
    final hasPreAr = await _preAdhanFileExists('ar');
    final hasPreEn = await _preAdhanFileExists('en');
    states['pre_adhan'] = (hasPreAr && hasPreEn)
        ? DownloadStatus.downloaded
        : DownloadStatus.notDownloaded;

    downloadStates.value = states;
  }

  Future<bool> _fileExists(String reciterId, bool isFajr) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3',
      );
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _preAdhanFileExists(String lang) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pre_adhan_audio/pre_adhan_${lang}_v2.mp3');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<bool> downloadReciterAudio(
    String reciterId, {
    bool isFajr = false,
  }) async {
    final stateKey = isFajr ? 'fajr_$reciterId' : 'standard_$reciterId';
    _updateState(stateKey, DownloadStatus.downloading);
    final url = isFajr
        ? fajrReciterUrls[reciterId]
        : standardReciterUrls[reciterId];
    if (url == null) {
      _updateState(stateKey, DownloadStatus.notDownloaded);
      return false;
    }

    try {
      final success = await _downloadFile(url, reciterId, isFajr);
      if (success) {
        _updateState(stateKey, DownloadStatus.downloaded);
        return true;
      }
    } catch (_) {}

    _updateState(stateKey, DownloadStatus.notDownloaded);
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
      final file = File(
        '${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3',
      );
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
      final file = File('${dir.path}/pre_adhan_audio/pre_adhan_${lang}_v2.mp3');
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

  Future<bool> isReciterDownloaded(
    String reciterId, {
    bool isFajr = false,
  }) async {
    return await _fileExists(reciterId, isFajr);
  }

  Future<bool> isPreAdhanDownloaded() async {
    return (await _preAdhanFileExists('ar')) &&
        (await _preAdhanFileExists('en'));
  }

  Future<void> playPreview(String reciterId, {bool isFajr = false}) async {
    await stopPreview();
    _previewPlayer = AudioPlayer();

    final dir = await getApplicationDocumentsDirectory();
    final localPath =
        '${dir.path}/adhan_audio/${reciterId}_${isFajr ? 'fajr' : 'standard'}.mp3';
    final localFile = File(localPath);
    if (await localFile.exists()) {
      await _previewPlayer!.play(DeviceFileSource(localPath));
    } else {
      final url = isFajr
          ? fajrReciterUrls[reciterId]
          : standardReciterUrls[reciterId];
      if (url != null) {
        await _previewPlayer!.play(UrlSource(url));
      }
    }
  }

  Future<void> playPreAdhanPreview(String lang) async {
    await stopPreview();
    _previewPlayer = AudioPlayer();

    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/pre_adhan_audio/pre_adhan_${lang}_v2.mp3';
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
    return '${dir.path}/pre_adhan_audio/pre_adhan_${lang}_v2.mp3';
  }
}
