import '../models/islamic_library_models.dart';

class ProphetsData {
  static const List<ProphetStory> prophets = [
    ProphetStory(
      id: 1,
      nameAr: 'آدم عليه السلام',
      nameEn: 'Adam (peace be upon him)',
      titleAr: 'أبو البشر وخليفة الله في الأرض',
      titleEn: 'The Father of Humanity and First Prophet',
      quranMentions: 25,
      keySurahs: ['Al-Baqarah', 'Al-A\'raf', 'Al-Hijr', 'Ta-Ha'],
      periodAr: 'فجر الخلق والبداية',
      periodEn: 'Dawn of Human Creation',
      summaryAr:
          'أول إنسان خلقه الله بيده من طين، ونفخ فيه من روحه، وأسجد له الملائكة إكراماً، وعلمه الأسماء كلها.',
      summaryEn:
          'The first human being created by Allah from clay, breathed into with life, honored before the angels, and taught the names of all things.',
      sections: [
        StorySection(
          titleAr: 'خلق آدم وتعليم الأسماء',
          titleEn: 'Creation and Knowledge',
          contentAr:
              'أخبر الله ملائكته بأنه جاعل في الأرض خليفة، فخلق آدم عليه السلام من سلالة من طين، ثم سواه ونفخ فيه من روحه، وعلمه أسماء الأشياء كلها دلالة على رفعة مقام العلم والعقل.',
          contentEn:
              'Allah informed the angels that He would place a vicegerent on earth. He fashioned Adam from clay, breathed into him the soul He created, and endowed him with the knowledge of the names of all things, demonstrating the supreme dignity of knowledge.',
          quranVerseAr:
              'وَإِذْ قَالَ رَبُّكَ لِلْمَلَائِكَةِ إِنِّي جَاعِلٌ فِي الْأَرْضِ خَلِيفَةً',
          quranVerseEn:
              'And [mention] when your Lord said to the angels: Indeed, I will make upon the earth a successive authority.',
          quranRef: 'Surah Al-Baqarah 2:30',
        ),
        StorySection(
          titleAr: 'الامتحان والهبوط إلى الأرض',
          titleEn: 'The Trial and Earthly Mission',
          contentAr:
              'أسكن الله آدم وزوجته حواء الجنة ونهاهما عن شجرة واحدة، فوسوس لهما الشيطان فأكلا منها. فتلقى آدم من ربه كلمات فتاب عليه، وأهبطهما إلى الأرض لعمارة الكون وعبادة الله بالاستغفار والتوبة الصادقة.',
          contentEn:
              'Allah settled Adam and Eve in Paradise forbidding only one tree. Satan deceived them into eating from it. Adam immediately repented with humble words, and Allah accepted his repentance and ordained earth as humanity\'s dwelling of stewardship and worship.',
          quranVerseAr:
              'فَتَلَقَّىٰ آدَمُ مِن رَّبِّهِ كَلِمَاتٍ فَتَابَ عَلَيْهِ ۚ إِنَّهُ هُوَ التَّوَّابُ الرَّحِيمُ',
          quranVerseEn:
              'Then Adam received from his Lord [some] words, and He accepted his repentance. Indeed, it is He who is the Accepting of repentance, the Merciful.',
          quranRef: 'Surah Al-Baqarah 2:37',
        ),
      ],
      bookStartPage: 1,
      bookEndPage: 87,
    ),
    ProphetStory(
      id: 2,
      nameAr: 'إدريس عليه السلام',
      nameEn: 'Idris (Enoch)',
      titleAr: 'النبي الصديق وأول من خط بالقلم',
      titleEn: 'The Truthful Prophet Raised to High Rank',
      quranMentions: 2,
      keySurahs: ['Maryam', 'Al-Anbiya'],
      periodAr: 'العصور الأولى بعد آدم',
      periodEn: 'Early Generations of Humanity',
      summaryAr:
          'نبي كريم من أوائل الرسل، وصفه الله بالصديق الصابر، ورفعه مكاناً علياً.',
      summaryEn:
          'A noble prophet known for steadfast patience, truthfulness, devotion to Allah, and being raised to an exalted station.',
      sections: [
        StorySection(
          titleAr: 'الصديق الصابر والمكان العلي',
          titleEn: 'The Steadfast Truthful One',
          contentAr:
              'كان إدريس عليه السلام من خيرة الأنبياء صلاحاً وصبراً، ويُروى أنه كان أول من خاط الثياب وأول من خط بالقلم، ودعا قومه إلى توحيد الله وترك المنكرات.',
          contentEn:
              'Prophet Idris was renowned for his righteousness, patience, and profound piety. Tradition notes him as among the pioneers of the written word and righteous craftsmanship, tirelessly guiding his people to the worship of the One Creator.',
          quranVerseAr:
              'وَاذْكُرْ فِي الْكِتَابِ إِدْرِيسَ ۚ إِنَّهُ كَانَ صِدِّيقًا نَّبِيًّا * وَرَفَعْنَاهُ مَكَانًا عَلِيًّا',
          quranVerseEn:
              'And mention in the Book, Idris. Indeed, he was a man of truth and a prophet. And We raised him to a high station.',
          quranRef: 'Surah Maryam 19:56-57',
        ),
      ],
      bookStartPage: 88,
      bookEndPage: 131,
    ),
    ProphetStory(
      id: 3,
      nameAr: 'نوح عليه السلام',
      nameEn: 'Nuh (Noah)',
      titleAr: 'أول أولي العزم وشيخ المرسلين',
      titleEn: 'The Patriarch of the Prophets and the Ark',
      quranMentions: 43,
      keySurahs: ['Nuh', 'Hud', 'Al-Mu\'minun', 'Al-Shu\'ara'],
      periodAr: 'عصر الطوفان العظيم',
      periodEn: 'Era of the Great Flood',
      summaryAr:
          'دعا قومه ٩٥٠ عاماً بالليل والنهار سراً وعلانية، وبنى الفلك بأمر الله ونجا المؤمنون من الطوفان العظيم.',
      summaryEn:
          'He called his people patiently for 950 years day and night, constructed the Ark by divine inspiration, and saved believers from the Great Deluge.',
      sections: [
        StorySection(
          titleAr: 'الدعوة الطويلة والصبر الجميل',
          titleEn: 'Nine and a Half Centuries of Calling',
          contentAr:
              'قضى نوح عليه السلام تسعمائة وخمسين سنة يدعو قومه إلى التوحيد وينهاهم عن عبادة الأصنام، فما آمن معه إلا قليل، ولم يقابلوا نصحه إلا بالسخرية والإعراض.',
          contentEn:
              'Nuh called his people for 950 years with boundless compassion and perseverance, pleading with them night and day to leave idol worship, yet they responded with mockery and arrogance.',
          quranVerseAr:
              'وَلَقَدْ أَرْسَلْنَا نُوحًا إِلَىٰ قَوْمِهِ فَلَبِثَ فِيهِمْ أَلْفَ سَنَةٍ إِلَّا خَمْسِينَ عَامًا',
          quranVerseEn:
              'And We certainly sent Noah to his people, and he remained among them a thousand years minus fifty years.',
          quranRef: 'Surah Al-Ankabut 29:14',
        ),
        StorySection(
          titleAr: 'بناء الفلك والطوفان والنجاة',
          titleEn: 'Building the Ark and Deliverance',
          contentAr:
              'أوحى الله لنوح أن يصنع الفلك بأعين الله ووحيه. وحين فار التنور أمره الله بأن يحمل فيها من كل زوجين اثنين وأهله إلا من سبق عليه القول، واستوت السفينة على الجودي.',
          contentEn:
              'By divine instruction, Nuh built the Ark while mocked by passersby. When the floodwaters burst from the earth and poured from the sky, Nuh boarded the believers and pairs of all living creatures, until the Ark rested on Mount Judi.',
          quranVerseAr:
              'وَقِيلَ يَا أَرْضُ ابْلَعِي مَاءَكِ وَيَا سَمَاءُ أَقْلِعِي وَغِيضَ الْمَاءُ وَقُضِيَ الْأَمْرُ وَاسْتَوَتْ عَلَى الْجُودِيِّ',
          quranVerseEn:
              'And it was said: O earth, swallow your water, and O sky, withhold [your rain]. And the water subsided, and the matter was accomplished, and the ship came to rest upon Mount Judi.',
          quranRef: 'Surah Hud 11:44',
        ),
      ],
      bookStartPage: 132,
      bookEndPage: 179,
    ),
    ProphetStory(
      id: 4,
      nameAr: 'هود عليه السلام',
      nameEn: 'Hud (Eber)',
      titleAr: 'نبي قبيلة عاد وإرم ذات العماد',
      titleEn: 'Prophet to the Mighty People of ‘Ad',
      quranMentions: 7,
      keySurahs: ['Hud', 'Al-A\'raf', 'Al-Shu\'ara', 'Al-Ahqaf'],
      periodAr: 'الأحقاف بجنوب شبه الجزيرة العربية',
      periodEn: 'Ancient Southern Arabia (Al-Ahqaf)',
      summaryAr:
          'أُرسل إلى قوم عاد أصحاب القوة والقصور في الأحقاف، فأنذرهم بطش الله حين استكبروا في الأرض بغير الحق.',
      summaryEn:
          'Sent to the mighty civilization of ‘Ad in Al-Ahqaf who boasted of their unparalleled physical strength and towering architecture.',
      sections: [
        StorySection(
          titleAr: 'الدعوة والتحذير من الغرور',
          titleEn: 'Warning Against Tyranny and Pride',
          contentAr:
              'كان قوم عاد أصحاب بسطة في الأجسام وبنوا إرم ذات العماد التي لم يخلق مثلها في البلاد، فدعاهم هود لشكر نعم الله وإفراده بالعبادة، فاستكبروا وقالوا من أشد منا قوة.',
          contentEn:
              'The people of ‘Ad were gifted with immense strength and towering palaces, yet they became arrogant. Hud reminded them that all blessings come from Allah, but they scoffed and relied upon their earthly might.',
          quranVerseAr:
              'وَإِلَىٰ عَادٍ أَخَاهُمْ هُودًا ۗ قَالَ يَا قَوْمِ اعْبُدُوا اللَّهَ مَا لَكُم مِّنْ إِلَٰهٍ غَيْرُهُ',
          quranVerseEn:
              'And to \'Ad [We sent] their brother Hud. He said: O my people, worship Allah; you have no deity other than Him.',
          quranRef: 'Surah Hud 11:50',
        ),
        StorySection(
          titleAr: 'الريح العقيم ونجاة المؤمنين',
          titleEn: 'The Fierce Gale and Salvation',
          contentAr:
              'حين كذبوا نبيهم أرسل الله عليهم ريحاً صرصراً عاتية سخرها عليهم سبع ليال وثمانية أيام حسوماً، فأهلكتهم ونجى هود والذين آمنوا معه برحمة من الله.',
          contentEn:
              'After persistent rejection, Allah unleashed a roaring, barren wind for seven consecutive nights and eight days, leaving the tyrants lifeless while saving Hud and the believers in safety.',
          quranVerseAr:
              'سَخَّرَهَا عَلَيْهِمْ سَبْعَ لَيَالٍ وَثَمَانِيَةَ أَيَّامٍ حُسُومًا فَتَرَى الْقَوْمَ فِيهَا صَرْعَىٰ',
          quranVerseEn:
              'Which He imposed upon them for seven nights and eight days in succession, so you would see the people therein fallen as if they were hollow trunks of palm trees.',
          quranRef: 'Surah Al-Haqqah 69:7',
        ),
      ],
      bookStartPage: 180,
      bookEndPage: 195,
    ),
    ProphetStory(
      id: 5,
      nameAr: 'صالح عليه السلام',
      nameEn: 'Salih',
      titleAr: 'نبي ثمود وآية الناقة المباركة',
      titleEn: 'Prophet to Thamud and the Miraculous She-Camel',
      quranMentions: 9,
      keySurahs: ['Al-A\'raf', 'Hud', 'Al-Hijr', 'Al-Shams'],
      periodAr: 'مدائن صالح / الحجر (شمال الجزيرة)',
      periodEn: 'Al-Hijr (Mada\'in Salih)',
      summaryAr:
          'بُعث إلى قوم ثمود الذين ينحتون من الجبال بيوتاً، وأخرج الله لهم الناقة آية مبصرة فعقروها فحل بهم العذاب.',
      summaryEn:
          'Sent to Thamud who carved elaborate dwellings into stone cliffs; Allah granted them a miraculous she-camel as a sign, but they slaughtered her in defiance.',
      sections: [
        StorySection(
          titleAr: 'معجزة الناقة الصامتة',
          titleEn: 'The Miraculous She-Camel',
          contentAr:
              'طلب قوم ثمود آية خارقة، فأخرج الله لهم من الصخرة ناقة عظيمة لها شرب يوم ولهم شرب يوم معلوم، وحذرهم صالح من إيذائها.',
          contentEn:
              'The people demanded a miraculous sign from stone. Allah brought forth a grand she-camel who shared access to water alternately, and Salih cautioned them against touching her with harm.',
          quranVerseAr:
              'هَٰذِهِ نَاقَةُ اللَّهِ لَكُمْ آيَةً ۖ فَذَرُوهَا تَأْكُلْ فِي أَرْضِ اللَّهِ',
          quranVerseEn:
              'This is the she-camel of Allah [sent] to you as a sign. So leave her to eat within Allah\'s earth and do not touch her with harm.',
          quranRef: 'Surah Al-A\'raf 7:73',
        ),
        StorySection(
          titleAr: 'عقر الناقة والصيحة',
          titleEn: 'The Slaughter and The Blast',
          contentAr:
              'تآمر طغاة ثمود فعقروا الناقة وتحدوا نبيهم بالعذاب، فأنذرهم صالح بثلاثة أيام، ثم أخذتهم الرجفة والصيحة فأصبحوا في ديارهم جاثمين.',
          contentEn:
              'Defiant leaders conspired and hamstrung the she-camel. Salih warned that three days remained before punishment. The mighty blast struck them, leaving them prostrate in their homes.',
          quranVerseAr:
              'فَعَقَرُوا النَّاقَةَ وَعَتَوْا عَنْ أَمْرِ رَبِّهِمْ وَقَالُوا يَا صَالِحُ ائْتِنَا بِمَا تَعِدُنَا',
          quranVerseEn:
              'So they hamstrung the she-camel and were insolent toward the command of their Lord and said: O Salih, bring us what you promise us, if you should be of the messengers.',
          quranRef: 'Surah Al-A\'raf 7:77',
        ),
      ],
      bookStartPage: 196,
      bookEndPage: 203,
    ),
    ProphetStory(
      id: 6,
      nameAr: 'إبراهيم عليه السلام',
      nameEn: 'Ibrahim (Abraham)',
      titleAr: 'خليل الرحمن وأبو الأنبياء وإمام الحنفاء',
      titleEn: 'The Intimate Friend of Allah and Father of Prophets',
      quranMentions: 69,
      keySurahs: [
        'Ibrahim',
        'Al-Baqarah',
        'Al-An\'am',
        'Al-Anbiya',
        'Al-Saffat',
      ],
      periodAr: 'بابل والشام والحجاز (أور الكلدانيين ومكة)',
      periodEn: 'Mesopotamia, the Levant, and Makkah',
      summaryAr:
          'حطم الأصنام بيده، ونجاه الله من النار العظيمة، ورفع قواعد البيت الحرام مع ولده إسماعيل، وجعل الله في ذريته النبوة والكتاب.',
      summaryEn:
          'Smashed the idols of Babylon, delivered miraculously from the blazing furnace, built the Kaaba with his son Ismail, and was made an imam for humanity.',
      sections: [
        StorySection(
          titleAr: 'مناظرة النمرود وتحطيم الأصنام',
          titleEn: 'Confronting Idolatry and Nimrod',
          contentAr:
              'ناظر إبراهيم قومه بالعقل والبرهان وحطم أصنامهم ليبين عجزها، وناظر ملكهم النمرود في إحياء الموتى وشروق الشمس، فلما ألقوه في النار قال الله للنار كوني برداً وسلاماً.',
          contentEn:
              'With pure logic and faith, Ibrahim shattered the idols of Babylon to awaken his people. When thrown into an enormous furnace, Allah commanded the fire to become cool and peaceful for him.',
          quranVerseAr:
              'قُلْنَا يَا نَارُ كُونِي بَرْدًا وَسَلَامًا عَلَىٰ إِبْرَاهِيمَ',
          quranVerseEn: 'We said: O fire, be coolness and safety upon Abraham.',
          quranRef: 'Surah Al-Anbiya 21:69',
        ),
        StorySection(
          titleAr: 'بناء الكعبة والنداء بالحج',
          titleEn: 'Building the Kaaba and Proclaiming Hajj',
          contentAr:
              'هاجر إبراهيم إلى مكة وترك هاجر وإسماعيل عند البيت بواد غير ذي زرع، ثم عاد بأمر الله ليرفعا معاً قواعد البيت الحرام وأذن في الناس بالحج.',
          contentEn:
              'Guided by divine command, Ibrahim settled Hajar and infant Ismail in the barren valley of Makkah. Later, father and son raised the foundations of the Sacred House and called mankind to pilgrimage.',
          quranVerseAr:
              'وَإِذْ يَرْفَعُ إِبْرَاهِيمُ الْقَوَاعِدَ مِنَ الْبَيْتِ وَإِسْمَاعِيلُ رَبَّنَا تَقَبَّلْ مِنَّا',
          quranVerseEn:
              'And [mention] when Abraham was raising the foundations of the House and [with him] Ishmael, [saying]: Our Lord, accept [this] from us.',
          quranRef: 'Surah Al-Baqarah 2:127',
        ),
      ],
      bookStartPage: 204,
      bookEndPage: 307,
    ),
    ProphetStory(
      id: 7,
      nameAr: 'لوط عليه السلام',
      nameEn: 'Lut (Lot)',
      titleAr: 'ابن أخي إبراهيم ونبي سدوم وعمورة',
      titleEn: 'Prophet to the Cities of the Plain (Sodom)',
      quranMentions: 27,
      keySurahs: ['Al-A\'raf', 'Hud', 'Al-Hijr', 'Al-Shu\'ara', 'Al-Ankabut'],
      periodAr: 'سدوم قرب البحر الميت',
      periodEn: 'The Jordan Valley (Near the Dead Sea)',
      summaryAr:
          'دعا قومه إلى العفة وترك الفواحش الشنيعة التي لم يسبقهم إليها أحد من العالمين، فكذبوه فعاقبهم الله بصيحة وحجارة من سجيل.',
      summaryEn:
          'Called his people to purity and righteousness, warning against unprecedented abominations, until Allah turned their corrupt dwellings upside down.',
      sections: [
        StorySection(
          titleAr: 'الدعوة إلى الفطرة والعفة',
          titleEn: 'Advocating Purity and Human Nature',
          contentAr:
              'جاهد لوط عليه السلام في إصلاح قومه ونهاهم عن الفاحشة وقطع السبيل وإتيان المنكر في نواديهم، ولكنهم هددوه بالإخراج من القرية لطهارته.',
          contentEn:
              'Lut urged his society toward morality and justice, condemning highway robbery and unnatural indecency, yet they threatened him with exile solely for his commitment to purity.',
          quranVerseAr:
              'إِنَّكُمْ لَتَأْتُونَ الْفَاحِشَةَ مَا سَبَقَكُم بِهَا مِنْ أَحَدٍ مِّنَ الْعَالَمِينَ',
          quranVerseEn:
              'Indeed, you commit such immorality as no one has preceded you with from among the worlds.',
          quranRef: 'Surah Al-Ankabut 29:28',
        ),
        StorySection(
          titleAr: 'نزول الملائكة وهلاك الظالمين',
          titleEn: 'Angelic Visitors and Retribution',
          contentAr:
              'جاءت الملائكة ضيوفاً إلى لوط فبشروه بنجاته وأهله إلا امرأته، وأمروه بالخروج ليلاً قبل شروق الشمس حيث جعل الله عالي القرية سافلها وأمطر عليها حجارة من سجيل.',
          contentEn:
              'Angels arrived in human form to instruct Lut to leave by night with his believers, excluding his treasonous wife. At sunrise, a devastating seismic inversion and rained stones eradicated the corrupt city.',
          quranVerseAr:
              'فَجَعَلْنَا عَالِيَهَا سَافِلَهَا وَأَمْطَرْنَا عَلَيْهِمْ حِجَارَةً مِّن سِجِّيلٍ',
          quranVerseEn:
              'So We made the highest part [of the city] its lowest and rained upon them stones of hard clay.',
          quranRef: 'Surah Al-Hijr 15:74',
        ),
      ],
      bookStartPage: 208,
      bookEndPage: 216,
    ),
    ProphetStory(
      id: 8,
      nameAr: 'إسماعيل عليه السلام',
      nameEn: 'Ismail (Ishmael)',
      titleAr: 'الذبيح الصابر وجد العرب المستعربة والنبي المصطفى',
      titleEn: 'The Patient Sacrifice and Forefather of the Arabs',
      quranMentions: 12,
      keySurahs: ['Al-Baqarah', 'Maryam', 'Al-Saffat', 'Sad'],
      periodAr: 'مكة المكرمة وبطحاء البيت الحرام',
      periodEn: 'Valley of Makkah',
      summaryAr:
          'بكر إبراهيم، تفجرت زمزم تحت قدميه طفلاً، واستسلم للذبح امتثالاً لأمر ربه ففداه الله بذبح عظيم، وشارك في بناء الكعبة.',
      summaryEn:
          'Eldest son of Ibrahim, blessed with Zamzam in infancy, willingly submitted to divine sacrifice before being ransomed with a magnificent ram.',
      sections: [
        StorySection(
          titleAr: 'نبع زمزم والاستسلام لأمر الله',
          titleEn: 'The Well of Zamzam and Absolute Surrender',
          contentAr:
              'تركه إبراهيم مع أمه هاجر في بطحاء مكة، فسعت هاجر بين الصفا والمروة حتى فجر جبريل زمزم. وحين شب رأى إبراهيم ذبحه فقال إسماعيل يا أبت افعل ما تؤمر ستجدني إن شاء الله من الصابرين.',
          contentEn:
              'As an infant left with Hajar in Makkah, water gushed from Zamzam beneath his feet. Later, when tested with the vision of sacrifice, young Ismail replied with profound faith: "O my father, do as you are commanded."',
          quranVerseAr:
              'قَالَ يَا أَبَتِ افْعَلْ مَا تُؤْمَرُ ۖ سَتَجِدُنِي إِن شَاءَ اللَّهُ مِنَ الصَّابِرِينَ',
          quranVerseEn:
              'He said: O my father, do as you are commanded. You will find me, if Allah wills, of the steadfast.',
          quranRef: 'Surah Al-Saffat 37:102',
        ),
      ],
      bookStartPage: 217,
      bookEndPage: 234,
    ),
    ProphetStory(
      id: 9,
      nameAr: 'إسحاق عليه السلام',
      nameEn: 'Ishaq (Isaac)',
      titleAr: 'الغلام العليم وبشارة سارة الملائكية',
      titleEn: 'The Promised Son and Forefather of Israelite Prophets',
      quranMentions: 17,
      keySurahs: ['Hud', 'Al-Hijr', 'Maryam', 'Al-Saffat'],
      periodAr: 'أرض كنعان وفلسطين والشام',
      periodEn: 'Canaan and the Levant',
      summaryAr:
          'بشرت الملائكة إبراهيم وسارة به على كبر سنهما، وكان نبياً صالحاً مباركاً من نسله يعقوب وبنو إسرائيل.',
      summaryEn:
          'Announced to Sarah and Ibrahim in their old age as a miraculous glad tiding, blessed with prophetic lineage leading to Jacob and the Children of Israel.',
      sections: [
        StorySection(
          titleAr: 'البشارة والبركة',
          titleEn: 'The Glad Tidings of Righteousness',
          contentAr:
              'جاءت الملائكة تبشر إبراهيم وزوجته سارة بإسحاق ومن وراء إسحاق يعقوب، فتعجبت سارة من الولادة في الشيخوخة، فبينت الملائكة أن أمر الله لا عجب فيه، وجعله الله نبياً مباركاً.',
          contentEn:
              'Angels gave the joyous news of Ishaq to elderly parents Sarah and Ibrahim. Allah blessed him with profound wisdom, making him an exemplary guide walking in righteous monotheism.',
          quranVerseAr:
              'فَبَشَّرْنَاهَا بِإِسْحَاقَ وَمِن وَرَاءِ إِسْحَاقَ يَعْقُوبَ',
          quranVerseEn:
              'And We gave her good tidings of Isaac and after Isaac, Jacob.',
          quranRef: 'Surah Hud 11:71',
        ),
      ],
      bookStartPage: 235,
      bookEndPage: 240,
    ),
    ProphetStory(
      id: 10,
      nameAr: 'يعقوب عليه السلام',
      nameEn: 'Ya\'qub (Jacob / Israel)',
      titleAr: 'إسرائيل ذو الصبر الجميل وأبو الأسباط',
      titleEn: 'Israel, Possessor of Beautiful Patience',
      quranMentions: 16,
      keySurahs: ['Yusuf', 'Al-Baqarah', 'Ali \'Imran', 'Maryam'],
      periodAr: 'فلسطين ومصر القديمة',
      periodEn: 'Canaan and Ancient Egypt',
      summaryAr:
          'صبر على فراق أحب أبنائه يوسف عقوداً طويلة دون أن يفقد حسن الظن بربه، حتى رد الله عليه بصره وجمع شمله بأهله.',
      summaryEn:
          'Endured the heartbreaking separation from his beloved son Yusuf for decades with unshakeable reliance upon Allah until his sight and family were restored.',
      sections: [
        StorySection(
          titleAr: 'الصبر الجميل وحسن الظن بالله',
          titleEn: 'Patience Without Despair',
          contentAr:
              'لما غُيب يوسف عنه كظم يعقوب حزنه واعتصم بالصبر الجميل، وابيضت عيناه من الحزن وهو كظيم، مؤكداً لأبنائه أنه يعلم من الله ما لا يعلمون.',
          contentEn:
              'When Yusuf disappeared, Ya\'qub took refuge in "Sabrun Jameel" (graceful patience). Though tears whitened his eyes, his faith never wavered, declaring: "I complain of my grief only to Allah."',
          quranVerseAr:
              'قَالَ إِنَّمَا أَشْكُو بَثِّي وَحُزْنِي إِلَى اللَّهِ وَأَعْلَمُ مِنَ اللَّهِ مَا لَا تَعْلَمُونَ',
          quranVerseEn:
              'He said: I only complain of my suffering and my grief to Allah, and I know from Allah that which you do not know.',
          quranRef: 'Surah Yusuf 12:86',
        ),
      ],
      bookStartPage: 323,
      bookEndPage: 345,
    ),
    ProphetStory(
      id: 11,
      nameAr: 'يوسف عليه السلام',
      nameEn: 'Yusuf (Joseph)',
      titleAr: 'الصديق العفيف وعزيز مصر',
      titleEn: 'The Truthful, Noble Minister of Egypt',
      quranMentions: 27,
      keySurahs: ['Yusuf', 'Al-An\'am', 'Ghafir'],
      periodAr: 'مصر القديمة في عهد الهكسوس',
      periodEn: 'Ancient Egypt',
      summaryAr:
          'أحسن القصص؛ من غياهب الجب وبيعه عبداً، إلى فتنة امرأة العزيز والسجن، حتى مكن الله له في الأرض وصار عزيز مصر.',
      summaryEn:
          'The finest of stories: from the dark well and slavery, through wrongful imprisonment, to becoming Egypt’s visionary treasurer and forgiving his brothers.',
      sections: [
        StorySection(
          titleAr: 'من الجب والسجن إلى التمكين',
          titleEn: 'From Betrayal and Prison to Authority',
          contentAr:
              'ألقاه إخوته حسداً في البئر فاشترته قافلة وبِيع في مصر، وثبت أمام فتنة امرأة العزيز مفضلاً السجن على المعصية، وفسر رؤيا الملك فأنقذ مصر والمنطقة من المجاعة وصار على خزائن الأرض.',
          contentEn:
              'Cast into a well by jealous brothers, sold into servitude, and falsely imprisoned after choosing integrity over sin, Yusuf interpreted the Pharaoh’s dream to avert famine and rose to rule over Egypt\'s storehouses.',
          quranVerseAr:
              'قَالَ اجْعَلْنِي عَلَىٰ خَزَائِنِ الْأَرْضِ ۖ إِنِّي حَفِيظٌ عَلِيمٌ',
          quranVerseEn:
              'He said: Appoint me over the storehouses of the land. Indeed, I will be a knowing guardian.',
          quranRef: 'Surah Yusuf 12:55',
        ),
        StorySection(
          titleAr: 'العفو التام وتأويل الرؤيا',
          titleEn: 'Sublime Forgiveness and Dream Fulfilled',
          contentAr:
              'حين أتى إخوته يطلبون الميرة لم ينتقم منهم بل قال لا تثريب عليكم اليوم يغفر الله لكم، ورفع أبويه على العرش وخروا له سجداً تحقيقاً لرؤياه في صغره.',
          contentEn:
              'When his destitute brothers arrived seeking grain, he showed unmatched mercy, saying: "No blame will there be upon you today; Allah will forgive you," and seated his parents on the throne.',
          quranVerseAr:
              'قَالَ لَا تَثْرِيبَ عَلَيْكُمُ الْيَوْمَ ۖ يَغْفِرُ اللَّهُ لَكُمْ ۖ وَهُوَ أَرْحَمُ الرَّاحِمِينَ',
          quranVerseEn:
              'He said: No blame will there be upon you today. Allah will forgive you; and He is the most merciful of the merciful.',
          quranRef: 'Surah Yusuf 12:92',
        ),
      ],
      bookStartPage: 346,
      bookEndPage: 377,
    ),
    ProphetStory(
      id: 12,
      nameAr: 'أيوب عليه السلام',
      nameEn: 'Ayyub (Job)',
      titleAr: 'مضرب الأمثال في الصبر والشكر',
      titleEn: 'The Paragon of Enduring Patience',
      quranMentions: 4,
      keySurahs: ['Al-Anbiya', 'Sad'],
      periodAr: 'أرض حوران بالشام',
      periodEn: 'Hauran and the Levant',
      summaryAr:
          'ابتلاه الله بفقد أهله وماله ومرض جسده سنوات طوالاً، فلم يزدد إلا شكراً وتضرعاً حتى كشف الله ضره وعوضه خيراً.',
      summaryEn:
          'Tested with catastrophic loss of wealth, children, and agonizing physical illness, his tongue remained moist with praise until Allah cured him completely.',
      sections: [
        StorySection(
          titleAr: 'البلاء العظيم والأدب في الدعاء',
          titleEn: 'The Supreme Test and Beautiful Prayer',
          contentAr:
              'أصاب أيوب عليه السلام مرض شديد في جسده وذهب ماله ومات ولده، فصبر صبراً لم يُعهد، ونادى ربه بأدب رفيع: مسني الضر وأنت أرحم الراحمين.',
          contentEn:
              'Ayyub suffered prolonged bodily affliction, loss of sustenance, and grief, yet remained steadfast without complaint, calling upon Allah with consummate humility.',
          quranVerseAr:
              'وَأَيُّوبَ إِذْ نَادَىٰ رَبَّهُ أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ',
          quranVerseEn:
              'And [mention] Job, when he called to his Lord: Indeed, adversity has touched me, and You are the most merciful of the merciful.',
          quranRef: 'Surah Al-Anbiya 21:83',
        ),
      ],
      bookStartPage: 378,
      bookEndPage: 388,
    ),
    ProphetStory(
      id: 13,
      nameAr: 'شعيب عليه السلام',
      nameEn: 'Shu\'ayb (Jethro)',
      titleAr: 'خطيب الأنبياء ونبي أهل مدين وأصحاب الأيكة',
      titleEn: 'Orator of the Prophets to Midian',
      quranMentions: 11,
      keySurahs: ['Al-A\'raf', 'Hud', 'Al-Shu\'ara', 'Al-Ankabut'],
      periodAr: 'مدين بالقرب من معان وخليج العقبة',
      periodEn: 'Midian (Gulf of Aqaba region)',
      summaryAr:
          'دعا قومه إلى إيفاء الكيل والميزان وترك بخس الناس أشياءهم، واشتهر بفصاحته وبلاغته في الحجة والنصح.',
      summaryEn:
          'Renowned for eloquence, he championed economic ethics and integrity, pleading with Midian to stop defrauding weights and cheating merchants.',
      sections: [
        StorySection(
          titleAr: 'الدعوة إلى العدل الاقتصادي',
          titleEn: 'Advocating Commercial Honesty and Justice',
          contentAr:
              'نهى شعيب قومه عن التطفيف في المكاييل والموازين وقطع الطرقات والفساد المالي، ودعاهم إلى تقوى الله مؤكداً أنه لا يريد إلا الإصلاح ما استطاع.',
          contentEn:
              'Shu\'ayb urged his community to conduct honest business without shortchanging customers, declaring: "I only intend reform as much as I am able; and my success is not but through Allah."',
          quranVerseAr:
              'إِنْ أُرِيدُ إِلَّا الْإِصْلَاحَ مَا اسْتَطَعْتُ ۚ وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ',
          quranVerseEn:
              'I only intend reform as much as I am able. And my success is not but through Allah. Upon Him I have relied, and to Him I return.',
          quranRef: 'Surah Hud 11:88',
        ),
      ],
      bookStartPage: 389,
      bookEndPage: 391,
    ),
    ProphetStory(
      id: 14,
      nameAr: 'موسى عليه السلام',
      nameEn: 'Musa (Moses)',
      titleAr: 'كليم الله وصاحب الآيات التسع وقاهر فرعون',
      titleEn: 'The One Who Spoke Directly to Allah and Vanquished Pharaoh',
      quranMentions: 136,
      keySurahs: [
        'Al-Baqarah',
        'Al-A\'raf',
        'Ta-Ha',
        'Al-Qasas',
        'Al-Shu\'ara',
      ],
      periodAr: 'مصر القديمة وشبه جزيرة سيناء',
      periodEn: 'Ancient Egypt and Mount Sinai',
      summaryAr:
          'أكثر الأنبياء ذكراً في القرآن؛ ألقي طفلاً في اليم، ورباه قصر فرعون، وكلمه الله عند الطور، وفلق له البحر، وأنزل عليه التوراة.',
      summaryEn:
          'The most mentioned prophet in the Quran; cast as a baby into the Nile, raised in Pharaoh\'s palace, spoken to at Mount Tur, split the Red Sea, and delivered the Torah.',
      sections: [
        StorySection(
          titleAr: 'الولادة في اليم والمناجاة بالطور',
          titleEn: 'The Ark on the Nile and Speaking to Allah',
          contentAr:
              'أوحى الله لأمه أن تقذفه في التابوت فالتقطه آل فرعون، وحين بلغ أشده وخرج إلى مدين عاد فكلمه ربه عند جبل الطور بالوادي المقدس طوى، وأرسله بآيات بينات إلى فرعون وملئه.',
          contentEn:
              'Protected by Allah from Pharaoh\'s slaughter of newborns, he returned to Egypt after fleeing to Midian. At Mount Sinai, Allah spoke directly to him and granted nine radiant miracles.',
          quranVerseAr: 'وَكَلَّمَ اللَّهُ مُوسَىٰ تَكْلِيمًا',
          quranVerseEn: 'And to Moses Allah spoke directly.',
          quranRef: 'Surah An-Nisa 4:164',
        ),
        StorySection(
          titleAr: 'فلق البحر وهلاك فرعون وجنوده',
          titleEn: 'Splitting the Red Sea and Deliverance',
          contentAr:
              'خرج موسى ببني إسرائيل فتبعهم فرعون بجنوده، فلما تراءى الجمعان قال أصحاب موسى إنا لمدركون، قال كلا إن معي ربي سيهدين، فضرب البحر بعصاه فانفلق فكان كل فرق كالطود العظيم.',
          contentEn:
              'Trapped between the sea and Pharaoh’s advancing legions, Moses declared with absolute certainty: "No! Indeed, with me is my Lord; He will guide me." The sea divided miraculously into towering walls.',
          quranVerseAr:
              'قَالَ كَلَّا ۖ إِنَّ مَعِيَ رَبِّي سَيَهْدِينِ * فَأَوْحَيْنَا إِلَىٰ مُوسَىٰ أَنِ اضْرِب بِّعَصَاكَ الْبَحْرَ',
          quranVerseEn:
              '[Moses] said: No! Indeed, with me is my Lord; He will guide me. Then We inspired to Moses: Strike with your staff the sea, and it parted.',
          quranRef: 'Surah Al-Shu\'ara 26:62-63',
        ),
      ],
      bookStartPage: 392,
      bookEndPage: 412,
    ),
    ProphetStory(
      id: 15,
      nameAr: 'هارون عليه السلام',
      nameEn: 'Harun (Aaron)',
      titleAr: 'نبي الله الفصيح ووزير موسى وأخوه',
      titleEn: 'The Eloquent Prophet and Co-Leader with Moses',
      quranMentions: 20,
      keySurahs: ['Ta-Ha', 'Al-Qasas', 'Al-A\'raf', 'Maryam'],
      periodAr: 'مصر القديمة وتيه سيناء',
      periodEn: 'Egypt and the Sinai Wilderness',
      summaryAr:
          'أخو موسى الأكبر، آتاه الله الفصاحة والبيان فجعله وزيراً لموسى وعضداً له في تبليغ الرسالة ومواجهة طغيان فرعون.',
      summaryEn:
          'The gifted, eloquent brother of Moses who served as his steadfast deputy and partner in delivering the message before the Egyptian royal court.',
      sections: [
        StorySection(
          titleAr: 'الوزير الصالح والأخ المؤازر',
          titleEn: 'The Righteous Deputy and Supporter',
          contentAr:
              'سأل موسى ربه أن يجعل له وزيراً من أهله هارون أخاه ليشدد به أزره ويشركه في أمره، فاستجاب الله دعاءه وجعل هارون نبياً ناصحاً صبوراً.',
          contentEn:
              'Musa supplicated Allah to grant him his brother Harun as an eloquent vizier to strengthen him. Allah answered his prayer, making Harun an honored prophet assisting his brother.',
          quranVerseAr:
              'وَاجْعَل لِّي وَزِيرًا مِّنْ أَهْلِي * هَارُونَ أَخِي * اشْدُدْ بِهِ أَزْرِي',
          quranVerseEn:
              'And appoint for me a minister from my family: Aaron, my brother. Increase through him my strength.',
          quranRef: 'Surah Ta-Ha 20:29-31',
        ),
      ],
      bookStartPage: 413,
      bookEndPage: 416,
    ),
    ProphetStory(
      id: 16,
      nameAr: 'ذو الكفل عليه السلام',
      nameEn: 'Dhul-Kifl (Ezekiel)',
      titleAr: 'النبي الصابر الكافل بالحق والعدل',
      titleEn: 'The Patient Prophet Who Maintained His Pledge',
      quranMentions: 2,
      keySurahs: ['Al-Anbiya', 'Sad'],
      periodAr: 'بلاد الشام وبابل',
      periodEn: 'Ancient Levant and Mesopotamia',
      summaryAr:
          'ذكره الله في القرآن مقترناً بإسماعيل وإدريس في الصبر وإدخالهم في رحمته، واشتهر بوفائه بعهود الحق والعدل بين الناس.',
      summaryEn:
          'Praised alongside Ismail and Idris for supreme patience and righteousness, fulfilling all solemn commitments with exemplary justice.',
      sections: [
        StorySection(
          titleAr: 'وفاء العهد والعدالة',
          titleEn: 'Faithfulness to Covenants',
          contentAr:
              'تكفل ذو الكفل بالصيام بالنهار والقيام بالليل والحكم بين الناس بالقسط دون غضب أو تفريط، فوفى بما تعهد به وأثنى الله عليه في محكم تنزيله.',
          contentEn:
              'Dhul-Kifl bound himself to fasting by day, worship by night, and ruling with righteous fairness without yielding to anger, earning high honor in divine scripture.',
          quranVerseAr:
              'وَإِسْمَاعِيلَ وَإِدْرِيسَ وَذَا الْكِفْلِ ۖ كُلٌّ مِّنَ الصَّابِرِينَ * وَأَدْخَلْنَاهُمْ فِي رَحْمَتِنَا',
          quranVerseEn:
              'And [mention] Ishmael and Idris and Dhul-Kifl; all were of the patient. And We admitted them into Our mercy. Indeed, they were of the righteous.',
          quranRef: 'Surah Al-Anbiya 21:85-86',
        ),
      ],
      bookStartPage: 417,
      bookEndPage: 612,
    ),
    ProphetStory(
      id: 17,
      nameAr: 'داود عليه السلام',
      nameEn: 'Dawud (David)',
      titleAr: 'الملك العادل صاحب الزبور ومسبح الجبال والطير',
      titleEn: 'The Righteous King, Bearer of the Zabur (Psalms)',
      quranMentions: 16,
      keySurahs: ['Al-Baqarah', 'Al-Isra', 'Al-Anbiya', 'Saba', 'Sad'],
      periodAr: 'القدس وفلسطين (مملكة إسرائيل المتحدة)',
      periodEn: 'Jerusalem and Ancient Palestine',
      summaryAr:
          'قتل جالوت، وآتاه الله الملك والحكمة والزبور، وألان له الحديد، وكانت الجبال والطيور تسبح معه إذا رتل مزاميره.',
      summaryEn:
          'Felled the tyrant Goliath, blessed with kingship, wisdom, and the Psalms; iron was made pliable in his hands, and mountains glorified Allah alongside him.',
      sections: [
        StorySection(
          titleAr: 'قتل جالوت وإلانة الحديد والتسبيح',
          titleEn: 'Slaying Goliath and Softened Iron',
          contentAr:
              'برز داود وهو فتى مؤمن فقتل جالوت بحجر مقلاعه، وآتاه الله الملك والنبوة، وألان له الحديد يصنع منه دروعاً سابغات، وكان إذا قرأ الزبور بصوته الرخيم سبحت معه الجبال والطير.',
          contentEn:
              'As a young soldier, Dawud struck down Goliath. Allah bestowed upon him royal dominion and prophecy, softened iron for him to weave protective mail, and joined mountains with his melodies of praise.',
          quranVerseAr:
              'وَسَخَّرْنَا مَعَ دَاوُودَ الْجِبَالَ يُسَبِّحْنَ وَالطَّيْرَ ۚ وَكُنَّا فَاعِلِينَ',
          quranVerseEn:
              'And We subjected the mountains to exalt [Us], along with David and [also] the birds. And We were [capable of] that.',
          quranRef: 'Surah Al-Anbiya 21:79',
        ),
      ],
      bookStartPage: 462,
      bookEndPage: 545,
    ),
    ProphetStory(
      id: 18,
      nameAr: 'سليمان عليه السلام',
      nameEn: 'Sulaiman (Solomon)',
      titleAr: 'الملك النبي الذي سخرت له الرياح والجن وفهم منطق الطير',
      titleEn: 'The Royal Prophet Who Understood the Speech of Birds',
      quranMentions: 17,
      keySurahs: ['Al-Baqarah', 'Al-Anbiya', 'Al-Naml', 'Saba', 'Sad'],
      periodAr: 'مملكة القدس والشام',
      periodEn: 'Jerusalem and Southern Levant',
      summaryAr:
          'ورث داود، وسخر الله له الريح تجري بأمره، وعلمه لغة الطير والحيوان، وسخر له الجن، ودعا ملكة سبأ بلقيس إلى الإسلام فأسلمت.',
      summaryEn:
          'Inherited prophetic wisdom and was granted an empire unequaled in history; wind and jinn obeyed him, he understood ants and birds, and guided Queen Bilqis to Islam.',
      sections: [
        StorySection(
          titleAr: 'منطق الطير وملكة سبأ',
          titleEn: 'The Speech of Birds and the Queen of Sheba',
          contentAr:
              'سمع سليمان نملة تحذر قومها فتبسم ضاحكاً وشكر نعمة ربه، وحمل الهدهد رسالته التوحيدية إلى بلقيس ملكة سبأ، حتى جاءت صاغرة وأعلنت إسلامها مع سليمان لله رب العالمين.',
          contentEn:
              'Hearing an ant cautioning its colony, Solomon smiled and gave grateful praise. Guided by the hoopoe, he sent a letter to Queen Bilqis of Sheba calling her to truth, leading her to accept Islam.',
          quranVerseAr:
              'قَالَتْ رَبِّ إِنِّي ظَلَمْتُ نَفْسِي وَأَسْلَمْتُ مَعَ سُلَيْمَانَ لِلَّهِ رَبِّ الْعَالَمِينَ',
          quranVerseEn:
              'She said: My Lord, indeed I have wronged myself, and I submit with Solomon to Allah, Lord of the worlds.',
          quranRef: 'Surah Al-Naml 27:44',
        ),
      ],
      bookStartPage: 628,
      bookEndPage: 645,
    ),
    ProphetStory(
      id: 19,
      nameAr: 'إلياس عليه السلام',
      nameEn: 'Ilyas (Elijah)',
      titleAr: 'نبي بعلبك ومحارب عبادة صنم بعل',
      titleEn: 'The Resolute Prophet Who Opposed Baal Worship',
      quranMentions: 2,
      keySurahs: ['Al-An\'am', 'Al-Saffat'],
      periodAr: 'بعلبك وبلاد الشام',
      periodEn: 'Baalbek and Ancient Phoenicia/Levant',
      summaryAr:
          'بُعث إلى بني إسرائيل في بعلبك بعد انحرافهم وعبادتهم لصنم بعل، فنهاهم ودعاهم لعبادة أحسن الخالقين.',
      summaryEn:
          'Sent to the Israelites in Baalbek when they fell into idolatry worshiping the idol Baal, challenging them to return to the Best of Creators.',
      sections: [
        StorySection(
          titleAr: 'الإنكار على عبادة بعل',
          titleEn: 'Confronting Idolatry with Truth',
          contentAr:
              'أنكر إلياس على قومه ترك عبادة الله وعبادة صنم مصنوع اسمه بعل، وحذرهم من عاقبة التكذيب، فخلد الله ذكره في الآخرين وجعله من عباده المؤمنين.',
          contentEn:
              'Ilyas bravely confronted his people for forsaking Allah to worship an inanimate idol called Baal, leaving an enduring legacy of uncompromising monotheism.',
          quranVerseAr:
              'أَتَدْعُونَ بَعْلًا وَتَذَرُونَ أَحْسَنَ الْخَالِقِينَ * اللَّهَ رَبَّكُمْ وَرَبَّ آبَائِكُمُ الْأَوَّلِينَ',
          quranVerseEn:
              'Do you call upon Baal and leave the best of creators—Allah, your Lord and the Lord of your first forefathers?',
          quranRef: 'Surah Al-Saffat 37:125-126',
        ),
      ],
      bookStartPage: 646,
      bookEndPage: 660,
    ),
    ProphetStory(
      id: 20,
      nameAr: 'اليسع عليه السلام',
      nameEn: 'Al-Yasa\' (Elisha)',
      titleAr: 'النبي الفاضل وخليفة إلياس في الدعوة',
      titleEn: 'The Faithful Successor and Righteous Guide',
      quranMentions: 2,
      keySurahs: ['Al-An\'am', 'Sad'],
      periodAr: 'أرض الشام وفلسطين',
      periodEn: 'The Levant',
      summaryAr:
          'صاحب إلياس وخلفه في بني إسرائيل، فضله الله على العالمين وجعله من الأخيار الأبرار.',
      summaryEn:
          'Companion and successor to Ilyas among the Children of Israel, favored by Allah and recorded among the foremost righteous servants.',
      sections: [
        StorySection(
          titleAr: 'الاصطفاء والفضل',
          titleEn: 'Divine Choice and Virtue',
          contentAr:
              'كان اليسع عليه السلام قدوة في الهدى والاستقامة والعدل، قاد قومه بعد إلياس بكتاب الله وشريعته، وشهد له القرآن برفعة المقام مع سائر الرسل.',
          contentEn:
              'Al-Yasa\' guided his community following Ilyas, embodying steadfast adherence to divine revelation and recorded among the blessed elect of humanity.',
          quranVerseAr:
              'وَاذْكُرْ إِسْمَاعِيلَ وَالْيَسَعَ وَذَا الْكِفْلِ ۖ وَكُلٌّ مِّنَ الْأَخْيَارِ',
          quranVerseEn:
              'And remember Ishmael, Elisha, and Dhul-Kifl, and all are among the outstanding.',
          quranRef: 'Surah Sad 38:48',
        ),
      ],
      bookStartPage: 661,
      bookEndPage: 710,
    ),
    ProphetStory(
      id: 21,
      nameAr: 'يونس عليه السلام',
      nameEn: 'Yunus (Jonah / Dhun-Nun)',
      titleAr: 'ذو النون وصاحب الحوت ودعاء الكرب العظيم',
      titleEn: 'The Man of the Whale and the Supplication of Relief',
      quranMentions: 4,
      keySurahs: ['Yunus', 'Al-Anbiya', 'Al-Saffat', 'Al-Qalam'],
      periodAr: 'نينوى بالعراق (الموصل القديمة)',
      periodEn: 'Nineveh (Ancient Mesopotamia / Iraq)',
      summaryAr:
          'أُرسل إلى نينوى، فخرج مغاضباً فالتقمه الحوت في ظلمات ثلاث، فنادى بالتسبيح والتوحيد فنجاه الله وآمن قومه مائة ألف أو يزيدون.',
      summaryEn:
          'Sent to Nineveh; swallowed by a gigantic whale in three depths of darkness, his sincere invocation of repentance secured miraculous salvation.',
      sections: [
        StorySection(
          titleAr: 'في بطن الحوت ودعاء الظلمات',
          titleEn: 'Inside the Whale and the Exalted Cry',
          contentAr:
              'ركب يونس السفينة فثقلت، فألقي في البحر فالتقمه الحوت وهو مليم، فنادى في ظلمات البحر والليل وبطن الحوت: لا إله إلا أنت سبحانك إني كنت من الظالمين، فاستجاب الله له ونبذه بالعراء.',
          contentEn:
              'Cast from a tempest-tossed vessel into the raging deep, a great whale engulfed him without harming a bone. Within the darkness, his prayer echoed: "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers."',
          quranVerseAr:
              'فَنَادَىٰ فِي الظُّلُمَاتِ أَن لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
          quranVerseEn:
              'And he called out within the darknesses: There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
          quranRef: 'Surah Al-Anbiya 21:87',
        ),
      ],
      bookStartPage: 711,
      bookEndPage: 728,
    ),
    ProphetStory(
      id: 22,
      nameAr: 'زكريا عليه السلام',
      nameEn: 'Zakariyya (Zechariah)',
      titleAr: 'كافل مريم والشيخ الداعي بالذرية الطيبة',
      titleEn: 'Guardian of Mary and Supplicant for Righteous Heir',
      quranMentions: 7,
      keySurahs: ['Ali \'Imran', 'Maryam', 'Al-Anbiya'],
      periodAr: 'بيت المقدس بفلسطين',
      periodEn: 'Jerusalem Temple',
      summaryAr:
          'كفل مريم البتول في محرابها، ودعا ربه في شيخوخته أن يهبه ولداً زكياً يرث النبوة، فبشرته الملائكة بيحيى.',
      summaryEn:
          'Caregiver to the blessed virgin Mary; despite advanced age and barrenness, his intimate prayers were answered with the gift of John (Yahya).',
      sections: [
        StorySection(
          titleAr: 'الدعاء الخفي والبشارة بيحيى',
          titleEn: 'The Silent Whispered Prayer Answered',
          contentAr:
              'رأى زكريا كرامات مريم ورزق الله لها، فنادى ربه نداء خفياً وهو شيخ اشتعل رأسه شيباً وامرأته عاقر، فاستجاب الله وبشرته الملائكة وهو قائم يصلي في المحراب بيحيى.',
          contentEn:
              'Witnessing the miraculous provision granted to Mary in the temple, Zakariyya called in secret: "My Lord, grant me from Yourself a good offspring." Angels proclaimed the birth of Yahya while he prayed in the sanctuary.',
          quranVerseAr:
              'هُنَالِكَ دَعَا زَكَرِيَّا رَبَّهُ ۖ قَالَ رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً',
          quranVerseEn:
              'At that, Zechariah called upon his Lord, saying: My Lord, grant me from Yourself a good offspring. Indeed, You are the Hearer of prayer.',
          quranRef: 'Surah Ali \'Imran 3:38',
        ),
      ],
      bookStartPage: 729,
      bookEndPage: 765,
    ),
    ProphetStory(
      id: 23,
      nameAr: 'يحيى عليه السلام',
      nameEn: 'Yahya (John the Baptist)',
      titleAr: 'النبي الحليم المصدق بكلمة من الله والسيد الحصور',
      titleEn: 'The Pure, Noble, Ascetic Prophet',
      quranMentions: 5,
      keySurahs: ['Ali \'Imran', 'Maryam', 'Al-Anbiya'],
      periodAr: 'فلسطين ونهر الأردن',
      periodEn: 'Jordan Valley and Jerusalem',
      summaryAr:
          'آتاه الله الحكم صبياً، وكان براً بوالديه تقياً حنوناً، مصدقاً بكلمة من الله (عيسى عليه السلام).',
      summaryEn:
          'Endowed with wisdom as a youth, gentle and devoted to parents, confirming the coming of the Messiah (Jesus).',
      sections: [
        StorySection(
          titleAr: 'الحكمة صبياً والبر بالوالدين',
          titleEn: 'Early Wisdom and Reverence',
          contentAr:
              'نشأ يحيى عليه السلام زاهداً في الدنيا، محباً للطاعة، أوتي الفهم والتوراة وهو صبي صغير، ولم يكن جباراً عصياً بل كان سلاماً يوم وُلد ويوم يموت ويوم يُبعث حياً.',
          contentEn:
              'Granted profound scriptural insight in early youth, Yahya lived a life of pure asceticism, tenderness to living creatures, and unwavering duty to his parents.',
          quranVerseAr:
              'يَا يَحْيَىٰ خُذِ الْكِتَابَ بِقُوَّةٍ ۖ وَآتَيْنَاهُ الْحُكْمَ صَبِيًّا * وَحَنَانًا مِّن لَّدُنَّا وَزَكَاةً ۖ وَكَانَ تَقِيًّا',
          quranVerseEn:
              '[Allah said]: O John, take the Scripture with determination. And We gave him judgement [while yet] a boy, and affection from Us and purity, and he was devout.',
          quranRef: 'Surah Maryam 19:12-13',
        ),
      ],
      bookStartPage: 766,
      bookEndPage: 797,
    ),
    ProphetStory(
      id: 24,
      nameAr: 'عيسى عليه السلام',
      nameEn: 'Isa (Jesus, the Messiah)',
      titleAr: 'المسيح كلمة الله وروحه وابن مريم البتول',
      titleEn: 'The Messiah, Word of Allah, and Son of Mary',
      quranMentions: 25,
      keySurahs: ['Ali \'Imran', 'Al-Ma\'idah', 'Maryam', 'Al-Zukhruf'],
      periodAr: 'الناصرة والقدس بفلسطين',
      periodEn: 'Nazareth and Jerusalem',
      summaryAr:
          'وُلد بمعجزة إلهية من مريم العذراء من غير أب، تكلم في المهد صبياً، وأبرأ الأكمه والأبرص وأحيا الموتى بإذن الله، ورفعه الله إليه.',
      summaryEn:
          'Born miraculously to the virgin Mary without a father; spoke in the cradle, cured the blind and leper, brought dead to life by Allah\'s leave, and was raised to heaven.',
      sections: [
        StorySection(
          titleAr: 'المولد المعجز والكلام في المهد',
          titleEn: 'The Miraculous Birth and Speech in the Cradle',
          contentAr:
              'نفخ الله في مريم من روحه فحملت بعيسى عذراء بتولاً، ولما عادت به لقومها أشارت إليه وهو طفل في المهد، فأنطقه الله: إني عبد الله آتاني الكتاب وجعلني نبياً.',
          contentEn:
              'Conceived miraculously through the angel Gabriel, Mary faced her questioning society with divine silence. The infant in the cradle miraculously defended his mother, proclaiming his prophethood.',
          quranVerseAr:
              'قَالَ إِنِّي عَبْدُ اللَّهِ آتَانِيَ الْكِتَابَ وَجَعَلَنِي نَبِيًّا',
          quranVerseEn:
              '[Jesus] said: Indeed, I am the servant of Allah. He has given me the Scripture and made me a prophet.',
          quranRef: 'Surah Maryam 19:30',
        ),
        StorySection(
          titleAr: 'معجزات الشفاء والرفع إلى السماء',
          titleEn: 'Healing Miracles and Divine Ascension',
          contentAr:
              'أيّد الله عيسى بروح القدس، فكان يخلق من الطين كهيئة الطير فينفخ فيه فيكون طيراً بإذن الله، ويبرئ الأكمه والأبرص ويحيي الموتى بإذن الله، ولما مكر به أعداؤه لم يقتلوه ولم يصلبوه بل رفعه الله إليه.',
          contentEn:
              'Confirmed by miracles of clay birds given life, healing the blind and leper, and reviving the dead by Allah’s leave. When conspirators plotted against his life, Allah saved and ascended him into heaven.',
          quranVerseAr:
              'وَمَا قَتَلُوهُ وَمَا صَلَبُوهُ وَلَٰكِن شُبِّهَ لَهُمْ ۚ ... بَل رَّفَعَهُ اللَّهُ إِلَيْهِ',
          quranVerseEn:
              'And they did not kill him, nor did they crucify him; but [another] was made to resemble him to them... Rather, Allah raised him to Himself.',
          quranRef: 'Surah An-Nisa 4:157-158',
        ),
      ],
      bookStartPage: 798,
      bookEndPage: 888,
    ),
    ProphetStory(
      id: 25,
      nameAr: 'محمد ﷺ',
      nameEn: 'Muhammad (peace and blessings be upon him)',
      titleAr: 'خاتم النبيين والمرسلين ورحمة الله للعالمين',
      titleEn: 'The Seal of the Prophets and Mercy to all Creation',
      quranMentions: 4,
      keySurahs: ['Muhammad', 'Al-Ahzab', 'Al-Fath', 'Al-Anbiya', 'Al-Qalam'],
      periodAr: 'مكة المكرمة والمدينة المنورة',
      periodEn: 'Makkah and Madinah (570 - 632 CE)',
      summaryAr:
          'سيد ولد آدم وخاتم الرسل، أُرسل للناس كافة هادياً ومبشراً ونذيراً، صاحب القرآن الكريم المعجزة الخالدة والخلق العظيم.',
      summaryEn:
          'Leader of humanity and final messenger to all mankind; brought the timeless miracle of the Quran and embodied the highest ethical conduct.',
      sections: [
        StorySection(
          titleAr: 'رحمة للعالمين وخاتم الأنبياء',
          titleEn: 'Mercy to the Worlds and Seal of Prophets',
          contentAr:
              'بعثه الله في أمة أمية ليخرج البشرية من ظلمات الجهل والشرك إلى نور التوحيد والعدل، وشهد له ربه بعظمة خلقه وشمول رحمته لسائر الخلائق.',
          contentEn:
              'Sent as the final messenger to elevate humanity out of spiritual ignorance into the light of divine truth and brotherhood, embodying consummate moral perfection.',
          quranVerseAr: 'وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
          quranVerseEn:
              'And We have not sent you, [O Muhammad], except as a mercy to the worlds.',
          quranRef: 'Surah Al-Anbiya 21:107',
        ),
        StorySection(
          titleAr: 'القرآن المعجزة الخالدة والخلق العظيم',
          titleEn: 'The Living Miracle and Noble Character',
          contentAr:
              'أوحى الله إليه القرآن الكريم معجزاً محفوظاً بحفظ الله إلى يوم الدين، وكان خلقه القرآن؛ يجمع بين الرحمة والحزم، والشجاعة واللين، ففتح القلوب بالحق حتى استقر دين الله في مشارق الأرض ومغاربها.',
          contentEn:
              'Bestowed with the living miracle of the Quran preserved forever, his wife Aisha described him: "His character was the Quran." He guided hearts with wisdom and established justice and truth throughout the earth.',
          quranVerseAr: 'وَإِنَّكَ لَعَلَىٰ خُلُقٍ عَظِيمٍ',
          quranVerseEn: 'And indeed, you are of a great moral character.',
          quranRef: 'Surah Al-Qalam 68:4',
        ),
      ],
      bookStartPage: 1,
      bookEndPage: 452,
    ),
  ];
}
