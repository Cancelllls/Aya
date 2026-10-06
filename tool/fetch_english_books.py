import urllib.request
import urllib.parse
import zipfile
import io
import re
import json
import gzip
import os

def clean_english_text(text):
    if not text:
        return ""
    # Remove HTML tags if any remain
    text = re.sub(r'<[^>]+>', ' ', text)
    # Fix common OCR artifacts for Basmalah
    text = re.sub(
        r'^[=^J\s\d\\pbi~`!\^]*With\s+[A-Za-z\s\'’\^\.\-]+\s+(?:Redeemer|flecte&amp;a|flectesm|Rsde&amp;a|flecte&am|Rsde&a|flecte|Rsde)\s*',
        'In the Name of Allah, the Most Gracious, the Most Merciful.\n\n',
        text,
        flags=re.IGNORECASE
    )
    # Replace broken peace-be-upon-him OCR symbols
    text = text.replace('fL*j -m^ M J^.', 'ﷺ')
    text = text.replace('fL*j -m^', 'ﷺ')
    text = text.replace('(Peace be upon him)', 'ﷺ')
    text = text.replace('(peace be upon him)', 'ﷺ')
    text = text.replace('(PBUH)', 'ﷺ')
    text = text.replace('(pbuh)', 'ﷺ')
    text = text.replace('(May Allah be pleased with him)', 'رضي الله عنه')
    text = text.replace('(RA)', 'رضي الله عنه')
    
    # Clean OCR navigation headers and indices
    text = re.sub(r'»\s*Ar\s*Raheeq\s*Al\s*Mukhtum', '', text, flags=re.IGNORECASE)
    text = re.sub(r'Pre[vy]ious\s+Chapter\s+[lI]ndex\.{0,3}', '', text, flags=re.IGNORECASE)
    text = re.sub(r'Page\s+\d+\s+Next\s+Chapter\.{0,3}', '', text, flags=re.IGNORECASE)
    text = re.sub(r'Next\s+Chapter', '', text, flags=re.IGNORECASE)
    text = re.sub(r'CONTENTS:\s*', '', text, flags=re.IGNORECASE)

    # Clean OCR Basmalah gibberish before Prophet name
    text = re.sub(
        r'^[=^JV¥\\/s\d pbi~`!\^\|\.\-]+With\s+[A-Za-z\s\'’\^\.\-]+\s+(?:Redeemer|flecte&amp;rrw|flecte&amp;ffw|flecte&amp;a|flectesm|Rsde&amp;mw|Rsde&amp;a|flecte&am|Rsde&a|flecte|Rsde)\s*',
        'In the Name of Allah, the Most Gracious, the Most Merciful.\n\n',
        text,
        flags=re.IGNORECASE
    )
    text = re.sub(
        r'^[=^JV¥\\/s\d pbi~`!\^\|\.\-]+(?=Prophet\s+[A-Z])',
        'In the Name of Allah, the Most Gracious, the Most Merciful.\n\n',
        text,
        flags=re.IGNORECASE
    )
    
    # Clean bracket artifacts
    text = re.sub(r'\[[٠-٩\d]+\]', '', text)
    text = re.sub(r'\([٠-٩\d]+\)', '', text)
    text = re.sub(r'\[\s*\*\s*\]', '', text)
    text = re.sub(r'\(\s*\*\s*\)', '', text)
    
    # Normalize whitespace
    text = re.sub(r'[ \t]+', ' ', text)
    lines = [l.strip() for l in text.split('\n')]
    cleaned = []
    prev_blank = False
    for l in lines:
        if not l:
            if not prev_blank:
                cleaned.append('')
                prev_blank = True
        else:
            cleaned.append(l)
            prev_blank = False
    return '\n'.join(cleaned).strip()

def process_ibn_kathir():
    item = 'pdfy-FFZIzpkiBPA9qqDp'
    filename = 'Stories of the Prophets by Ibn Kathir.epub'
    encoded_fn = urllib.parse.quote(filename)
    url = f'https://archive.org/download/{item}/{encoded_fn}'
    print(f'Fetching {url}...')
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        content = r.read()

    with zipfile.ZipFile(io.BytesIO(content)) as z:
        pages = []
        for n in z.namelist():
            m = re.match(r'EPUB/page_(\d+)\.html', n)
            if m:
                pages.append((int(m.group(1)), n))
        pages.sort()

        all_pages = []
        chapters = []
        current_chapter_title = 'Introduction'
        current_chapter_pages = []
        chapter_idx = 1
        chapter_start_page = 1

        for pnum, n in pages:
            raw = z.read(n).decode('utf-8', errors='ignore')
            # Extract paragraphs
            paras = re.findall(r'<p>(.*?)</p>', raw, re.DOTALL | re.IGNORECASE)
            clean_paras = [clean_english_text(p) for p in paras if clean_english_text(p)]
            text = '\n\n'.join(clean_paras)
            
            # Detect title from first bold/h/line or Prophet mention
            first_line = clean_paras[0] if clean_paras else ''
            page_title = ''
            if re.match(r'^(?:Prophet\s+[A-Za-z]+|Contents|Introduction)', first_line, re.IGNORECASE):
                page_title = first_line.split('\n')[0]
                if len(page_title) > 60:
                    page_title = page_title[:60]
            elif len(first_line) < 50 and not first_line.endswith('.'):
                page_title = first_line
            
            p_obj = {
                'pageId': pnum + 1,
                'pageNum': pnum + 1,
                'title': page_title,
                'text': text
            }
            all_pages.append(p_obj)
            current_chapter_pages.append(p_obj)

            if page_title.startswith('Prophet ') and current_chapter_pages:
                if len(current_chapter_pages) > 1:
                    # Close previous chapter
                    prev_pages = current_chapter_pages[:-1]
                    chapters.append({
                        'chapterIndex': chapter_idx,
                        'title': current_chapter_title,
                        'startPage': chapter_start_page,
                        'endPage': prev_pages[-1]['pageNum'],
                        'pages': prev_pages
                    })
                    chapter_idx += 1
                    chapter_start_page = p_obj['pageNum']
                    current_chapter_title = page_title
                    current_chapter_pages = [p_obj]
                else:
                    current_chapter_title = page_title

        if current_chapter_pages:
            chapters.append({
                'chapterIndex': chapter_idx,
                'title': current_chapter_title,
                'startPage': chapter_start_page,
                'endPage': current_chapter_pages[-1]['pageNum'],
                'pages': current_chapter_pages
            })

        book_data = {
            'bookId': 'qisas_al_anbiya_en',
            'titleAr': 'قصص الأنبياء (مترجم)',
            'titleEn': 'Stories of the Prophets (Ibn Kathir)',
            'authorAr': 'الحافظ ابن كثير',
            'authorEn': 'Al-Hafiz Ibn Kathir (Tr. Muhammad Mustapha)',
            'totalPages': len(all_pages),
            'totalChapters': len(chapters),
            'chapters': chapters
        }

        out_gz = 'assets/books/qisas_al_anbiya_en.json.gz'
        with gzip.open(out_gz, 'wt', encoding='utf-8') as gz:
            json.dump(book_data, gz, ensure_ascii=False)
        print(f'Successfully built {out_gz}: {os.path.getsize(out_gz)} bytes ({len(all_pages)} pages, {len(chapters)} chapters)')
        return book_data

def process_sealed_nectar():
    item = 'Ar-raheeqAl-makhtum'
    filename = 'sealed-nectar.epub'
    encoded_fn = urllib.parse.quote(filename)
    url = f'https://archive.org/download/{item}/{encoded_fn}'
    print(f'Fetching {url}...')
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        content = r.read()

    with zipfile.ZipFile(io.BytesIO(content)) as z:
        pages = []
        for n in z.namelist():
            m = re.match(r'EPUB/page_(\d+)\.html', n)
            if m:
                pages.append((int(m.group(1)), n))
        pages.sort()

        all_pages = []
        chapters = []
        current_chapter_title = 'Table of Contents'
        current_chapter_pages = []
        chapter_idx = 1
        chapter_start_page = 1

        for pnum, n in pages:
            raw = z.read(n).decode('utf-8', errors='ignore')
            paras = re.findall(r'<p>(.*?)</p>', raw, re.DOTALL | re.IGNORECASE)
            clean_paras = [clean_english_text(p) for p in paras if clean_english_text(p)]
            text = '\n\n'.join(clean_paras)
            
            first_line = clean_paras[0] if clean_paras else ''
            page_title = ''
            if len(first_line) < 60 and not first_line.endswith('.') and (first_line.isupper() or 'THE ' in first_line or 'AL-' in first_line or 'CHAPTER' in first_line.upper() or 'TRIBES' in first_line.upper()):
                page_title = first_line.strip()
            elif len(first_line) < 45 and not first_line.endswith('.'):
                page_title = first_line.strip()

            p_obj = {
                'pageId': pnum + 1,
                'pageNum': pnum + 1,
                'title': page_title,
                'text': text
            }
            all_pages.append(p_obj)
            current_chapter_pages.append(p_obj)

            if page_title and current_chapter_pages and len(current_chapter_pages) > 2:
                prev_pages = current_chapter_pages[:-1]
                chapters.append({
                    'chapterIndex': chapter_idx,
                    'title': current_chapter_title,
                    'startPage': chapter_start_page,
                    'endPage': prev_pages[-1]['pageNum'],
                    'pages': prev_pages
                })
                chapter_idx += 1
                chapter_start_page = p_obj['pageNum']
                current_chapter_title = page_title
                current_chapter_pages = [p_obj]

        if current_chapter_pages:
            chapters.append({
                'chapterIndex': chapter_idx,
                'title': current_chapter_title,
                'startPage': chapter_start_page,
                'endPage': current_chapter_pages[-1]['pageNum'],
                'pages': current_chapter_pages
            })

        book_data = {
            'bookId': 'raheeq_makhtum_en',
            'titleAr': 'الرحيق المختوم (مترجم)',
            'titleEn': 'The Sealed Nectar (Ar-Raheeq Al-Makhtum)',
            'authorAr': 'صفي الرحمن المباركفوري',
            'authorEn': 'Safi-ur-Rahman al-Mubarakpuri (Darussalam)',
            'totalPages': len(all_pages),
            'totalChapters': len(chapters),
            'chapters': chapters
        }

        out_gz = 'assets/books/raheeq_makhtum_en.json.gz'
        with gzip.open(out_gz, 'wt', encoding='utf-8') as gz:
            json.dump(book_data, gz, ensure_ascii=False)
        print(f'Successfully built {out_gz}: {os.path.getsize(out_gz)} bytes ({len(all_pages)} pages, {len(chapters)} chapters)')
        return book_data

if __name__ == '__main__':
    process_ibn_kathir()
    process_sealed_nectar()
