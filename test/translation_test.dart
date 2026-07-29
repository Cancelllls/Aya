import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/translation_service.dart';

void main() {
  group('TranslationService', () {
    setUp(() {
      TranslationService.setLanguage('en');
    });

    test('language defaults to English', () {
      expect(TranslationService.currentLanguage, 'en');
    });

    test('switches to Arabic', () {
      TranslationService.setLanguage('ar');
      expect(TranslationService.currentLanguage, 'ar');
      expect(TranslationService.isArabic, isTrue);
    });

    test('switches back to English', () {
      TranslationService.setLanguage('ar');
      TranslationService.setLanguage('en');
      expect(TranslationService.currentLanguage, 'en');
      expect(TranslationService.isArabic, isFalse);
    });

    test('t() returns English translation', () {
      expect(TranslationService.t('home'), 'Home');
      expect(TranslationService.t('quran'), 'Quran');
      expect(TranslationService.t('prayer'), 'Prayer');
    });

    test('t() returns Arabic translation', () {
      TranslationService.setLanguage('ar');
      expect(TranslationService.t('home'), isNotEmpty);
      expect(TranslationService.t('quran'), isNotEmpty);
      expect(TranslationService.t('prayer'), isNotEmpty);
    });

    test('t() falls back to key for unknown keys', () {
      expect(TranslationService.t('nonexistent_key_12345'), 'nonexistent_key_12345');
    });

    test('all supported keys exist in both languages', () {
      final keys = [
        'home', 'quran', 'prayer', 'azkar', 'settings',
        'morning', 'evening', 'post_prayer', 'daily_duas',
        'cancel', 'delete', 'reset_counts', 'quran_downloads',
        'qibla', 'tasbih', 'auto_scroll',
        'welcome_app_name', 'welcome_start_now', 'welcome_next',
        'welcome_feat_prayer_title', 'welcome_feat_quran_title',
        'welcome_feat_qibla_title', 'welcome_feat_tasbih_title',
        'welcome_intro_desc', 'delete_confirm', 'app_lang',
      ];
      for (final key in keys) {
        // English
        TranslationService.setLanguage('en');
        expect(TranslationService.t(key), isNot(key), reason: 'EN: $key not translated');
        // Arabic
        TranslationService.setLanguage('ar');
        expect(TranslationService.t(key), isNot(key), reason: 'AR: $key not translated');
      }
    });

    test('Arabic translations are different from English', () {
      final keys = ['home', 'quran', 'prayer', 'settings'];
      for (final key in keys) {
        TranslationService.setLanguage('en');
        final en = TranslationService.t(key);
        TranslationService.setLanguage('ar');
        final ar = TranslationService.t(key);
        expect(en, isNot(ar), reason: '$key has same text in both languages');
      }
    });
  });
}
