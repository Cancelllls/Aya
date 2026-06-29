with open('lib/screens/surah_reader_screen.dart', 'r') as f:
    text = f.read()

text = text.replace(
    "import 'package:google_fonts/google_fonts.dart';",
    "import 'package:google_fonts/google_fonts.dart';\nimport 'package:scroll_to_index/scroll_to_index.dart';"
)

text = text.replace(
    "final ScrollController _scrollController = ScrollController();",
    "final AutoScrollController _scrollController = AutoScrollController();"
)

# Replace the _scrollToAyah method entirely
old_scroll_to_ayah = """  void _scrollToAyah(int ayahNum) {
    if (!mounted) return;
    
    void performSearch(int attempt, double currentGuess) {
      if (!mounted) return;
      
      if (!_scrollController.hasClients) {
        if (attempt < 20) {
          Future.delayed(const Duration(milliseconds: 100), () => performSearch(attempt + 1, currentGuess));
        }
        return;
      }
      
      final key = _readingMode == 'continuous' 
          ? _pageKeys[(ayahNum - 1) ~/ 5]
          : _ayahKeys[ayahNum];
          
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration.zero,
          alignment: 0.0,
        );
      } else if (attempt < 20) {
        int maxRendered = -1;
        int minRendered = 99999;
        
        final keysToCheck = _readingMode == 'continuous' ? _pageKeys : _ayahKeys;
        for (final k in keysToCheck.keys) {
          if (keysToCheck[k]?.currentContext != null) {
            if (k > maxRendered) maxRendered = k;
            if (k < minRendered) minRendered = k;
          }
        }
        
        final targetIndex = _readingMode == 'continuous' ? ((ayahNum - 1) ~/ 5) : ayahNum;
        
        if (maxRendered != -1 && targetIndex > maxRendered) {
          currentGuess += 800;
          if (currentGuess > _scrollController.position.maxScrollExtent) {
            currentGuess = _scrollController.position.maxScrollExtent;
          }
          _scrollController.jumpTo(currentGuess);
        } else if (minRendered != 99999 && targetIndex < minRendered) {
          currentGuess -= 800;
          if (currentGuess < 0) currentGuess = 0;
          _scrollController.jumpTo(currentGuess);
        } else {
          currentGuess += 500;
          _scrollController.jumpTo(currentGuess);
        }
        
        Future.delayed(const Duration(milliseconds: 50), () => performSearch(attempt + 1, currentGuess));
      }
    }

    if (_scrollController.hasClients) {
      final key = _readingMode == 'continuous' 
          ? _pageKeys[(ayahNum - 1) ~/ 5]
          : _ayahKeys[ayahNum];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration.zero,
          alignment: 0.0,
        );
      } else {
        final initialGuess = (_readingMode == 'continuous' ? ((ayahNum - 1) ~/ 5) : ayahNum) * 150.0;
        _scrollController.jumpTo(initialGuess);
        Future.delayed(const Duration(milliseconds: 50), () => performSearch(0, initialGuess));
      }
    } else {
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToAyah(ayahNum));
    }
  }"""

new_scroll_to_ayah = """  void _scrollToAyah(int ayahNum) {
    if (!mounted) return;
    
    int targetIndex = _readingMode == 'continuous' ? ((ayahNum - 1) ~/ 5) : ayahNum;
    
    // AutoScrollController easily scrolls to index even if off-screen.
    // If not attached yet, wait a tiny bit.
    if (!_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToAyah(ayahNum));
      return;
    }
    
    _scrollController.scrollToIndex(
      targetIndex, 
      preferPosition: AutoScrollPosition.begin,
    );
  }"""

text = text.replace(old_scroll_to_ayah, new_scroll_to_ayah)

with open('lib/screens/surah_reader_screen.dart', 'w') as f:
    f.write(text)

