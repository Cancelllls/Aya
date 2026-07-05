import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quran_models.dart';

class LocalQuranService {
  static List<dynamic>? _warshData;
  static List<dynamic>? _qaloonData;

  static Future<void> _loadData() async {
    if (_warshData == null) {
      final warshStr = await rootBundle.loadString('assets/quran/warsh.json');
      _warshData = json.decode(warshStr);
    }
    if (_qaloonData == null) {
      final qaloonStr = await rootBundle.loadString('assets/quran/qaloon.json');
      _qaloonData = json.decode(qaloonStr);
    }
  }

  static Future<List<Ayah>> getSurahAyahs(int surahNumber, String scriptType) async {
    await _loadData();
    List<dynamic> dataToUse = scriptType == 'warsh' ? _warshData! : _qaloonData!;

    final surahData = dataToUse.where((row) => row['sura_no'] == surahNumber).toList();
    List<Ayah> ayahs = [];

    for (var row in surahData) {
      String text = row['aya_text'];
      // Remove trailing digits if they are present in the text (like ١٢)
      final numRegex = RegExp(r'[٠-٩]+$');
      text = text.replaceAll(numRegex, '').trim();

      ayahs.add(
        Ayah(
          number: row['id'], // Global ayah number
          numberInSurah: row['aya_no'],
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
