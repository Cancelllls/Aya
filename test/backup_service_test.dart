import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backup Schema Validation', () {
    test('validates backup JSON structure with all expected keys', () {
      final sampleBackup = {
        'version': 1,
        'exported_at': '2026-08-19T12:00:00.000Z',
        'bookmarks': ['hadith_bukhari_1'],
        'quran_bookmarks': ['{"surah":1,"ayah":1}'],
        'settings': {
          'prayer_method': 'Egyptian',
          'theme_preset': 'teal_gold',
          'lang_code': 'ar',
          'calc_method': 5,
        },
        'custom_azkar': [],
        'prayer_tracker': [
          {'date': '2026-08-19', 'fajr': 1, 'dhuhr': 1, 'asr': 1, 'maghrib': 1, 'isha': 1}
        ],
      };

      final jsonStr = jsonEncode(sampleBackup);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['version'], equals(1));
      expect(decoded.containsKey('exported_at'), isTrue);
      expect(decoded.containsKey('bookmarks'), isTrue);
      expect(decoded.containsKey('quran_bookmarks'), isTrue);
      expect(decoded.containsKey('settings'), isTrue);
      expect(decoded.containsKey('custom_azkar'), isTrue);
      expect(decoded.containsKey('prayer_tracker'), isTrue);

      final settings = decoded['settings'] as Map<String, dynamic>;
      expect(settings['prayer_method'], equals('Egyptian'));
      expect(settings['calc_method'], equals(5));
    });
  });
}
