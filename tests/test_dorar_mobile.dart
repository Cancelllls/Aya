import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final query = Uri.encodeComponent('انما الاعمال بالنيات');
  final url = 'https://dorar.net/api/v1/hadith/search?query=$query';
  
  final res = await http.get(Uri.parse(url));
  print('status: \${res.statusCode}');
  if (res.statusCode == 200) {
    print(res.body.substring(0, 100));
  }
}
