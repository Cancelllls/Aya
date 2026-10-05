import urllib.request
import json
import re
import time
import os
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
    # Clean up excessive newlines
    lines = [line.strip() for line in text.split('\n')]
    cleaned_lines = []
    prev_empty = False
    for line in lines:
        if not line:
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
                    'pageNum': page_num,
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

def fetch_full_book(book_id, total_pages, title_ar, title_en, author_ar, author_en, output_path):
    print(f"Starting download for {title_ar} ({total_pages} pages)...")
    pages_dict = {}
    
    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(fetch_single_page, book_id, pid): pid for pid in range(1, total_pages + 1)}
        completed = 0
        for future in as_completed(futures):
            res = future.result()
            pages_dict[res['pageId']] = res
            completed += 1
            if completed % 50 == 0 or completed == total_pages:
                print(f"[{title_ar}] Downloaded {completed}/{total_pages} pages ({(completed/total_pages)*100:.1f}%)")
    
    # Sort pages sequentially
    sorted_pages = [pages_dict[pid] for pid in range(1, total_pages + 1)]
    
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
        'bookId': str(book_id),
        'titleAr': title_ar,
        'titleEn': title_en,
        'authorAr': author_ar,
        'authorEn': author_en,
        'totalPages': total_pages,
        'totalChapters': len(chapters),
        'chapters': chapters
    }
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(book_data, f, ensure_ascii=False, indent=2)
        
    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"Successfully saved {title_ar} to {output_path} ({size_mb:.2f} MB, {len(chapters)} chapters).")

if __name__ == '__main__':
    # 1. Ar-Raheeq Al-Makhtum (452 pages)
    fetch_full_book(
        book_id=9820,
        total_pages=452,
        title_ar="الرحيق المختوم",
        title_en="Ar-Raheeq Al-Makhtum (The Sealed Nectar)",
        author_ar="صفي الرحمن المباركفوري",
        author_en="Safiur Rahman al-Mubarakpuri",
        output_path="assets/books/raheeq_makhtum.json"
    )
    
    # 2. Qisas al-Anbiya (888 pages)
    fetch_full_book(
        book_id=932,
        total_pages=888,
        title_ar="قصص الأنبياء",
        title_en="Stories of the Prophets",
        author_ar="ابن كثير",
        author_en="Ibn Kathir",
        output_path="assets/books/qisas_al_anbiya.json"
    )
