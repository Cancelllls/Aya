import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/adhan_audio_service.dart';

void main() {
  group('AdhanAudioService reciters and pre-adhan assets', () {
    test('standardReciterUrls contains all 7 canonical reciters', () {
      expect(AdhanAudioService.standardReciterUrls.length, equals(7));
      expect(AdhanAudioService.standardReciterUrls.containsKey('mishary'), isTrue);
      expect(AdhanAudioService.standardReciterUrls.containsKey('abdul_basit'), isTrue);
      expect(AdhanAudioService.standardReciterUrls.containsKey('manssour'), isTrue);
      expect(AdhanAudioService.standardReciterUrls.containsKey('maghriby'), isTrue);
      expect(AdhanAudioService.standardReciterUrls.containsKey('kazabri'), isTrue);
      expect(AdhanAudioService.standardReciterUrls.containsKey('riad'), isTrue);
      expect(AdhanAudioService.standardReciterUrls.containsKey('nakshabandi'), isTrue);
    });

    test('fajrReciterUrls contains all 4 Fajr-specific reciters', () {
      expect(AdhanAudioService.fajrReciterUrls.length, equals(4));
      expect(AdhanAudioService.fajrReciterUrls.containsKey('mishary'), isTrue);
      expect(AdhanAudioService.fajrReciterUrls.containsKey('abdul_basit'), isTrue);
      expect(AdhanAudioService.fajrReciterUrls.containsKey('madinah'), isTrue);
      expect(AdhanAudioService.fajrReciterUrls.containsKey('nurdin'), isTrue);
    });

    test('preAdhanVoiceUrls contains Arabic and English reminder audio mappings', () {
      expect(AdhanAudioService.preAdhanVoiceUrls.containsKey('standard'), isTrue);
      final standard = AdhanAudioService.preAdhanVoiceUrls['standard']!;
      expect(standard['ar'], equals('prayer_reminder_call.mp3'));
      expect(standard['en'], equals('prayer_reminder_call.mp3'));
    });

    test('bundled audio verification methods return true immediately', () async {
      final service = AdhanAudioService.instance;
      expect(await service.isReciterDownloaded('mishary'), isTrue);
      expect(await service.isReciterDownloaded('mishary', isFajr: true), isTrue);
      expect(await service.isPreAdhanDownloaded(), isTrue);
      expect(await service.downloadReciterAudio('mishary'), isTrue);
    });
  });
}
