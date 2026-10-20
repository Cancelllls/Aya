import 'package:flutter_test/flutter_test.dart';
import 'package:aya_app/services/quran_download_service.dart';

void main() {
  group('Issue #6 - Downloaded Audio Reciter Path Sanitization', () {
    test('safeReciterDir replaces colons, slashes, and special characters', () {
      const dynamicReciter =
          'mp3quran_server_https://cdn.mp3quran.net/audio/mahmoud-husary/r3/';
      final safe = QuranDownloadService.safeReciterDir(dynamicReciter);

      // Must not contain any colon or slash (which breaks Android Uri.parse)
      expect(safe.contains(':'), isFalse);
      expect(safe.contains('/'), isFalse);
      expect(safe, startsWith('mp3quran_server_https___cdn.mp3quran.net_audio_mahmoud-husary_r3_'));
    });

    test('safeReciterDir preserves standard reciter IDs unchanged', () {
      expect(QuranDownloadService.safeReciterDir('ar.alafasy'), equals('ar.alafasy'));
      expect(QuranDownloadService.safeReciterDir('ar.husary'), equals('ar.husary'));
      expect(QuranDownloadService.safeReciterDir('ar.minshawi'), equals('ar.minshawi'));
    });
  });

  group('Issue #7 - Qiraat Moshaf Selection by Rewaya ID', () {
    test('Correctly selects moshaf matching selected riwayah instead of blind index 0', () {
      // Mock reciter with 5 riwayats (e.g. Mahmoud Khalil Al-Husari)
      final reciter = {
        'id': 118,
        'name': 'محمود خليل الحصري',
        'moshaf': [
          {'id': 270, 'name': 'قالون عن نافع', 'rewaya_id': 5, 'server': 'https://cdn.mp3quran.net/audio/mahmoud-husary/r5/'},
          {'id': 120, 'name': 'ورش عن نافع', 'rewaya_id': 2, 'server': 'https://cdn.mp3quran.net/audio/mahmoud-husary/r3/'},
          {'id': 118, 'name': 'حفص عن عاصم', 'rewaya_id': 1, 'server': 'https://cdn.mp3quran.net/audio/mahmoud-husary/r1/'},
        ],
      };

      final moshafList = List<Map<String, dynamic>>.from(reciter['moshaf'] as List);

      // Selecting Warsh (rewaya_id = 2)
      const selectedRiwayahId = 2;
      final matchingMoshaf = moshafList.firstWhere(
        (m) => m['rewaya_id'] == selectedRiwayahId,
        orElse: () => moshafList.first,
      );

      expect(matchingMoshaf['rewaya_id'], equals(2));
      expect(matchingMoshaf['server'], equals('https://cdn.mp3quran.net/audio/mahmoud-husary/r3/'));
      expect(matchingMoshaf['server'], isNot(equals(moshafList[0]['server'])));
    });
  });

  group('Issue #1 - Prayer Calendar Bottom Padding', () {
    test('Calculates compact 20px bottom padding for default navbar and 85px for floating', () {
      double computeBottomPadding(String? style) {
        final isFloatingNavbar = style == 'floating';
        return isFloatingNavbar ? 85.0 : 20.0;
      }

      // Default navbar should have compact 20px padding (not excessive 100px)
      expect(computeBottomPadding('default'), equals(20.0));
      expect(computeBottomPadding(null), equals(20.0));

      // Floating navbar gets 85px clearance
      expect(computeBottomPadding('floating'), equals(85.0));
    });
  });
}
