import re

with open('lib/main.dart', 'r') as f:
    text = f.read()

# Add initial values
text = text.replace('int _prayerInitialTab = 0;', 'int _prayerInitialTab = 0;\n  int? _hadithInitialNumber;\n  String? _hadithInitialBookId;')

# Add to HadithScreen
text = text.replace('''      HadithScreen(
        storage: widget.storage,
      ),''', '''      HadithScreen(
        storage: widget.storage,
        initialHadithNumber: _hadithInitialNumber,
        initialBookId: _hadithInitialBookId,
      ),''')

# Add to key
text = text.replace("key: ValueKey<String>('$_currentTab-$_azkarInitialTab-$_prayerInitialTab')", "key: ValueKey<String>('$_currentTab-$_azkarInitialTab-$_prayerInitialTab-$_hadithInitialNumber-$_hadithInitialBookId')")

# Update BookmarksScreen launch
old_launch = '''                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookmarksScreen(storage: widget.storage),
                  ),
                );'''

new_launch = '''                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookmarksScreen(storage: widget.storage),
                  ),
                );
                
                if (result != null && result is Map) {
                  if (result['tab'] != null) {
                    setState(() {
                      _currentTab = result['tab'];
                      if (result['tab'] == 2) {
                        _hadithInitialNumber = result['hadithNumber'];
                        _hadithInitialBookId = result['bookId'];
                      }
                    });
                  }
                }'''

text = text.replace(old_launch, new_launch)

with open('lib/main.dart', 'w') as f:
    f.write(text)
