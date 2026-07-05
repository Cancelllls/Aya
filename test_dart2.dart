import 'dart:convert';
import 'dart:io';

void main() async {
  final req = await HttpClient().getUrl(Uri.parse('http://api.alquran.cloud/v1/surah/2/quran-qaloon'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final data = jsonDecode(body);
  String text = data['data']['ayahs'][0]['text'];
  print('Raw: ' + text);
  
  String t = text.replaceAll(RegExp(r'^[\u200e\u200f\u202a-\u202e\u2066-\u2069\ufeff\s]+'), '');
  final basmalahs = [
    "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
    "بِسْمِ ٱللَّهِ ٱلرَّحْمَنِ ٱلرَّحِيمِ",
    "بِسْمِ ٱللهِ ٱلرَّحْمَنِ ٱلرَّحِيمِ",
    "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
    "بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ",
    "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
    "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
    "بِسْمِ اللهِ الرَّحْمَٰنِ الرَّحِيمِ",
  ];
  
  bool matched = false;
  for (final basmalah in basmalahs) {
    if (t.startsWith(basmalah)) {
      matched = true;
      if (t.trim() == basmalah) {
        print('Matched exactly: ' + t);
      } else {
        print('Cleaned: ' + t.substring(basmalah.length).trim());
      }
      break;
    }
  }
  
  if (!matched) {
    print('No match!');
    if (t.contains('بِسْمِ') && t.contains('الرَّحِيمِ')) {
      print('Fallback would trigger');
    }
  }
}
