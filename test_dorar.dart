import 'package:dorar_hadith/dorar_hadith.dart';

void main() async {
  try {
    final client = DorarClient();
    final results = await client.searchHadith(HadithSearchParams(value: 'صيام'));
    print("Found: ${results.data.length}");
  } catch(e) {
    print("Error: $e");
  }
}
