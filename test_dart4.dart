void main() {
  String t = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الم";
  String t2 = "بسم الله الرحمن الرحيم الم";
  String t3 = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
  
  String clean(String text) {
    String stripDiacritics(String s) {
      return s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    }
    
    final normalized = stripDiacritics(text);
    final bismillahNoTashkeel = "بسم الله الرحمن الرحيم";
    
    final fullyNormalized = normalized.replaceAll('ٱ', 'ا');
    
    if (fullyNormalized.startsWith(bismillahNoTashkeel)) {
      int charsToSkip = bismillahNoTashkeel.length;
      int originalIndex = 0;
      int nonDiacriticCount = 0;
      
      while (originalIndex < text.length && nonDiacriticCount < charsToSkip) {
        if (!RegExp(r'[\u064B-\u065F\u0670]').hasMatch(text[originalIndex])) {
          nonDiacriticCount++;
        }
        originalIndex++;
      }
      
      // Consume trailing diacritics of the last skipped letter
      while (originalIndex < text.length && RegExp(r'[\u064B-\u065F\u0670]').hasMatch(text[originalIndex])) {
        originalIndex++;
      }
      
      if (originalIndex < text.length) {
        return text.substring(originalIndex).trim();
      } else {
        return text;
      }
    }
    return text;
  }
  
  print("1: " + clean(t));
  print("2: " + clean(t2));
  print("3: " + clean(t3));
}
