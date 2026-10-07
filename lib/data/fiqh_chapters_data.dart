import '../models/islamic_library_models.dart';

class FiqhChaptersData {
  static const List<FiqhChapter> chapters = [
    FiqhChapter(
      id: 1,
      number: 1,
      titleAr: 'مقدمة الكتاب في أصول الفقه ومصادره',
      titleEn: 'Introduction: Principles & Sources of Fiqh',
      categoryAr: 'أصول وقواعد',
      categoryEn: 'Principles & Methodology',
      summaryAr:
          'بيان معنى الفقه لغة واصطلاحاً، ومصادر التشريع الإسلامي الأربعة المتفق عليها (الكتاب، السنة، الإجماع، القياس)، ومكانة التفقه في الدين ومنهج الكتاب.',
      summaryEn:
          'Definition of Fiqh, primary sources of Islamic legislation (Quran, Sunnah, Consensus, Analogy), virtue of seeking religious knowledge, and methodological framework.',
      readTimeMinutes: 8,
      bookStartPage: 1,
      bookEndPage: 20,
      bookStartPageEn: 1,
      bookEndPageEn: 20,
    ),
    FiqhChapter(
      id: 2,
      number: 2,
      titleAr: 'كتاب الطهارة',
      titleEn: 'Book of Purification (Kitab at-Taharah)',
      categoryAr: 'فقه العبادات',
      categoryEn: 'Worship Jurisprudence',
      summaryAr:
          'أحكام المياه، الآنية، سنن الفطرة، صفة الوضوء ونواقضه، المسح على الخفين والجبائر، الغسل من الجنابة، التيمم، إزالة النجاسات، وأحكام الحيض والنفاس.',
      summaryEn:
          'Rulings on waters, utensils, natural disposition (Fitrah), ablution (Wudu) and its nullifiers, wiping over socks, ritual bath (Ghusl), dry ablution (Tayammum), impurities, and menses.',
      readTimeMinutes: 15,
      bookStartPage: 21,
      bookEndPage: 62,
      bookStartPageEn: 21,
      bookEndPageEn: 62,
    ),
    FiqhChapter(
      id: 3,
      number: 3,
      titleAr: 'كتاب الصلاة',
      titleEn: 'Book of Prayer (Kitab as-Salah)',
      categoryAr: 'فقه العبادات',
      categoryEn: 'Worship Jurisprudence',
      summaryAr:
          'شروط الصلاة وأركانها وواجباتها وسننها ومكروهاتها ومبطلاتها، صلاة الجماعة والإمامة، سجود السهو والتلاوة، صلاة التطوع، وصلاة أهل الأعذار والجمعة والعيدين والاستسقاء والكسوف والجنائز.',
      summaryEn:
          'Conditions, pillars, obligations, Sunan, and nullifiers of prayer, congregational prayer, prostrations of forgetfulness, voluntary prayers, traveler prayer, Friday, Eid, eclipse, and funerals.',
      readTimeMinutes: 25,
      bookStartPage: 63,
      bookEndPage: 140,
      bookStartPageEn: 63,
      bookEndPageEn: 140,
    ),
    FiqhChapter(
      id: 4,
      number: 4,
      titleAr: 'كتاب الزكاة',
      titleEn: 'Book of Zakah (Kitab az-Zakah)',
      categoryAr: 'فقه العبادات',
      categoryEn: 'Worship Jurisprudence',
      summaryAr:
          'شروط وجوب الزكاة، زكاة الذهب والفضة والعملات المعاصرة، عروض التجارة، بهيمة الأنعام، الحبوب والثمار، زكاة الفطر، ومصارف الزكاة الثمانية المستحقين لها.',
      summaryEn:
          'Conditions of obligation, Nisab thresholds for gold, silver, modern currencies, trade goods, livestock, agricultural crops, Zakat al-Fitr, and the eight eligible recipient categories.',
      readTimeMinutes: 12,
      bookStartPage: 141,
      bookEndPage: 167,
      bookStartPageEn: 141,
      bookEndPageEn: 167,
    ),
    FiqhChapter(
      id: 5,
      number: 5,
      titleAr: 'كتاب الصيام',
      titleEn: 'Book of Fasting (Kitab as-Siyam)',
      categoryAr: 'فقه العبادات',
      categoryEn: 'Worship Jurisprudence',
      summaryAr:
          'أحكام صيام شهر رمضان، ثبوت دخول الشهر، الأعذار المبيحة للفطر والقضاء والفدية، مفسدات الصوم، صيام التطوع، الأيام المنهي عن صيامها، وأحكام الاعتكاف.',
      summaryEn:
          'Rulings of Ramadan, crescent sighting, valid exemptions from fasting, expiations, nullifiers of fast, voluntary fasting, prohibited fasting days, and spiritual seclusion (I\'tikaf).',
      readTimeMinutes: 10,
      bookStartPage: 168,
      bookEndPage: 189,
      bookStartPageEn: 168,
      bookEndPageEn: 189,
    ),
    FiqhChapter(
      id: 6,
      number: 6,
      titleAr: 'كتاب الحج والعمرة',
      titleEn: 'Book of Hajj & Umrah (Kitab al-Hajj)',
      categoryAr: 'فقه العبادات',
      categoryEn: 'Worship Jurisprudence',
      summaryAr:
          'شروط وجوب الحج والعمرة، المواقيت الزمانية والمكانية، الإحرام ومحظوراته، أركان الحج وواجباته وصفته بالتفصيل من التروية إلى طواف الوداع، الهدي والأضحية والعقيقة، وزيارة المسجد النبوي.',
      summaryEn:
          'Conditions of obligation, temporal and spatial Mawaqit, Ihram prohibitions, pillars and rituals from Mina to Farewell Tawaf, sacrificial offerings, and visiting the Prophet\'s Mosque.',
      readTimeMinutes: 14,
      bookStartPage: 190,
      bookEndPage: 217,
      bookStartPageEn: 190,
      bookEndPageEn: 217,
    ),
    FiqhChapter(
      id: 7,
      number: 7,
      titleAr: 'كتاب الجهاد',
      titleEn: 'Book of Jihad (Kitab al-Jihad)',
      categoryAr: 'فقه المعاملات والدولة',
      categoryEn: 'State & Governance',
      summaryAr:
          'مشروعية الجهاد في سبيل الله وضوابطه، شروطه، أحكام الأسرى والغنائم، الأمان والهدنة، والرباط في سبيل الله وثوابه.',
      summaryEn:
          'Legitimacy and conditions of defense in Islam, ethical rules of engagement, treatment of captives, treaties, covenants of peace, and vigilance along borders (Ribat).',
      readTimeMinutes: 8,
      bookStartPage: 218,
      bookEndPage: 229,
      bookStartPageEn: 218,
      bookEndPageEn: 229,
    ),
    FiqhChapter(
      id: 8,
      number: 8,
      titleAr: 'كتاب المعاملات المالية والبيوع',
      titleEn: 'Book of Financial Transactions & Sales',
      categoryAr: 'فقه المعاملات',
      categoryEn: 'Commercial Jurisprudence',
      summaryAr:
          'أركان البيع وشروطه، البيوع المنهي عنها والربا، الخيارات، السلم، القرض، الرهن، الضمان والحوالة، الصلح، الوكالة، الشركة، المساقاة، والإجارة وإحياء الموات.',
      summaryEn:
          'Pillars and conditions of trade, prohibited transactions and usury (Riba), contractual options (Khiyar), collateral, guarantees, debt transfer, leasing (Ijarah), and partnerships.',
      readTimeMinutes: 20,
      bookStartPage: 230,
      bookEndPage: 289,
      bookStartPageEn: 230,
      bookEndPageEn: 289,
    ),
    FiqhChapter(
      id: 9,
      number: 9,
      titleAr: 'كتاب المواريث والوصايا والعتق',
      titleEn: 'Book of Inheritance, Wills & Emancipation',
      categoryAr: 'فقه المعاملات',
      categoryEn: 'Estate & Inheritance',
      summaryAr:
          'أسباب الإرث وموانعه، أصحاب الفروض والعصبات، الحجب والعول، قسمة التركات، وأحكام الوصية الشرعية وشروطها وحدودها.',
      summaryEn:
          'Causes and impediments to inheritance, prescribed fractional shares (Ashab al-Furud), universal heirs (Asabah), shielding, estate distribution, and testamentary bequests (Wasaya).',
      readTimeMinutes: 10,
      bookStartPage: 290,
      bookEndPage: 308,
      bookStartPageEn: 290,
      bookEndPageEn: 308,
    ),
    FiqhChapter(
      id: 10,
      number: 10,
      titleAr: 'كتاب النكاح والطلاق والأسرة',
      titleEn: 'Book of Marriage, Divorce & Family',
      categoryAr: 'فقه الأسرة',
      categoryEn: 'Family Jurisprudence',
      summaryAr:
          'الخطبة وأركان النكاح وشروطه، المحرمات من النساء، الصداق (المهر)، عشرة النساء، الطلاق وأحكامه وأقسامه، الخلع، الإيلاء، الظهار، اللعان، العِدَد، ونفقة الأقارب والحضانة.',
      summaryEn:
          'Engagement, marriage contract validity, prohibited degrees, dower (Mahr), marital rights, divorce procedures (Talaq), mutual release (Khul\'), waiting periods (Iddah), alimony, and custody.',
      readTimeMinutes: 18,
      bookStartPage: 309,
      bookEndPage: 357,
      bookStartPageEn: 309,
      bookEndPageEn: 357,
    ),
    FiqhChapter(
      id: 11,
      number: 11,
      titleAr: 'كتاب الجنايات والديات',
      titleEn: 'Book of Penalties & Blood Money (Kitab al-Jinayat)',
      categoryAr: 'القضاء والجنايات',
      categoryEn: 'Penal Law',
      summaryAr:
          'أنواع القتل (عمد، شبه عمد، خطأ)، شروط وجوب القصاص وما يسقطه، مقادير الديات في النفس والأطراف، وأحكام القسامة.',
      summaryEn:
          'Classifications of homicide, conditions and remissions of retribution (Qisas), blood-money compensation (Diyah) for lives and bodily injuries, and solemn oaths.',
      readTimeMinutes: 10,
      bookStartPage: 358,
      bookEndPage: 376,
      bookStartPageEn: 358,
      bookEndPageEn: 376,
    ),
    FiqhChapter(
      id: 12,
      number: 12,
      titleAr: 'كتاب الحدود',
      titleEn: 'Book of Prescribed Punishments (Kitab al-Hudud)',
      categoryAr: 'القضاء والجنايات',
      categoryEn: 'Penal Law',
      summaryAr:
          'حد الزنا، حد القذف، حد شرب الخمر، حد السرقة، حد الحرابة وقطاع الطرق، حد الردة، والتعزير في المعاصي التي لا حد فيها.',
      summaryEn:
          'Prescribed legal penalties for major transgressions, procedural safeguards, evidentiary standards, repenting, and discretionary correctional measures (Ta\'zir).',
      readTimeMinutes: 12,
      bookStartPage: 377,
      bookEndPage: 401,
      bookStartPageEn: 377,
      bookEndPageEn: 401,
    ),
    FiqhChapter(
      id: 13,
      number: 13,
      titleAr: 'كتاب الأيمان والنذور',
      titleEn: 'Book of Oaths & Vows (Kitab al-Ayman)',
      categoryAr: 'فقه الأحكام',
      categoryEn: 'Oaths & Commitments',
      summaryAr:
          'أقسام الأيمان، اليمين المنعقدة واللغو والغموس، كفارة اليمين، وأحكام النذر وشروطه وما يصح منه وما يحرم.',
      summaryEn:
          'Classifications of oaths, binding oaths vs inadvertent oaths, expiation of broken oaths (Kaffarah), and rulings governing vows (Nadhr).',
      readTimeMinutes: 6,
      bookStartPage: 402,
      bookEndPage: 410,
      bookStartPageEn: 402,
      bookEndPageEn: 410,
    ),
    FiqhChapter(
      id: 14,
      number: 14,
      titleAr: 'كتاب الأطعمة والذبائح والصيد',
      titleEn: 'Book of Foods, Slaughter & Hunting',
      categoryAr: 'فقه المعاملات',
      categoryEn: 'Dietary Laws',
      summaryAr:
          'الأصل في الأطعمة، الحلال والحرام من الحيوانات والطيور والبحريات، شروط الذكاة الشرعية، ذبائح أهل الكتاب، وأحكام الصيد بالآلات والجوارح المعلمة.',
      summaryEn:
          'Permissibility in foods, Halal and prohibited animal consumption, criteria of Halal slaughter (Dhakah), meat of People of the Book, and hunting guidelines.',
      readTimeMinutes: 9,
      bookStartPage: 411,
      bookEndPage: 429,
      bookStartPageEn: 411,
      bookEndPageEn: 429,
    ),
    FiqhChapter(
      id: 15,
      number: 15,
      titleAr: 'كتاب القضاء والشهادات',
      titleEn: 'Book of Judiciary & Testimony (Kitab al-Qada)',
      categoryAr: 'القضاء والجنايات',
      categoryEn: 'Judiciary & Testimony',
      summaryAr:
          'مشروعية القضاء وشروط القاضي، آداب الحكم والقضاء، طرق إثبات الحقوق، الدعاوى والبينات، وشروط قبول الشهادة واليمين.',
      summaryEn:
          'The judicial institution in Islam, qualifications and ethics of judges, burden of proof, admissibility of witnesses, evidentiary oaths, and legal declarations.',
      readTimeMinutes: 7,
      bookStartPage: 430,
      bookEndPage: 439,
      bookStartPageEn: 430,
      bookEndPageEn: 439,
    ),
  ];

  static FiqhChapter? getChapterById(int id) {
    try {
      return chapters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<String> get categoriesAr => [
        'الكل',
        'فقه العبادات',
        'فقه المعاملات',
        'فقه الأسرة',
        'القضاء والجنايات',
        'أصول وقواعد',
      ];

  static List<String> get categoriesEn => [
        'All',
        'Worship Jurisprudence',
        'Commercial Jurisprudence',
        'Family Jurisprudence',
        'Penal Law & Judiciary',
        'Principles & Methodology',
      ];
}
