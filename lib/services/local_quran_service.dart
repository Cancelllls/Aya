import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quran_models.dart';

class LocalQuranService {
  static final Map<String, List<dynamic>> _data = {};

  static Future<void> _loadData(String scriptType) async {
    if (!_data.containsKey(scriptType)) {
      try {
        final jsonStr = await rootBundle.loadString('assets/quran/$scriptType.json');
        _data[scriptType] = json.decode(jsonStr);
      } catch (e) {
        // Fallback to warsh if not found
        if (!_data.containsKey('warsh')) {
          final warshStr = await rootBundle.loadString('assets/quran/warsh.json');
          _data['warsh'] = json.decode(warshStr);
        }
        _data[scriptType] = _data['warsh']!;
      }
    }
  }

  static Future<List<Ayah>> getSurahAyahs(int surahNumber, String scriptType) async {
    await _loadData(scriptType);
    List<dynamic> dataToUse = _data[scriptType]!;

    final surahData = dataToUse.where((row) => row['sura_no'] == surahNumber).toList();
    List<Ayah> ayahs = [];

    for (var row in surahData) {
      String text = row['aya_text'];
      // Remove trailing digits if they are present in the text (like ١٢)
      final numRegex = RegExp(r'[٠-٩]+$');
      text = text.replaceAll(numRegex, '').trim();
      
      final globalAyahNum = row['id'] as int;
      final numInSurah = row['aya_no'] as int;
      text = Ayah.cleanBasmalah(text, numInSurah, globalAyahNum);

      ayahs.add(
        Ayah(
          number: globalAyahNum,
          numberInSurah: numInSurah,
          text: text,
          translation: '', // No translation available for this exact mapping
          juz: row['jozz'],
          hizb: 0,
        ),
      );
    }
    return ayahs;
  }
}
