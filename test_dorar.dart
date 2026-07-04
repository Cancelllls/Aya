import 'package:dorar_hadith/dorar_hadith.dart';

void main() async {
  final client = DorarClient();
  final sharhResults = await client.searchSharh(
    HadithSearchParams(value: "الأعمال بالنيات", page: 1),
  );
  print("--- HADITH TEXT ---");
  print(sharhResults.data.first.hadithText);
  print("--- SHARH TEXT ---");
  print(sharhResults.data.first.sharhText);
  await client.dispose();
}
