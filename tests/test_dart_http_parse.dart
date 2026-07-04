import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;

void main() async {
  final url =
      'https://dorar.net/dorar_api.json?skey=%D8%A7%D9%86%D9%85%D8%A7%20%D8%A7%D9%84%D8%A7%D8%B9%D9%85%D8%A7%D9%84%20%D8%A8%D8%A7%D9%84%D9%86%D9%8A%D8%A7%D8%AA&st=p2';
  final response = await http.get(Uri.parse(url));
  final decoded = jsonDecode(response.body);
  final htmlString = decoded['ahadith']['result'] ?? '';

  final document = html_parser.parse(htmlString);
  final hadithDivs = document.querySelectorAll('.hadith');
  final infoDivs = document.querySelectorAll('.hadith-info');

  print('Hadith divs: ' + hadithDivs.length.toString());
  print('Info divs: ' + infoDivs.length.toString());
  if (hadithDivs.isNotEmpty) {
    print(
      'First hadith text: ' +
          hadithDivs[0].text.trim().substring(0, 50) +
          '...',
    );
  }
}
