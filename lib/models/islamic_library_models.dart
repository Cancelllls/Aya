class StorySection {
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final String? quranVerseAr;
  final String? quranVerseEn;
  final String? quranRef;

  const StorySection({
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    this.quranVerseAr,
    this.quranVerseEn,
    this.quranRef,
  });
}

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
  final List<StorySection> sections;

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
    required this.sections,
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
  final List<StorySection> sections;

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
    required this.sections,
  });
}
