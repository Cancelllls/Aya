import 'dart:convert';
import 'dart:io';

void main() async {
  final req = await HttpClient().getUrl(Uri.parse('http://api.alquran.cloud/v1/surah/1/quran-qaloon'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final data = jsonDecode(body);
  final ayah = data['data']['ayahs'][0];
  print('Qaloon Fatiha 1 global number: \${ayah['number']}');
}
