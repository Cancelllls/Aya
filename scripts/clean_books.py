#!/usr/bin/env python3
import gzip
import json
import re
import html

def clean_english_book():
    path = 'assets/books/qisas_al_anbiya_en.json.gz'
    with gzip.open(path, 'rt', encoding='utf-8') as f:
        data = json.load(f)

    # Corrupted Basmalah regex: anything from start of string/line up to 'Prophet [A-Z]'
    # containing typical OCR garbage words
    basmalah_regex = re.compile(
        r'^(?:[^\w\s]*\s*(?:With\s+|V¥\\?it\\?\s*)?[A-Za-z\W\d]*?(?:Allah|Adah|AUafi|khftiful|MwcjAj|Mwcitu|WeneJftyf|Merdfiif|Redeemer)[^\n]*?)(?=Prophet\s+[A-Z])',
        re.IGNORECASE
    )

    cleaned_basmalah = 0
    cleaned_watermarks = 0

    for ch in data['chapters']:
        for p in ch['pages']:
            t = p['text']
            # 1. Unescape HTML entities (&amp; -> &, etc.)
            t = html.unescape(t)

            # 2. Fix page 1 missing initial 'S'
            if p['pageNum'] == 1 and t.startswith('tories of the Prophet'):
                t = 'S' + t

            # 3. Clean corrupted Basmalah before 'Prophet '
            if basmalah_regex.search(t):
                cleaned_basmalah += 1
                t = basmalah_regex.sub('In the Name of Allah, the Most Beneficent, the Most Merciful\n\n', t)

            # 4. Remove website watermark stamps (handles .com, .CQm, etc.)
            if 'islambasics' in t.lower():
                cleaned_watermarks += 1
                t = re.sub(r'\s*www\.islambasics\.[a-zA-Z0-9]+\s*$', '', t, flags=re.IGNORECASE)

            p['text'] = t

    print(f'[EN] Cleaned {cleaned_basmalah} corrupted Basmalah headers.')
    print(f'[EN] Cleaned {cleaned_watermarks} website watermarks.')

    # Verify no remnants
    for ch in data['chapters']:
        for p in ch['pages']:
            t = p['text']
            if 'islambasics' in t:
                print(f'[EN WARNING] Watermark remaining in P.{p["pageNum"]}')
            if '&amp;' in t:
                print(f'[EN WARNING] &amp; remaining in P.{p["pageNum"]}')
            if any(w in t[:80] for w in ['V¥', '=^J', 'flecte', 'BGtw', 'Merdfiif', 'WeneJftyf', 'SottGfoctctf']):
                print(f'[EN WARNING] OCR artifact in P.{p["pageNum"]}: {repr(t[:60])}')

    with gzip.open(path, 'wt', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)
    print(f'[EN] Successfully wrote cleaned data to {path}.')


def is_footnote_line(line):
    l = line.strip()
    if not l:
        return False
    # Signature marks alone
    cleaned = re.sub(r'[\(\[\"\'\s]*[م\d\s\-]*\d*[\s\-]*قص[صـَ]+ الانبياء[\s\d\-]*[\)\]\"\'\s]*', '', l).strip()
    if not cleaned:
        return True
    
    variance_words = [
        'المطبوعة', 'المطيوعة', 'المظبوعة',
        'سقطت من', 'سقط من',
        'لَيست فِي', 'ليست في',
        'تحريف', 'تَحْرِيف',
        'صَوَابه من', 'صوابه من',
        'ميزَان الِاعْتِدَال',
        'ذيل تذكرة الْحفاظ',
        'تَارِيخ الادب الْعَرَبِيّ لبروكلمان',
    ]
    if any(w in l for w in variance_words):
        return True
    
    if re.match(r'^(?:[اطبج]\s*:|من\s+[اطبج]|\([اطبج]\))', l):
        return True
    
    # Standalone bottom citation like "سورة الأنبياء 77"
    if re.match(r'^سُ?ورَة\s+[\u0621-\u064A\s]+\d+(?:\s*[-–]\s*\d+)?(?:\s+سُ?ورَة\s+[\u0621-\u064A\s]+\d+)*\.?$', l):
        return True
    
    # Standalone bottom reference like "ص 22 من هذا الجزء"
    if re.match(r'^ص\s+\d+\s+من\s+هذا\s+الْ?جُ?زْ?ء\.?$', l):
        return True

    return False


def clean_arabic_book():
    path = 'assets/books/qisas_al_anbiya.json.gz'
    with gzip.open(path, 'rt', encoding='utf-8') as f:
        data = json.load(f)

    signature_regex = re.compile(r'[\(\[\"\'\s]*[م\d\s\-]*\d*[\s\-]*قص[صـَ]+ الانبياء[\s\d\-]*[\)\]\"\'\s]*')
    
    cleaned_signatures = 0
    cleaned_footnotes = 0

    for ch in data['chapters']:
        for p in ch['pages']:
            t = p['text']

            # 1. Remove inline signature marks
            if signature_regex.search(t):
                cleaned_signatures += len(signature_regex.findall(t))
                t = signature_regex.sub(' ', t)

            # 2. Strip trailing footnote lines
            lines = t.split('\n')
            idx = len(lines) - 1
            while idx >= 0:
                l = lines[idx].strip()
                if not l:
                    idx -= 1
                    continue
                if is_footnote_line(l):
                    cleaned_footnotes += 1
                    idx -= 1
                else:
                    break

            t = '\n'.join(lines[:idx + 1]).strip()
            # Collapse any double spaces introduced by signature removal
            t = re.sub(r'[ \t]{2,}', ' ', t)
            p['text'] = t

    print(f'[AR] Cleaned {cleaned_signatures} print signatures.')
    print(f'[AR] Cleaned {cleaned_footnotes} bottom footnote lines.')

    with gzip.open(path, 'wt', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)
    print(f'[AR] Successfully wrote cleaned data to {path}.')


if __name__ == '__main__':
    clean_english_book()
    clean_arabic_book()
