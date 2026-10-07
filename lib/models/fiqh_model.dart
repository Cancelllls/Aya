class FiqhCategory {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String iconName;

  const FiqhCategory({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.iconName,
  });

  String getTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String getDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;
}

class FiqhEvidence {
  final String type; // 'quran', 'hadith', 'consensus'
  final String textAr;
  final String textEn;
  final String reference;

  const FiqhEvidence({
    required this.type,
    required this.textAr,
    required this.textEn,
    required this.reference,
  });
}

class FiqhSection {
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final List<String> bulletPointsAr;
  final List<String> bulletPointsEn;

  const FiqhSection({
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    this.bulletPointsAr = const [],
    this.bulletPointsEn = const [],
  });

  String getTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String getContent(bool isArabic) => isArabic ? contentAr : contentEn;
  List<String> getBulletPoints(bool isArabic) =>
      isArabic ? bulletPointsAr : bulletPointsEn;
}

class FiqhFaq {
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;

  const FiqhFaq({
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
  });

  String getQuestion(bool isArabic) => isArabic ? questionAr : questionEn;
  String getAnswer(bool isArabic) => isArabic ? answerAr : answerEn;
}

class FiqhTopic {
  final String id;
  final String categoryId;
  final String titleAr;
  final String titleEn;
  final String summaryAr;
  final String summaryEn;
  final int readTimeMinutes;
  final List<FiqhSection> sections;
  final List<FiqhEvidence> evidences;
  final List<FiqhFaq> faqs;
  final List<String> keywords;

  const FiqhTopic({
    required this.id,
    required this.categoryId,
    required this.titleAr,
    required this.titleEn,
    required this.summaryAr,
    required this.summaryEn,
    this.readTimeMinutes = 4,
    required this.sections,
    this.evidences = const [],
    this.faqs = const [],
    this.keywords = const [],
  });

  String getTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String getSummary(bool isArabic) => isArabic ? summaryAr : summaryEn;
}
