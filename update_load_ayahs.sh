#!/bin/bash
# insert import
sed -i 's/import '\''\.\.\/services\/api_service\.dart'\'';/import '\''\.\.\/services\/api_service\.dart'\'';\nimport '\''\.\.\/services\/local_quran_service\.dart'\'';/g' lib/screens/surah_reader_screen.dart

cat << 'INNER_EOF' > replacement.dart
  Future<void> _loadAyahs() async {
    setState(() => _isLoading = true);
    try {
      final tafsirEdition = widget.storage.getString(
        'default_tafsir',
        defaultValue: 'ar.muyassar',
      );
      
      List<Ayah> list;
      if (_quranScriptType == 'hafs') {
        list = await ApiService.fetchSurahDetails(
          _currentSurah.number,
          tafsirEdition: tafsirEdition,
        );
      } else {
        list = await LocalQuranService.getSurahAyahs(
          _currentSurah.number,
          _quranScriptType,
        );
      }
INNER_EOF

# Replace from `Future<void> _loadAyahs()` down to `tafsirEdition: tafsirEdition,` with our new block
awk -v r="$(cat replacement.dart)" '/Future<void> _loadAyahs\(\) async \{/{
    print r
    f=1
    next
}
f && /tafsirEdition: tafsirEdition,/{
    getline
    f=0
    next
}
!f' lib/screens/surah_reader_screen.dart > temp.dart && mv temp.dart lib/screens/surah_reader_screen.dart
rm replacement.dart
