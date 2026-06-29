import 'package:dorar_hadith/dorar_hadith.dart';
void main() async {
  final client = DorarClient();
  try {
    final res = await client.searchHadith(HadithSearchParams(value: 'الاعمال بالنيات'));
    print(res.data.length);
  } catch (e) {
    print(e);
  }
}
