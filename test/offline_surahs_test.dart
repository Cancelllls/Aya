import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/offline_surahs.dart';

void main() {
  group('allOfflineSurahs', () {
    test('contains all 114 surahs', () {
      expect(allOfflineSurahs, hasLength(114));
    });

    test('surahs are in order 1-114', () {
      for (int i = 0; i < 114; i++) {
        expect(allOfflineSurahs[i].number, i + 1);
      }
    });

    test('every surah has required fields', () {
      for (final s in allOfflineSurahs) {
        expect(s.name, isNotEmpty);
        expect(s.englishName, isNotEmpty);
        expect(s.numberOfAyahs, greaterThan(0));
        expect(s.revelationType, anyOf('Meccan', 'Medinan'));
      }
    });

    test('ayah counts are realistic', () {
      expect(allOfflineSurahs[0].numberOfAyahs, 7); // 1. Al-Fatiha
      expect(allOfflineSurahs[1].numberOfAyahs, 286); // 2. Al-Baqarah
      expect(allOfflineSurahs[35].numberOfAyahs, 83); // 36. Ya-Sin
      expect(allOfflineSurahs[111].numberOfAyahs, 4); // 112. Al-Ikhlas
      expect(allOfflineSurahs[113].numberOfAyahs, 6); // 114. An-Nas
    });

    test('Al-Fatiha is Meccan', () {
      expect(allOfflineSurahs[0].revelationType, 'Meccan');
    });

    test('Al-Baqarah is Medinan', () {
      expect(allOfflineSurahs[1].revelationType, 'Medinan');
    });
  });
}
