class PredefinedVerse {
  final String arabic;
  final String translation;
  final String surahNameAr;
  final String surahNameEn;
  final int surahNumber;
  final int ayahNumber;

  PredefinedVerse({
    required this.arabic,
    required this.translation,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.surahNumber,
    required this.ayahNumber,
  });

  String getDisplayString(bool isArabic) {
    if (isArabic) {
      return '$arabic\n\n— سورة $surahNameAr ($surahNumber:$ayahNumber)';
    } else {
      return '$arabic\n\n$translation\n— Surah $surahNameEn ($surahNumber:$ayahNumber)';
    }
  }
}

class QuranVersesData {
  static final List<PredefinedVerse> verses = [
    PredefinedVerse(
      surahNumber: 2,
      ayahNumber: 152,
      arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
      translation:
          "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
      surahNameAr: "البقرة",
      surahNameEn: "Al-Baqarah",
    ),
    PredefinedVerse(
      surahNumber: 94,
      ayahNumber: 5,
      arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
      translation: "For indeed, with hardship [will be] ease.",
      surahNameAr: "الشرح",
      surahNameEn: "Ash-Sharh",
    ),
    PredefinedVerse(
      surahNumber: 2,
      ayahNumber: 286,
      arabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
      translation: "Allah does not burden a soul beyond that it can bear.",
      surahNameAr: "البقرة",
      surahNameEn: "Al-Baqarah",
    ),
    PredefinedVerse(
      surahNumber: 2,
      ayahNumber: 186,
      arabic:
          "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ",
      translation:
          "And when My servants ask you concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me.",
      surahNameAr: "البقرة",
      surahNameEn: "Al-Baqarah",
    ),
    PredefinedVerse(
      surahNumber: 39,
      ayahNumber: 53,
      arabic:
          "لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا",
      translation:
          "Do not despair of the mercy of Allah. Indeed, Allah forgives all sins.",
      surahNameAr: "الزمر",
      surahNameEn: "Az-Zumar",
    ),
    PredefinedVerse(
      surahNumber: 13,
      ayahNumber: 28,
      arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
      translation:
          "Unquestionably, by the remembrance of Allah hearts are assured.",
      surahNameAr: "الرعد",
      surahNameEn: "Ar-Ra'd",
    ),
    PredefinedVerse(
      surahNumber: 14,
      ayahNumber: 7,
      arabic: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
      translation:
          "If you are grateful, I will surely increase you [in favor].",
      surahNameAr: "إبراهيم",
      surahNameEn: "Ibrahim",
    ),
    PredefinedVerse(
      surahNumber: 20,
      ayahNumber: 46,
      arabic: "لَا تَخَافَا ۖ إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَىٰ",
      translation: "Fear not. Indeed, I am with you both; I hear and I see.",
      surahNameAr: "طه",
      surahNameEn: "Taha",
    ),
    PredefinedVerse(
      surahNumber: 3,
      ayahNumber: 139,
      arabic:
          "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ",
      translation:
          "So do not weaken and do not grieve, and you will be superior if you are [true] believers.",
      surahNameAr: "آل عمران",
      surahNameEn: "Ali 'Imran",
    ),
    PredefinedVerse(
      surahNumber: 65,
      ayahNumber: 3,
      arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
      translation:
          "And whoever relies upon Allah - then He is sufficient for him.",
      surahNameAr: "الطلاق",
      surahNameEn: "At-Talaq",
    ),
    PredefinedVerse(
      surahNumber: 40,
      ayahNumber: 60,
      arabic: "وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ",
      translation:
          "And your Lord says, \"Call upon Me; I will respond to you.\"",
      surahNameAr: "غافر",
      surahNameEn: "Ghafir",
    ),
    PredefinedVerse(
      surahNumber: 2,
      ayahNumber: 156,
      arabic:
          "الَّذِينَ إِذَا أَصَابَتْهُم مُّصِيبَةٌ قَالُوا إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ",
      translation:
          "Who, when disaster strikes them, say, \"Indeed we belong to Allah, and indeed to Him we will return.\"",
      surahNameAr: "البقرة",
      surahNameEn: "Al-Baqarah",
    ),
    PredefinedVerse(
      surahNumber: 17,
      ayahNumber: 82,
      arabic:
          "وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ",
      translation:
          "And We send down of the Quran that which is healing and mercy for the believers.",
      surahNameAr: "الإسراء",
      surahNameEn: "Al-Isra",
    ),
    PredefinedVerse(
      surahNumber: 21,
      ayahNumber: 87,
      arabic:
          "لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ",
      translation:
          "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.",
      surahNameAr: "الأنبياء",
      surahNameEn: "Al-Anbya",
    ),
    PredefinedVerse(
      surahNumber: 21,
      ayahNumber: 107,
      arabic: "وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ",
      translation:
          "And We have not sent you, [O Muhammad], except as a mercy to the worlds.",
      surahNameAr: "الأنبياء",
      surahNameEn: "Al-Anbya",
    ),
    PredefinedVerse(
      surahNumber: 50,
      ayahNumber: 16,
      arabic: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ",
      translation: "And We are closer to him than [his] jugular vein.",
      surahNameAr: "ق",
      surahNameEn: "Qaf",
    ),
    PredefinedVerse(
      surahNumber: 55,
      ayahNumber: 60,
      arabic: "هَلْ جَزَاءُ الْإِحْسَانِ إِلَّا الْإِحْسَانُ",
      translation: "Is the reward for good [anything] but good?",
      surahNameAr: "الرحمن",
      surahNameEn: "Ar-Rahman",
    ),
    PredefinedVerse(
      surahNumber: 57,
      ayahNumber: 4,
      arabic: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
      translation: "And He is with you wherever you are.",
      surahNameAr: "الحديد",
      surahNameEn: "Al-Hadid",
    ),
    PredefinedVerse(
      surahNumber: 25,
      ayahNumber: 63,
      arabic:
          "وَعِبَادُ الرَّحْمَٰنِ الَّذِينَ يَمْشُونَ عَلَى الْأَرْضِ هَوْنًا وَإِذَا خَاطَبَهُمُ الْجَاهِلُونَ قَالُوا سَلَامًا",
      translation:
          "And the servants of the Most Merciful are those who walk upon the earth easily, and when the ignorant address them, they say, \"Peace.\"",
      surahNameAr: "الفرقان",
      surahNameEn: "Al-Furqan",
    ),
    PredefinedVerse(
      surahNumber: 30,
      ayahNumber: 21,
      arabic:
          "وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا لِّتَسْكُنُوا إِلَيْهَا وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً",
      translation:
          "And of His signs is that He created for you from yourselves mates that you may find tranquility in them; and He placed between you affection and mercy.",
      surahNameAr: "الروم",
      surahNameEn: "Ar-Rum",
    ),
    PredefinedVerse(
      surahNumber: 33,
      ayahNumber: 56,
      arabic:
          "إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا",
      translation:
          "Indeed, Allah and His angels confer blessing upon the Prophet. O you who have believed, ask [Allah to confer] blessing upon him and ask [Allah to grant him] peace.",
      surahNameAr: "الأحزاب",
      surahNameEn: "Al-Ahzab",
    ),
    PredefinedVerse(
      surahNumber: 49,
      ayahNumber: 10,
      arabic:
          "إِنَّمَا الْمُؤْمِنُونَ إِخْوَةٌ فَأَصْلِحُوا بَيْنَ أَخَوَيْكُمْ",
      translation:
          "The believers are but brothers, so make settlement between your brothers.",
      surahNameAr: "الحجرات",
      surahNameEn: "Al-Hujurat",
    ),
    PredefinedVerse(
      surahNumber: 49,
      ayahNumber: 12,
      arabic:
          "يَا أَيُّهَا الَّذِينَ آمَنُوا اجْتَنِبُوا كَثِيرًا مِّنَ الظَّنِّ إِنَّ بَعْضَ الظَّنِّ إِثْمٌ",
      translation:
          "O you who have believed, avoid much [negative] assumption. Indeed, some assumption is sin.",
      surahNameAr: "الحجرات",
      surahNameEn: "Al-Hujurat",
    ),
    PredefinedVerse(
      surahNumber: 29,
      ayahNumber: 69,
      arabic: "وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا",
      translation:
          "And those who strive for Us - We will surely guide them to Our ways.",
      surahNameAr: "العنكبوت",
      surahNameEn: "Al-'Ankabut",
    ),
    PredefinedVerse(
      surahNumber: 8,
      ayahNumber: 30,
      arabic:
          "وَيَمْكُرُونَ وَيَمْكُرُ اللَّهُ ۖ وَاللَّهُ خَيْرُ الْمَاكِرِينَ",
      translation:
          "But they plan, and Allah plans. And Allah is the best of planners.",
      surahNameAr: "الأنفال",
      surahNameEn: "Al-Anfal",
    ),
    PredefinedVerse(
      surahNumber: 112,
      ayahNumber: 1,
      arabic: "قُلْ هُوَ اللَّهُ أَحَدٌ",
      translation: "Say, \"He is Allah, [who is] One.\"",
      surahNameAr: "الإخلاص",
      surahNameEn: "Al-Ikhlas",
    ),
    PredefinedVerse(
      surahNumber: 25,
      ayahNumber: 65,
      arabic:
          "رَبَّنَا اصْرِفْ عَنَّا عَذَابَ جَهَنَّمَ ۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا",
      translation:
          "Our Lord, avert from us the punishment of Hell. Indeed, its punishment is ever adhering.",
      surahNameAr: "الفرقان",
      surahNameEn: "Al-Furqan",
    ),
    PredefinedVerse(
      surahNumber: 4,
      ayahNumber: 86,
      arabic:
          "وَإِذَا حُيِّيتُم بِتَحِيَّةٍ فَحَيُّوا بِأَحْسَنَ مِنْهَا أَوْ رُدُّوهَا",
      translation:
          "And when you are greeted with a greeting, greet with one better than it or return it.",
      surahNameAr: "النساء",
      surahNameEn: "An-Nisa",
    ),
    PredefinedVerse(
      surahNumber: 17,
      ayahNumber: 23,
      arabic:
          "وَقَضَىٰ رَبُّكَ أَلَّا تَعْبُدُوا إِلَّا إِيَّاهُ وَبِالْوَالِدَيْنِ إِحْسَانًا",
      translation:
          "And your Lord has decreed that you not worship except Him, and to parents, good treatment.",
      surahNameAr: "الإسراء",
      surahNameEn: "Al-Isra",
    ),
    PredefinedVerse(
      surahNumber: 67,
      ayahNumber: 19,
      arabic:
          "أَوَلَمْ يَرَوْا إِلَى الطَّيْرِ فَوْقَهُمْ صَافَّاتٍ وَيَقْبِضْنَ ۚ مَا يُمْسِكُهُنَّ إِلَّا الرَّحْمَٰنُ",
      translation:
          "Do they not see the birds above them with wings outspread and [sometimes] folded? None holds them except the Most Merciful.",
      surahNameAr: "الملك",
      surahNameEn: "Al-Mulk",
    ),
  ];
}
