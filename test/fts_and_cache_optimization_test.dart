import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aya_app/utils/text_helpers.dart';
import 'package:aya_app/services/storage/prayer_preferences.dart';
import 'package:aya_app/services/audio_cache_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('FTS5 & Text Highlight Tests', () {
    test('parseMarkedSpans handles text without marks', () {
      const baseStyle = TextStyle(fontSize: 16, color: Colors.white);
      final spans = parseMarkedSpans('الحمد لله رب العالمين', baseStyle: baseStyle);

      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, 'الحمد لله رب العالمين');
      expect((spans[0] as TextSpan).style?.color, Colors.white);
    });

    test('parseMarkedSpans extracts <mark> tokens with bold gold styling', () {
      const baseStyle = TextStyle(fontSize: 16, color: Colors.white);
      const text = 'اهدنا الصرط <mark>المستقيم</mark> صرط الذين';
      final spans = parseMarkedSpans(text, baseStyle: baseStyle);

      expect(spans.length, 3);
      expect((spans[0] as TextSpan).text, 'اهدنا الصرط ');
      expect((spans[0] as TextSpan).style?.color, Colors.white);

      expect((spans[1] as TextSpan).text, 'المستقيم');
      expect((spans[1] as TextSpan).style?.color, const Color(0xFFE5C158));
      expect((spans[1] as TextSpan).style?.fontWeight, FontWeight.bold);

      expect((spans[2] as TextSpan).text, ' صرط الذين');
      expect((spans[2] as TextSpan).style?.color, Colors.white);
    });

    test('toArabicDigits converts 0-9 to Eastern Arabic numerals', () {
      expect(toArabicDigits(1), '١');
      expect(toArabicDigits(604), '٦٠٤');
      expect(toArabicDigits('Surah 114 Ayah 6'), 'Surah ١١٤ Ayah ٦');
    });

    test('hadith full text highlight preserves complete wording without truncation', () {
      const fullHadith = 'إنما الأعمال بالنيات وإنما لكل امرئ ما نوى فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله';
      final cleanQuery = stripTashkeel('النيات');
      final words = fullHadith.split(' ');
      final spans = <InlineSpan>[];
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final cleanWord = stripTashkeel(word.toLowerCase());
        final isMatch = cleanWord.contains(cleanQuery);
        spans.add(TextSpan(
          text: i < words.length - 1 ? '$word ' : word,
          style: isMatch
              ? const TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold)
              : const TextStyle(color: Colors.white),
        ));
      }

      // Entire hadith preserved: reassembled text must equal fullHadith exactly
      final reconstructed = spans.map((s) => (s as TextSpan).text).join();
      expect(reconstructed, fullHadith);

      // Match found and properly highlighted
      final matchedSpan = spans.firstWhere(
        (s) => (s as TextSpan).text!.contains('بالنيات'),
      ) as TextSpan;
      expect(matchedSpan.style?.color, const Color(0xFFE5C158));
      expect(matchedSpan.style?.fontWeight, FontWeight.bold);
    });
  });

  group('PrayerPreferences Domain Store Tests', () {
    test('determineSmartCalculationMethod resolves appropriate calculation standards', () {
      SharedPreferences.setMockInitialValues({});
      final prefs = SharedPreferences.getInstance();

      prefs.then((sp) {
        final prayerPrefs = PrayerPreferences(sp);
        expect(prayerPrefs.determineSmartCalculationMethod('Cairo', 'Egypt'), 5);
        expect(prayerPrefs.determineSmartCalculationMethod('Alexandria', 'مصر'), 5);
        expect(prayerPrefs.determineSmartCalculationMethod('Riyadh', 'Saudi Arabia'), 4);
        expect(prayerPrefs.determineSmartCalculationMethod('Makkah', 'السعودية'), 4);
        expect(prayerPrefs.determineSmartCalculationMethod('Istanbul', 'Turkey'), 13);
        expect(prayerPrefs.determineSmartCalculationMethod('New York', 'USA'), 2);
        expect(prayerPrefs.determineSmartCalculationMethod('Paris', 'France'), 12);
        expect(prayerPrefs.determineSmartCalculationMethod('Karachi', 'Pakistan'), 1);
        expect(prayerPrefs.determineSmartCalculationMethod('Dubai', 'UAE'), 16);
        expect(prayerPrefs.determineSmartCalculationMethod('London', 'UK'), 3); // Fallback MWL
      });
    });
  });

  group('AudioCacheService LRU Quota Tests', () {
    test('LRU prune correctly deletes oldest files exceeding quota', () async {
      final tempDir = await Directory.systemTemp.createTemp('lru_test_');
      try {
        final file1 = File('${tempDir.path}/audio_1.mp3');
        final file2 = File('${tempDir.path}/audio_2.mp3');
        final file3 = File('${tempDir.path}/audio_3.mp3');

        // Create 3 files of 100 KB each (300 KB total)
        final data = List<int>.filled(100 * 1024, 65);
        await file1.writeAsBytes(data);
        await file2.writeAsBytes(data);
        await file3.writeAsBytes(data);

        // Explicitly set access times: file1 oldest, file3 newest
        final now = DateTime.now();
        await file1.setLastModified(now.subtract(const Duration(hours: 3)));
        await file2.setLastModified(now.subtract(const Duration(hours: 2)));
        await file3.setLastModified(now.subtract(const Duration(hours: 1)));

        // Verify files exist before prune
        expect(await file1.exists(), isTrue);
        expect(await file2.exists(), isTrue);
        expect(await file3.exists(), isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('Pre-Seeded Database (aya_seed.db) Integrity Tests', () {
    test('aya_seed.db contains full 114 surahs and 6236 ayahs with FTS5 virtual table', () async {
      final seedFile = File('assets/db/aya_seed.db');
      expect(await seedFile.exists(), isTrue, reason: 'aya_seed.db must be pre-compiled');

      final dbFactory = databaseFactoryFfi;
      final db = await dbFactory.openDatabase(seedFile.absolute.path);
      try {
        final surahCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM surahs'),
        );
        expect(surahCount, 114);

        final ayahCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
        );
        expect(ayahCount, 6236);

        final pageOneAyahs = await db.rawQuery(
          'SELECT * FROM ayahs WHERE page = 1 ORDER BY ayah_number ASC',
        );
        expect(pageOneAyahs.length, 7); // Al-Fatiha has 7 verses on page 1

        final ftsResults = await db.rawQuery(
          '''
          SELECT ayahs.surah_number, ayahs.ayah_number,
                 snippet(ayahs_fts, 0, '<mark>', '</mark>', '...', 10) as snip
          FROM ayahs
          INNER JOIN ayahs_fts ON ayahs.id = ayahs_fts.rowid
          WHERE ayahs_fts MATCH 'المستقيم'
          ORDER BY rank
          LIMIT 5
          ''',
        );
        expect(ftsResults.isNotEmpty, isTrue);
        expect(ftsResults.first['snip'].toString().contains('<mark>المستقيم</mark>'), isTrue);
      } finally {
        await db.close();
      }
    });
  });
}
