import 'dart:convert';
import 'dart:io';

void main() async {
  final req = await HttpClient().getUrl(Uri.parse('http://api.alquran.cloud/v1/surah/2/quran-qaloon'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final data = jsonDecode(body);
  String text = data['data']['ayahs'][0]['text'];
  print('Raw: ' + text);
  
  String stripDiacritics(String s) {
    return s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }
  
  String t = text.replaceAll(RegExp(r'^[\u200e\u200f\u202a-\u202e\u2066-\u2069\ufeff\s]+'), '');
  final normalized = stripDiacritics(t);
  final fullyNormalized = normalized.replaceAll('ٱ', 'ا'); // Normalize Alif Wasla
  print('Fully Normalized: ' + fullyNormalized);
  
  final bismillahNoTashkeel = "بسم الله الرحمن الرحيم";
  print('StartsWith Bismillah? \${fullyNormalized.startsWith(bismillahNoTashkeel)}');
}
