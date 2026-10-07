class ProphetStory {
  final int id;
  final String nameAr;
  final String nameEn;
  final String titleAr;
  final String titleEn;
  final int quranMentions;
  final List<String> keySurahs;
  final String periodAr;
  final String periodEn;
  final String summaryAr;
  final String summaryEn;
  final int? bookStartPage;
  final int? bookEndPage;
  final int? bookStartPageEn;
  final int? bookEndPageEn;

  const ProphetStory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.titleAr,
    required this.titleEn,
    required this.quranMentions,
    required this.keySurahs,
    required this.periodAr,
    required this.periodEn,
    required this.summaryAr,
    required this.summaryEn,
    this.bookStartPage,
    this.bookEndPage,
    this.bookStartPageEn,
    this.bookEndPageEn,
  });
}

class SirahChapter {
  final int id;
  final int number;
  final String periodAr;
  final String periodEn;
  final String yearAr;
  final String yearEn;
  final String titleAr;
  final String titleEn;
  final String summaryAr;
  final String summaryEn;
  final int readTimeMinutes;
  final int? bookStartPage;
  final int? bookEndPage;
  final int? bookStartPageEn;
  final int? bookEndPageEn;

  const SirahChapter({
    required this.id,
    required this.number,
    required this.periodAr,
    required this.periodEn,
    required this.yearAr,
    required this.yearEn,
    required this.titleAr,
    required this.titleEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.readTimeMinutes,
    this.bookStartPage,
    this.bookEndPage,
    this.bookStartPageEn,
    this.bookEndPageEn,
  });
}

class FiqhChapter {
  final int id;
  final int number;
  final String titleAr;
  final String titleEn;
  final String categoryAr;
  final String categoryEn;
  final String summaryAr;
  final String summaryEn;
  final int readTimeMinutes;
  final int bookStartPage;
  final int bookEndPage;
  final int? bookStartPageEn;
  final int? bookEndPageEn;

  const FiqhChapter({
    required this.id,
    required this.number,
    required this.titleAr,
    required this.titleEn,
    required this.categoryAr,
    required this.categoryEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.readTimeMinutes,
    required this.bookStartPage,
    required this.bookEndPage,
    this.bookStartPageEn,
    this.bookEndPageEn,
  });
}
