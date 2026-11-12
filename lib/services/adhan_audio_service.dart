import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

class AdhanAudioService {
  AdhanAudioService._();
  static final AdhanAudioService instance = AdhanAudioService._();

  static const Map<String, String> fajrReciterUrls = {
    'mishary': 'adhan_fajr_meshary_al_fasy_kuwait.mp3',
    'abdul_basit': 'adhan_fajr_abdelbasset_abdessamad_egypte.mp3',
    'manssour': 'adhan_fajr_manssour_el_zahrani.mp3',
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
  StreamSubscription<void>? _completeSub;

  Future<void> _playAsset(
    String assetPath, {
    VoidCallback? onComplete,
  }) async {
    await stopPreview();
    final player = AudioPlayer();
    _previewPlayer = player;
    _completeSub = player.onPlayerComplete.listen((_) {
      if (_previewPlayer == player) {
        onComplete?.call();
      }
    });
    await player.play(AssetSource(assetPath));
  }

  Future<void> playPreview(
    String reciterId, {
    bool isFajr = false,
    VoidCallback? onComplete,
  }) async {
    final map = isFajr ? fajrReciterUrls : standardReciterUrls;
    final filename =
        map[reciterId] ??
        (isFajr
            ? 'adhan_fajr_meshary_al_fasy_kuwait.mp3'
            : 'adhan_meshary_al_fasy_kuwait.mp3');
    await _playAsset('audio/adhan/$filename', onComplete: onComplete);
  }

  Future<void> playNotificationTonePreview(
    String tone, {
    VoidCallback? onComplete,
  }) async {
    if (tone == 'system') {
      await stopPreview();
      return; // System sound cannot be played via asset
    }
    String assetPath;
    switch (tone) {
      case 'takbeer':
        assetPath = 'audio/adhan/adhan_meshary_al_fasy_kuwait.mp3';
        break;
      case 'salati':
        assetPath = 'audio/adhan/pre_adhan_ela_salati.mp3';
        break;
      case 'call':
      case 'chime':
      default:
        assetPath = 'audio/adhan/prayer_reminder_call.mp3';
        break;
    }
    await _playAsset(assetPath, onComplete: onComplete);
  }

  Future<void> stopPreview() async {
    await _completeSub?.cancel();
    _completeSub = null;
    if (_previewPlayer != null) {
      try {
        await _previewPlayer!.stop();
        await _previewPlayer!.dispose();
      } catch (_) {}
      _previewPlayer = null;
    }
  }

  /// Resolves the effective reciter ID, treating null or empty overrides as unset.
  static String resolveReciterId({
    required bool isFajr,
    String? customReciter,
    String? defaultReciter,
  }) {
    if (isFajr) {
      return (customReciter != null && customReciter.isNotEmpty)
          ? customReciter
          : 'mishary';
    }
    if (customReciter != null && customReciter.isNotEmpty) {
      return customReciter;
    }
    return (defaultReciter != null && defaultReciter.isNotEmpty)
        ? defaultReciter
        : 'mishary';
  }
}
