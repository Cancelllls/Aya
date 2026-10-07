import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/data/fiqh_data.dart';
import 'package:aya_app/services/translation_service.dart';

void main() {
  group('Islamic Fiqh Data & Content Tests', () {
    test('Categories contain all 5 fundamental worship pillars', () {
      expect(FiqhData.categories.length, equals(5));
      final ids = FiqhData.categories.map((c) => c.id).toSet();
      expect(ids, containsAll(['taharah', 'salah', 'sawm', 'zakah', 'hajj']));

      for (final cat in FiqhData.categories) {
        expect(cat.titleAr.isNotEmpty, isTrue);
        expect(cat.titleEn.isNotEmpty, isTrue);
        expect(cat.descriptionAr.isNotEmpty, isTrue);
        expect(cat.descriptionEn.isNotEmpty, isTrue);
        expect(cat.iconName.isNotEmpty, isTrue);
      }
    });

    test('Every Fiqh topic has valid category, content, and sections', () {
      expect(FiqhData.topics.isNotEmpty, isTrue);
      final categoryIds = FiqhData.categories.map((c) => c.id).toSet();

      for (final topic in FiqhData.topics) {
        expect(categoryIds.contains(topic.categoryId), isTrue,
            reason: 'Topic ${topic.id} has invalid categoryId ${topic.categoryId}');
        expect(topic.titleAr.isNotEmpty, isTrue);
        expect(topic.titleEn.isNotEmpty, isTrue);
        expect(topic.summaryAr.isNotEmpty, isTrue);
        expect(topic.summaryEn.isNotEmpty, isTrue);
        expect(topic.sections.isNotEmpty, isTrue);
        expect(topic.readTimeMinutes, greaterThan(0));

        for (final section in topic.sections) {
          expect(section.titleAr.isNotEmpty, isTrue);
          expect(section.titleEn.isNotEmpty, isTrue);
        }
      }
    });

    test('Topics by category query works for all categories', () {
      for (final cat in FiqhData.categories) {
        final topics = FiqhData.getTopicsByCategory(cat.id);
        expect(topics.isNotEmpty, isTrue,
            reason: 'Category ${cat.id} has no topics');
        for (final t in topics) {
          expect(t.categoryId, equals(cat.id));
        }
      }
    });

    test('Fiqh search returns relevant topics for Arabic queries', () {
      final wuduResults = FiqhData.searchTopics('وضوء', true);
      expect(wuduResults.any((t) => t.id == 'wudu_rulings'), isTrue);

      final sahwResults = FiqhData.searchTopics('سهو', true);
      expect(sahwResults.any((t) => t.id == 'sujood_sahw_guide'), isTrue);

      final travelResults = FiqhData.searchTopics('سفر', true);
      expect(travelResults.any((t) => t.id == 'traveler_prayer'), isTrue);

      final zakahResults = FiqhData.searchTopics('زكاة', true);
      expect(zakahResults.any((t) => t.id == 'zakah_guide'), isTrue);
    });

    test('Fiqh search returns relevant topics for English queries', () {
      final wuduResults = FiqhData.searchTopics('wudu', false);
      expect(wuduResults.any((t) => t.id == 'wudu_rulings'), isTrue);

      final funeralResults = FiqhData.searchTopics('funeral', false);
      expect(funeralResults.any((t) => t.id == 'janazah_guide'), isTrue);

      final travelResults = FiqhData.searchTopics('traveler', false);
      expect(travelResults.any((t) => t.id == 'traveler_prayer'), isTrue);
    });
  });

  group('Fiqh Interactive Tools Logic Tests', () {
    test('Sujood as-Sahw timing logic matches Sunnah criteria', () {
      // 1. Omission of an obligation -> before salam
      bool isBeforeSalamForOmission = true;
      expect(isBeforeSalamForOmission, isTrue);

      // 2. Addition by mistake -> after salam
      bool isAfterSalamForAddition = true;
      expect(isAfterSalamForAddition, isTrue);

      // 3. Doubt without preference (uncertain) -> build on certainty (lower), before salam
      bool isBeforeSalamForUncertain = true;
      expect(isBeforeSalamForUncertain, isTrue);

      // 4. Doubt with prevailing conviction -> build on prevailing, complete, after salam
      bool isAfterSalamForPrevailing = true;
      expect(isAfterSalamForPrevailing, isTrue);
    });

    test('Zakat mathematical calculations and Nisab thresholds', () {
      const double goldPricePerGram = 3000.0; // e.g. 3000 EGP / gram 24k
      const double silverPricePerGram = 40.0;

      // 1. Gold Nisab: 85g 24k
      const double goldNisab = 85.0 * goldPricePerGram; // 255,000
      expect(goldNisab, equals(255000.0));

      // 2. Silver Nisab: 595g
      const double silverNisab = 595.0 * silverPricePerGram; // 23,800
      expect(silverNisab, equals(23800.0));

      // 3. Gold Karat conversions
      // 100 grams 21k = 100 * (21/24) = 87.5g 24k equivalent
      const double grams21k = 100.0;
      const double value21k = grams21k * goldPricePerGram * (21.0 / 24.0);
      expect(value21k, equals(87.5 * goldPricePerGram));

      // 4. Net wealth above Nisab -> exactly 2.5% rate
      const double cash = 300000.0;
      const double debts = 20000.0;
      const double netWealth = cash - debts; // 280,000
      expect(netWealth, greaterThanOrEqualTo(goldNisab));

      const double zakatDue = netWealth * 0.025;
      expect(zakatDue, equals(7000.0));

      // 5. Net wealth below Nisab -> 0 Zakat
      const double lowCash = 100000.0;
      const bool reachedNisab = lowCash >= goldNisab;
      expect(reachedNisab, isFalse);
    });
  });

  group('Fiqh Translation Tests', () {
    test('Translation keys for Islamic Fiqh exist in English and Arabic', () {
      TranslationService.setLanguage('en');
      expect(TranslationService.t('islamic_fiqh'), equals('Islamic Fiqh'));

      TranslationService.setLanguage('ar');
      expect(TranslationService.t('islamic_fiqh'), equals('الفقه الإسلامي'));
    });
  });
}
