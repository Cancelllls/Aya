import 'package:dorar_hadith/dorar_hadith.dart';

void main() async {
  final client = DorarClient();
  try {
    print('Searching Sharh...');
    final sharhResults = await client.searchSharh(
      HadithSearchParams(value: 'إنما الأعمال بالنيات', page: 1),
    );

    print('Found \${sharhResults.data.length} sharh results');
    if (sharhResults.data.isNotEmpty) {
      final s = sharhResults.data.first;
      print('Sharh: \${s.sharhText?.substring(0, 50)}...');
    }
  } catch (e) {
    print('Error: \$e');
  } finally {
    await client.dispose();
  }
}
