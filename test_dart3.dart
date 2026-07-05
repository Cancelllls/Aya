void main() {
  String text = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الم";
  String textNoDiacritics = "بسم الله الرحمن الرحيم الم";
  
  String stripDiacritics(String s) {
    return s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }
  
  print(stripDiacritics(text));
  print(stripDiacritics(textNoDiacritics));
}
