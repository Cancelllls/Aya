import 'package:dorar_hadith/dorar_hadith.dart';

void main() async {
  final client = DorarClient();
  final query = 'الأعمال بالنيات';

  try {
    print('--- Testing searchSharh (Explanation) ---');
    final sharhResults = await client.searchSharh(
      HadithSearchParams(value: query, page: 1),
    );

    if (sharhResults.data.isNotEmpty) {
      final s = sharhResults.data.first;
      print('HADITH TEXT:');
      print(s.hadithText.replaceAll(RegExp(r'<[^>]*>'), '').trim());
      print('\nSHARH TEXT:');
      print(s.sharhText?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? 'NULL');
    } else {
      print('No sharh results.');
    }

    print('\n\n--- Testing searchHadith (Grading) ---');
    final hadithResults = await client.searchHadith(
      HadithSearchParams(value: query, page: 1),
    );

    if (hadithResults.data.isNotEmpty) {
      final h = hadithResults.data.first;
      print('HADITH TEXT:');
      print(h.hadith.replaceAll(RegExp(r'<[^>]*>'), '').trim());
      print('\nINFO:');
      print(
        'الراوي: ${h.rawi}\nالمحدث: ${h.mohdith}\nالمصدر: ${h.book}\nالخلاصة: ${h.grade}',
      );
    } else {
      print('No hadith results.');
    }
  } finally {
    await client.dispose();
  }
}
