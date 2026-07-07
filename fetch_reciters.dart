import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final resAr = await HttpClient().getUrl(Uri.parse('https://mp3quran.net/api/v3/reciters?language=ar'));
  final respAr = await resAr.close();
  final dataAr = await respAr.transform(utf8.decoder).join();
  
  final resEn = await HttpClient().getUrl(Uri.parse('https://mp3quran.net/api/v3/reciters?language=eng'));
  final respEn = await resEn.close();
  final dataEn = await respEn.transform(utf8.decoder).join();
  
  final jsonAr = json.decode(dataAr);
  final jsonEn = json.decode(dataEn);
  
  final file = File('lib/data/reciters_data.dart');
  
  final sb = StringBuffer();
  sb.writeln('const Map<String, dynamic> recitersDataAr = ${json.encode(jsonAr)};');
  sb.writeln('const Map<String, dynamic> recitersDataEn = ${json.encode(jsonEn)};');
  
  await file.writeAsString(sb.toString());
}
