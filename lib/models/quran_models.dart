class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  int get startingJuz => _surahJuzMap[number] ?? 1;
  int get startingHizb => _surahHizbMap[number] ?? 1;

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
    );
  }

  /// Factory for Quran.com API fallback
  factory Surah.fromQuranCom(Map<String, dynamic> json) {
    final trans = json['translated_name'] as Map<String, dynamic>?;
    return Surah(
      number: json['id'] as int? ?? json['number'] as int? ?? 0,
      name: json['name_arabic'] as String? ?? json['name'] as String? ?? '',
      englishName: json['name_simple'] as String? ?? json['english_name'] as String? ?? json['englishName'] as String? ?? '',
      englishNameTranslation: trans != null ? trans['name'] as String? ?? '' : json['english_name_translation'] as String? ?? '',
      numberOfAyahs: json['verses_count'] as int? ?? json['number_of_ayahs'] as int? ?? json['numberOfAyahs'] as int? ?? 0,
      revelationType: json['revelation_place'] as String? ?? json['revelation_type'] as String? ?? json['revelationType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'englishName': englishName,
    'englishNameTranslation': englishNameTranslation,
    'numberOfAyahs': numberOfAyahs,
    'revelationType': revelationType,
  };

  static const Map<int, int> _surahJuzMap = {
    1: 1, 2: 1, 3: 3, 4: 4, 5: 6, 6: 7, 7: 8, 8: 9, 9: 10, 10: 11,
    11: 11, 12: 12, 13: 13, 14: 13, 15: 14, 16: 14, 17: 15, 18: 15, 19: 16, 20: 16,
    21: 17, 22: 17, 23: 18, 24: 18, 25: 18, 26: 19, 27: 19, 28: 20, 29: 20, 30: 21,
    31: 21, 32: 21, 33: 21, 34: 22, 35: 22, 36: 22, 37: 23, 38: 23, 39: 23, 40: 24,
    41: 24, 42: 25, 43: 25, 44: 25, 45: 25, 46: 26, 47: 26, 48: 26, 49: 26, 50: 26,
    51: 26, 52: 27, 53: 27, 54: 27, 55: 27, 56: 27, 57: 27, 58: 28, 59: 28, 60: 28,
    61: 28, 62: 28, 63: 28, 64: 28, 65: 28, 66: 28, 67: 29, 68: 29, 69: 29, 70: 29,
    71: 29, 72: 29, 73: 29, 74: 29, 75: 29, 76: 29, 77: 29, 78: 30, 79: 30, 80: 30,
    81: 30, 82: 30, 83: 30, 84: 30, 85: 30, 86: 30, 87: 30, 88: 30, 89: 30, 90: 30,
    91: 30, 92: 30, 93: 30, 94: 30, 95: 30, 96: 30, 97: 30, 98: 30, 99: 30, 100: 30,
    101: 30, 102: 30, 103: 30, 104: 30, 105: 30, 106: 30, 107: 30, 108: 30, 109: 30,
    110: 30, 111: 30, 112: 30, 113: 30, 114: 30
  };

  static const Map<int, int> _surahHizbMap = {
    1: 1, 2: 1, 3: 6, 4: 8, 5: 11, 6: 14, 7: 16, 8: 18, 9: 19, 10: 21,
    11: 22, 12: 24, 13: 25, 14: 26, 15: 27, 16: 27, 17: 29, 18: 30, 19: 31, 20: 31,
    21: 33, 22: 33, 23: 35, 24: 35, 25: 36, 26: 37, 27: 38, 28: 39, 29: 40, 30: 41,
    31: 41, 32: 41, 33: 42, 34: 43, 35: 44, 36: 44, 37: 45, 38: 46, 39: 46, 40: 47,
    41: 48, 42: 49, 43: 49, 44: 50, 45: 50, 46: 51, 47: 51, 48: 51, 49: 52, 50: 52,
    51: 52, 52: 53, 53: 53, 54: 53, 55: 53, 56: 54, 57: 54, 58: 55, 59: 55, 60: 55,
    61: 55, 62: 56, 63: 56, 64: 56, 65: 56, 66: 56, 67: 57, 68: 57, 69: 57, 70: 57,
    71: 58, 72: 58, 73: 58, 74: 58, 75: 58, 76: 58, 77: 58, 78: 59, 79: 59, 80: 59,
    81: 59, 82: 59, 83: 59, 84: 59, 85: 59, 86: 59, 87: 59, 88: 60, 89: 60, 90: 60,
    91: 60, 92: 60, 93: 60, 94: 60, 95: 60, 96: 60, 97: 60, 98: 60, 99: 60, 100: 60,
    101: 60, 102: 60, 103: 60, 104: 60, 105: 60, 106: 60, 107: 60, 108: 60, 109: 60,
    110: 60, 111: 60, 112: 60, 113: 60, 114: 60
  };
}

class Ayah {
  final int number;
  final int numberInSurah;
  final String text;
  final String translation;
  final int juz;
  final int hizb;
  String tafseer;

  Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.translation,
    required this.juz,
    required this.hizb,
    this.tafseer = '',
  });

  static String _cleanBasmalah(String text, int numberInSurah, int globalNumber) {
    if (numberInSurah != 1) return text;
    // Do not clean Basmalah for Surah 1 (Al-Fatiha), which corresponds to global ayah numbers 1 to 7
    if (globalNumber >= 1 && globalNumber <= 7) return text;
    final basmalahs = [
      "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
      "بِسْمِ ٱللَّهِ ٱلرَّحْمَنِ ٱلرَّحِيمِ",
      "بِسْمِ ٱللهِ ٱلرَّحْمَنِ ٱلرَّحِيمِ",
      "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
      "بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ",
      "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
      "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
      "بِسْمِ اللهِ الرَّحْمَٰنِ الرَّحِيمِ",
    ];
    for (final basmalah in basmalahs) {
      if (text.startsWith(basmalah)) {
        if (text.trim() == basmalah) {
          return text;
        }
        return text.substring(basmalah.length).trim();
      }
    }
    return text;
  }

  factory Ayah.fromEditions(
    Map<String, dynamic> arabicJson, 
    Map<String, dynamic> englishJson, 
    [Map<String, dynamic>? tafseerJson]
  ) {
    final hizbQuarter = arabicJson['hizbQuarter'] as int? ?? 1;
    final calculatedHizb = ((hizbQuarter - 1) ~/ 4) + 1;
    final numInSurah = arabicJson['numberInSurah'] as int;
    final rawText = arabicJson['text'] as String;
    final globalNum = arabicJson['number'] as int;
    return Ayah(
      number: globalNum,
      numberInSurah: numInSurah,
      text: _cleanBasmalah(rawText, numInSurah, globalNum),
      translation: englishJson['text'] as String,
      juz: arabicJson['juz'] as int,
      hizb: calculatedHizb,
      tafseer: tafseerJson != null ? tafseerJson['text'] as String? ?? '' : '',
    );
  }

  /// Factory for Quran.com verses fallback
  factory Ayah.fromQuranCom(Map<String, dynamic> json) {
    final transList = json['translations'] as List<dynamic>?;
    final transText = (transList != null && transList.isNotEmpty)
        ? transList[0]['text'] as String? ?? ''
        : '';
    final numInSurah = json['verse_number'] as int? ?? (json['verse_key'] != null ? int.parse(json['verse_key'].toString().split(':')[1]) : 1);
    final rawText = json['text_uthmani'] as String? ?? json['text'] as String? ?? '';
    final globalNum = json['id'] as int? ?? 0;
    return Ayah(
      number: globalNum,
      numberInSurah: numInSurah,
      text: _cleanBasmalah(rawText, numInSurah, globalNum),
      translation: transText.isNotEmpty ? transText : (json['text_simple'] as String? ?? json['translation'] as String? ?? ''),
      juz: json['juz_number'] as int? ?? 0,
      hizb: json['hizb_number'] as int? ?? 0,
      tafseer: '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'numberInSurah': numberInSurah,
    'text': text,
    'translation': translation,
    'juz': juz,
    'hizb': hizb,
    'tafseer': tafseer,
  };

  factory Ayah.fromJson(Map<String, dynamic> json) {
    final numInSurah = json['numberInSurah'] as int;
    final rawText = json['text'] as String;
    final globalNum = json['number'] as int;
    return Ayah(
      number: globalNum,
      numberInSurah: numInSurah,
      text: _cleanBasmalah(rawText, numInSurah, globalNum),
      translation: json['translation'] as String,
      juz: json['juz'] as int,
      hizb: json['hizb'] as int? ?? 0,
      tafseer: json['tafseer'] as String? ?? '',
    );
  }
}
