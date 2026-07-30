#!/usr/bin/env python3
"""
Extract hadith sharh from Shamela parquet + OpenITI text files,
build final sharh_cache.json for Aya Islamic App.
"""
import json, re, os, sys
import pandas as pd

OUT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/sharh_data"
CACHE_OUT = os.path.dirname(os.path.abspath(__file__)) + "/sharh_cache.json"
ASSETS = os.path.dirname(os.path.abspath(__file__)) + "/../assets/hadith"

def load_hadiths(path):
    if not os.path.exists(path): return {}
    with open(path) as f:
        data = json.load(f)
    return {h.get('hadithnumber',0): h.get('text','') for h in data.get('hadiths', data.get('hadith',[]))}

def extract_query(text, max_words=8):
    clean = re.sub(r'[ً-ٰ]', '', text).strip()
    words = clean.split()
    for i in range(len(words)):
        segment = ' '.join(words[i:])
        if re.search(r'سَمِعْتُ|يَقُولُ|أَنَّ.*رَسُول|عَنِ.*النَّبِيّ|قَالَ.*رَسُول', segment):
            return ' '.join(words[i:][:max_words])
    if len(words) > 8: return ' '.join(words[5:15])
    return ' '.join(words[:max_words])

def build_cache_entries(book_id, parsed_data, hadith_db, source_name):
    """Build cache entries from {hadith_num: explanation_text} dict."""
    cache = {}
    for num_str, explanation in parsed_data.items():
        num = int(num_str) if isinstance(num_str, str) else num_str
        hadith_text = hadith_db.get(num, '')
        if not hadith_text: continue
        key = f"{book_id}:{num}"
        truncated = explanation[:4000]
        if len(explanation) > 4000:
            truncated += f"\n\n[...المزيد في {source_name} — {len(explanation)} حرف]"
        cache[key] = {
            'q': extract_query(hadith_text),
            't': hadith_text[:500],
            'e': truncated,
            'g': '',
            '_source': source_name,
            '_ok': True,
        }
    return cache

def extract_shamela_parsed(path):
    """Load parsed JSON from Shamela extraction."""
    if not os.path.exists(path): return {}
    with open(path) as f:
        return json.load(f)

print("📦 Loading hadith databases...")
HADITH = {
    'bukhari': load_hadiths(f"{ASSETS}/ara-bukhari.json"),
    'muslim': load_hadiths(f"{ASSETS}/ara-muslim.json"),
    'abudawud': load_hadiths(f"{ASSETS}/ara-abudawud.json"),
    'tirmidhi': load_hadiths(f"{ASSETS}/ara-tirmidhi.json"),
    'nasai': load_hadiths(f"{ASSETS}/ara-nasai.json"),
    'ibnmajah': load_hadiths(f"{ASSETS}/ara-ibnmajah.json"),
}
for k, v in HADITH.items(): print(f"  {k}: {len(v)} hadiths")

# ── Step 1: Load all parsed sources ──
print("\n📖 Loading parsed sharh data...")
cache = {}

# Bukhari: OpenITI Fath al-Bari (best quality) + Shamela supplement
if os.path.exists(f"{OUT_DIR}/bukhari_parsed.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/bukhari_parsed.json")
    entries = build_cache_entries('bukhari', data, HADITH['bukhari'],
                                   'Fath al-Bari — ابن حجر العسقلاني (OpenITI)')
    cache.update(entries)
    print(f"  Bukhari (OpenITI): {len(entries)}")

# Also merge Shamela version for missing hadiths
if os.path.exists(f"{OUT_DIR}/bukhari_parsed_shamela.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/bukhari_parsed_shamela.json")
    shamela_entries = build_cache_entries('bukhari', data, HADITH['bukhari'],
                                           'Fath al-Bari — ابن حجر العسقلاني (Shamela)')
    new = 0
    for k, v in shamela_entries.items():
        if k not in cache or not cache[k].get('e'):
            cache[k] = v; new += 1
    print(f"  Bukhari (Shamela supplement): +{new} new")

# Muslim: Merge OpenITI + Shamela Sharh al-Nawawi
if os.path.exists(f"{OUT_DIR}/muslim_parsed.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/muslim_parsed.json")
    entries = build_cache_entries('muslim', data, HADITH['muslim'],
                                   'شرح النووي — الإمام النووي (OpenITI)')
    cache.update(entries)
    print(f"  Muslim (OpenITI): {len(entries)}")

# Abu Dawud: Awn al-Ma'bud from bracket markers [رقم]
if os.path.exists(f"{OUT_DIR}/abudawud_parsed_shamela.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/abudawud_parsed_shamela.json")
    entries = build_cache_entries('abudawud', data, HADITH['abudawud'],
                                   'عون المعبود — شرف الحق العظيم آبادي (Shamela)')
    cache.update(entries)
    print(f"  Abu Dawud (Shamela numbered): {len(entries)}")
if os.path.exists(f"{OUT_DIR}/abudawud_parsed_awn.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/abudawud_parsed_awn.json")
    awn_entries = build_cache_entries('abudawud', data, HADITH['abudawud'],
                                       'عون المعبود — شرف الحق العظيم آبادي (Shamela)')
    new = 0
    for k, v in awn_entries.items():
        if k not in cache or not cache[k].get('e'):
            cache[k] = v; new += 1
    print(f"  Abu Dawud (Awn al-Ma'bud bracket): +{new} new")

# Tirmidhi: al-Urf al-Shadhi + Hashiya
if os.path.exists(f"{OUT_DIR}/tirmidhi_parsed_hash.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/tirmidhi_parsed_hash.json")
    entries = build_cache_entries('tirmidhi', data, HADITH['tirmidhi'],
                                   'العرف الشذي — محمد أنور الكشميري (Shamela)')
    cache.update(entries)
    print(f"  Tirmidhi (Shamela hash): {len(entries)}")

# Nasai: Dhakhirat al-Uqba + Hashiya
if os.path.exists(f"{OUT_DIR}/nasai_parsed_shamela.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/nasai_parsed_shamela.json")
    entries = build_cache_entries('nasai', data, HADITH['nasai'],
                                   'ذخيرة العقبى — محمد الإتيوبي (Shamela)')
    cache.update(entries)
    print(f"  Nasai (Shamela numbered): {len(entries)}")
if os.path.exists(f"{OUT_DIR}/nasai_parsed_hash.json"):
    data = extract_shamela_parsed(f"{OUT_DIR}/nasai_parsed_hash.json")
    hash_entries = build_cache_entries('nasai', data, HADITH['nasai'],
                                        'حاشية السندي على النسائي (Shamela)')
    new = 0
    for k, v in hash_entries.items():
        if k not in cache or not cache[k].get('e'):
            cache[k] = v; new += 1
    print(f"  Nasai (Hashiya supplement): +{new} new")

# ── Step 2: Merge with existing Dorar cache ──
dorar_path = f"{OUT_DIR}/../sharh_cache.json.dorar"
if os.path.exists(dorar_path):
    with open(dorar_path) as f:
        dorar = json.load(f)
    print(f"\n📦 Dorar cache: {len(dorar)} entries")
    for key, entry in cache.items():
        if key in dorar and dorar[key].get('_ok'):
            de = dorar[key]
            if not entry.get('g') and de.get('g'): entry['g'] = de['g']
            if de.get('e', '').strip():
                entry['_dorar'] = de['e'][:500]
        dorar[key] = entry
    final = dorar
else:
    final = cache

# ── Step 3: Stats & Save ──
print(f"\n💾 Writing {len(final)} entries...")
with open(CACHE_OUT, 'w', encoding='utf-8') as f:
    json.dump(final, f, ensure_ascii=False, indent=2)

size_mb = os.path.getsize(CACHE_OUT) / (1024*1024)
from collections import Counter
books = Counter()
with_sharh = 0
for key, entry in final.items():
    parts = key.split(':')
    if len(parts) == 2: books[parts[0]] += 1
    if entry.get('e', '').strip(): with_sharh += 1

print(f"  File: {CACHE_OUT} ({size_mb:.1f} MB)")
print(f"  With explanation: {with_sharh}/{len(final)}")
for book, count in books.most_common():
    sources = set()
    for key in final:
        if key.startswith(f"{book}:"):
            s = final[key].get('_source', '?')
            if s: sources.add(s)
    print(f"  {book}: {count} — {', '.join(sources)}")

print("\n✅ Done!")
