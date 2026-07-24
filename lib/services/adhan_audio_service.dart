import 'package:audioplayers/audioplayers.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded }

class AdhanAudioService {
  AdhanAudioService._();
  static final AdhanAudioService instance = AdhanAudioService._();

  static const Map<String, String> fajrReciterUrls = {
    'mishary': 'adhan_fajr_meshary_al_fasy_kuwait.mp3',
    'abdul_basit': 'adhan_fajr_abdelbasset_abdessamad_egypte.mp3',
    'madinah': 'adhan_fajr_al_haram_el_madani_saoudia.mp3',
    'nurdin': 'adhan_fajr_nurdin_al_haddiwi_fajr_morocco.mp3',
  };

  static const Map<String, String> standardReciterUrls = {
    'mishary': 'adhan_meshary_al_fasy_kuwait.mp3',
    'abdul_basit': 'adhan_abdelbasset_abdessamad_egypte.mp3',
    'manssour': 'adhan_manssour_el_zahrani.mp3',
    'maghriby': 'adhan_nurdin_hamza_al_maghriby_quds.mp3',
    'kazabri': 'adhan_omar_al_kazabri_morocco.mp3',
    'riad': 'adhan_riad_al_djazairi_algeria.mp3',
    'nakshabandi': 'adhan_sayed_al_nakshabandi_egypte.mp3',
  };

  // Pre-Adhan voice files
  static const Map<String, Map<String, String>> preAdhanVoiceUrls = {
    'standard': {
      'ar': 'prayer_reminder_call.mp3',
      'en': 'prayer_reminder_call.mp3',
    },
  };

  AudioPlayer? _previewPlayer;

  Future<void> init() async {
    // No-op: files are bundled as assets
  }

  Future<bool> downloadReciterAudio(
    String reciterId, {
    bool isFajr = false,
  }) async {
    return true; // Files are bundled
  }

  Future<bool> downloadPreAdhanVoice() async {
    return true; // Files are bundled
  }

  Future<bool> isReciterDownloaded(
    String reciterId, {
    bool isFajr = false,
  }) async {
    return true; // Always available
  }

  Future<bool> isPreAdhanDownloaded() async {
    return true; // Always available
  }

  Future<void> playPreview(String reciterId, {bool isFajr = false}) async {
    await stopPreview();
    _previewPlayer = AudioPlayer();

    final filename = isFajr
        ? fajrReciterUrls[reciterId]
        : standardReciterUrls[reciterId];
    if (filename != null) {
      await _previewPlayer!.play(AssetSource('audio/adhan/$filename'));
    }
  }

  Future<void> playPreAdhanPreview(String lang) async {
    await stopPreview();
    _previewPlayer = AudioPlayer();

    final urls = preAdhanVoiceUrls['standard'];
    if (urls != null) {
      final filename = urls[lang];
      if (filename != null) {
        await _previewPlayer!.play(AssetSource('audio/adhan/$filename'));
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
    return ''; // Not needed anymore
  }

  Future<String> getPreAdhanLocalPath(String lang) async {
    return ''; // Not needed anymore
  }
}
