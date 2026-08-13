class HadithBook {
  final String id;
  final String nameEn;
  final String nameAr;
  final int totalHadiths;
  final bool arabicOnly;

  const HadithBook({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.totalHadiths,
    this.arabicOnly = false,
  });
}

const List<HadithBook> hadithBooks = [
  HadithBook(
    id: 'bukhari',
    nameEn: 'Sahih al-Bukhari',
    nameAr: 'صحيح البخاري',
    totalHadiths: 7563,
  ),
  HadithBook(
    id: 'muslim',
    nameEn: 'Sahih Muslim',
    nameAr: 'صحيح مسلم',
    totalHadiths: 3033,
  ),
  HadithBook(
    id: 'abudawud',
    nameEn: 'Sunan Abu Dawud',
    nameAr: 'سنن أبي داود',
    totalHadiths: 5274,
  ),
  HadithBook(
    id: 'tirmidhi',
    nameEn: 'Jami` at-Tirmidhi',
    nameAr: 'جامع الترمذي',
    totalHadiths: 3956,
  ),
  HadithBook(
    id: 'nasai',
    nameEn: 'Sunan an-Nasa\'i',
    nameAr: 'سنن النسائي',
    totalHadiths: 5758,
  ),
  HadithBook(
    id: 'ibnmajah',
    nameEn: 'Sunan Ibn Majah',
    nameAr: 'سنن ابن ماجه',
    totalHadiths: 4341,
  ),
  HadithBook(
    id: 'malik',
    nameEn: 'Muwatta Malik',
    nameAr: 'موطأ مالك',
    totalHadiths: 1985,
  ),
  HadithBook(
    id: 'riyadussalihin',
    nameEn: 'Riyad as-Salihin',
    nameAr: 'رياض الصالحين',
    totalHadiths: 1896,
  ),

  HadithBook(
    id: 'adabalmufrad',
    nameEn: 'Al-Adab Al-Mufrad',
    nameAr: 'الأدب المفرد',
    totalHadiths: 1326,
  ),
  HadithBook(
    id: 'bulughalmaram',
    nameEn: 'Bulugh al-Maram',
    nameAr: 'بلوغ المرام',
    totalHadiths: 1767,
  ),
  HadithBook(
    id: 'mishkat',
    nameEn: 'Mishkat al-Masabih',
    nameAr: 'مشكاة المصابيح',
    totalHadiths: 4428,
  ),
  HadithBook(
    id: 'shamail',
    nameEn: 'Shama\'il Muhammadiyah',
    nameAr: 'الشمائل المحمدية',
    totalHadiths: 402,
  ),
  HadithBook(
    id: 'ahmed',
    nameEn: 'Musnad Ahmad (Arabic)',
    nameAr: 'مسند الإمام أحمد',
    totalHadiths: 26363,
    arabicOnly: true,
  ),
];
