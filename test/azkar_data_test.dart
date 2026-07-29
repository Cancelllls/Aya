import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/azkar_data.dart';

void main() {
  group('AzkarData', () {
    test('all categories are non-empty', () {
      for (final list in AzkarData.allCategories) {
        expect(list, isNotEmpty);
      }
    });

    test('morning azkar contains 12 items', () {
      expect(AzkarData.morning, hasLength(12));
    });

    test('evening azkar contains 12 items', () {
      expect(AzkarData.evening, hasLength(12));
    });

    test('post-prayer azkar contains 8 items', () {
      expect(AzkarData.postPrayer, hasLength(8));
    });

    test('daily azkar contains 2 items', () {
      expect(AzkarData.daily, hasLength(2));
    });

    test('sleep/waking azkar contains 6 items', () {
      expect(AzkarData.sleepWaking, hasLength(6));
    });

    test('salah-specific azkar contains 8 items', () {
      expect(AzkarData.salahSpecific, hasLength(8));
    });

    test('life events azkar contains 9 items', () {
      expect(AzkarData.lifeEvents, hasLength(9));
    });

    test('protection/ruqyah contains 7 items', () {
      expect(AzkarData.protectionRuqyah, hasLength(7));
    });

    test('forgiveness/tawbah contains 10 items', () {
      expect(AzkarData.forgivenessTawbah, hasLength(10));
    });

    test('every item has arabic text', () {
      for (final list in AzkarData.allCategories) {
        for (final item in list) {
          expect(item.arabic, isNotEmpty, reason: '${item.id} missing arabic');
        }
      }
    });

    test('every item has unique id', () {
      final ids = <String>{};
      for (final list in AzkarData.allCategories) {
        for (final item in list) {
          expect(ids.contains(item.id), isFalse, reason: 'Duplicate id: ${item.id}');
          ids.add(item.id);
        }
      }
    });

    test('every item has count > 0', () {
      for (final list in AzkarData.allCategories) {
        for (final item in list) {
          expect(item.count, greaterThan(0), reason: '${item.id} has count <= 0');
        }
      }
    });

    test('every item has a reference', () {
      for (final list in AzkarData.allCategories) {
        for (final item in list) {
          expect(item.reference, isNotEmpty, reason: '${item.id} missing reference');
        }
      }
    });

    test('all 9 categories in allCategories', () {
      expect(AzkarData.allCategories, hasLength(9));
    });
  });

  group('NamesOfAllahData', () {
    test('contains exactly 99 names', () {
      expect(NamesOfAllahData.names, hasLength(99));
    });

    test('names are sequentially numbered 1-99', () {
      for (int i = 0; i < 99; i++) {
        expect(NamesOfAllahData.names[i].number, i + 1);
      }
    });

    test('every name has arabic and translation', () {
      for (final name in NamesOfAllahData.names) {
        expect(name.arabic, isNotEmpty);
        expect(name.transliteration, isNotEmpty);
        expect(name.translation, isNotEmpty);
      }
    });
  });
}
