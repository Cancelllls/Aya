void main() {
  String _buildHadithQuery(String text) {
    String query = '';
    
    final quoteMatch = RegExp(r'["«](.*?)["»]').firstMatch(text);
    if (quoteMatch != null && quoteMatch.group(1)!.trim().length > 10) {
      final words = quoteMatch.group(1)!.trim().split(RegExp(r'\s+'));
      query = words.take(10).join(' ');
    } else {
      final pbuhIndex = text.indexOf('صلى الله عليه وسلم');
      if (pbuhIndex != -1) {
        final afterPbuh = text
            .substring(pbuhIndex + 18)
            .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
            .trim();
        final words = afterPbuh.split(RegExp(r'\s+'));
        if (words.length > 3) query = words.take(10).join(' ');
      }
      
      if (query.isEmpty) {
        final raIndex = text.indexOf('رضي الله عنه');
        if (raIndex != -1) {
          final afterRa = text
              .substring(raIndex + 12)
              .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
              .trim();
          final words = afterRa.split(RegExp(r'\s+'));
          if (words.length > 3) query = words.take(10).join(' ');
        }
      }
      
      if (query.isEmpty) {
        final words = text.split(RegExp(r'\s+'));
        if (words.length > 20) {
          query = words.skip(10).take(10).join(' ');
        } else {
          query = words.take(10).join(' ');
        }
      }
    }
    
    query = query.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
    if (query.isEmpty) {
      final rawWords = text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim().split(RegExp(r'\s+'));
      query = rawWords.take(5).join(' ');
    }
    return query;
  }

  print("Empty: '${_buildHadithQuery("")}'");
  print("Normal: '${_buildHadithQuery("قال رسول الله صلى الله عليه وسلم: إنما الأعمال بالنيات")}'");
  print("Short: '${_buildHadithQuery("حديث قصير")}'");
  print("Quotes: '${_buildHadithQuery('قال: "هذا حديث فيه تفصيل كثير جدا"')}'");
}
