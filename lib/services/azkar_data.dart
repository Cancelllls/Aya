class AzkarItem {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int count;
  final String reference;

  AzkarItem({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.count,
    required this.reference,
  });
}

class NameOfAllah {
  final int number;
  final String arabic;
  final String transliteration;
  final String translation;

  NameOfAllah({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

class AzkarData {
  static List<List<AzkarItem>> get allCategories => [
    morning, evening, postPrayer, daily,
    sleepWaking, salahSpecific, lifeEvents,
    protectionRuqyah, forgivenessTawbah,
  ];

  static final List<AzkarItem> morning = [
    AzkarItem(
      id: "m1",
      arabic:
          "أَعُوذُ بِاللهِ مِنَ الشَّيْطَانِ الرَّجِيمِ: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۚ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۚ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ.",
      transliteration:
          "A'oodhu billaahi minash-Shaytaanir-Rajeem. Allaahu laa 'ilaaha 'illaa Huwal-Hayyul-Qayyoom, laa ta'khudhuhu sinatun wa laa nawm, lahu maa fis-samaawaati wa maa fil-'ardh, man dhal-ladhee yashfa'u 'indahu 'illaa bi'idhnih, ya'lamu maa bayna 'aydeehim wa maa khalfahum, wa laa yuheetoona bishay'im-min 'ilmihi 'illaa bimaa shaa'a, wasi'a kursiyyuhus-samaawaati wal-'ardh, wa laa ya'ooduhu hifdhuhumaa, wa Huwal-'Aliyyul-'Adheem.",
      translation:
          "Allahu! There is no deity but He, the Living, the Sustainer of all. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great. (Ayat al-Kursi)",
      count: 1,
      reference: "Surah Al-Baqarah 2:255",
    ),
    AzkarItem(
      id: "m2",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ. اللَّهُ الصَّمَدُ. لَمْ يَلِدْ وَلَمْ يُولَدْ. وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul Huwallaahu 'Ahad. Allaahus-Samad. Lam yalid wa lam yoolad. Wa lam yakul-lahu kufuwan 'ahad.",
      translation:
          "In the Name of Allah, the Most Gracious, the Most Merciful. Say: He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent. (Surah Al-Ikhlas)",
      count: 3,
      reference:
          "Abu Dawud & Al-Tirmidhi - Recited 3 times morning & evening suffices everything.",
    ),
    AzkarItem(
      id: "m3",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ. مِن شَرِّ مَا خَلَقَ. وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ. وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ. وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul 'a'oodhu birabbil-falaq. Min sharri maa khalaq. Wa min sharri ghaasiqin 'idhaa waqab. Wa min sharrin-naffaathaati fil-'uqad. Wa min sharri haasidin 'idhaa hasad.",
      translation:
          "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of daybreak from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies. (Surah Al-Falaq)",
      count: 3,
      reference: "Abu Dawud & Al-Tirmidhi",
    ),
    AzkarItem(
      id: "m4",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ. مَلِكِ النَّاسِ. إِلَٰهِ النَّاسِ. مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ. الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ. مِنَ الْجِنَّةِ وَالنَّاسِ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul 'a'oodhu birabbin-naas. Malikin-naas. 'Ilaahin-naas. Min sharril-waswaasil-khannaas. Alladhee yuwaswisu fee sudoorin-naas. Minal-jinnati wannaas.",
      translation:
          "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer - who whispers [evil] into the breasts of mankind - from among the jinn and mankind. (Surah An-Nas)",
      count: 3,
      reference: "Abu Dawud & Al-Tirmidhi",
    ),
    AzkarItem(
      id: "m5",
      arabic:
          "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ، وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.",
      transliteration:
          "Asbahnaa wa 'asbahal-mulku lillaahi walhamdu lillaahi, laa 'ilaaha 'illallaahu wahdahu laa shareeka lahu, lahul-mulku wa lahul-hamdu wa Huwa 'alaa kulli shay'in Qadeer. Rabbi 'as'aluka khayra maa fee hadhal-yawmi wa khayra maa ba'dahu, wa 'a'oodhu bika min sharri maa fee hadhal-yawmi wa sharri maa ba'dahu, Rabbi 'a'oodhu bika minal-kasali wa soo'il-kibar, Rabbi 'a'oodhu bika min 'adhaabin fin-naari wa 'adhaabin fil-qabr.",
      translation:
          "We have entered the morning and at this very time the whole universe belongs to Allah, and all praise is for Allah. There is no deity but Allah, Alone, with no partner. His is the sovereignty and His is the praise, and He is Able to do all things. My Lord, I ask You for the good of this day and the good of what follows it, and I seek refuge in You from the evil of this day and the evil of what follows it. My Lord, I seek refuge in You from laziness and senility. My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.",
      count: 1,
      reference: "Muslim 4/2088",
    ),
    AzkarItem(
      id: "m6",
      arabic:
          "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.",
      transliteration:
          "Allaahumma 'Anta Rabbee laa 'ilaaha 'illaa 'Anta, khalaqtanee wa 'anaa 'abduka, wa 'anaa 'alaa 'ahdika wa wa'dika mas-tata'tu, 'a'oodhu bika min sharri maa sana'tu, 'aboo'u laka bini'matika 'alayya, wa 'aboo'u bidhanbee faghfir lee fa'innahu laa yaghfirudh-dhunooba 'illaa 'Anta.",
      translation:
          "O Allah, You are my Lord, there is no deity but You. You created me and I am Your servant, and I am faithful to Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge before You Your favor upon me, and I acknowledge my sin, so forgive me, for indeed, no one forgives sins except You. (Sayyid al-Istighfar)",
      count: 1,
      reference:
          "Al-Bukhari 7/150 - Entry to Paradise if recited and dying on the same day.",
    ),
    AzkarItem(
      id: "m7",
      arabic:
          "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ.",
      transliteration:
          "Allaahumma bika 'asbahnaa, wa bika 'amsaynaa, wa bika nahyaa, wa bika namootu wa 'ilaykan-nushoor.",
      translation:
          "O Allah, by Your leave we have reached the morning and by Your leave we have reached the evening, by Your leave we live and by Your leave we die, and unto You is our resurrection.",
      count: 1,
      reference: "Al-Tirmidhi 3/142",
    ),
    AzkarItem(
      id: "m8",
      arabic:
          "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.",
      transliteration:
          "Bismillaahil-ladhee laa yadhurru ma'as-mihi shay'un fil-'ardhi wa laa fis-samaa'i wa Huwas-Samee'ul-'Aleem.",
      translation:
          "In the Name of Allah, Who with His Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
      count: 3,
      reference:
          "Abu Dawud 4/323 - Nothing will harm whoever recites it 3 times.",
    ),
    AzkarItem(
      id: "m9",
      arabic:
          "رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالْإِسْلَامِ دِيناً، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيَّاً.",
      transliteration:
          "Radheetu billaahi Rabban, wa bil-'Islaami deenan, wa bi-Muhammadin (sallallaahu 'alayhi wa sallam) Nabiyyan.",
      translation:
          "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.",
      count: 3,
      reference:
          "Abu Dawud & Al-Tirmidhi - Guaranteed Allah's pleasure on the Day of Resurrection.",
    ),
    AzkarItem(
      id: "m10",
      arabic:
          "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.",
      transliteration:
          "Hasbiyallaahu laa 'ilaaha 'illaa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem.",
      translation:
          "Allah is sufficient for me. There is no deity but He. Over Him I rely and He is the Lord of the Great Throne.",
      count: 7,
      reference:
          "Abu Dawud 4/321 - Allah will suffice him for whatever concerns him.",
    ),
    AzkarItem(
      id: "m11",
      arabic:
          "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.",
      transliteration:
          "Yaa Hayyu yaa Qayyoomu birahmatika 'astagheethu 'aslih lee sha'nee kullahu wa laa takilnee 'ilaa nafsee tarfata 'aynin.",
      translation:
          "O Ever Living One, O Self-Sustaining One, in Your mercy I seek relief. Correct all of my affairs for me and do not leave me to myself even for the blink of an eye.",
      count: 1,
      reference: "Al-Hakim 1/545",
    ),
    AzkarItem(
      id: "m12",
      arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.",
      transliteration: "Subhaanallaahi wa bihamdih.",
      translation: "Glory be to Allah and His is the praise.",
      count: 100,
      reference:
          "Muslim 4/2071 - Sins are wiped away even if they are like the foam of the sea.",
    ),
  ];

  static final List<AzkarItem> evening = [
    AzkarItem(
      id: "e1",
      arabic:
          "أَعُوذُ بِاللهِ مِنَ الشَّيْطَانِ الرَّجِيمِ: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۚ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۚ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ.",
      transliteration:
          "A'oodhu billaahi minash-Shaytaanir-Rajeem. Allaahu laa 'ilaaha 'illaa Huwal-Hayyul-Qayyoom, laa ta'khudhuhu sinatun wa laa nawm, lahu maa fis-samaawaati wa maa fil-'ardh, man dhal-ladhee yashfa'u 'indahu 'illaa bi'idhnih, ya'lamu maa bayna 'aydeehim wa maa khalfahum, wa laa yuheetoona bishay'im-min 'ilmihi 'illaa bimaa shaa'a, wasi'a kursiyyuhus-samaawaati wal-'ardh, wa laa ya'ooduhu hifdhuhumaa, wa Huwal-'Aliyyul-'Adheem.",
      translation:
          "Allahu! There is no deity but He, the Living, the Sustainer of all. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great. (Ayat al-Kursi)",
      count: 1,
      reference: "Surah Al-Baqarah 2:255",
    ),
    AzkarItem(
      id: "e2",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ. اللَّهُ الصَّمَدُ. لَمْ يَلِدْ وَلَمْ يُولَدْ. وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul Huwallaahu 'Ahad. Allaahus-Samad. Lam yalid wa lam yoolad. Wa lam yakul-lahu kufuwan 'ahad.",
      translation:
          "In the Name of Allah, the Most Gracious, the Most Merciful. Say: He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent. (Surah Al-Ikhlas)",
      count: 3,
      reference: "Abu Dawud & Al-Tirmidhi",
    ),
    AzkarItem(
      id: "e3",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ. مِن شَرِّ مَا خَلَقَ. وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ. وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ. وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul 'a'oodhu birabbil-falaq. Min sharri maa khalaq. Wa min sharri ghaasiqin 'idhaa waqab. Wa min sharrin-naffaathaati fil-'uqad. Wa min sharri haasidin 'idhaa hasad.",
      translation:
          "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of daybreak from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies. (Surah Al-Falaq)",
      count: 3,
      reference: "Abu Dawud & Al-Tirmidhi",
    ),
    AzkarItem(
      id: "e4",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ. مَلِكِ النَّاسِ. إِلَٰهِ النَّاسِ. مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ. الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ. مِنَ الْجِنَّةِ وَالنَّاسِ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul 'a'oodhu birabbin-naas. Malikin-naas. 'Ilaahin-naas. Min sharril-waswaasil-khannaas. Alladhee yuwaswisu fee sudoorin-naas. Minal-jinnati wannaas.",
      translation:
          "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer - who whispers [evil] into the breasts of mankind - from among the jinn and mankind. (Surah An-Nas)",
      count: 3,
      reference: "Abu Dawud & Al-Tirmidhi",
    ),
    AzkarItem(
      id: "e5",
      arabic:
          "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ، وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.",
      transliteration:
          "Amsaynaa wa 'amsayal-mulku lillaahi walhamdu lillaahi, laa 'ilaaha 'illallaahu wahdahu laa shareeka lahu, lahul-mulku wa lahul-hamdu wa Huwa 'alaa kulli shay'in Qadeer. Rabbi 'as'aluka khayra maa fee hadhihil-laylati wa khayra maa ba'dahaa, wa 'a'oodhu bika min sharri maa fee hadhihil-laylati wa sharri maa ba'dahaa, Rabbi 'a'oodhu bika minal-kasali wa soo'il-kibar, Rabbi 'a'oodhu bika min 'adhaabin fin-naari wa 'adhaabin fil-qabr.",
      translation:
          "We have entered the evening and at this very time the whole universe belongs to Allah, and all praise is for Allah. There is no deity but Allah, Alone, with no partner. His is the sovereignty and His is the praise, and He is Able to do all things. My Lord, I ask You for the good of this night and the good of what follows it, and I seek refuge in You from the evil of this night and the evil of what follows it. My Lord, I seek refuge in You from laziness and senility. My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.",
      count: 1,
      reference: "Muslim 4/2088",
    ),
    AzkarItem(
      id: "e6",
      arabic:
          "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.",
      transliteration:
          "Allaahumma 'Anta Rabbee laa 'ilaaha 'illaa 'Anta, khalaqtanee wa 'anaa 'abduka, wa 'anaa 'alaa 'ahdika wa wa'dika mas-tata'tu, 'a'oodhu bika min sharri maa sana'tu, 'aboo'u laka bini'matika 'alayya, wa 'aboo'u bidhanbee faghfir lee fa'innahu laa yaghfirudh-dhunooba 'illaa 'Anta.",
      translation:
          "O Allah, You are my Lord, there is no deity but You. You created me and I am Your servant, and I am faithful to Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge before You Your favor upon me, and I acknowledge my sin, so forgive me, for indeed, no one forgives sins except You. (Sayyid al-Istighfar)",
      count: 1,
      reference: "Al-Bukhari 7/150",
    ),
    AzkarItem(
      id: "e7",
      arabic:
          "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ.",
      transliteration:
          "Allaahumma bika 'amsaynaa, wa bika 'asbahnaa, wa bika nahyaa, wa bika namootu wa 'ilaykal-maseer.",
      translation:
          "O Allah, by Your leave we have reached the evening and by Your leave we have reached the morning, by Your leave we live and by Your leave we die, and unto You is our return.",
      count: 1,
      reference: "Al-Tirmidhi 3/142",
    ),
    AzkarItem(
      id: "e8",
      arabic:
          "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.",
      transliteration:
          "Bismillaahil-ladhee laa yadhurru ma'as-mihi shay'un fil-'ardhi wa laa fis-samaa'i wa Huwas-Samee'ul-'Aleem.",
      translation:
          "In the Name of Allah, Who with His Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
      count: 3,
      reference: "Abu Dawud 4/323",
    ),
    AzkarItem(
      id: "e9",
      arabic:
          "رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالْإِسْلَامِ دِيناً، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيَّاً.",
      transliteration:
          "Radheetu billaahi Rabban, wa bil-'Islaami deenan, wa bi-Muhammadin (sallallaahu 'alayhi wa sallam) Nabiyyan.",
      translation:
          "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.",
      count: 3,
      reference: "Abu Dawud & Al-Tirmidhi",
    ),
    AzkarItem(
      id: "e10",
      arabic:
          "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.",
      transliteration:
          "Hasbiyallaahu laa 'ilaaha 'illaa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem.",
      translation:
          "Allah is sufficient for me. There is no deity but He. Over Him I rely and He is the Lord of the Great Throne.",
      count: 7,
      reference: "Abu Dawud 4/321",
    ),
    AzkarItem(
      id: "e11",
      arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.",
      transliteration:
          "A'oodhu bikalimaatillaahit-taammaati min sharri maa khalaq.",
      translation:
          "I seek refuge in the perfect words of Allah from the evil of what He has created.",
      count: 3,
      reference:
          "Al-Tirmidhi 3/187 - Protected from poisonous bites and general evil at night.",
    ),
    AzkarItem(
      id: "e12",
      arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.",
      transliteration: "Subhaanallaahi wa bihamdih.",
      translation: "Glory be to Allah and His is the praise.",
      count: 100,
      reference: "Muslim 4/2071",
    ),
  ];

  static final List<AzkarItem> postPrayer = [
    AzkarItem(
      id: "p1",
      arabic:
          "أَسْتَغْفِرُ اللهَ ، أَسْتَغْفِرُ اللهَ ، أَسْتَغْفِرُ اللهَ. اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.",
      transliteration:
          "Astaghfirullaah, Astaghfirullaah, Astaghfirullaah. Allaahumma 'Antas-Salaamu wa minkas-salaamu, tabaarakta yaa Dhal-Jalaali wal-'Ikraam.",
      translation:
          "I seek the forgiveness of Allah (three times). O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honor.",
      count: 1,
      reference: "Muslim 1/414",
    ),
    AzkarItem(
      id: "p2",
      arabic:
          "لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ، لَا إِلَهَ إِلَّا اللهُ وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلَهَ إِلَّا اللهُ مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ.",
      transliteration:
          "Laa 'ilaaha 'illallaahu wahdahu laa shareeka lahu, lahul-mulku wa lahul-hamdu wa Huwa 'alaa kulli shay'in Qadeer. Laa hawla wa laa quwwata 'illaa billaah, laa 'ilaaha 'illallaahu wa laa na'budu 'illaa 'iyyaah, lahun-ni'matu wa lahul-fadhlu wa lahuth-thanaa'ul-hasan, laa 'ilaaha 'illallaahu mukhliseena lahud-deena wa law karihal-kaafiroon.",
      translation:
          "There is no deity but Allah Alone, with no partner. His is the sovereignty and His is the praise, and He is Able to do all things. There is no might or power except with Allah. There is no deity but Allah, and we worship none but Him. To Him belongs all favor, grace, and noble praise. There is no deity but Allah, to Whom we are sincere in devotion, even if the disbelievers dislike it.",
      count: 1,
      reference: "Muslim 1/415",
    ),
    AzkarItem(
      id: "p3",
      arabic:
          "اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ.",
      transliteration:
          "Allaahumma laa maani'a limaa 'a'tayta, wa laa mu'tiya limaa mana'ta, wa laa yanfa'u dhal-jaddi minkal-jadd.",
      translation:
          "O Allah, none can prevent what You have given, and none can give what You have prevented, and no wealth or majesty can benefit its possessor against You.",
      count: 1,
      reference: "Al-Bukhari 1/205, Muslim 1/414",
    ),
    AzkarItem(
      id: "p4",
      arabic:
          "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ، وَشُكْرِكَ، وَحُسْنِ عِبَادَتِكَ.",
      transliteration:
          "Allaahumma 'a'innee 'alaa dhikrika, wa shukrika, wa husni 'ibaadatik.",
      translation:
          "O Allah, help me to remember You, to give thanks to You, and to worship You in the best manner.",
      count: 1,
      reference: "Abu Dawud 2/86, An-Nasa'i 3/53",
    ),
    AzkarItem(
      id: "p5",
      arabic: "سُبْحَانَ اللهِ ، وَالْحَمْدُ للهِ ، وَاللهُ أَكْبَرُ.",
      transliteration: "Subhaanallaah, Walhamdulillaah, Wallaahu 'Akbar.",
      translation:
          "Glory be to Allah, Praise be to Allah, Allah is the Greatest. (Recited 33 times each)",
      count: 33,
      reference: "Muslim 1/418",
    ),
    AzkarItem(
      id: "p6",
      arabic:
          "لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
      transliteration:
          "Laa 'ilaaha 'illallaahu wahdahu laa shareeka lahu, lahul-mulku wa lahul-hamdu wa Huwa 'alaa kulli shay'in Qadeer.",
      translation:
          "There is no deity but Allah Alone, with no partner. His is the sovereignty and His is the praise, and He is Able to do all things. (Recite once after Tasbih to complete 100)",
      count: 1,
      reference: "Muslim 1/418",
    ),
    AzkarItem(
      id: "p7",
      arabic:
          "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۚ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۚ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ.",
      transliteration:
          "Allaahahu laa 'ilaaha 'illaa Huwal-Hayyul-Qayyoom, laa ta'khudhuhu sinatun wa laa nawm, lahu maa fis-samaawaati wa maa fil-'ardh, man dhal-ladhee yashfa'u 'indahu 'illaa bi'idhnih, ya'lamu maa bayna 'aydeehim wa maa khalfahum, wa laa yuheetoona bishay'im-min 'ilmihi 'illaa bimaa shaa'a, wasi'a kursiyyuhus-samaawaati wal-'ardh, wa laa ya'ooduhu hifdhuhumaa, wa Huwal-'Aliyyul-'Adheem.",
      translation:
          "Allahu! There is no deity but He, the Living, the Sustainer of all. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great. (Ayat al-Kursi)",
      count: 1,
      reference: "An-Nasa'i - Recited after every obligatory prayer.",
    ),
    AzkarItem(
      id: "p8",
      arabic:
          "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ. اللَّهُ الصَّمَدُ. لَمْ يَلِدْ وَلَمْ يُولَدْ. وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ. بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ. مِن شَرِّ مَا خَلَقَ. وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ. وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ. وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ. بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ. مَلِكِ النَّاسِ. إِلَٰهِ النَّاسِ. مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ. الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ. مِنَ الْجِنَّةِ وَالنَّاسِ.",
      transliteration:
          "Bismillaahir-Rahmaanir-Raheem. Qul Huwallaahu 'Ahad. Allaahus-Samad. Lam yalid wa lam yoolad. Wa lam yakul-lahu kufuwan 'ahad. Bismillaahir-Rahmaanir-Raheem. Qul 'a'oodhu birabbil-falaq... Bismillaahir-Rahmaanir-Raheem. Qul 'a'oodhu birabbin-naas...",
      translation: "Surah Al-Ikhlas, Surah Al-Falaq, and Surah An-Nas.",
      count: 1,
      reference:
          "Abu Dawud & Al-Tirmidhi - Recited after every obligatory prayer.",
    ),
  ];

  static final List<AzkarItem> daily = [
    AzkarItem(
      id: "d1",
      arabic:
          "بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ.",
      transliteration:
          "Bismillaahi, tawakkaltu 'alallaahi, wa laa hawla wa laa quwwata 'illaa billaah.",
      translation:
          "In the name of Allah, I place my trust in Allah, and there is no might or power except with Allah. (Dua when leaving home)",
      count: 1,
      reference: "Abu Dawud 4/325",
    ),
    AzkarItem(
      id: "d2",
      arabic:
          "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.",
      transliteration:
          "Rabbanaa 'aatinaa fid-dunyaa hasanatan wa fil-'Aakhirati hasanatan wa qinaa 'adhaaban-Naar.",
      translation:
          "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.",
      count: 1,
      reference: "Surah Al-Baqarah 2:201",
    ),
  ];

  // ========== SLEEP / WAKING AZKAR ==========
  static final List<AzkarItem> sleepWaking = [
    AzkarItem(
      id: "sw1",
      arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.",
      transliteration: "Bismika Allaahumma 'amootu wa 'ahyaa.",
      translation: "In Your name, O Allah, I die and I live. (Before sleeping)",
      count: 1,
      reference: "Al-Bukhari 6324",
    ),
    AzkarItem(
      id: "sw2",
      arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.",
      transliteration: "Alhamdu lillaahil-ladhee 'ahyaanaa ba'da maa 'amaatanaa wa 'ilayhin-nushoor.",
      translation: "All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection. (Upon waking up)",
      count: 1,
      reference: "Al-Bukhari 6312",
    ),
    AzkarItem(
      id: "sw3",
      arabic: "اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ.",
      transliteration: "Allaahumma 'aslamtu nafsee 'ilayka, wa wajjahtu wajhee 'ilayka, wa fawwadhtu 'amree 'ilayka, wa 'alja'tu dhahree 'ilayka, raghbatan wa rahbatan 'ilayka, laa malja'a wa laa manjaa minka 'illaa 'ilayka, 'aamantu bikitaabikal-ladhee 'anzalta, wa binabiyyikal-ladhee 'arsalta.",
      translation: "O Allah, I submit myself to You, I turn my face to You, I entrust my affairs to You, and I lean my back upon You, out of hope and fear of You. There is no refuge or escape from You except to You. I believe in Your Book which You have revealed and in Your Prophet whom You have sent. (Before sleeping — if you die that night, you die upon fitrah)",
      count: 1,
      reference: "Al-Bukhari 247, Muslim 2710",
    ),
    AzkarItem(
      id: "sw4",
      arabic: "سُبْحَانَ اللهِ (٣٣)، الْحَمْدُ لِلَّهِ (٣٣)، اللهُ أَكْبَرُ (٣٤).",
      transliteration: "Subhaanallaah (33x), Alhamdulillaah (33x), Allaahu 'Akbar (34x).",
      translation: "Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (34 times). (Recite before sleeping — better than a servant to help you)",
      count: 100,
      reference: "Al-Bukhari 3705, Muslim 2727",
    ),
    AzkarItem(
      id: "sw5",
      arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.",
      transliteration: "Allaahumma qinee 'adhaabaka yawma tab'athu 'ibaadak.",
      translation: "O Allah, protect me from Your punishment on the Day You resurrect Your servants. (Before sleep)",
      count: 3,
      reference: "Abu Dawud 5045",
    ),
    AzkarItem(
      id: "sw6",
      arabic: "اللَّهُمَّ رَبَّ السَّمَاوَاتِ وَرَبَّ الْأَرْضِ وَرَبَّ الْعَرْشِ الْعَظِيمِ، رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى، وَمُنْزِلَ التَّوْرَاةِ وَالْإِنْجِيلِ وَالْفُرْقَانِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ شَيْءٍ أَنْتَ آخِذٌ بِنَاصِيَتِهِ، اللَّهُمَّ أَنْتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ، وَأَنْتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ، وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ، وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنِنَا مِنَ الْفَقْرِ.",
      transliteration: "Allaahumma Rabbas-samaawaati wa Rabbal-'ardhi wa Rabbal-'Arshil-'Adheem, Rabbanaa wa Rabba kulli shay', Faaliqal-habbi wan-nawaa, wa Munzilat-Tawraati wal-'Injeeli wal-Furqaan, 'a'oodhu bika min sharri kulli shay'in 'Anta 'aakhidhun binaasiyatih. Allaahumma 'Antal-'Awwalu fa laysa qablaka shay', wa 'Antal-'Aakhiru fa laysa ba'daka shay', wa 'Antadh-Dhaahiru fa laysa fawqaka shay', wa 'Antal-Baatinu fa laysa doonaka shay', iqdhi 'annad-dayna wa 'aghninaa minal-faqr.",
      translation: "O Allah, Lord of the heavens and the earth and Lord of the Great Throne, our Lord and Lord of everything, Splitter of the grain and the date-stone, Revealer of the Torah, the Gospel, and the Furqan (Quran), I seek refuge in You from the evil of everything that You seize by the forelock. O Allah, You are the First, there is nothing before You; You are the Last, there is nothing after You; You are the Manifest, there is nothing above You; You are the Hidden, there is nothing beyond You. Settle our debt and enrich us from poverty. (Before sleep)",
      count: 1,
      reference: "Muslim 2713",
    ),
  ];

  // ========== SALAH-SPECIFIC AZKAR ==========
  static final List<AzkarItem> salahSpecific = [
    AzkarItem(
      id: "ss1",
      arabic: "اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحمُودًا الَّذِي وَعَدْتَهُ.",
      transliteration: "Allaahumma Rabba haadhihid-da'watit-taammah, was-Salaatil-qaa'imah, 'aati Muhammadanil-waseelata wal-fadheelah, wab'athhu maqaaman mahmoodanil-ladhee wa'adtah.",
      translation: "O Allah, Lord of this perfect call and established prayer, grant Muhammad the Wasilah (a station in Paradise) and the Fadheelah (superiority over creation), and raise him to the Praised Station which You promised him. (After the Adhan)",
      count: 1,
      reference: "Al-Bukhari 614",
    ),
    AzkarItem(
      id: "ss2",
      arabic: "اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي لِسَانِي نُورًا، وَفِي سَمْعِي نُورًا، وَفِي بَصَرِي نُورًا، وَمِنْ فَوْقِي نُورًا، وَمِنْ تَحْتِي نُورًا، وَعَنْ يَمِينِي نُورًا، وَعَنْ شِمَالِي نُورًا، وَمِنْ أَمَامِي نُورًا، وَمِنْ خَلْفِي نُورًا، وَاجْعَلْ فِي نَفْسِي نُورًا، وَأَعْظِمْ لِي نُورًا.",
      transliteration: "Allaahummaj'al fee qalbee noora, wa fee lisaanee noora, wa fee sam'ee noora, wa fee basaree noora, wa min fawqee noora, wa min tahtee noora, wa 'an yameenee noora, wa 'an shimaalee noora, wa min 'amaamee noora, wa min khalfee noora, waj'al fee nafsee noora, wa 'a'dhim lee noora.",
      translation: "O Allah, place light in my heart, light on my tongue, light in my hearing, light in my sight, light above me, light below me, light on my right, light on my left, light in front of me, light behind me, place light in my soul, and magnify light for me. (Dua when going to the masjid)",
      count: 1,
      reference: "Al-Bukhari 6316, Muslim 763",
    ),
    AzkarItem(
      id: "ss3",
      arabic: "اللَّهُمَّ اغْفِرْ لِي ذُنُوبِي، وَافْتَحْ لِي أَبْوَابَ رَحْمَتِكَ.",
      transliteration: "Allaahummagh-fir lee dhunoobee, waftah lee 'abwaaba rahmatik.",
      translation: "O Allah, forgive my sins and open for me the doors of Your mercy. (When entering the masjid)",
      count: 1,
      reference: "Muslim 713",
    ),
    AzkarItem(
      id: "ss4",
      arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ.",
      transliteration: "Allaahumma 'innee 'as'aluka min fadhlik.",
      translation: "O Allah, I ask You from Your bounty. (When leaving the masjid)",
      count: 1,
      reference: "Muslim 713",
    ),
    AzkarItem(
      id: "ss5",
      arabic: "اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ. اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِيَ الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ.",
      transliteration: "Allaahumma 'innee 'astakheeruka bi'ilmika, wa 'astaqdiruka biqudratika, wa 'as'aluka min fadhlikal-'adheem, fa'innaka taqdiru wa laa 'aqdiru, wa ta'lamu wa laa 'a'lamu, wa 'Anta 'Allaamul-Ghuyoob. Allaahumma 'in kunta ta'lamu 'anna haadhal-'amra khayrun lee fee deenee wa ma'aashee wa 'aaqibati 'amree faqdurhu lee wa yassirhu lee thumma baarik lee feeh, wa 'in kunta ta'lamu 'anna haadhal-'amra sharrun lee fee deenee wa ma'aashee wa 'aaqibati 'amree fasrifhu 'annee wasrifnee 'anh, waqdur liyal-khayra haythu kaana thumma 'ardhinee bih.",
      translation: "O Allah, I seek Your guidance by Your knowledge, and I seek empowerment by Your power, and I ask You from Your immense bounty. For You have power and I have none; You know and I know not; You are the Knower of hidden things. O Allah, if You know this matter to be good for my religion, my livelihood, and the outcome of my affairs, then decree it for me, facilitate it for me, and bless me in it. If You know this matter to be evil for my religion, my livelihood, and the outcome of my affairs, then turn it away from me and turn me away from it, and decree for me good wherever it may be, and make me content with it. (Salat al-Istikhara)",
      count: 1,
      reference: "Al-Bukhari 1162",
    ),
    AzkarItem(
      id: "ss6",
      arabic: "اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لِي فِيمَا أَعْطَيْتَ، وَقِنِي شَرَّ مَا قَضَيْتَ، فَإِنَّكَ تَقْضِي وَلَا يُقْضَى عَلَيْكَ، وَإِنَّهُ لَا يَذِلُّ مَنْ وَالَيْتَ وَلَا يَعِزُّ مَنْ عَادَيْتَ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ.",
      transliteration: "Allaahummah-dinee feeman hadayta, wa 'aafinee feeman 'aafayta, wa tawallanee feeman tawallayta, wa baarik lee feemaa 'a'tayta, wa qinee sharra maa qadhayta, fa'innaka taqdhee wa laa yuqdhaa 'alayka, wa 'innahu laa yadhillu man waalayta wa laa ya'izzu man 'aadayta, tabaarakta Rabbanaa wa ta'aalayta.",
      translation: "O Allah, guide me among those whom You have guided, grant me well-being among those You have granted well-being, protect me among those You have protected, bless for me what You have given me, and shield me from the evil of what You have decreed. Blessed are You, our Lord, and Exalted. (Qunoot in Witr)",
      count: 1,
      reference: "Abu Dawud 1425, At-Tirmidhi 464",
    ),
    AzkarItem(
      id: "ss7",
      arabic: "التَّحِيَّاتُ لِلَّهِ، وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللهِ الصَّالِحِينَ. أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ.",
      transliteration: "At-Tahiyyaatu lillaahi was-Salawaatu wat-Tayyibaat. As-Salaamu 'alayka 'ayyuhan-Nabiyyu wa rahmatullaahi wa barakaatuh. As-Salaamu 'alaynaa wa 'alaa 'ibaadillaahis-saaliheen. 'Ash-hadu 'allaa 'ilaaha 'illallaahu, wa 'ash-hadu 'anna Muhammadan 'abduhu wa Rasooluh.",
      translation: "All greetings, prayers, and pure words are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no deity but Allah, and I bear witness that Muhammad is His servant and Messenger. (At-Tashahhud)",
      count: 1,
      reference: "Al-Bukhari 831, Muslim 402",
    ),
    AzkarItem(
      id: "ss8",
      arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ.",
      transliteration: "Allaahumma salli 'alaa Muhammadin wa 'alaa 'aali Muhammadin, kamaa sallayta 'alaa 'Ibraaheema wa 'alaa 'aali 'Ibraaheem, 'innaka Hameedun Majeed. Allaahumma baarik 'alaa Muhammadin wa 'alaa 'aali Muhammadin, kamaa baarakta 'alaa 'Ibraaheema wa 'alaa 'aali 'Ibraaheem, 'innaka Hameedun Majeed.",
      translation: "O Allah, send Your blessings upon Muhammad and the family of Muhammad, as You sent blessings upon Ibrahim and the family of Ibrahim. Indeed, You are Praiseworthy, Glorious. O Allah, send Your grace upon Muhammad and the family of Muhammad, as You sent grace upon Ibrahim and the family of Ibrahim. Indeed, You are Praiseworthy, Glorious. (Salawat Ibrahimiyyah)",
      count: 1,
      reference: "Al-Bukhari 3370, Muslim 406",
    ),
  ];

  // ========== LIFE EVENTS AZKAR ==========
  static final List<AzkarItem> lifeEvents = [
    AzkarItem(
      id: "le1",
      arabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ. وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ.",
      transliteration: "Subhaanal-ladhee sakhkhara lanaa haadhaa wa maa kunnaa lahu muqrineen. Wa 'innaa 'ilaa Rabbinaa lamunqaliboon.",
      translation: "Glory be to the One who has subjected this for us, for we could never have accomplished it. And indeed, to our Lord we will return. (When mounting a vehicle / travel)",
      count: 1,
      reference: "Surah Az-Zukhruf 43:13-14",
    ),
    AzkarItem(
      id: "le2",
      arabic: "اللَّهُمَّ صَيِّبًا نَافِعًا.",
      transliteration: "Allaahumma sayyiban naafi'an.",
      translation: "O Allah, (make it) a beneficial rain. (When it rains)",
      count: 1,
      reference: "Al-Bukhari 1032",
    ),
    AzkarItem(
      id: "le3",
      arabic: "مُطِرْنَا بِفَضْلِ اللَّهِ وَرَحْمَتِهِ.",
      transliteration: "Mutirnaa bifadhlillaahi wa rahmatih.",
      translation: "We have received rain by the grace of Allah and His mercy. (After rainfall)",
      count: 1,
      reference: "Al-Bukhari 846",
    ),
    AzkarItem(
      id: "le4",
      arabic: "اللَّهُمَّ حَوَالَيْنَا وَلَا عَلَيْنَا.",
      transliteration: "Allaahumma hawaalaynaa wa laa 'alaynaa.",
      translation: "O Allah, around us and not upon us. (When rain is excessive)",
      count: 1,
      reference: "Al-Bukhari 1013",
    ),
    AzkarItem(
      id: "le5",
      arabic: "الْحَمْدُ لِلَّهِ الَّذِي كَسَانِي هَذَا الثَّوْبَ وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ.",
      transliteration: "Alhamdu lillaahil-ladhee kasaanee haadhaath-thawba wa razaqaneehi min ghayri hawlim-minnee wa laa quwwah.",
      translation: "All praise is for Allah who clothed me with this garment and provided it for me without any might or power from me. (When wearing new clothes)",
      count: 1,
      reference: "Abu Dawud 4023",
    ),
    AzkarItem(
      id: "le6",
      arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا الطَّعَامَ وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ.",
      transliteration: "Alhamdu lillaahil-ladhee 'at'amanee haadhaat-ta'aama wa razaqaneehi min ghayri hawlim-minnee wa laa quwwah.",
      translation: "All praise is for Allah who fed me this food and provided it for me without any might or power from me. (After eating)",
      count: 1,
      reference: "Abu Dawud 4023, At-Tirmidhi 3458",
    ),
    AzkarItem(
      id: "le7",
      arabic: "بِسْمِ اللَّهِ، اللَّهُمَّ جَنِّبْنَا الشَّيْطَانَ وَجَنِّبِ الشَّيْطَانَ مَا رَزَقْتَنَا.",
      transliteration: "Bismillaahi, Allaahumma jannibnash-shaytaana wa jannibish-shaytaana maa razaqtanaa.",
      translation: "In the name of Allah. O Allah, keep Satan away from us and keep Satan away from what You provide us. (Before intimate relations)",
      count: 1,
      reference: "Al-Bukhari 141, Muslim 1434",
    ),
    AzkarItem(
      id: "le8",
      arabic: "إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ. اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا.",
      transliteration: "'Innaa lillaahi wa 'innaa 'ilayhi raaji'oon. Allaahumma'jurni fee museebatee wa 'akhlif lee khayran minhaa.",
      translation: "Indeed, to Allah we belong and to Him we shall return. O Allah, reward me in my affliction and replace it with something better. (When a calamity strikes)",
      count: 1,
      reference: "Muslim 918",
    ),
    AzkarItem(
      id: "le9",
      arabic: "اللَّهُمَّ أَذْهِبِ الْبَأْسَ رَبَّ النَّاسِ، وَاشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا.",
      transliteration: "Allaahumma 'adhhibil-ba'sa Rabban-naas, washfi 'Antash-Shaafee, laa shifaa'a 'illaa shifaa'uka, shifaa'an laa yughaadiru saqamaa.",
      translation: "O Allah, remove the hardship, Lord of mankind. Grant cure, for You are the Curer. There is no cure but Your cure — a cure that leaves no illness. (When visiting the sick)",
      count: 1,
      reference: "Al-Bukhari 5743",
    ),
  ];

  // ========== PROTECTION / RUQYAH AZKAR ==========
  static final List<AzkarItem> protectionRuqyah = [
    AzkarItem(
      id: "pr1",
      arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.",
      transliteration: "A'oodhu bikalimaatillaahit-taammaati min sharri maa khalaq.",
      translation: "I seek refuge in the perfect words of Allah from the evil of what He has created.",
      count: 3,
      reference: "Muslim 2709",
    ),
    AzkarItem(
      id: "pr2",
      arabic: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ.",
      transliteration: "Allaahumma 'innee 'a'oodhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-bukhli wal-jubn, wa dhala'id-dayni wa ghalabatir-rijaal.",
      translation: "O Allah, I seek refuge in You from anxiety and sorrow, from inability and laziness, from miserliness and cowardice, from the burden of debt, and from being overpowered by men.",
      count: 1,
      reference: "Al-Bukhari 6369",
    ),
    AzkarItem(
      id: "pr3",
      arabic: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْبَرَصِ وَالْجُنُونِ وَالْجُذَامِ وَمِنْ سَيِّئِ الْأَسْقَامِ.",
      transliteration: "Allaahumma 'innee 'a'oodhu bika minal-barasi wal-junooni wal-judhaami wa min sayyi'il-'asqaam.",
      translation: "O Allah, I seek refuge in You from vitiligo, insanity, leprosy, and from all evil diseases.",
      count: 1,
      reference: "Abu Dawud 1554",
    ),
    AzkarItem(
      id: "pr4",
      arabic: "اللَّهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ، وَأَصْلِحْ لِي شَأْنِي كُلَّهُ، لَا إِلَهَ إِلَّا أَنْتَ.",
      transliteration: "Allaahumma rahmataka 'arjoo fa laa takilnee 'ilaa nafsee tarfata 'aynin, wa 'aslih lee sha'nee kullahu, laa 'ilaaha 'illaa 'Anta.",
      translation: "O Allah, it is Your mercy that I hope for, so do not leave me to myself even for the blink of an eye. Rectify all of my affairs for me. There is no deity but You.",
      count: 1,
      reference: "Abu Dawud 5090",
    ),
    AzkarItem(
      id: "pr5",
      arabic: "اللَّهُمَّ إِنِّي عَبْدُكَ، ابْنُ عَبْدِكَ، ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ. أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ سَمَّيْتَ بِهِ نَفْسَكَ، أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ، أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ، أَوِ اسْتَأْثَرْتَ بِهِ فِي عِلْمِ الْغَيْبِ عِنْدَكَ، أَنْ تَجْعَلَ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي وَغَمِّي.",
      transliteration: "Allaahumma 'innee 'abduka, ibnu 'abdika, ibnu 'amatika, naasiyatee biyadika, maadhin fiyya hukmuka, 'adlun fiyya qadhaa'uka. 'As'aluka bikulli ismin huwa laka sammayta bihi nafsaka, 'aw 'anzaltahu fee kitaabika, 'aw 'allamtahu 'ahadan min khalqika, 'awista'tharta bihi fee 'ilmil-ghaybi 'indaka, 'an taj'alal-Qur'aana rabee'a qalbee, wa noora sadree, wa jalaa'a huznee, wa dhahaaba hammee wa ghammee.",
      translation: "O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand. Your command over me is forever executed, and Your decree over me is just. I ask You by every Name belonging to You which You named Yourself with, or revealed in Your Book, or taught to any of Your creation, or have preserved in the knowledge of the unseen with You, that You make the Quran the life of my heart, the light of my breast, the departure of my sorrow, and the removal of my anxiety and grief. (For anxiety and distress)",
      count: 1,
      reference: "Ahmad 1/391, Ibn Hibban 972",
    ),
    AzkarItem(
      id: "pr6",
      arabic: "لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ.",
      transliteration: "Laa 'ilaaha 'illaa 'Anta subhaanaka 'innee kuntu minadh-dhaalimeen.",
      translation: "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers. (Dua of Yunus — no Muslim supplicates with it for anything except that Allah responds)",
      count: 1,
      reference: "Surah Al-Anbiya 21:87, At-Tirmidhi 3505",
    ),
    AzkarItem(
      id: "pr7",
      arabic: "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ.",
      transliteration: "Allaahumma 'aafinee fee badanee, Allaahumma 'aafinee fee sam'ee, Allaahumma 'aafinee fee basaree, laa 'ilaaha 'illaa 'Anta.",
      translation: "O Allah, grant me well-being in my body, my hearing, and my sight. There is no deity but You.",
      count: 3,
      reference: "Abu Dawud 5092",
    ),
  ];

  // ========== FORGIVENESS / TAWBAH AZKAR ==========
  static final List<AzkarItem> forgivenessTawbah = [
    AzkarItem(
      id: "ft1",
      arabic: "أَسْتَغْفِرُ اللهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ.",
      transliteration: "Astaghfirullaahal-'Adheemal-ladhee laa 'ilaaha 'illaa Huwal-Hayyul-Qayyoomu wa 'atoobu 'ilayh.",
      translation: "I seek forgiveness from Allah the Mighty, besides whom there is no deity, the Ever-Living, the Self-Sustaining, and I repent to Him. (Sayyid al-Istighfar for major forgiveness)",
      count: 3,
      reference: "At-Tirmidhi 3577",
    ),
    AzkarItem(
      id: "ft2",
      arabic: "اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ، دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ، وَعَلَانِيَتَهُ وَسِرَّهُ.",
      transliteration: "Allaahummagh-fir lee dhanbee kullahu, diqqahu wa jillahu, wa 'awwalahu wa 'aakhirahu, wa 'alaaniyatahu wa sirrahu.",
      translation: "O Allah, forgive all my sins — the small and the great, the first and the last, the open and the secret.",
      count: 1,
      reference: "Muslim 483",
    ),
    AzkarItem(
      id: "ft3",
      arabic: "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي.",
      transliteration: "Allaahumma 'innaka 'Afuwwun tuhibbul-'afwa fa'fu 'annee.",
      translation: "O Allah, You are the Oft-Pardoning, You love to pardon, so pardon me. (Especially recommended in the last 10 nights of Ramadan)",
      count: 1,
      reference: "At-Tirmidhi 3513, Ibn Majah 3850",
    ),
    AzkarItem(
      id: "ft4",
      arabic: "رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ.",
      transliteration: "Rabbanagh-fir lanaa dhunoobanaa wa 'israafanaa feee 'amrinaa wa thabbit 'aqdaamanaa wansurnaa 'alal-qawmil-kaafireen.",
      translation: "Our Lord, forgive us our sins and our excesses in our affairs, make our feet firm, and give us victory over the disbelieving people.",
      count: 1,
      reference: "Surah Aal-Imran 3:147",
    ),
    AzkarItem(
      id: "ft5",
      arabic: "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ.",
      transliteration: "Rabbanaa dhalamnaa 'anfusanaa wa 'in lam taghfir lanaa wa tarhamnaa lanakoonanna minal-khaasireen.",
      translation: "Our Lord, we have wronged ourselves. If You do not forgive us and have mercy on us, we will surely be among the losers. (Dua of Adam and Hawwa)",
      count: 1,
      reference: "Surah Al-A'raf 7:23",
    ),
    AzkarItem(
      id: "ft6",
      arabic: "رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا. رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا. رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ، وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا، أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ.",
      transliteration: "Rabbanaa laa tu'aakhidhnaa 'in naseenaa 'aw 'akh-ta'naa. Rabbanaa wa laa tahmil 'alaynaa 'isran kamaa hamaltahu 'alal-ladheena min qablinaa. Rabbanaa wa laa tuhammilnaa maa laa taaqata lanaa bih, wa'fu 'annaa waghfir lanaa warhamnaa, 'Anta Mawlaanaa fansurnaa 'alal-qawmil-kaafireen.",
      translation: "Our Lord, do not impose blame on us if we forget or make a mistake. Our Lord, do not place on us a burden as You placed on those before us. Our Lord, do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our Protector, so give us victory over the disbelieving people. (Last two verses of Surah Al-Baqarah)",
      count: 1,
      reference: "Surah Al-Baqarah 2:286",
    ),
    AzkarItem(
      id: "ft7",
      arabic: "اللَّهُمَّ اغْفِرْ لِي، وَارْحَمْنِي، وَاهْدِنِي، وَعَافِنِي، وَارْزُقْنِي.",
      transliteration: "Allaahummagh-fir lee, warhamnee, wahdinee, wa 'aafinee, warzuqnee.",
      translation: "O Allah, forgive me, have mercy on me, guide me, grant me well-being, and provide for me.",
      count: 1,
      reference: "Muslim 2697, Abu Dawud 850",
    ),
    AzkarItem(
      id: "ft8",
      arabic: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ.",
      transliteration: "Subhaanaka Allaahumma wa bihamdika, 'ash-hadu 'allaa 'ilaaha 'illaa 'Anta, 'astaghfiruka wa 'atoobu 'ilayk.",
      translation: "Glory be to You, O Allah, and all praise. I bear witness that there is no deity but You. I seek Your forgiveness and repent to You. (Kaffarat al-Majlis — expiation for the gathering)",
      count: 1,
      reference: "At-Tirmidhi 3433, Abu Dawud 4859",
    ),
    AzkarItem(
      id: "ft9",
      arabic: "رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَنْ دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ.",
      transliteration: "Rabbigh-fir lee wa liwaalidayya wa liman dakhala baytiya mu'minan wa lilmu'mineena walmu'minaat.",
      translation: "My Lord, forgive me and my parents, and whoever enters my house as a believer, and the believing men and believing women. (Dua of Nuh for parents and believers)",
      count: 1,
      reference: "Surah Nuh 71:28",
    ),
    AzkarItem(
      id: "ft10",
      arabic: "اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ. اللَّهُمَّ نَقِّنِي مِنْ خَطَايَايَ كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ. اللَّهُمَّ اغْسِلْنِي مِنْ خَطَايَايَ بِالثَّلْجِ وَالْمَاءِ وَالْبَرَدِ.",
      transliteration: "Allaahumma baa'id baynee wa bayna khataayaaya kamaa baa'adta baynal-mashriqi wal-maghrib. Allaahumma naqqinee min khataayaaya kamaa yunaqqath-thawbul-'abyadhu minad-danas. Allaahummagh-silnee min khataayaaya bith-thalji wal-maa'i wal-barad.",
      translation: "O Allah, distance me from my sins as You have distanced the East from the West. O Allah, cleanse me of my sins as a white garment is cleansed of dirt. O Allah, wash away my sins with snow, water, and hail. (Opening supplication in Salah)",
      count: 1,
      reference: "Al-Bukhari 744, Muslim 598",
    ),
  ];
}

class NamesOfAllahData {
  static final List<NameOfAllah> names = [
    NameOfAllah(
      number: 1,
      arabic: "الرَّحْمَن",
      transliteration: "Ar-Rahman",
      translation: "The Beneficent / The Most Merciful",
    ),
    NameOfAllah(
      number: 2,
      arabic: "الرَّحِيم",
      transliteration: "Ar-Rahim",
      translation: "The Merciful / The Most Compassionate",
    ),
    NameOfAllah(
      number: 3,
      arabic: "الْمَلِك",
      transliteration: "Al-Malik",
      translation: "The King / The Sovereign Lord",
    ),
    NameOfAllah(
      number: 4,
      arabic: "الْقُدُّوس",
      transliteration: "Al-Quddus",
      translation: "The Holy / The One free from all errors",
    ),
    NameOfAllah(
      number: 5,
      arabic: "السَّلَام",
      transliteration: "As-Salam",
      translation: "The Source of Peace and Safety",
    ),
    NameOfAllah(
      number: 6,
      arabic: "الْمُؤْمِن",
      transliteration: "Al-Mu'min",
      translation: "The Giver of Faith / The Guardian of Faith",
    ),
    NameOfAllah(
      number: 7,
      arabic: "الْمُهَيْمِن",
      transliteration: "Al-Muhaymin",
      translation: "The Protector / The Overseer",
    ),
    NameOfAllah(
      number: 8,
      arabic: "الْعَزِيز",
      transliteration: "Al-Aziz",
      translation: "The Almighty / The Mighty",
    ),
    NameOfAllah(
      number: 9,
      arabic: "الْجَبَّار",
      transliteration: "Al-Jabbar",
      translation: "The Compeller / The Restorer",
    ),
    NameOfAllah(
      number: 10,
      arabic: "الْمُتَكَبِّر",
      transliteration: "Al-Mutakabbir",
      translation: "The Majestic / The Supreme",
    ),
    NameOfAllah(
      number: 11,
      arabic: "الْخَالِق",
      transliteration: "Al-Khaliq",
      translation: "The Creator",
    ),
    NameOfAllah(
      number: 12,
      arabic: "الْبَارِئ",
      transliteration: "Al-Bari'",
      translation: "The Evolver / The Maker",
    ),
    NameOfAllah(
      number: 13,
      arabic: "الْمُصَوِّر",
      transliteration: "Al-Musawwir",
      translation: "The Fashioner / The Shaper",
    ),
    NameOfAllah(
      number: 14,
      arabic: "الْغَفَّار",
      transliteration: "Al-Ghaffar",
      translation: "The Repeatedly Forgiving",
    ),
    NameOfAllah(
      number: 15,
      arabic: "الْقَهَّار",
      transliteration: "Al-Qahhar",
      translation: "The Subduer / The All-Dominant",
    ),
    NameOfAllah(
      number: 16,
      arabic: "الْوَهَّاب",
      transliteration: "Al-Wahhab",
      translation: "The Giver of All / The Bestower",
    ),
    NameOfAllah(
      number: 17,
      arabic: "الرَّزَّاق",
      transliteration: "Ar-Razzaq",
      translation: "The Provider / The Sustainer",
    ),
    NameOfAllah(
      number: 18,
      arabic: "الْفَتَّاح",
      transliteration: "Al-Fattah",
      translation: "The Opener / The Judge",
    ),
    NameOfAllah(
      number: 19,
      arabic: "الْعَلِيم",
      transliteration: "Al-Alim",
      translation: "The All-Knowing",
    ),
    NameOfAllah(
      number: 20,
      arabic: "الْقَابِض",
      transliteration: "Al-Qabid",
      translation: "The Withholder / The Constrictor",
    ),
    NameOfAllah(
      number: 21,
      arabic: "الْبَاسِط",
      transliteration: "Al-Basit",
      translation: "The Extender / The Expander",
    ),
    NameOfAllah(
      number: 22,
      arabic: "الْخَافِض",
      transliteration: "Al-Khafid",
      translation: "The Abaser / The Humbler",
    ),
    NameOfAllah(
      number: 23,
      arabic: "الرَّافِع",
      transliteration: "Ar-Rafi'",
      translation: "The Exalter",
    ),
    NameOfAllah(
      number: 24,
      arabic: "الْمُعِزّ",
      transliteration: "Al-Mu'izz",
      translation: "The Giver of Honor",
    ),
    NameOfAllah(
      number: 25,
      arabic: "الْمُذِلّ",
      transliteration: "Al-Mudhill",
      translation: "The Giver of Dishonor",
    ),
    NameOfAllah(
      number: 26,
      arabic: "السَّمِيع",
      transliteration: "As-Sami'",
      translation: "The All-Hearing",
    ),
    NameOfAllah(
      number: 27,
      arabic: "الْبَصِير",
      transliteration: "Al-Basir",
      translation: "The All-Seeing",
    ),
    NameOfAllah(
      number: 28,
      arabic: "الْحَكَم",
      transliteration: "Al-Hakam",
      translation: "The Judge / The Arbitrator",
    ),
    NameOfAllah(
      number: 29,
      arabic: "الْعَدْل",
      transliteration: "Al-Adl",
      translation: "The Utterly Just",
    ),
    NameOfAllah(
      number: 30,
      arabic: "اللَّطِيف",
      transliteration: "Al-Latif",
      translation: "The Gentle / The Subtly Kind",
    ),
    NameOfAllah(
      number: 31,
      arabic: "الْخَبِير",
      transliteration: "Al-Khabir",
      translation: "The All-Aware",
    ),
    NameOfAllah(
      number: 32,
      arabic: "الْحَلِيم",
      transliteration: "Al-Halim",
      translation: "The Forbearing / The Indulgent",
    ),
    NameOfAllah(
      number: 33,
      arabic: "الْعَظِيم",
      transliteration: "Al-Azim",
      translation: "The Magnificent / The Infinite",
    ),
    NameOfAllah(
      number: 34,
      arabic: "الْغَفُور",
      transliteration: "Al-Ghafur",
      translation: "The All-Forgiving",
    ),
    NameOfAllah(
      number: 35,
      arabic: "الشَّكُور",
      transliteration: "Ash-Shakur",
      translation: "The Most Appreciative / Gratefully Rewarder",
    ),
    NameOfAllah(
      number: 36,
      arabic: "الْعَلِيّ",
      transliteration: "Al-Aliy",
      translation: "The Highest / The Sublimely Exalted",
    ),
    NameOfAllah(
      number: 37,
      arabic: "الْكَبِير",
      transliteration: "Al-Kabir",
      translation: "The Greatest / The Infinite",
    ),
    NameOfAllah(
      number: 38,
      arabic: "الْحَفِيظ",
      transliteration: "Al-Hafidh",
      translation: "The Preserver",
    ),
    NameOfAllah(
      number: 39,
      arabic: "الْمُقِيت",
      transliteration: "Al-Muqit",
      translation: "The Nourisher / The Maintainer",
    ),
    NameOfAllah(
      number: 40,
      arabic: "الْحَسِيب",
      transliteration: "Al-Hasib",
      translation: "The Bringer of Judgment / The Reckoner",
    ),
    NameOfAllah(
      number: 41,
      arabic: "الْجَلِيل",
      transliteration: "Al-Jalil",
      translation: "The Majestic",
    ),
    NameOfAllah(
      number: 42,
      arabic: "الْكَرِيم",
      transliteration: "Al-Karim",
      translation: "The Most Generous / The Bountiful",
    ),
    NameOfAllah(
      number: 43,
      arabic: "الرَّقِيب",
      transliteration: "Ar-Raqib",
      translation: "The Watchful",
    ),
    NameOfAllah(
      number: 44,
      arabic: "الْمُجِيب",
      transliteration: "Al-Mujib",
      translation: "The Responsive / The Answerer",
    ),
    NameOfAllah(
      number: 45,
      arabic: "الْوَاسِع",
      transliteration: "Al-Wasi'",
      translation: "The All-Encompassing / The Boundless",
    ),
    NameOfAllah(
      number: 46,
      arabic: "الْحَكِيم",
      transliteration: "Al-Hakim",
      translation: "The All-Wise",
    ),
    NameOfAllah(
      number: 47,
      arabic: "الْوَدُود",
      transliteration: "Al-Wadud",
      translation: "The Loving One",
    ),
    NameOfAllah(
      number: 48,
      arabic: "الْمَجِيد",
      transliteration: "Al-Majid",
      translation: "The All-Glorious",
    ),
    NameOfAllah(
      number: 49,
      arabic: "الْبَاعِث",
      transliteration: "Al-Ba'ith",
      translation: "The Resurrector",
    ),
    NameOfAllah(
      number: 50,
      arabic: "الشَّهِيد",
      transliteration: "Ash-Shahid",
      translation: "The All-Observing Witness",
    ),
    NameOfAllah(
      number: 51,
      arabic: "الْحَقّ",
      transliteration: "Al-Haqq",
      translation: "The Absolute Truth",
    ),
    NameOfAllah(
      number: 52,
      arabic: "الْوَكِيل",
      transliteration: "Al-Wakil",
      translation: "The Trustee / The Dependable",
    ),
    NameOfAllah(
      number: 53,
      arabic: "الْقَوِيّ",
      transliteration: "Al-Qawiy",
      translation: "The All-Strong",
    ),
    NameOfAllah(
      number: 54,
      arabic: "الْمَتِين",
      transliteration: "Al-Matin",
      translation: "The Firm / The Steadfast",
    ),
    NameOfAllah(
      number: 55,
      arabic: "الْوَلِيّ",
      transliteration: "Al-Waliy",
      translation: "The Protecting Associate / Helper",
    ),
    NameOfAllah(
      number: 56,
      arabic: "الْحَمِيد",
      transliteration: "Al-Hamid",
      translation: "The Praiseworthy",
    ),
    NameOfAllah(
      number: 57,
      arabic: "الْمُحْصِي",
      transliteration: "Al-Muhsi",
      translation: "The All-Enumerating / Appraiser",
    ),
    NameOfAllah(
      number: 58,
      arabic: "الْمُبْدِئ",
      transliteration: "Al-Mubdi'",
      translation: "The Originator / The Initiator",
    ),
    NameOfAllah(
      number: 59,
      arabic: "الْمُعِيد",
      transliteration: "Al-Mu'id",
      translation: "The Restorer / Reinstater",
    ),
    NameOfAllah(
      number: 60,
      arabic: "الْمُحْيِي",
      transliteration: "Al-Muhyi",
      translation: "The Giver of Life",
    ),
    NameOfAllah(
      number: 61,
      arabic: "الْمُمِيت",
      transliteration: "Al-Mumit",
      translation: "The Bringer of Death / Destroyer",
    ),
    NameOfAllah(
      number: 62,
      arabic: "الْحَيّ",
      transliteration: "Al-Hayy",
      translation: "The Ever-Living",
    ),
    NameOfAllah(
      number: 63,
      arabic: "الْقَيُّوم",
      transliteration: "Al-Qayyoom",
      translation: "The Self-Sustaining / Eternal",
    ),
    NameOfAllah(
      number: 64,
      arabic: "الْوَاجِد",
      transliteration: "Al-Wajid",
      translation: "The Perceiver / The Finder",
    ),
    NameOfAllah(
      number: 65,
      arabic: "الْمَاجِد",
      transliteration: "Al-Majid",
      translation: "The Illustrious / The Magnificent",
    ),
    NameOfAllah(
      number: 66,
      arabic: "الْوَاحِد",
      transliteration: "Al-Wahid",
      translation: "The One / Unique",
    ),
    NameOfAllah(
      number: 67,
      arabic: "الأَحَد",
      transliteration: "Al-Ahad",
      translation: "The Only One",
    ),
    NameOfAllah(
      number: 68,
      arabic: "الصَّمَد",
      transliteration: "As-Samad",
      translation: "The Self-Sufficient / Eternal Refuge",
    ),
    NameOfAllah(
      number: 69,
      arabic: "الْقَادِر",
      transliteration: "Al-Qadir",
      translation: "The Capable / The Omnipotent",
    ),
    NameOfAllah(
      number: 70,
      arabic: "الْمُقْتَدِر",
      transliteration: "Al-Muqtadir",
      translation: "The Omnipotent / Determiner",
    ),
    NameOfAllah(
      number: 71,
      arabic: "الْمُقَدِّم",
      transliteration: "Al-Muqaddim",
      translation: "The Promoter / Expediter",
    ),
    NameOfAllah(
      number: 72,
      arabic: "الْمُؤَخِّر",
      transliteration: "Al-Mu'akhkhir",
      translation: "The Delayer / Postponer",
    ),
    NameOfAllah(
      number: 73,
      arabic: "الأَوَّل",
      transliteration: "Al-Awwal",
      translation: "The Very First",
    ),
    NameOfAllah(
      number: 74,
      arabic: "الآخِر",
      transliteration: "Al-Akhir",
      translation: "The Very Last",
    ),
    NameOfAllah(
      number: 75,
      arabic: "الظَّاهِر",
      transliteration: "Adh-Dhahir",
      translation: "The Manifest / The Evident",
    ),
    NameOfAllah(
      number: 76,
      arabic: "الْبَاطِن",
      transliteration: "Al-Batin",
      translation: "The Hidden / The Unseen",
    ),
    NameOfAllah(
      number: 77,
      arabic: "الْوَالِي",
      transliteration: "Al-Wali",
      translation: "The Patron / The Governor",
    ),
    NameOfAllah(
      number: 78,
      arabic: "الْمُتَعَالِي",
      transliteration: "Al-Muta'ali",
      translation: "The Self-Exalted",
    ),
    NameOfAllah(
      number: 79,
      arabic: "الْبَرّ",
      transliteration: "Al-Barr",
      translation: "The Most Good / Bountiful",
    ),
    NameOfAllah(
      number: 80,
      arabic: "التَّوَّاب",
      transliteration: "At-Tawwab",
      translation: "The Ever-Relenting / Acceptor of Repentance",
    ),
    NameOfAllah(
      number: 81,
      arabic: "الْمُنْتَقِم",
      transliteration: "Al-Muntaqim",
      translation: "The Avenger",
    ),
    NameOfAllah(
      number: 82,
      arabic: "العَفُوّ",
      transliteration: "Al-Afuw",
      translation: "The Supreme Pardoner / Effacer of Sins",
    ),
    NameOfAllah(
      number: 83,
      arabic: "الرَّؤُوف",
      transliteration: "Ar-Ra'uf",
      translation: "The Most Compassionate / Kind",
    ),
    NameOfAllah(
      number: 84,
      arabic: "مَالِكُ الْمُلْكِ",
      transliteration: "Malik-ul-Mulk",
      translation: "The Owner of All Sovereignty",
    ),
    NameOfAllah(
      number: 85,
      arabic: "ذُو الْجَلَالِ وَالْإِكْرَامِ",
      transliteration: "Dhu-l-Jalali wa-l-Ikram",
      translation: "The Owner of Majesty and Honor",
    ),
    NameOfAllah(
      number: 86,
      arabic: "الْمُقْسِط",
      transliteration: "Al-Muqsit",
      translation: "The Equitable / Requiter",
    ),
    NameOfAllah(
      number: 87,
      arabic: "الْجَامِع",
      transliteration: "Al-Jami'",
      translation: "The Gatherer / Uniter",
    ),
    NameOfAllah(
      number: 88,
      arabic: "الْغَنِيّ",
      transliteration: "Al-Ghaniy",
      translation: "The All-Rich / Independent",
    ),
    NameOfAllah(
      number: 89,
      arabic: "الْمُغْنِي",
      transliteration: "Al-Mughni",
      translation: "The Enricher / Giver of Wealth",
    ),
    NameOfAllah(
      number: 90,
      arabic: "الْمَانِع",
      transliteration: "Al-Mani'",
      translation: "The Preventer / Shielder",
    ),
    NameOfAllah(
      number: 91,
      arabic: "الضَّارّ",
      transliteration: "Ad-Darr",
      translation: "The Distressor / Creator of Harm",
    ),
    NameOfAllah(
      number: 92,
      arabic: "النَّافِع",
      transliteration: "An-Nafi'",
      translation: "The Creator of Good / Benefactor",
    ),
    NameOfAllah(
      number: 93,
      arabic: "النُّور",
      transliteration: "An-Nur",
      translation: "The Absolute Light",
    ),
    NameOfAllah(
      number: 94,
      arabic: "الْهَادِي",
      transliteration: "Al-Hadi",
      translation: "The Provider of Guidance",
    ),
    NameOfAllah(
      number: 95,
      arabic: "الْبَدِيع",
      transliteration: "Al-Badi'",
      translation: "The Incomparable Originator",
    ),
    NameOfAllah(
      number: 96,
      arabic: "الْبَاقِي",
      transliteration: "Al-Baqi",
      translation: "The Everlasting / Immutable",
    ),
    NameOfAllah(
      number: 97,
      arabic: "الْوَارِث",
      transliteration: "Al-Warith",
      translation: "The Ultimate Inheritor",
    ),
    NameOfAllah(
      number: 98,
      arabic: "الرَّشِيد",
      transliteration: "Ar-Rashid",
      translation: "The Right Guide / Teacher",
    ),
    NameOfAllah(
      number: 99,
      arabic: "الصَّبُور",
      transliteration: "As-Sabur",
      translation: "The Patient One",
    ),
  ];
}
