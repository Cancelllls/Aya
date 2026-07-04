import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final url =
      'https://dorar.net/dorar_api.json?skey=%D8%A7%D9%86%D9%85%D8%A7%20%D8%A7%D9%84%D8%A7%D8%B9%D9%85%D8%A7%D9%84%20%D8%A8%D8%A7%D9%84%D9%86%D9%8A%D8%A7%D8%AA&st=p2';
  try {
    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      print('Parsed JSON OK!');
    } else {
      print('Failed');
    }
  } catch (e) {
    print('Error: $e');
  }
}
