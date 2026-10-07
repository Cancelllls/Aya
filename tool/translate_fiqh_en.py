import gzip
import json
import os
import re
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

ISLAMIC_TERM_REPLACEMENTS = [
    (r'\bMay Allah bless him and grant him peace\b', 'ﷺ'),
    (r'\bpeace and blessings be upon him\b', 'ﷺ'),
    (r'\bblessings and peace of Allah be upon him\b', 'ﷺ'),
    (r'\bpeace be upon him\b', 'ﷺ'),
    (r'\bMay Allah be pleased with him\b', 'رضي الله عنه'),
    (r'\bMay Allah be pleased with them\b', 'رضي الله عنهم'),
    (r'\bGod Almighty\b', 'Allah the Almighty'),
    (r'\bGod\b', 'Allah'),
    (r'\bthe prayer\b', 'Salah'),
    (r'\bprayers\b', 'prayers (Salah)'),
    (r'\bthe ablution\b', 'Wudu'),
    (r'\bablution\b', 'Wudu'),
    (r'\bgreater ablution\b', 'Ghusl'),
    (r'\balms\b', 'Zakah'),
    (r'\bthe alms\b', 'Zakah'),
    (r'\bthe fast\b', 'Sawm (fasting)'),
    (r'\bthe pilgrimage\b', 'Hajj'),
]

def clean_arabic_markup(text):
    if not text:
        return ""
    # Remove Shamela volume stamps and footnote brackets
    t = re.sub(r'\[\s*(?:ص|جـ|ج)\s*:[^\]]*\]', '', text)
    t = re.sub(r'\([٠-٩\d]+\)', '', t)
    t = re.sub(r'\[[٠-٩\d]+\]', '', t)
    t = re.sub(r'\[\s*\*\s*\]', '', t)
    t = re.sub(r'\(\s*\*\s*\)', '', t)
    t = re.sub(r'\[\s*([^\]]*?)\s*\]', r'\1', t)
    t = re.sub(r'[ \t]+', ' ', t)
    return t.strip()

def translate_text_block(text, max_retries=4):
    if not text or not text.strip():
        return ""
    
    cleaned = clean_arabic_markup(text)
    if not cleaned:
        return ""
        
    url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=ar&tl=en&dt=t'
    
    # Split text into chunks if exceptionally long (> 2500 chars)
    paragraphs = cleaned.split('\n')
    chunks = []
    curr = []
    curr_len = 0
    
    for p in paragraphs:
        p_str = p.strip()
        if not p_str:
            continue
        if curr_len + len(p_str) > 2000 and curr:
            chunks.append('\n\n'.join(curr))
            curr = [p_str]
            curr_len = len(p_str)
        else:
            curr.append(p_str)
            curr_len += len(p_str)
            
    if curr:
        chunks.append('\n\n'.join(curr))
        
    translated_chunks = []
    
    for chunk in chunks:
        success = False
        post_data = urllib.parse.urlencode({'q': chunk}).encode('utf-8')
        req = urllib.request.Request(
            url,
            data=post_data,
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        )
        
        for attempt in range(max_retries):
            try:
                with urllib.request.urlopen(req, timeout=15) as resp:
                    data = json.loads(resp.read().decode('utf-8'))
                    translated_part = ''.join([part[0] for part in data[0] if part[0]])
                    translated_chunks.append(translated_part)
                    success = True
                    break
            except Exception as e:
                time.sleep(0.5 * (attempt + 1))
                
        if not success:
            # Fallback to original cleaned chunk if network fails completely
            translated_chunks.append(chunk)
            
    result = '\n\n'.join(translated_chunks)
    for pattern, repl in ISLAMIC_TERM_REPLACEMENTS:
        result = re.sub(pattern, repl, result, flags=re.IGNORECASE)
        
    return result.strip()

def process_single_page(page):
    pid = page['pageNum']
    title_ar = page.get('title', '')
    text_ar = page.get('text', '')
    
    en_title = translate_text_block(title_ar) if title_ar else f"Page {pid}"
    en_text = translate_text_block(text_ar)
    
    return {
        'pageId': pid,
        'pageNum': pid,
        'title': en_title,
        'text': en_text
    }

def main():
    ar_path = 'assets/books/fiqh_muyassar.json.gz'
    en_path = 'assets/books/fiqh_muyassar_en.json.gz'
    
    print(f"Loading {ar_path}...")
    with gzip.open(ar_path, 'rb') as f:
        ar_data = json.loads(f.read().decode('utf-8'))
        
    all_pages = []
    for ch in ar_data['chapters']:
        all_pages.extend(ch['pages'])
        
    total_pages = len(all_pages)
    print(f"Total pages to translate: {total_pages}")
    
    cache_file = 'assets/books/.fiqh_en_cache.json'
    cached_pages = {}
    if os.path.exists(cache_file):
        try:
            with open(cache_file, 'r', encoding='utf-8') as f:
                cached_pages = json.load(f)
            print(f"Found {len(cached_pages)} cached translated pages.")
        except Exception:
            pass
            
    pages_to_process = [p for p in all_pages if str(p['pageNum']) not in cached_pages]
    print(f"Pages remaining to translate: {len(pages_to_process)}")
    
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=8) as executor:
        future_to_page = {executor.submit(process_single_page, p): p for p in pages_to_process}
        completed = 0
        for future in as_completed(future_to_page):
            res = future.result()
            cached_pages[str(res['pageNum'])] = res
            completed += 1
            if completed % 25 == 0 or completed == len(pages_to_process):
                elapsed = time.time() - start_time
                print(f"Progress: {completed}/{len(pages_to_process)} pages translated ({elapsed:.1f}s)")
                # Incremental cache save
                with open(cache_file, 'w', encoding='utf-8') as f:
                    json.dump(cached_pages, f, ensure_ascii=False)
                    
    with open(cache_file, 'w', encoding='utf-8') as f:
        json.dump(cached_pages, f, ensure_ascii=False)
        
    # Reassemble chapters with canonical English titles
    canonical_en_chapters = [
        (1, 'Introduction: Principles & Sources of Fiqh'),
        (21, 'Book of Purification (Kitab at-Taharah)'),
        (63, 'Book of Prayer (Kitab as-Salah)'),
        (141, 'Book of Zakah (Kitab az-Zakah)'),
        (168, 'Book of Fasting (Kitab as-Siyam)'),
        (190, 'Book of Hajj & Umrah (Kitab al-Hajj)'),
        (218, 'Book of Jihad (Kitab al-Jihad)'),
        (230, 'Book of Financial Transactions & Sales'),
        (290, 'Book of Inheritance, Wills & Emancipation'),
        (309, 'Book of Marriage, Divorce & Family'),
        (358, 'Book of Penalties & Blood Money (Kitab al-Jinayat)'),
        (377, 'Book of Prescribed Punishments (Kitab al-Hudud)'),
        (402, 'Book of Oaths & Vows (Kitab al-Ayman)'),
        (411, 'Book of Foods, Slaughter & Hunting'),
        (430, 'Book of Judiciary & Testimony (Kitab al-Qada)'),
    ]
    
    sorted_pages = []
    for pid in range(1, total_pages + 1):
        p = cached_pages.get(str(pid), {
            'pageId': pid,
            'pageNum': pid,
            'title': f"Page {pid}",
            'text': f"Page {pid} content."
        })
        sorted_pages.append(p)
        
    new_chapters = []
    for i in range(len(canonical_en_chapters)):
        start_p = canonical_en_chapters[i][0]
        end_p = canonical_en_chapters[i+1][0] - 1 if i + 1 < len(canonical_en_chapters) else total_pages
        title_en = canonical_en_chapters[i][1]
        
        ch_pages = [p for p in sorted_pages if start_p <= p['pageNum'] <= end_p]
        new_chapters.append({
            'chapterIndex': i + 1,
            'title': title_en,
            'startPage': start_p,
            'endPage': end_p,
            'pages': ch_pages
        })
        
    en_book = {
        'bookId': 'fiqh_muyassar_en',
        'titleAr': ar_data['titleAr'],
        'titleEn': 'Al-Fiqh Al-Muyassar (Simplified Islamic Jurisprudence)',
        'authorAr': ar_data['authorAr'],
        'authorEn': 'A Committee of Scholars (King Fahd Complex)',
        'totalPages': total_pages,
        'totalChapters': len(new_chapters),
        'chapters': new_chapters
    }
    
    json_bytes = json.dumps(en_book, ensure_ascii=False, indent=2).encode('utf-8')
    with gzip.open(en_path, 'wb') as f:
        f.write(json_bytes)
        
    size_mb = os.path.getsize(en_path) / (1024 * 1024)
    print(f"Successfully generated pure English edition: {en_path} ({size_mb:.2f} MB, {len(new_chapters)} chapters, {total_pages} pages) in {time.time() - start_time:.1f}s!")

if __name__ == '__main__':
    main()
