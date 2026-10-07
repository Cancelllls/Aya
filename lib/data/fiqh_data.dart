import '../models/fiqh_model.dart';

class FiqhData {
  static const List<FiqhCategory> categories = [
    FiqhCategory(
      id: 'taharah',
      titleAr: 'الطهارة',
      titleEn: 'Purification',
      descriptionAr: 'أحكام الوضوء، الغسل، التيمم، والمسح على الخفين',
      descriptionEn: 'Rulings of Wudu, Ghusl, Tayammum, and wiping over socks',
      iconName: 'water_drop',
    ),
    FiqhCategory(
      id: 'salah',
      titleAr: 'الصلاة',
      titleEn: 'Prayer (Salah)',
      descriptionAr: 'شروط الصلاة، أركانها، واجباتها، سجود السهو، وصلاة المسافر والجنازة',
      descriptionEn: 'Conditions, pillars, obligations, Sujood as-Sahw, traveler and funeral prayer',
      iconName: 'mosque',
    ),
    FiqhCategory(
      id: 'sawm',
      titleAr: 'الصيام',
      titleEn: 'Fasting (Sawm)',
      descriptionAr: 'مفطرات الصيام، الأعذار المبيحة للفطر، وصيام التطوع',
      descriptionEn: 'Nullifiers of fast, valid exemptions, and voluntary fasting',
      iconName: 'nights_stay',
    ),
    FiqhCategory(
      id: 'zakah',
      titleAr: 'الزكاة والصدقات',
      titleEn: 'Zakah & Charity',
      descriptionAr: 'نصاب الذهب والفضة، زكاة المال، زكاة الفطر، ومصارف الزكاة',
      descriptionEn: 'Nisab thresholds, cash and gold Zakah, Zakat al-Fitr, and recipients',
      iconName: 'volunteer_activism',
    ),
    FiqhCategory(
      id: 'hajj',
      titleAr: 'الحج والعمرة',
      titleEn: 'Hajj & Umrah',
      descriptionAr: 'صفة العمرة، أركان الحج وواجباته، ومحظورات الإحرام',
      descriptionEn: 'Step-by-step Umrah, pillars and duties of Hajj, and Ihram prohibitions',
      iconName: 'explore',
    ),
  ];

  static const List<FiqhTopic> topics = [
    // ==========================================
    // 1. TAHARAH (PURIFICATION)
    // ==========================================
    FiqhTopic(
      id: 'wudu_rulings',
      categoryId: 'taharah',
      titleAr: 'صفة الوضوء وأركانه وسننه',
      titleEn: 'Method, Pillars, and Sunan of Wudu',
      summaryAr: 'شرح عملي مفصل لكيفية الوضوء الصحيحة مع بيان فروضه وسننه وما ينقضه',
      summaryEn: 'Comprehensive practical guide to valid Wudu, its obligatory pillars, sunan, and nullifiers',
      readTimeMinutes: 5,
      keywords: ['وضوء', 'طهور', 'فروض', 'سنن', 'نواقض', 'wudu', 'ablution', 'pillars', 'nullifiers'],
      sections: [
        FiqhSection(
          titleAr: 'أركان (فروض) الوضوء الستة',
          titleEn: 'The Six Obligatory Pillars of Wudu',
          contentAr: 'أركان الوضوء هي التي لا يصح الوضوء إلا بها، وإذا تُرك واحد منها بطل الوضوء وجبت إعادته:',
          contentEn: 'The pillars of Wudu without which ablution is invalid. Omitting any of them invalidates the Wudu:',
          bulletPointsAr: [
            'النية: ومحلها القلب، لقوله ﷺ: «إنما الأعمال بالنيات».',
            'غسل الوجه كاملاً: ومنه المضمضة والاستنشاق، وحده من منابت شعر الرأس إلى أسفل اللحية طولاً، ومن الأذن إلى الأذن عرضاً.',
            'غسل اليدين مع المرفقين: والبدء من أطراف الأصابع حتى يشمل المرفق كاملاً.',
            'مسح الرأس كله: ومنه الأذنان، بأن يبل يديه ويمر بهما من مقدم الرأس إلى قفاه ثم يردهما إلى الموضع الذي بدأ منه.',
            'غسل الرجلين مع الكعبين: والكعبان هما العظمان الناتئان عند مفصل الساق والقدم.',
            'الترتيب والموالاة: الترتيب بين الأعضاء كما ذكرها الله، والموالاة بألا يؤخر غسل عضو حتى يجف العضو الذي قبله في زمن معتدل.',
          ],
          bulletPointsEn: [
            'Intention (Niyyah): Located in the heart without verbalization.',
            'Washing the entire face: Including rinsing the mouth (Madmadah) and sniffing water into the nose (Istinshaq), from forehead hairline to chin and ear to ear.',
            'Washing both arms including elbows: Starting from fingertips up to and including the elbows.',
            'Wiping the entire head: Including the ears, with wet hands from forehead to nape and returning.',
            'Washing both feet including ankles: Ensuring the protruding ankle bones are fully covered.',
            'Order and continuity (Tartib & Muwalat): Performing steps sequentially without delaying until previous limbs dry.',
          ],
        ),
        FiqhSection(
          titleAr: 'سنن ومستحبات الوضوء',
          titleEn: 'Sunan and Recommended Acts of Wudu',
          contentAr: 'أفعال يُثاب فاعلها ولا يبطل الوضوء بتركها، اقتداءً بسنة النبي ﷺ:',
          contentEn: 'Recommended acts following the Prophet ﷺ that increase reward but do not invalidate Wudu if omitted:',
          bulletPointsAr: [
            'التسمية في أوله: قول «بسم الله».',
            'استعمال السواك عند المضمضة.',
            'غسل الكفين ثلاثاً في أول الوضوء قبل إدخالهما الإناء.',
            'المبالغة في المضمضة والاستنشاق لغير الصائم.',
            'تخليل اللحية الكثيفة بالماء وتخليل أصابع اليدين والرجلين.',
            'تقديم الميامن على المياسر (البدء باليمين).',
            'الغسل ثلاثاً ثلاثاً (والواجب مرة واحدة تعم العضو).',
            'الدعاء بعد الفراغ منه: «أشهد أن لا إله إلا الله وحده لا شريك له وأشهد أن محمداً عبده ورسوله، اللهم اجعلني من التوابين واجعلني من المتطهرين».',
          ],
          bulletPointsEn: [
            'Saying "Bismillah" at the beginning.',
            'Using the Siwak (tooth-stick) during mouth rinsing.',
            'Washing hands up to wrists 3 times at the beginning.',
            'Exaggerating in rinsing mouth and nose (unless fasting).',
            'Combing through a thick beard with wet fingers and running water between fingers and toes.',
            'Starting with the right side before the left.',
            'Washing each limb three times (one complete wash is obligatory; three is optimal sunnah).',
            'Supplication after finishing: "Ashhadu alla ilaha illallah wahdahu la sharika lah..."',
          ],
        ),
        FiqhSection(
          titleAr: 'نواقض الوضوء',
          titleEn: 'Nullifiers of Wudu',
          contentAr: 'الأمور التي إذا حدثت بعد الطهارة بطل الوضوء ووجب تجديده للصلاة:',
          contentEn: 'Actions or events that invalidate Wudu and require repeating ablution before prayer:',
          bulletPointsAr: [
            'الخارج من السبيلين: بول، غائط، ريح، مذي، أو ودي.',
            'زوال العقل أو تغطيته: بنوم مستغرق عميق لا يشعر فيه النائم بنفسه، أو بإغماء أو سكر أو جنون (أما النوم اليسير جالساً فلا ينقض).',
            'أكل لحم الإبل (الجزور): لثبوت الحديث الصحيح في الأمر بالوضوء منه.',
            'مس الفرج باليد مباشرة بشهوة من غير حائل عند جمهور الفقهاء.',
          ],
          bulletPointsEn: [
            'Anything emitted from the two paths: Urine, stool, passing gas, Madhy (pre-seminal fluid), or Wady.',
            'Loss or coverage of consciousness: Deep sleep where one loses awareness of passing wind, fainting, intoxication, or anaesthesia (light dozing while firmly seated does not break wudu).',
            'Eating camel meat: Due to the explicit authentic command of the Prophet ﷺ.',
            'Touching the private parts directly without barrier with lust (according to majority).',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'quran',
          textAr: 'يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا قُمْتُمْ إِلَى الصَّلَاةِ فَاغْسِلُوا وُجُوهَكُمْ وَأَيْدِيَكُمْ إِلَى الْمَرَافِقِ وَامْسَحُوا بِرُءُوسِكُمْ وَأَرْجُلَكُمْ إِلَى الْكَعْبَيْنِ',
          textEn: 'O you who believe! When you rise to prayer, wash your faces and your hands to the elbows, wipe your heads, and wash your feet to the ankles. (Al-Ma\'idah: 6)',
          reference: 'سورة المائدة: 6',
        ),
        FiqhEvidence(
          type: 'hadith',
          textAr: '«لا تُقْبَلُ صَلاةُ مَن أَحْدَثَ حتى يَتَوَضَّأَ»',
          textEn: '"The prayer of none of you will be accepted if he relieves himself, until he performs ablution."',
          reference: 'صحيح البخاري ومسلم',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'هل خروج الدم من الجرح ينقض الوضوء؟',
          questionEn: 'Does bleeding from a wound invalidate Wudu?',
          answerAr: 'الراجح من أقوال أهل العلم أن خروج الدم أو القيح من غير السبيلين لا ينقض الوضوء، سواء كان قليلاً أو كثيراً، إلا إذا رغب المتوضئ في الاحتياط وغسله.',
          answerEn: 'The stronger scholarly opinion is that bleeding from wounds or nosebleeds does not break Wudu, regardless of amount, though washing away the blood from clothes is required.',
        ),
        FiqhFaq(
          questionAr: 'شككت هل أحدثت أم لا بعد الوضوء، فماذا أفعل؟',
          questionEn: 'What if I doubt whether I passed wind or broke Wudu?',
          answerAr: 'اليقين لا يزول بالشك؛ فإذا كنت متيقناً من الطهارة وشككت في الحدث فأنت طاهر، عملاً بحديث النبي ﷺ: «لا ينصرف حتى يسمع صوتاً أو يجد ريحاً».',
          answerEn: 'Certainty is not overruled by doubt. If you were certain of being pure, remain on that certainty unless you hear a sound or detect an odor.',
        ),
      ],
    ),

    FiqhTopic(
      id: 'wiping_socks',
      categoryId: 'taharah',
      titleAr: 'المسح على الخفين والجوربين',
      titleEn: 'Wiping Over Socks and Leather Footwear',
      summaryAr: 'شروط المسح، مدته للمقيم والمسافر، وكيفيته الصحيحة وما يبطله',
      summaryEn: 'Rules, conditions, duration limits for residents and travelers, and nullifiers of wiping over socks',
      readTimeMinutes: 4,
      keywords: ['مسح', 'خفين', 'جوربين', 'شراب', 'طهارة', 'wiping', 'socks', 'khuff', 'duration'],
      sections: [
        FiqhSection(
          titleAr: 'شروط صحة المسح',
          titleEn: 'Conditions for Valid Wiping',
          contentAr: 'يجوز المسح على الخفين (الجلد) والجوربين (القماش والقطن الساتر) بالشروط الآتية:',
          contentEn: 'Wiping over leather slippers (Khuffayn) or thick modern socks (Jawrabayn) is permissible with these criteria:',
          bulletPointsAr: [
            'أن يُلبسا على طهارة مائية كاملة: أي بعد إتمام وضوء كامل غُسلت فيه القدمان.',
            'أن يكونا طاهرين خاليين من النجاسة.',
            'أن يكونا ساترين لمحل الفرض (يغطيان الكعبين والقدم كاملاً).',
            'أن يكون المسح في الحدث الأصغر خاصة (أما في الجنابة وموجبات الغسل فلا يجزئ المسح بل يجب نزعهما وغسل القدمين).',
          ],
          bulletPointsEn: [
            'Putting them on after completing a full water ablution where feet were washed.',
            'The socks/footwear must be clean and free of filth.',
            'They must cover the obligatory area (covering the entire foot up to and including ankles).',
            'Wiping applies only to minor ritual impurity (Hadath Asghar); major impurity (Janabah/Ghusl) requires removing them.',
          ],
        ),
        FiqhSection(
          titleAr: 'مدة المسح',
          titleEn: 'Duration of Wiping',
          contentAr: 'تبدأ مدة المسح من أول مسحة بعد الحدث وليس من وقت اللبس:',
          contentEn: 'The duration counter begins from the FIRST WIPE after breaking wudu, NOT from when the socks were put on:',
          bulletPointsAr: [
            'للمقيم: يوم وليلة (24 ساعة كاملة).',
            'للمسافر: ثلاثة أيام بلياليهن (72 ساعة كاملة).',
            'إذا مسح وهو مقيم ثم سافر أتم مسح مسافر، وإذا مسح مسافراً ثم أقام أتم مسح مقيم إن بقي من مدته شيء.',
          ],
          bulletPointsEn: [
            'For a resident: 24 hours (one day and one night).',
            'For a traveler: 72 hours (three days and three nights).',
            'If a person wipes while resident then travels, he continues as a traveler. If he returns while traveling, resident duration applies.',
          ],
        ),
        FiqhSection(
          titleAr: 'كيفية المسح ومبطلاته',
          titleEn: 'How to Wipe and Its Nullifiers',
          contentAr: 'السنة أن يمسح أعلى الخف أو الجورب فقط ببل يديه بالماء وإمرارهما على ظاهر القدم من أطراف الأصابع إلى الساق:',
          contentEn: 'The sunnah is to wipe only the upper surface of the foot by running moist hands over the top of the sock:',
          bulletPointsAr: [
            'يمسح ظاهر (أعلى) الخف أو الجورب ولا يمسح أسفله ولا عقبه لقول علي رضي الله عنه: «لو كان الدين بالرأي لكان أسفل الخف أولى بالمسح من أعلاه».',
            'مبطلات المسح: انتهاء المدة (24 ساعة للمقيم أو 72 للمسافر)، نزع الخفين أو أحدهما، أو حدوث ما يوجب الغسل الأكبر.',
          ],
          bulletPointsEn: [
            'Wipe only the top surface, not underneath or behind the heel.',
            'Ali (RA) said: "If religion were based on opinion, the bottom of the footwear would be more worthy of wiping than the top, but I saw the Prophet ﷺ wipe over the top of his footwear."',
            'Nullifiers: Expiration of the 24h/72h duration, taking off one or both socks, or occurrence of major ritual impurity (Janabah).',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'hadith',
          textAr: '«جَعَلَ رَسولُ اللهِ ﷺ ثَلَاثَةَ أَيَّامٍ وَلَيَالِيَهُنَّ لِلْمُسَافِرِ، وَيَوْماً وَلَيْلَةً لِلْمُقِيمِ»',
          textEn: '"The Messenger of Allah ﷺ fixed the period of three days and nights for the traveler and one day and night for the resident (to wipe over footwear)."',
          reference: 'صحيح مسلم عن علي بن أبي طالب',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'لو خلعت الجورب بعد أن مسحت عليه وأنا على طهارة، هل يبطل وضوئي؟',
          questionEn: 'If I remove my socks after wiping while still in a state of purity, is my Wudu broken?',
          answerAr: 'الراجح أن خلع الجورب لا ينقض الوضوء ذاته، لكن لا يجوز لك المسح عليه مجدداً إذا أعدت لبسه إلا بعد وضوء جديد تغسل فيه قدميك.',
          answerEn: 'The stronger opinion is that removing socks does not break your underlying Wudu; however, you cannot wipe over them again if re-worn until you perform a fresh ablution with feet washed.',
        ),
      ],
    ),

    FiqhTopic(
      id: 'ghusl_rulings',
      categoryId: 'taharah',
      titleAr: 'أحكام الغسل وموجباته وكيفيته',
      titleEn: 'Rulings and Method of Ritual Bath (Ghusl)',
      summaryAr: 'الأسباب الموجبة للغسل، الغسل المجزئ والغسل الكامل، وأحكام الطهارة الكبرى',
      summaryEn: 'Causes requiring Ghusl, the sufficient minimal method vs complete sunnah method',
      readTimeMinutes: 4,
      keywords: ['غسل', 'جنابة', 'حيض', 'نفاس', 'طهارة كبرى', 'ghusl', 'janabah', 'purification'],
      sections: [
        FiqhSection(
          titleAr: 'موجبات الغسل (متى يجب الغسل؟)',
          titleEn: 'Causes Requiring Ghusl',
          contentAr: 'يجب الغسل الأكبر في الحالات التالية:',
          contentEn: 'Full ritual bath is obligatory upon the occurrence of:',
          bulletPointsAr: [
            'خروج المني بلذة في يقظة أو احتلام في نوم.',
            'الجماع والتقاء الختانين وإن لم يحصل إنزال لقوله ﷺ: «إذا جلس بين شعبها الأربع ثم جهدها فقد وجب الغسل».',
            'انقطاع دم الحيض والنفاس عند المرأة.',
            'دخول الكافر في الإسلام.',
            'الموت (تغسيل الميت المسلم فرض كفاية إلا الشهيد في المعركة).',
          ],
          bulletPointsEn: [
            'Emission of sexual fluid (Mani) with desire in waking or through a wet dream.',
            'Marital intercourse regardless of whether ejaculation occurred.',
            'Cessation of menstrual bleeding (Hayd) or post-natal bleeding (Nifas).',
            'Entering Islam for a new Muslim.',
            'Death (washing a deceased Muslim is a communal duty, except a martyr slain in battle).',
          ],
        ),
        FiqhSection(
          titleAr: 'كيفية الغسل: المجزئ والكامل',
          titleEn: 'How to Perform Ghusl: Minimal vs. Complete',
          contentAr: 'للغسل كيفيتان: كيفية مجزئة وكيفية كاملة مستحبة:',
          contentEn: 'Ghusl has two recognized forms: minimal (sufficient) and complete (sunnah):',
          bulletPointsAr: [
            'الغسل المجزئ (الواجب): النية، ثم تعميم البدن كله بالماء مرة واحدة مع المضمضة والاستنشاق وتخليل أصول الشعر حتى يصل الماء للبشرة.',
            'الغسل الكامل (المستحب): النية، غسل اليدين ثلاثاً، غسل الفرج وإزالة الأذى، الوضوء كاملاً كوضوء الصلاة، صب الماء على الرأس ثلاثاً مع تخليل أصول الشعر، ثم إفاضة الماء على سائر الجسد بالبدء بالشق الأيمن ثم الأيسر ودلك ما استطاع من بدنه.',
          ],
          bulletPointsEn: [
            'Sufficient (Minimal): Sincere intention, followed by washing the entire body once with water including mouth, nose, and wetting the roots of hair.',
            'Complete (Sunnah): Intention, washing hands 3 times, washing private parts, performing complete Wudu, pouring water 3 times over head rubbing hair roots, then washing entire body starting with right side then left.',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'quran',
          textAr: 'وَإِنْ كُنْتُمْ جُنُبًا فَاطَّهَّرُوا',
          textEn: 'And if you are in a state of janabah, then purify yourselves. (Al-Ma\'idah: 6)',
          reference: 'سورة المائدة: 6',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'هل يغني الغسل عن الوضوء إذا نوى الطهارتين؟',
          questionEn: 'Does Ghusl suffice for Wudu without performing ablution separately?',
          answerAr: 'نعم، الغسل من الجنابة يرفع الحدثين الأصغر والأكبر إذا نوى ذلك، ولا يشترط إعادة الوضوء بعده إلا إذا أحدث بناقض كالبول أو الريح أثناء أو بعد الغسل.',
          answerEn: 'Yes, Ghusl for major impurity lifts both major and minor impurities simultaneously if intended, provided one did not pass gas or urine during or after.',
        ),
      ],
    ),

    // ==========================================
    // 2. SALAH (PRAYER)
    // ==========================================
    FiqhTopic(
      id: 'salah_pillars',
      categoryId: 'salah',
      titleAr: 'شروط الصلاة وأركانها وواجباتها',
      titleEn: 'Conditions, Pillars, and Duties of Prayer',
      summaryAr: 'الفروق الدقيقة بين الشروط والأركان والواجبات، وما يسقط بالسهو وما يبطل الصلاة',
      summaryEn: 'Crucial distinctions between prayer conditions, pillars, and obligations, and how forgetfulness affects each',
      readTimeMinutes: 6,
      keywords: ['صلاة', 'أركان', 'واجبات', 'شروط', 'سجود السهو', 'salah', 'pillars', 'conditions', 'obligations'],
      sections: [
        FiqhSection(
          titleAr: 'شروط صحة الصلاة الـ 9',
          titleEn: 'The 9 Conditions of Valid Prayer',
          contentAr: 'الشرط هو ما يجب تقديمه قبل الصلاة ويستمر معها، وبدونه لا تصح:',
          contentEn: 'Pre-requisites that must be fulfilled before entering prayer and maintained throughout:',
          bulletPointsAr: [
            'الإسلام، والعقل، والتمييز.',
            'دخول الوقت: لقوله تعالى: ﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾.',
            'الطهارة من الحدثين (الأصغر بالوضوء والأكبر بالغسل).',
            'طهارة البدن والثوب ومكان الصلاة من النجاسة.',
            'ستر العورة بثوب طاهر لا يصف البشرة (عورة الرجل من السرة إلى الركبة، والمرأة الحرة كلها عورة في الصلاة إلا وجهها وكفيها).',
            'استقبال القبلة (الكعبة المشرفة).',
            'النية: ومحلها القلب دون التلفظ بها.',
          ],
          bulletPointsEn: [
            'Islam, sanity, and discernment (age of understanding).',
            'Entrance of the designated prayer time.',
            'Purity from both minor and major ritual impurities.',
            'Cleanness of body, clothes, and place of prayer from physical filth.',
            'Covering the Awrah with non-transparent clothing (men: navel to knees; women: entire body except face and hands).',
            'Facing the Qiblah direction.',
            'Intention (Niyyah) in the heart.',
          ],
        ),
        FiqhSection(
          titleAr: 'أركان الصلاة الـ 14 (لا تسقط عمداً ولا سهواً)',
          titleEn: 'The 14 Pillars of Prayer (Never Waived)',
          contentAr: 'الركن جزء من الصلاة لا يسقط عمداً ولا سهواً ولا جهلاً؛ فإن تُرِك وجب الإتيان به وبما بعده مع سجود السهو:',
          contentEn: 'Core structural pillars that cannot be skipped, whether intentionally or by mistake. If missed, they must be made up:',
          bulletPointsAr: [
            'القيام في الفرض للقادر عليه.',
            'تكبيرة الإحرام (قول: الله أكبر في البداية).',
            'قراءة سورة الفاتحة في كل ركعة.',
            'الركوع، والرفع والاعتدال منه قائماً.',
            'السجود على الأعضاء السبعة (الجبهة مع الأنف، الكفان، الركبتان، وأطراف أصابع القدمين).',
            'الرفع من السجود والجلوس بين السجدتين.',
            'الطمأنينة والخشوع في جميع الأركان.',
            'التشهد الأخير، والجلوس له.',
            'الصلاة على النبي ﷺ في التشهد الأخير.',
            'التسليم، والترتيب بين الأركان.',
          ],
          bulletPointsEn: [
            'Standing during obligatory prayers for those able.',
            'Takbirat al-Ihram (the opening "Allahu Akbar").',
            'Recitation of Surah Al-Fatihah in every rak\'ah.',
            'Ruku\' (bowing) and straightening upright from it.',
            'Sujood (prostration) upon 7 limbs (forehead with nose, two palms, two knees, and toes).',
            'Sitting upright between the two prostrations.',
            'Tranquility and composure (Tum\'anīnah) in all positions.',
            'The final Tashahhud and sitting for it.',
            'Sending blessings upon the Prophet ﷺ in the final Tashahhud.',
            'The Tasleem (salam) and maintaining proper sequence.',
          ],
        ),
        FiqhSection(
          titleAr: 'واجبات الصلاة الـ 8 (تُجبر بسجود السهو)',
          titleEn: 'The 8 Obligations of Prayer (Compensated by Sujood as-Sahw)',
          contentAr: 'الواجب ما يُثاب فاعله، وإذا تُرِك عمداً بطلت الصلاة، وإذا تُرِك سهواً أجزأ عنه سجود السهو:',
          contentEn: 'Acts required in prayer; intentional omission invalidates prayer, but accidental omission is compensated by Sujood as-Sahw:',
          bulletPointsAr: [
            'جميع التكبيرات غير تكبيرة الإحرام (تكبيرات الانتقال).',
            'قول: «سمع الله لمن حمده» للإمام والمنفرد عند الرفع من الركوع.',
            'قول: «ربنا ولك الحمد» للإمام والمأموم والمنفرد.',
            'قول: «سبحان ربي العظيم» مرة في الركوع (والزيادة إلى ثلاث سنة).',
            'قول: «سبحان ربي الأعلى» مرة في السجود.',
            'قول: «رب اغفر لي» بين السجدتين.',
            'التشهد الأول، والجلوس له في الصلاة الثلاثية والرباعية.',
          ],
          bulletPointsEn: [
            'All transition Takbeers other than the opening Takbir.',
            'Saying "Sami\'a Allahu liman hamidah" when rising from Ruku\' (for imam and solo).',
            'Saying "Rabbana wa laka al-hamd" (for everyone).',
            'Saying "Subhana Rabbiya al-Azeem" once in Ruku\' (thrice is sunnah).',
            'Saying "Subhana Rabbiya al-A\'la" once in Sujood.',
            'Saying "Rabb ighfir li" between the two prostrations.',
            'The first Tashahhud and sitting for it in 3- and 4-rak\'ah prayers.',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'hadith',
          textAr: '«صَلُّوا كما رَأَيْتُمُونِي أُصَلِّي»',
          textEn: '"Pray as you have seen me praying."',
          reference: 'صحيح البخاري عن مالك بن الحويرث',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'نسيت التشهد الأول وقمت للركعة الثالثة، ماذا أفعل؟',
          questionEn: 'I forgot the first Tashahhud and stood up for the 3rd rak\'ah. What should I do?',
          answerAr: 'إذا استتممت قائماً فلا ترجع، وتابع صلاتك واسجد سجدتي السهو قبل السلام؛ لأن النبي ﷺ نسي التشهد الأول وقام فلما قضى صلاته سجد سجدتين قبل أن يسلم.',
          answerEn: 'If you have stood up completely, do not sit back down. Continue your prayer and perform two prostrations of forgetfulness BEFORE the Tasleem.',
        ),
      ],
    ),

    FiqhTopic(
      id: 'sujood_sahw_guide',
      categoryId: 'salah',
      titleAr: 'دليل سجود السهو الشامل',
      titleEn: 'Comprehensive Guide to Sujood as-Sahw',
      summaryAr: 'أسبابه الثلاثة: الزيادة والنقص والشك، ومتى يسجد المصلي قبل السلام ومتى بعده',
      summaryEn: 'The three causes: Addition, Omission, and Doubt, and whether to prostrate before or after salam',
      readTimeMinutes: 5,
      keywords: ['سجود السهو', 'نسيان الصلاة', 'زيادة', 'نقصان', 'شك', 'sujood sahw', 'forgetfulness', 'doubt'],
      sections: [
        FiqhSection(
          titleAr: 'الحالات التي يسجد فيها قبل السلام',
          titleEn: 'Cases for Prostrating BEFORE the Salam',
          contentAr: 'يُسجد سجدتا السهو قبل التسليم في حالتين رئيستين:',
          contentEn: 'Prostrate twice before saying the final Tasleem in two primary circumstances:',
          bulletPointsAr: [
            'عند النقص: إذا ترك المصلي واجباً من واجبات الصلاة سهواً (مثل نسيان التشهد الأول، أو نسيان تسبيح الركوع أو السجود).',
            'عند الشك مع عدم الترجيح: إذا تردد المصلي هل صلى ثلاثاً أم أربعاً ولم يترجح عنده شيء، فإنه يبني على اليقين وهو الأقل (يعتبرها ثلاثاً ويأتي برابعة) ثم يسجد سجدتين قبل السلام.',
          ],
          bulletPointsEn: [
            'In case of Omission (Naqs): When an obligation is omitted accidentally (such as missing the first Tashahhud or transition tasbeeh).',
            'In case of Doubt without preference (Shakk): When uncertain whether one prayed 3 or 4 rak\'ahs with no prevailing conviction, build on certainty (the lower number, i.e., 3), complete the 4th, and prostrate before salam.',
          ],
        ),
        FiqhSection(
          titleAr: 'الحالات التي يسجد فيها بعد السلام',
          titleEn: 'Cases for Prostrating AFTER the Salam',
          contentAr: 'يُسجد سجدتا السهو بعد التسليم ثم يُسلّم مرة ثانية في حالتين:',
          contentEn: 'Prostrate twice after the final Tasleem, then make tasleem again, in two cases:',
          bulletPointsAr: [
            'عند الزيادة: إذا زاد ركوعاً أو سجوداً أو ركعة كاملة سهواً وتذكر بعد الفراغ منها، يسجد بعد السلام لئلا يجمع بين زيادتين.',
            'عند الشك مع الترجيح والتحري: إذا شك المصلي وترجح عنده أحد الأمرين بغالب ظنه، بنى على ما ترجح وأتم صلاته وسلم، ثم سجد سجدتين بعد السلام وسلّم.',
            'إذا سلّم المصلي قبل إتمام صلاته ناسياً ثم تذكر بعد قليل: فإنه يُكمل ما بقي عليه ويسلّم، ثم يسجد سجدتين بعد السلام ويسلّم ثانية.',
          ],
          bulletPointsEn: [
            'In case of Addition (Ziyadah): If an extra bowing, prostration, or full rak\'ah was added accidentally.',
            'In case of Doubt with a strong prevailing conviction: Build on the prevailing likelihood, complete prayer, make salam, then prostrate twice after salam and make salam again.',
            'If one made salam prematurely by mistake then remembered quickly: Complete the remaining rak\'ahs, make salam, then prostrate twice and make salam again.',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'hadith',
          textAr: '«إِذَا شَكَّ أَحَدُكُمْ في صَلَاتِهِ، فَلَمْ يَدْرِ كَمْ صَلَّى ثَلَاثاً أَمْ أَرْبَعاً؟ فَلْيَطْرَحِ الشَّكَّ وَلْيَبْنِ علَى ما اسْتَيْقَنَ، ثُمَّ يَسْجُدُ سَجْدَتَيْنِ قَبْلَ أَنْ يُسَلِّمَ»',
          textEn: '"If any of you is in doubt during prayer and does not know whether he prayed three or four rak\'ahs, let him discard doubt and build upon what is certain, then prostrate twice before the salam."',
          reference: 'صحيح مسلم عن أبي سعيد الخدري',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'ماذا أقول في سجود السهو؟',
          questionEn: 'What do I recite during Sujood as-Sahw?',
          answerAr: 'يُقال فيه ما يُقال في سجود الصلاة المعتاد: «سبحان ربي الأعلى» ثلاثاً، ويدعو بما تيسر، ويكبّر عند الهويّ وعند الرفع.',
          answerEn: 'Recite exactly what is recited in standard prostration: "Subhana Rabbiya al-A\'la" three times, saying Takbeer when descending and rising.',
        ),
      ],
    ),

    FiqhTopic(
      id: 'traveler_prayer',
      categoryId: 'salah',
      titleAr: 'رخصة صلاة المسافر: القصر والجمع',
      titleEn: "Traveler's Prayer: Shortening and Combining",
      summaryAr: 'مسافة السفر، الصلوات التي تقصر، شروط الجمع بين الصلاتين، وأحكام الإقامة',
      summaryEn: 'Travel distance limits, which prayers are shortened, combining conditions, and stay durations',
      readTimeMinutes: 4,
      keywords: ['سفر', 'قصر', 'جمع', 'مسافر', 'رخصة', 'travel', 'qasr', 'jam', 'shortening', 'combining'],
      sections: [
        FiqhSection(
          titleAr: 'قصر الصلاة الرباعية',
          titleEn: 'Shortening Four-Rak\'ah Prayers (Qasr)',
          contentAr: 'قصر الصلاة سنة مؤكدة للمسافر في الصلاة الرباعية فقط:',
          contentEn: 'Shortening four-rak\'ah prayers to two rak\'ahs is an emphasized sunnah for the traveler:',
          bulletPointsAr: [
            'الصلوات التي تُقصر: الظهر، والعصر، والعشاء (تُصلى ركعتين بدلاً من أربع).',
            'الصلوات التي لا تُقصر إجماعاً: صلاة الفجر (ركعتان) وصلاة المغرب (ثلاث ركعات).',
            'مسافة القصر: ما يُعد سفراً في العرف (وقدره جمهور العلماء بنحو 80 إلى 85 كيلومتراً فأكثر).',
            'يبدأ القصر بمجرد مغادرة حدود مدينته ومفارقة بنيانها، ولا يقصر وهو بعد في بيته.',
          ],
          bulletPointsEn: [
            'Prayers that are shortened: Dhuhr, Asr, and Isha (prayed as 2 rak\'ahs instead of 4).',
            'Prayers never shortened: Fajr (always 2) and Maghrib (always 3).',
            'Distance threshold: What is recognized as travel (estimated by majority as ~80-85 km / 50 miles).',
            'Qasr begins only once you depart your town/city boundaries, not while still at home.',
          ],
        ),
        FiqhSection(
          titleAr: 'الجمع بين الصلاتين: تقديماً وتأخيراً',
          titleEn: 'Combining Prayers: Forward (Taqdim) or Delayed (Ta\'khir)',
          contentAr: 'يجوز للمسافر الجمع بين الظهر والعصر، وبين المغرب والعشاء في وقت إحداهما:',
          contentEn: 'Travelers may combine Dhuhr with Asr, and Maghrib with Isha, at the time of either prayer:',
          bulletPointsAr: [
            'جمع تقديم: صلاة الظهر والعصر معاً في وقت الظهر، أو صلاة المغرب والعشاء معاً في وقت المغرب.',
            'جمع تأخير: تأخير الظهر ليصليه مع العصر في وقت العصر، أو تأخير المغرب ليصليه مع العشاء في وقت العشاء.',
            'لا يجوز جمع الفجر مع غيره، ولا جمع العصر مع المغرب.',
            'يصلي كل صلاة بأذان وإقامتين (يقيم للأولى ثم يسلم ويقيم للثانية دون فاصل طويل).',
          ],
          bulletPointsEn: [
            'Jam\' Taqdim (Early): Praying Dhuhr + Asr during Dhuhr time, or Maghrib + Isha during Maghrib time.',
            'Jam\' Ta\'khir (Delayed): Delaying Dhuhr to pray with Asr in Asr time, or Maghrib with Isha in Isha time.',
            'Fajr is never combined with any prayer, and Asr is never combined with Maghrib.',
            'Perform each prayer separately with one Adhan and two separate Iqamahs without long delay between them.',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'quran',
          textAr: 'وَإِذَا ضَرَبْتُمْ فِي الْأَرْضِ فَلَيْسَ عَلَيْكُمْ جُنَاحٌ أَنْ تَقْصُرُوا مِنَ الصَّلَاةِ',
          textEn: 'And when you travel throughout the land, there is no blame upon you for shortening the prayer. (An-Nisa: 101)',
          reference: 'سورة النساء: 101',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'إذا صليت مسافراً خلف إمام مقيم، هل أقصر؟',
          questionEn: 'If I am a traveler praying behind a resident imam, do I shorten?',
          answerAr: 'لا، إذا صلى المسافر مأموماً خلف إمام مقيم وجب عليه متابعته وإتمام أربع ركعات لقول ابن عباس رضي الله عنهما: «تلك السنة».',
          answerEn: 'No. If a traveler prays behind a resident imam, he must follow the imam and pray the full 4 rak\'ahs.',
        ),
      ],
    ),

    FiqhTopic(
      id: 'janazah_guide',
      categoryId: 'salah',
      titleAr: 'صفة صلاة الجنازة وأدعيتها',
      titleEn: 'Funeral Prayer (Salat al-Janazah) & Supplications',
      summaryAr: 'شرح التكبيرات الأربع وأدعية الميت المأثورة عن رسول الله ﷺ',
      summaryEn: 'Step-by-step 4 Takbeers and authentic prophetic supplications for the deceased',
      readTimeMinutes: 4,
      keywords: ['جنازة', 'صلاة الجنازة', 'تكبيرات', 'دعاء الميت', 'janazah', 'funeral', 'takbeer'],
      sections: [
        FiqhSection(
          titleAr: 'كيفية صلاة الجنازة خطوة بخطوة',
          titleEn: 'Step-by-Step Method of Janazah Prayer',
          contentAr: 'صلاة الجنازة فرض كفاية، ليس فيها ركوع ولا سجود، وتقام بأربع تكبيرات قائماً:',
          contentEn: 'Salat al-Janazah is a communal obligation without Ruku\' or Sujood, performed standing with 4 Takbeers:',
          bulletPointsAr: [
            'التكبيرة الأولى: يكبر رافعاً يديه، ثم يستعيذ ويبسمل ويقرأ سورة الفاتحة سراً (ويستحب قراءة سورة قصيرة معها).',
            'التكبيرة الثانية: يكبر ثم يصلي على النبي ﷺ بالصلاة الإبراهيمية (كما في التشهد الأخير).',
            'التكبيرة الثالثة: يكبر ثم يدعو للميت بالدعاء المأثور بإخلاص وتضرع.',
            'التكبيرة الرابعة: يكبر ثم يقف قليلاً ويدعو لعموم المسلمين، ثم يسلم تسليمة واحدة عن يمينه (أو تسليمتين).',
          ],
          bulletPointsEn: [
            '1st Takbeer: Say Allahu Akbar, seek refuge with Allah, recite Bismillah and Surah Al-Fatihah silently.',
            '2nd Takbeer: Say Allahu Akbar and send blessings on Prophet Muhammad ﷺ (Al-Salah Al-Ibrahimiyyah).',
            '3rd Takbeer: Say Allahu Akbar and sincerely supplicate for the deceased.',
            '4th Takbeer: Say Allahu Akbar, pause briefly praying for all Muslims, then make Tasleem to the right.',
          ],
        ),
        FiqhSection(
          titleAr: 'أدعية الجنازة المأثورة',
          titleEn: 'Authentic Supplications for the Deceased',
          contentAr: 'من أجمع الأدعية النبوية في التكبيرة الثالثة:',
          contentEn: 'The most comprehensive authentic prophetic du\'a for the third Takbeer:',
          bulletPointsAr: [
            '«اللَّهُمَّ اغْفِرْ له وَارْحَمْهُ، وَعَافِهِ وَاعْفُ عنْه، وَأَكْرِمْ نُزُلَهُ، وَوَسِّعْ مُدْخَلَهُ، وَاغْسِلْهُ بالمَاءِ وَالثَّلْجِ وَالْبَرَدِ، وَنَقِّهِ مِنَ الخَطَايَا كما نَقَّيْتَ الثَّوْبَ الأبْيَضَ مِنَ الدَّنَسِ، وَأَبْدِلْهُ دَاراً خَيْراً مِن دَارِهِ، وَأَهْلاً خَيْراً مِن أَهْلِهِ، وَأَدْخِلْهُ الجَنَّةَ وَأَعِذْهُ مِن عَذَابِ القَبْرِ، وَمِنْ عَذَابِ النَّارِ».',
            'إذا كان الميت صغيراً (طفلاً لم يبلغ): «اللهم اجعله فرطاً وذخراً لوالديه، وشفيعاً مجاباً، اللهم ثقّل به موازينهما وأعظم به أجورهما».',
          ],
          bulletPointsEn: [
            '"Allahumma ighfir lahu war-hamhu, wa \'afihi wa\'fu \'anhu, wa akrim nuzulahu, wa wassi\' mudkhalahu, waghsilhu bil-ma\'i wath-thalji wal-barad, wa naqqihi minal-khataya kama naqqaytat-thawbal-abyada minad-danas..."',
            'For a child: "Allahumma ij\'alhu faratan wa dhukhran li-walidayhi wa shafi\'an mujaba..."',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'hadith',
          textAr: '«مَن صَلَّى علَى جَنَازَةٍ فَلَهُ قِيرَاطٌ، وَمَن تَبِعَهَا حتَّى تُدْفَنَ كانَ له قِيرَاطَانِ، أصْغَرُهُما مِثْلُ أُحُدٍ»',
          textEn: '"Whoever offers the funeral prayer receives one Qirat of reward, and whoever follows it until burial receives two Qirats, the smaller of which is like Mount Uhud."',
          reference: 'صحيح البخاري ومسلم',
        ),
      ],
      faqs: [],
    ),

    // ==========================================
    // 3. SAWM (FASTING)
    // ==========================================
    FiqhTopic(
      id: 'fasting_nullifiers',
      categoryId: 'sawm',
      titleAr: 'مفطرات الصيام المعاصرة وما لا يفسد الصوم',
      titleEn: 'Fasting Nullifiers & Contemporary Medical Issues',
      summaryAr: 'بيان المفطرات الحقيقية وحكم بخاخ الربو، قطرة العين والأذن، التحاليل والحقن',
      summaryEn: 'Core nullifiers, asthma inhalers, eye/ear drops, injections, blood tests, and tooth extraction',
      readTimeMinutes: 5,
      keywords: ['صيام', 'مفطرات', 'رمضان', 'بخاخ', 'حقن', 'قطرة', 'fasting', 'nullifiers', 'medical'],
      sections: [
        FiqhSection(
          titleAr: 'مفطرات الصيام المتفق عليها',
          titleEn: 'Agreed-Upon Nullifiers of Fasting',
          contentAr: 'يفسد الصوم إذا فعل المسلم أياً منها عالماً عامداً ذاكراً لصومه:',
          contentEn: 'The fast is invalidated if committed knowingly, intentionally, and remembering one\'s fast:',
          bulletPointsAr: [
            'الأكل والشرب عمداً (أما من أكل أو شرب ناسياً فصومه صحيح ويتم صومه لقوله ﷺ: «فإنما أطعمه الله وسقاه»).',
            'الجماع عمداً في نهار رمضان: وهو أعظم المفطرات إثماً ويوجب القضاء والكفارة المغلظة (عتق رقبة، فإن لم يجد فصيام شهرين متتابعين، فإن لم يستطع فإطعام 60 مسكيناً).',
            'إنزال المني عمداً بمباشرة أو استمناء.',
            'القيء عمداً (الاستقاءة)، أما من غلبه القيء دون قصد فلا شيء عليه.',
            'خروج دم الحيض أو النفاس عند المرأة.',
            'ما كان في معنى الأكل والشرب: كالإبر المغذية والمحاليل الوريدية التي تقوم مقام الطعام.',
          ],
          bulletPointsEn: [
            'Eating or drinking intentionally (eating/drinking forgetfully does NOT break fast).',
            'Marital intimacy during daylight hours: Requires making up the day and severe expiation (Kaffarah: fasting 2 consecutive months).',
            'Intentional ejaculation through contact.',
            'Vomiting intentionally (vomiting involuntarily does not break the fast).',
            'Onset of menstruation or post-natal bleeding.',
            'Nutritional intravenous drips providing nourishment substitute for food.',
          ],
        ),
        FiqhSection(
          titleAr: 'المسائل الطبية المعاصرة التي لا تفطر',
          titleEn: 'Contemporary Medical Items that Do NOT Break Fast',
          contentAr: 'أقر مجمع الفقه الإسلامي الدولي أن الأمور الآتية لا تفسد الصوم لأنها ليست أكلاً ولا شرباً:',
          contentEn: 'Confirmed by International Islamic Fiqh Academy as NOT breaking fast (neither food nor drink):',
          bulletPointsAr: [
            'قطرة العين، قطرة الأذن، وغسول الأذن (ما لم يبتلع ما قد ينفذ للحلق).',
            'بخاخ الربو المستعمل عن طريق الفم للتنفس.',
            'الحقن العلاجية العضلية أو الجلدية غير المغذية (مثل حقن الأنسولين وحقن البنسلين).',
            'سحب عينات الدم للتحليل المخبري.',
            'استعمال معجون وفرشاة الأسنان والسواك مع الحذر من ابتلاع شيء.',
            'حبة تحت اللسان التي تؤخذ لعلاج الذبحة الصدرية إذا تجنب ابتلاع ما تحلل منها.',
            'خلع الضرس وتنظيف الأسنان ما لم يبتلع دماً أو ماءً.',
          ],
          bulletPointsEn: [
            'Eye drops and ear drops.',
            'Asthma inhalers utilized for breathing expansion.',
            'Non-nutritive medical injections (intramuscular, subcutaneous, e.g. insulin).',
            'Taking blood samples for lab tests.',
            'Toothbrush, toothpaste, and Siwak (provided nothing is swallowed).',
            'Nitroglycerin tablets dissolved under tongue for angina.',
            'Dental extraction and tooth cleaning without swallowing fluid.',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'hadith',
          textAr: '«مَن نَسِيَ وَهو صَائِمٌ، فأكَلَ أوْ شَرِبَ، فَلْيُتِمَّ صَوْمَهُ، فإنَّما أَطْعَمَهُ اللَّهُ وَسَقَاهُ»',
          textEn: '"Whoever forgets while fasting and eats or drinks, let him complete his fast, for Allah has fed him and given him drink."',
          reference: 'صحيح البخاري ومسلم عن أبي هريرة',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'ما حكم بلع الريق أو البلغم أثناء الصيام؟',
          questionEn: 'Does swallowing saliva or phlegm break the fast?',
          answerAr: 'بلع الريق المعتاد جائز إجماعاً ولا يفطر. أما البلغم فالأولى مجّه وبصقه متى وصل إلى الفم، لكن إن نزل دون قصد فلا يفسد الصوم.',
          answerEn: 'Swallowing normal saliva does not break the fast by scholarly consensus. Phlegm reaching the mouth should be spat out, but unintentional swallowing does not void fast.',
        ),
      ],
    ),

    // ==========================================
    // 4. ZAKAH & CHARITY
    // ==========================================
    FiqhTopic(
      id: 'zakah_guide',
      categoryId: 'zakah',
      titleAr: 'دليل الزكاة الشامل: النصاب والمقدار والمصارف',
      titleEn: 'Comprehensive Zakah Guide: Nisab, Rates, and Recipients',
      summaryAr: 'شروط وجوب الزكاة، نصاب الذهب والفضة والعملات النقدية، ومصارف الزكاة الثمانية',
      summaryEn: 'Conditions of obligation, gold & silver Nisab, cash calculations, and the 8 eligible recipient categories',
      readTimeMinutes: 5,
      keywords: ['زكاة', 'نصاب', 'ذهب', 'فضة', 'مصارف الزكاة', 'zakah', 'nisab', 'charity', 'wealth'],
      sections: [
        FiqhSection(
          titleAr: 'شروط وجوب زكاة المال',
          titleEn: 'Conditions for Obligatory Zakah',
          contentAr: 'تجب الزكاة في أموال المسلم إذا توافرت الشروط التالية:',
          contentEn: 'Zakah is mandatory upon a Muslim\'s wealth when the following conditions are met:',
          bulletPointsAr: [
            'بلوغ النصاب: وهو الحد الأدنى للمال الذي تجب فيه الزكاة.',
            'حولان الحول: مرور سنة قمرية كاملة (354 يوماً) على بقاء المال بالغاً النصاب.',
            'الملك التام: أن يكون المال مستقراً ومملوكاً لصاحبه يملك التصرف فيه.',
            'الفضل عن الحاجات الأصلية: كالطعام والملبس والمسكن والمركب وسداد الديون الحالة.',
          ],
          bulletPointsEn: [
            'Reaching Nisab: The minimum threshold of net wealth.',
            'Passage of one lunar year (Hawl / 354 days) while holding Nisab.',
            'Complete and unrestricted ownership of the asset.',
            'Surplus above essential living needs (housing, vehicle, basic sustenance, immediate debts).',
          ],
        ),
        FiqhSection(
          titleAr: 'نصاب الذهب والفضة والأموال النقدية ومقدار الزكاة',
          titleEn: 'Nisab of Gold, Silver, Cash & Zakah Rate',
          contentAr: 'المقدار الواجب إخراجه هو ربع العشر (2.5%):',
          contentEn: 'The obligatory rate to pay out is 2.5% (one fortieth):',
          bulletPointsAr: [
            'نصاب الذهب: 85 غراماً من الذهب الخالص عيار 24 (أو 97.1 غراماً عيار 21).',
            'نصاب الفضة: 595 غراماً من الفضة الخالصة.',
            'نصاب الأوراق والعملات النقدية: يُقدّر بقيمة 85 غراماً من الذهب (أو 595 غراماً فضة)، فإذا ملك المسلم مبلغاً نقدياً يعادل قيمة هذا النصاب وحال عليه الحول وجبت فيه الزكاة بنسبة 2.5%.',
            'زكاة عروض التجارة: تقوّم البضائع المعروضة للبيع في نهاية الحول بقيمتها الحالية، وتضاف إلى السيولة النقدية وتخرج الزكاة بنسبة 2.5%.',
          ],
          bulletPointsEn: [
            'Gold Nisab: 85 grams of pure 24k gold (or ~97.1 grams of 21k gold).',
            'Silver Nisab: 595 grams of pure silver.',
            'Cash & Currency Nisab: Equivalent value of 85g gold; if cash holdings reach or exceed this for one lunar year, 2.5% is due.',
            'Trade Merchandise: Goods for sale evaluated at current retail value at end of year, combined with cash, and 2.5% paid.',
          ],
        ),
        FiqhSection(
          titleAr: 'مصارف الزكاة الثمانية',
          titleEn: 'The Eight Eligible Categories of Recipients',
          contentAr: 'حددهم الله تعالى حصرًا في سورة التوبة: ﴿إِنَّمَا الصَّدَقَاتُ لِلْفُقَرَاءِ وَالْمَسَاكِينِ...﴾:',
          contentEn: 'Explicitly restricted by Allah in Surah At-Tawbah (9:60):',
          bulletPointsAr: [
            'الفقراء: الذين لا يجدون شيئاً أو يجدون أقل من نصف كفايتهم.',
            'المساكين: الذين يجدون نصف كفايتهم أو أكثر ولكن لا تكفيهم.',
            'العاملون عليها: الجباة والموزعون للزكاة بتكليف رسمي.',
            'المؤلفة قلوبهم: الداخلون في الإسلام حديثاً لتثبيتهم أو من يُرجى إسلامه أو كف شره.',
            'في الرقاب: إعانة المكاتبين لفك رقابهم أو تحرير الأسرى المسلمين.',
            'الغارمون: المدينون العاجزون عن سداد ديونهم في غير معصية.',
            'في سبيل الله: المجاهدون والدعاة والمشاريع الدعوية الخالصة.',
            'ابن السبيل: المسافر المنقطع عن بلده ونفد ماله.',
          ],
          bulletPointsEn: [
            'The Poor (Al-Fuqara): Those having no wealth or less than half basic sufficiency.',
            'The Needy (Al-Masakin): Those finding half or more of sufficiency, but still falling short.',
            'Zakah Administrators: Official collectors and distributors.',
            'Those with inclined hearts: New Muslims to strengthen them or to attract to Islam.',
            'Freeing captives/slaves.',
            'Debt-ridden (Al-Gharimun): Those unable to pay off legitimate debts.',
            'In the cause of Allah (Fi Sabilillah).',
            'Stranded travelers (Ibn As-Sabil) whose funds have run out.',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'quran',
          textAr: 'إِنَّمَا الصَّدَقَاتُ لِلْفُقَرَاءِ وَالْمَسَاكِينِ وَالْعَامِلِينَ عَلَيْهَا وَالْمُؤَلَّفَةِ قُلُوبُهُمْ وَفِي الرِّقَابِ وَالْغَارِمِينَ وَفِي سَبِيلِ اللَّهِ وَابْنِ السَّبِيلِ ۖ فَرِيضَةً مِّنَ اللَّهِ',
          textEn: 'Zakah expenditures are only for the poor and for the needy and for those employed to collect it and for bringing hearts together and for freeing captives and for those in debt and for the cause of Allah and for the traveler. (At-Tawbah: 60)',
          reference: 'سورة التوبة: 60',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'هل يجوز إعطاء الزكاة للوالدين أو الأبناء؟',
          questionEn: 'Can Zakah be given to parents or children?',
          answerAr: 'لا يجوز دفع الزكاة للأصول (كالوالدين والأجداد) ولا للفروع (كالأولاد والأحفاد) إذا كانت نفقتهم واجبة عليك، وتدفع لهم من مالك الخاص لا من الزكاة.',
          answerEn: 'No, Zakah cannot be given to direct ascendants (parents, grandparents) or direct descendants (children, grandchildren) whom you are obliged to support.',
        ),
      ],
    ),

    // ==========================================
    // 5. HAJJ & UMRAH
    // ==========================================
    FiqhTopic(
      id: 'umrah_guide',
      categoryId: 'hajj',
      titleAr: 'صفة العمرة خطوة بخطوة',
      titleEn: 'Step-by-Step Practical Guide to Umrah',
      summaryAr: 'أركان العمرة الثلاثة: الإحرام، الطواف، والسعي، مع التحلل وسنن كل ركن',
      summaryEn: 'The three pillars of Umrah: Ihram, Tawaf around the Kaaba, Sa\'i between Safa and Marwa, and exit',
      readTimeMinutes: 5,
      keywords: ['عمرة', 'إحرام', 'طواف', 'سعي', 'حلق', 'كعبة', 'umrah', 'tawaf', 'ihram', 'sai'],
      sections: [
        FiqhSection(
          titleAr: 'أركان العمرة الثلاثة',
          titleEn: 'The Three Pillars of Umrah',
          contentAr: 'تتكون العمرة من ثلاثة أركان لا تصح إلا بها، وواجب واحد للتحلل:',
          contentEn: 'Umrah comprises three essential pillars and one completion duty:',
          bulletPointsAr: [
            '1. الإحرام: وهو نية الدخول في النسك من الميقات المحدد شرعاً مع التلبية: «لبيك اللهم عمرة».',
            '2. الطواف بالبيت: سبعة أشواط كاملة حول الكعبة المشرفة بدءاً من الحجر الأسود وانتهاءً به.',
            '3. السعي بين الصفا والمروة: سبعة أشواط تبدأ بالصفا وتنتهي بالمروة.',
            'واجب التحلل: الحلق أو التقصير (الحلق أفضل للرجال، والمرأة تقص من أطراف شعرها قدر أنملة).',
          ],
          bulletPointsEn: [
            '1. Ihram: Intention to enter sacred state at designated Miqat chanting Talbiyah: "Labbayk Allahumma Umrah".',
            '2. Tawaf: Seven full circuits around the Ka\'bah starting and ending at the Black Stone.',
            '3. Sa\'i: Seven laps between Mount Safa and Mount Marwa, starting at Safa and ending at Marwa.',
            'Completion Duty: Shaving head (Halq) or trimming hair (Taqsir) for men; women cut a fingertip length from hair ends.',
          ],
        ),
        FiqhSection(
          titleAr: 'محظورات الإحرام',
          titleEn: 'Prohibitions of Ihram',
          contentAr: 'ما يحرم على المحرم فعله بعد نية الإحرام:',
          contentEn: 'Actions forbidden after entering the state of Ihram:',
          bulletPointsAr: [
            'حلق شعر الرأس أو قصه أو إزالة شعر البدن.',
            'تقليم الأظافر.',
            'استعمال الطيب والعطور في البدن أو الثياب.',
            'تغطية الرأس بملاصق للرجل (كالعمامة أو الطاقية).',
            'لبس المخيط والمحيط للرجل (كالثوب والقميص والسراويل، ويجوز الإزار والرداء والنعلين وحزام النقود).',
            'عقد النكاح أو خطبة النساء أو الجماع ومقدماته.',
            'قتل صيد البر أو صيده.',
            'لبس النقاب والقفازين للمرأة (وتسدل على وجهها إذا مر بها الرجال الأجانب).',
          ],
          bulletPointsEn: [
            'Shaving, cutting, or removing body hair.',
            'Clipping fingernails or toenails.',
            'Applying scent, perfume, or scented soaps.',
            'Covering the head with form-fitting headwear for men (hats, turbans).',
            'Wearing tailored stitched clothing for men (shirts, trousers; unstitched waist-wrapper and upper sheet are worn).',
            'Contracting marriage or sexual intimacy.',
            'Hunting land game.',
            'Wearing face veils (Niqab) or gloves for women (lowering head-covering over face around non-mahrams is permitted).',
          ],
        ),
      ],
      evidences: [
        FiqhEvidence(
          type: 'hadith',
          textAr: '«العُمْرَةُ إلى العُمْرَةِ كَفَّارَةٌ لِما بيْنَهُمَا، والحَجُّ المَبْرُورُ ليسَ له جَزَاءٌ إلَّا الجَنَّةُ»',
          textEn: '"An Umrah to an Umrah is an expiation for whatever was committed between them, and the accepted Hajj has no reward other than Paradise."',
          reference: 'صحيح البخاري ومسلم عن أبي هريرة',
        ),
      ],
      faqs: [
        FiqhFaq(
          questionAr: 'ماذا يقال بين الركن اليماني والحجر الأسود؟',
          questionEn: 'What is recited between the Yemeni Corner and the Black Stone during Tawaf?',
          answerAr: 'يستحب أن يقول: «رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ».',
          answerEn: 'It is recommended to recite: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar" (2:201).',
        ),
      ],
    ),
  ];

  static FiqhCategory getCategory(String categoryId) {
    return categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => categories.first,
    );
  }

  static List<FiqhTopic> getTopicsByCategory(String categoryId) {
    return topics.where((t) => t.categoryId == categoryId).toList();
  }

  static List<FiqhTopic> searchTopics(String query, bool isArabic) {
    if (query.trim().isEmpty) return topics;
    final q = query.trim().toLowerCase();
    return topics.where((topic) {
      final titleMatch = topic.getTitle(isArabic).toLowerCase().contains(q);
      final summaryMatch = topic.getSummary(isArabic).toLowerCase().contains(q);
      final keywordMatch = topic.keywords.any((k) => k.toLowerCase().contains(q));
      final sectionMatch = topic.sections.any((s) =>
          s.getTitle(isArabic).toLowerCase().contains(q) ||
          s.getContent(isArabic).toLowerCase().contains(q) ||
          s.getBulletPoints(isArabic).any((b) => b.toLowerCase().contains(q)));
      final faqMatch = topic.faqs.any((f) =>
          f.getQuestion(isArabic).toLowerCase().contains(q) ||
          f.getAnswer(isArabic).toLowerCase().contains(q));
      return titleMatch || summaryMatch || keywordMatch || sectionMatch || faqMatch;
    }).toList();
  }
}
