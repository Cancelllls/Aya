import re

with open('lib/screens/hadith_screen.dart', 'r') as f:
    content = f.read()

old_query_func = """  String _buildHadithQuery(String text) {
    // 1. Try to extract text inside quotes (usually the core hadith matn)
    final quoteMatch = RegExp(r'["«](.*?)["»]').firstMatch(text);
    if (quoteMatch != null && quoteMatch.group(1)!.trim().length > 10) {
      final words = quoteMatch.group(1)!.trim().split(RegExp(r'\s+'));
      return words.take(10).join(' ');
    }

    // 2. Look for the Prophet's blessing and take what comes after it
    final pbuhIndex = text.indexOf('صلى الله عليه وسلم');
    if (pbuhIndex != -1) {
      final afterPbuh = text
          .substring(pbuhIndex + 18)
          .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
          .trim();
      final words = afterPbuh.split(RegExp(r'\s+'));
      if (words.length > 3) return words.take(10).join(' ');
    }

    // 3. Look for "رضي الله عنه" and take what comes after
    final raIndex = text.indexOf('رضي الله عنه');
    if (raIndex != -1) {
      final afterRa = text
          .substring(raIndex + 12)
          .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
          .trim();
      final words = afterRa.split(RegExp(r'\s+'));
      if (words.length > 3) return words.take(10).join(' ');
    }

    // 4. Fallback: skip the first chunk of words assuming it's a long narrator chain
    final words = text.split(RegExp(r'\s+'));
    if (words.length > 20) {
      return words.skip(10).take(10).join(' ');
    }

    return words.take(10).join(' ');
  }"""

new_query_func = """  String _buildHadithQuery(String text) {
    String query = '';
    
    final quoteMatch = RegExp(r'["«](.*?)["»]').firstMatch(text);
    if (quoteMatch != null && quoteMatch.group(1)!.trim().length > 10) {
      final words = quoteMatch.group(1)!.trim().split(RegExp(r'\\s+'));
      query = words.take(10).join(' ');
    } else {
      final pbuhIndex = text.indexOf('صلى الله عليه وسلم');
      if (pbuhIndex != -1) {
        final afterPbuh = text
            .substring(pbuhIndex + 18)
            .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
            .trim();
        final words = afterPbuh.split(RegExp(r'\\s+'));
        if (words.length > 3) query = words.take(10).join(' ');
      }
      
      if (query.isEmpty) {
        final raIndex = text.indexOf('رضي الله عنه');
        if (raIndex != -1) {
          final afterRa = text
              .substring(raIndex + 12)
              .replaceAll(RegExp(r'قال|يقول|:|["«»]'), '')
              .trim();
          final words = afterRa.split(RegExp(r'\\s+'));
          if (words.length > 3) query = words.take(10).join(' ');
        }
      }
      
      if (query.isEmpty) {
        final words = text.split(RegExp(r'\\s+'));
        if (words.length > 20) {
          query = words.skip(10).take(10).join(' ');
        } else {
          query = words.take(10).join(' ');
        }
      }
    }
    
    query = query.replaceAll(RegExp(r'[^\\w\\s\\u0600-\\u06FF]'), '').trim();
    if (query.isEmpty) {
      final rawWords = text.replaceAll(RegExp(r'[^\\w\\s\\u0600-\\u06FF]'), '').trim().split(RegExp(r'\\s+'));
      query = rawWords.take(5).join(' ');
    }
    
    return query.isEmpty ? "حديث" : query;
  }"""

if old_query_func in content:
    content = content.replace(old_query_func, new_query_func)
    with open('lib/screens/hadith_screen.dart', 'w') as f:
        f.write(content)
else:
    print("Function not found!")
