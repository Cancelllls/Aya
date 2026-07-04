import 'package:dorar_hadith/dorar_hadith.dart';

void main() async {
  final client = DorarClient();
  final res = await client.searchHadith(HadithSearchParams(value: 'إنما الأعمال بالنيات', page: 1));
  for (var h in res.data) {
    print('Rawi: "${h.rawi}"');
    print('Mohdith: "${h.mohdith}"');
    print('Book: "${h.book}"');
    print('Grade: "${h.grade}"');
    print('---');
  }
  client.dispose();
}
