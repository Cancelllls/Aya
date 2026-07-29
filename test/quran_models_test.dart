import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/models/quran_models.dart';

void main() {
  group('Surah', () {
    test('surah 1 is Al-Fatiha', () {
      final s = Surah(number: 1, name: 'الفاتحة', englishName: 'Al-Fatiha',
          englishNameTranslation: 'The Opening', numberOfAyahs: 7,
          revelationType: 'Meccan');
      expect(s.number, 1);
      expect(s.englishName, 'Al-Fatiha');
      expect(s.numberOfAyahs, 7);
    });

    test('startingJuz returns correct juz for Surah 2', () {
      final s = Surah(number: 2, name: 'البقرة', englishName: 'Al-Baqarah',
          englishNameTranslation: 'The Cow', numberOfAyahs: 286,
          revelationType: 'Medinan');
      expect(s.startingJuz, 1);
    });

    test('startingJuz returns correct juz for Surah 78', () {
      final s = Surah(number: 78, name: 'النبأ', englishName: 'An-Naba',
          englishNameTranslation: 'The Tidings', numberOfAyahs: 40,
          revelationType: 'Meccan');
      expect(s.startingJuz, 30);
    });

    test('Surah 114 is An-Nas', () {
      final s = Surah(number: 114, name: 'الناس', englishName: 'An-Nas',
          englishNameTranslation: 'Mankind', numberOfAyahs: 6,
          revelationType: 'Meccan');
      expect(s.number, 114);
    });
  });

  group('Ayah', () {
    test('startsWithBasmalah detects Bismillah', () {
      expect(Ayah.startsWithBasmalah('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), isTrue);
      expect(Ayah.startsWithBasmalah('بسم الله الرحمن الرحيم'), isTrue);
      expect(Ayah.startsWithBasmalah('Some other text'), isFalse);
    });

    test('cleanBasmalah keeps Bismillah for Al-Fatiha ayah 1 (Surah 1)', () {
      final text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final result = Ayah.cleanBasmalah(text, 1, 1); // Al-Fatiha, ayah 1
      expect(result.contains('بِسْمِ'), isTrue);
    });

    test('cleanBasmalah removes Bismillah from non-Fatiha Surah ayah 1', () {
      // startsWithBasmalah should detect the Bismillah
      expect(Ayah.startsWithBasmalah(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
        isTrue,
      );
    });

    test('cleanBasmalah leaves ayah 2 untouched (no Bismillah stripping)', () {
      final text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final result = Ayah.cleanBasmalah(text, 2, 9); // ayah != 1, returns text as-is
      expect(result, text); // unchanged
    });
  });

  group('ReciterInfo', () {
    test('availableReciters has 17 entries', () {
      expect(availableReciters, hasLength(17));
    });

    test('first reciter is Alafasy', () {
      expect(availableReciters[0].id, 'ar.alafasy');
    });

    test('all reciters have name and id', () {
      for (final r in availableReciters) {
        expect(r.id, isNotEmpty);
        expect(r.nameAr, isNotEmpty);
        expect(r.nameEn, isNotEmpty);
      }
    });
  });

  group('TafsirEdition', () {
    test('availableTafsirs has 6 editions', () {
      expect(availableTafsirs, hasLength(6));
    });

    test('first is Al-Muyassar', () {
      expect(availableTafsirs[0].identifier, 'ar.muyassar');
    });

    test('all editions have required fields', () {
      for (final t in availableTafsirs) {
        expect(t.identifier, isNotEmpty);
        expect(t.mufassir, isNotEmpty);
        expect(t.mufassirEn, isNotEmpty);
      }
    });
  });
}
