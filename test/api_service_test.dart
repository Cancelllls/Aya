import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/api_service.dart';

void main() {
  group('ApiService configuration and caching', () {
    test('appFlavor defaults to fdroid for open-source builds', () {
      expect(ApiService.appFlavor, equals('fdroid'));
    });
  });
}
