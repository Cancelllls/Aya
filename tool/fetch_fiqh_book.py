import urllib.request
import json
import re
import time
import os
import gzip
from concurrent.futures import ThreadPoolExecutor, as_completed

def clean_html(raw_html):
    if not raw_html:
        return ""
    # Remove anchor tags and copy buttons
    text = re.sub(r'<span[^>]*class=[\"\']anchor[\"\'][^>]*>.*?</span>', '', raw_html, flags=re.DOTALL)
    text = re.sub(r'<a[^>]*class=[\"\']btn_tag[^>]*>.*?</a>', '', text, flags=re.DOTALL)
    text = re.sub(r'<span[^>]*class=[\"\']c\d+[\"\']>(.*?)</span>', r'\1', text, flags=re.DOTALL)
    text = re.sub(r'<p[^>]*>', '\n\n', text)
    text = re.sub(r'</p>', '', text)
    text = re.sub(r'<br\s*/?>', '\n', text)
    text = re.sub(r'<[^>]+>', '', text)
    # Unescape HTML entities
    text = text.replace('&nbsp;', ' ').replace('&quot;', '"').replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
    # Remove Shamela volume/page stamps like [ص: ١٢٣] or [جـ ١ ص ٢]
    text = re.sub(r'\[\s*(?:ص|جـ|ج)\s*:[^\]]*\]', '', text)
    # Remove footnote markers like (١), (2), [١], [1], (*), etc.
    text = re.sub(r'\([٠-٩\d]+\)', '', text)
    text = re.sub(r'\[[٠-٩\d]+\]', '', text)
    text = re.sub(r'\(\s*\*\s*\)', '', text)
    text = re.sub(r'\[\s*\*\s*\]', '', text)
    # Unwrap editorial brackets around words: [كلمة] -> كلمة
    text = re.sub(r'\[\s*([^\]]*?)\s*\]', r'\1', text)
    # Remove empty brackets [] or ()
    text = re.sub(r'\[\s*\]', '', text)
    text = re.sub(r'\(\s*\)', '', text)
    # Clean multiple spaces on same line
    text = re.sub(r'[ \t]+', ' ', text)
    # Clean up excessive newlines
    lines = [line.strip() for line in text.split('\n')]
    cleaned_lines = []
    prev_empty = False
    for line in lines:
        if not line or line in ['[]', '()', '*', '(*)', '[*]']:
            if not prev_empty:
                cleaned_lines.append('')
                prev_empty = True
        else:
            cleaned_lines.append(line)
            prev_empty = False
    return '\n'.join(cleaned_lines).strip()

def fetch_single_page(book_id, page_id, max_retries=3):
    url = f"https://shamela.ws/ajax/pageContent/{book_id}/{page_id}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                title = (data.get('title') or '').strip()
                page_num = data.get('pageNum', page_id)
                nass = clean_html(data.get('nass', ''))
                return {
                    'pageId': page_id,
                    'pageNum': page_num if page_num and page_num > 0 else page_id,
                    'title': title,
                    'text': nass
                }
        except Exception as e:
            if attempt == max_retries - 1:
                print(f"Failed page {page_id} of book {book_id} after {max_retries} attempts: {e}")
                return {
                    'pageId': page_id,
                    'pageNum': page_id,
                    'title': '',
                    'text': ''
                }
            time.sleep(1.0 * (attempt + 1))

def fetch_fiqh_book():
    book_id = 22726
    total_pages = 439
    title_ar = "الفقه الميسر في ضوء الكتاب والسنة"
    title_en = "Al-Fiqh Al-Muyassar (Simplified Islamic Jurisprudence)"
    author_ar = "نخبة من العلماء"
    author_en = "A Committee of Scholars"
    output_gz_path = "assets/books/fiqh_muyassar.json.gz"
    
    print(f"Starting download for {title_ar} ({total_pages} pages)...")
    pages_dict = {}
    
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(fetch_single_page, book_id, pid): pid for pid in range(1, total_pages + 1)}
        completed = 0
        for future in as_completed(futures):
            res = future.result()
            pages_dict[res['pageId']] = res
            completed += 1
            if completed % 50 == 0 or completed == total_pages:
                print(f"[{title_ar}] Downloaded {completed}/{total_pages} pages ({(completed/total_pages)*100:.1f}%)")
    
    # Sort pages sequentially and renumber display pageNum sequentially
    sorted_pages = []
    for pid in range(1, total_pages + 1):
        p = pages_dict.get(pid, {'pageId': pid, 'pageNum': pid, 'title': '', 'text': ''})
        p['pageNum'] = pid
        sorted_pages.append(p)
    
    # Group into chapters based on titles
    chapters = []
    current_chapter = None
    
    for page in sorted_pages:
        title = page['title']
        if title and (current_chapter is None or title != current_chapter['title']):
            if current_chapter is not None:
                chapters.append(current_chapter)
            current_chapter = {
                'chapterIndex': len(chapters) + 1,
                'title': title,
                'startPage': page['pageNum'],
                'endPage': page['pageNum'],
                'pages': [page]
            }
        elif current_chapter is not None:
            current_chapter['endPage'] = page['pageNum']
            current_chapter['pages'].append(page)
        else:
            current_chapter = {
                'chapterIndex': 1,
                'title': 'المقدمة',
                'startPage': page['pageNum'],
                'endPage': page['pageNum'],
                'pages': [page]
            }
            
    if current_chapter is not None:
        chapters.append(current_chapter)
        
    book_data = {
        'bookId': 'fiqh_muyassar',
        'titleAr': title_ar,
        'titleEn': title_en,
        'authorAr': author_ar,
        'authorEn': author_en,
        'totalPages': total_pages,
        'totalChapters': len(chapters),
        'chapters': chapters
    }
    
    os.makedirs(os.path.dirname(output_gz_path), exist_ok=True)
    json_bytes = json.dumps(book_data, ensure_ascii=False, indent=2).encode('utf-8')
    with gzip.open(output_gz_path, 'wb') as f:
        f.write(json_bytes)
        
    size_mb = os.path.getsize(output_gz_path) / (1024 * 1024)
    print(f"Successfully saved {title_ar} to {output_gz_path} ({size_mb:.2f} MB, {len(chapters)} chapters).")

if __name__ == '__main__':
    fetch_fiqh_book()
