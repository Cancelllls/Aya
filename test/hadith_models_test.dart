import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/hadith_models.dart';

void main() {
  group('HadithBook metadata', () {
    test('hadithBooks contains all 13 canonical collections', () {
      expect(hadithBooks.length, equals(13));
    });

    test('all hadith books have valid non-empty IDs, names, and positive counts', () {
      for (final book in hadithBooks) {
        expect(book.id, isNotEmpty);
        expect(book.nameEn, isNotEmpty);
        expect(book.nameAr, isNotEmpty);
        expect(book.totalHadiths, isPositive);
      }
    });

    test('all book IDs are unique', () {
      final ids = hadithBooks.map((b) => b.id).toSet();
      expect(ids.length, equals(hadithBooks.length));
    });

    test('primary collections (Bukhari and Muslim) are present', () {
      final bukhari = hadithBooks.firstWhere((b) => b.id == 'bukhari');
      expect(bukhari.nameEn, equals('Sahih al-Bukhari'));
      expect(bukhari.totalHadiths, equals(7563));

      final muslim = hadithBooks.firstWhere((b) => b.id == 'muslim');
      expect(muslim.nameEn, equals('Sahih Muslim'));
      expect(muslim.totalHadiths, equals(3033));
    });

    test('Musnad Ahmad is marked as arabicOnly with 26363 hadiths', () {
      final ahmad = hadithBooks.firstWhere((b) => b.id == 'ahmed');
      expect(ahmad.arabicOnly, isTrue);
      expect(ahmad.totalHadiths, equals(26363));
    });
  });
}
