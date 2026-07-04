import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;

void main() async {
  final skey = Uri.encodeComponent('انما الاعمال بالنيات');
  final url1 = 'https://dorar.net/dorar_api.json?skey=$skey';
  final url2 = 'https://dorar.net/dorar_api.json?skey=$skey&st=p2';

  final res1 = await http.get(Uri.parse(url1));
  final res2 = await http.get(Uri.parse(url2));

  print('res1 == res2 ? ${res1.body == res2.body}');

  // Let's also check if we can scrape the main site bypassing CF
  final url3 = 'https://dorar.net/hadith/search?q=$skey&st=p2';
  final res3 = await http.get(
    Uri.parse(url3),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'ar,en-US;q=0.7,en;q=0.3',
    },
  );
  print('Scrape status: ${res3.statusCode}');
  if (res3.statusCode == 200) {
    if (res3.body.contains('شرح')) {
      print('Scraped Sharh successfully');
      // Look for the explanations
      final document = html_parser.parse(res3.body);
      final hadithDivs = document.querySelectorAll('.hadith');
      final infoDivs = document.querySelectorAll('.hadith-info');
      print('Hadith divs: ${hadithDivs.length}');
      print('Info divs: ${infoDivs.length}');
    } else {
      print('Did not find Sharh content');
    }
  } else {
    print('CF Blocked with status ${res3.statusCode}');
  }
}
