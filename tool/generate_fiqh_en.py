import json
import gzip
import os

def create_english_fiqh():
    with gzip.open('assets/books/fiqh_muyassar.json.gz', 'rb') as f:
        ar_data = json.loads(f.read().decode('utf-8'))
        
    en_chapters = []
    
    chapter_translation_map = {
        'مقدمات': ('Introduction & Preliminaries', 'Introduction to Islamic Jurisprudence according to the Quran and authentic Sunnah, explaining the definition of Fiqh, its origins, sources of legislation, and the significance of studying worship rulings.'),
        'كتاب الطهارة': ('The Book of Purification (Kitab at-Taharah)', 'Comprehensive rulings on ritual purity, waters, utensils, natural disposition (Fitrah), ablution (Wudu), wiping over socks, ritual bath (Ghusl), dry ablution (Tayammum), impurities, and menstruation.'),
        'كتاب الصلاة': ('The Book of Prayer (Kitab as-Salah)', 'The conditions, pillars, obligations, sunan, and description of prayer from Takbir to Tasleem, congregational prayer, prostrations of forgetfulness, traveler prayer, Friday prayer, and funerals.'),
        'كتاب الجنائز': ('The Book of Funerals (Kitab al-Jana\'iz)', 'Rulings regarding terminal sickness, washing the deceased, shrouding, the four Takbeers of the funeral prayer, burial etiquettes, and visiting graves.'),
        'كتاب الزكاة': ('The Book of Zakah (Kitab az-Zakah)', 'Conditions of obligation, Nisab thresholds for gold, silver, currencies, livestock, agriculture, trade merchandise, Zakat al-Fitr, and the eight eligible recipient categories.'),
        'كتاب الصيام': ('The Book of Fasting (Kitab as-Siyam)', 'Rulings on the month of Ramadan, sighting the crescent, valid exemptions from fasting, nullifiers of fast, contemporary medical issues, voluntary fasts, and Itikaf.'),
        'كتاب الحج': ('The Book of Hajj (Kitab al-Hajj)', 'Pillars and obligations of Hajj and Umrah, designated Mawaqit, prohibitions of Ihram, step-by-step rituals of Tawaf and Sa\'i, sacrificial animals, and visiting the Prophet\'s Mosque in Madinah.'),
    }
    
    page_counter = 1
    for ch in ar_data['chapters']:
        ar_title = ch['title']
        
        # Match primary title keyword
        matched_en_title = None
        matched_en_desc = None
        for k, (t, d) in chapter_translation_map.items():
            if k in ar_title:
                matched_en_title = f"{t} - {ar_title}"
                matched_en_desc = d
                break
                
        if not matched_en_title:
            matched_en_title = ar_title
            matched_en_desc = f"Chapter discussing: {ar_title} in the light of the Quran and authentic Sunnah."
            
        en_pages = []
        for p in ch['pages']:
            en_pages.append({
                'pageId': page_counter,
                'pageNum': page_counter,
                'title': matched_en_title,
                'text': f"{matched_en_title}\n\n{matched_en_desc}\n\nOriginal Text Reference:\n{p['text']}"
            })
            page_counter += 1
            
        en_chapters.append({
            'chapterIndex': ch['chapterIndex'],
            'title': matched_en_title,
            'startPage': en_pages[0]['pageNum'],
            'endPage': en_pages[-1]['pageNum'],
            'pages': en_pages
        })
        
    en_book = {
        'bookId': 'fiqh_muyassar_en',
        'titleAr': ar_data['titleAr'],
        'titleEn': 'Al-Fiqh Al-Muyassar (Simplified Islamic Jurisprudence)',
        'authorAr': ar_data['authorAr'],
        'authorEn': 'A Committee of Scholars (King Fahd Complex)',
        'totalPages': page_counter - 1,
        'totalChapters': len(en_chapters),
        'chapters': en_chapters
    }
    
    output_path = 'assets/books/fiqh_muyassar_en.json.gz'
    json_bytes = json.dumps(en_book, ensure_ascii=False, indent=2).encode('utf-8')
    with gzip.open(output_path, 'wb') as f:
        f.write(json_bytes)
        
    print(f"Successfully generated {output_path} ({os.path.getsize(output_path) / (1024*1024):.2f} MB)")

if __name__ == '__main__':
    create_english_fiqh()
