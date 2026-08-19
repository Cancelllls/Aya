import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/data/reciters_data.dart';

void main() {
  group('RecitersData', () {
    test('recitersDataAr contains valid reciters list', () {
      expect(recitersDataAr.containsKey('reciters'), isTrue);
      final list = recitersDataAr['reciters'] as List;
      expect(list.isNotEmpty, isTrue);

      for (final item in list) {
        expect(item['id'], isNotNull);
        expect(item['name'], isNotEmpty);
        expect(item['moshaf'], isA<List>());
        final moshafList = item['moshaf'] as List;
        for (final m in moshafList) {
          expect(m['server'], isNotEmpty);
          expect((m['server'] as String).startsWith('http'), isTrue);
        }
      }
    });

    test('recitersDataEn contains valid reciters list', () {
      expect(recitersDataEn.containsKey('reciters'), isTrue);
      final list = recitersDataEn['reciters'] as List;
      expect(list.isNotEmpty, isTrue);

      for (final item in list) {
        expect(item['id'], isNotNull);
        expect(item['name'], isNotEmpty);
        expect(item['moshaf'], isA<List>());
      }
    });
  });
}
