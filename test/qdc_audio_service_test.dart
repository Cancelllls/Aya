import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/qdc_audio_service.dart';

void main() {
  group('QdcAudioService', () {
    test('getQdcReciterId returns valid integer IDs for supported reciters', () {
      expect(QdcAudioService.getQdcReciterId('ar.alafasy'), equals(7));
      expect(QdcAudioService.getQdcReciterId('ar.abdulbasitmurattal'), equals(2));
      expect(QdcAudioService.getQdcReciterId('ar.abdulbasitmujawwad'), equals(1));
      expect(QdcAudioService.getQdcReciterId('ar.sudais'), equals(3));
      expect(QdcAudioService.getQdcReciterId('ar.shatri'), equals(4));
      expect(QdcAudioService.getQdcReciterId('ar.rifai'), equals(5));
      expect(QdcAudioService.getQdcReciterId('ar.husary'), equals(12));
      expect(QdcAudioService.getQdcReciterId('ar.minshawi'), equals(9));
    });

    test('getQdcReciterId returns null for unknown reciters', () {
      expect(QdcAudioService.getQdcReciterId('unknown.reciter'), isNull);
    });

    test('getCanonicalReciterId resolves legacy aliases to canonical IDs', () {
      expect(
        QdcAudioService.getCanonicalReciterId('ar.abdurrahmaansudais'),
        equals('ar.sudais'),
      );
      expect(
        QdcAudioService.getCanonicalReciterId('ar.abdulsamad'),
        equals('ar.abdulbasitmurattal'),
      );
      expect(
        QdcAudioService.getCanonicalReciterId('ar.shaatree'),
        equals('ar.shatri'),
      );
      expect(
        QdcAudioService.getCanonicalReciterId('ar.hanirifai'),
        equals('ar.rifai'),
      );
      expect(
        QdcAudioService.getCanonicalReciterId('ar.muhammadayyoub'),
        equals('ar.ayyoub'),
      );
    });

    test('getCanonicalReciterId preserves already-canonical IDs unchanged', () {
      expect(
        QdcAudioService.getCanonicalReciterId('ar.alafasy'),
        equals('ar.alafasy'),
      );
      expect(
        QdcAudioService.getCanonicalReciterId('ar.husary'),
        equals('ar.husary'),
      );
    });
  });
}
