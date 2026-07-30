#!/usr/bin/env python3
"""
Extract hadith sharh (explanations) from OpenITI classical Arabic texts
and merge with existing Dorar cache for the Aya Islamic app.

Sources:
  - Fath al-Bari (Ibn Hajar) → Sahih al-Bukhari
  - Sharh al-Nawawi (Minhaj) → Sahih Muslim

Output: sharh_cache.json — per-hadith grading + explanation
  Merges with existing Dorar data (if present), keeping Dorar's
  concise summaries where available and adding classical sharh.

Usage:
  python3 extract_sharh.py [--download] [--parse] [--merge]

First run:
  python3 extract_sharh.py --download --parse --merge
"""

import json
import os
import re
import sys
import time
import gzip
import argparse
import urllib.request
from pathlib import Path
from collections import defaultdict

# ── Configuration ────────────────────────────────────────────────

DATA_DIR = Path("sharh_data")
OUTPUT_FILE = "sharh_cache.json"
AYA_ASSETS = "../assets/hadith"

OPENITI_BASE = "https://raw.githubusercontent.com/OpenITI/RELEASE/master/data"

BOOKS = {
    "bukhari": {
        "sharh_name": "Fath al-Bari",
        "sharh_author": "Ibn Hajar al-Asqalani",
        "sharh_author_ar": "ابن حجر العسقلاني",
        "url": f"{OPENITI_BASE}/0852IbnHajarCasqalani/0852IbnHajarCasqalani.FathBari/0852IbnHajarCasqalani.FathBari.JK000166-ara1",
        "local_file": "fath_al_bari.txt",
        "hadith_file": f"{AYA_ASSETS}/ara-bukhari.json",
        "book_display": "Sahih al-Bukhari / صحيح البخاري",
        # Pattern to detect hadith entries
        # In Fath Bari: "# N " where N is the hadith number, followed by explanation
        # Sub-sections use "# | N (" for detailed commentary
    },
    "muslim": {
        "sharh_name": "Sharh al-Nawawi",
        "sharh_author": "Imam al-Nawawi",
        "sharh_author_ar": "الإمام النووي",
        "url": f"{OPENITI_BASE}/0676Nawawi/0676Nawawi.MinhajFiSharhMuslim/0676Nawawi.MinhajFiSharhMuslim.JK000137-ara1",
        "local_file": "sharh_nawawi_muslim.txt",
        "hadith_file": f"{AYA_ASSETS}/ara-muslim.json",
        "book_display": "Sahih Muslim / صحيح مسلم",
    },
}

HEADERS = {
    "User-Agent": "AyaApp/1.0 (Islamic Research; https://github.com/Cancelllls/Aya)",
    "Accept": "*/*",
}


# ── Download Phase ───────────────────────────────────────────────

def download_file(url: str, dest: Path, max_retries: int = 3) -> bool:
    """Download a file with retry logic."""
    if dest.exists():
        size_mb = dest.stat().st_size / (1024 * 1024)
        print(f"  ✓ Already downloaded ({size_mb:.1f} MB)")
        return True

    for attempt in range(max_retries):
        try:
            print(f"  Downloading ({dest.name})... ", end="", flush=True)
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = resp.read()
                dest.write_bytes(data)
                size_mb = len(data) / (1024 * 1024)
                print(f"{size_mb:.1f} MB")
                return True
        except Exception as e:
            print(f"failed: {e}")
            if attempt < max_retries - 1:
                wait = 2 ** attempt * 5
                print(f"  Retrying in {wait}s...")
                time.sleep(wait)
    return False


def parse_fath_bari(text: str) -> dict[int, str]:
    """
    Parse Fath al-Bari into {hadith_number: explanation_text}.

    Fath al-Bari structure:
      # قال البخاري ...  (intro explaining Bukhari's chapter titles)
      # 1 قوله حدثنا ...  (Hadith 1: "his saying: haddathana...")
          ... explanation paragraphs ...
          # | 1 ( ... )    (sub-commentary on a phrase)
          ... more explanation ...
      # 2 الحديث الثاني ... (Hadith 2)
          ... etc.

    We extract all text between "# N" and the next "# N+1",
    excluding "# |" sub-section markers (which are part of hadith N).
    """
    results = {}
    lines = text.split('\n')

    # Skip META headers
    start_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('#META#Header#End#'):
            start_idx = i + 1
            break

    # Find all hadith section starts
    # Pattern: "# N " or "# N قوله" at the start of a section
    hadith_starts = []  # [(line_idx, hadith_number)]
    for i in range(start_idx, len(lines)):
        line = lines[i]
        m = re.match(r'^# (\d+)\s', line)
        if m:
            hadith_num = int(m.group(1))
            # Skip very large numbers (likely page refs, not hadith numbers)
            if hadith_num < 20000:
                hadith_starts.append((i, hadith_num))

    print(f"  Found {len(hadith_starts)} hadith markers")

    if not hadith_starts:
        return results

    # Extract text for each hadith
    for idx, (line_idx, hadith_num) in enumerate(hadith_starts):
        # Next hadith start (or end of file)
        if idx + 1 < len(hadith_starts):
            next_line_idx = hadith_starts[idx + 1][0]
        else:
            # Last hadith - go until we hit 1000 lines or end
            next_line_idx = min(line_idx + 2000, len(lines))

        # Collect all explanation lines for this hadith
        explanation_lines = []
        for j in range(line_idx + 1, next_line_idx):
            line = lines[j]
            # Skip META, skip page breaks
            if line.startswith('#META#') or line.startswith('~~'):
                continue
            # Skip next hadith section
            if re.match(r'^# \d+\s', line):
                break
            # Include sub-section content (# | markers)
            if line.startswith('# '):
                # Keep the sub-heading but strip the marker
                line = line[2:]
            explanation_lines.append(line)

        # Clean and join
        explanation = '\n'.join(explanation_lines)
        explanation = re.sub(r'\n{3,}', '\n\n', explanation).strip()

        if len(explanation) > 100:
            results[hadith_num] = explanation

    return results


def parse_sharh_nawawi(text: str) -> dict[int, str]:
    """
    Parse Sharh al-Nawawi on Muslim.
    Similar structure to Fath Bari, but may use different markers.
    """
    # Try the same structure first
    results = parse_fath_bari(text)
    if len(results) > 100:
        return results

    # Alternative: look for hadith text patterns
    # Sharh Nawawi often quotes the hadith then explains
    # We'll try the generic approach
    print("  Trying alternative parsing...")
    results = {}
    lines = text.split('\n')

    # Skip headers
    start_idx = 0
    for i, line in enumerate(lines):
        if '#META#Header#End#' in line:
            start_idx = i + 1
            break

    # Look for "باب" + "قوله" patterns
    current_hadith = None
    current_text = []

    for i in range(start_idx, len(lines)):
        line = lines[i]
        if line.startswith('#META#') or line.startswith('~~'):
            continue

        m = re.match(r'^# (\d+)\s', line)
        if m:
            num = int(m.group(1))
            if num < 20000:
                if current_hadith and current_text:
                    text = '\n'.join(current_text).strip()
                    if len(text) > 100:
                        results[current_hadith] = text
                current_hadith = num
                current_text = []
                continue

        if current_hadith is not None:
            clean = line[2:] if line.startswith('# ') else line
            current_text.append(clean)

    # Don't forget the last hadith
    if current_hadith and current_text:
        text = '\n'.join(current_text).strip()
        if len(text) > 100:
            results[current_hadith] = text

    return results


# ── Merge Phase ───────────────────────────────────────────────────

def load_existing_cache() -> dict:
    """Load existing sharh_cache.json from Dorar scraper."""
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def load_hadith_data(book_id: str) -> list[dict]:
    """Load hadiths from bundled JSON."""
    config = BOOKS[book_id]
    path = Path(config["hadith_file"])
    if not path.exists():
        print(f"  ⚠ Hadith file not found: {path}")
        return []
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get("hadiths", data.get("hadith", []))


def build_cache(book_id: str, sharh_map: dict[int, str]) -> dict:
    """
    Build sharh_cache entries for one book.
    Returns dict of {book_id:hadith_number -> cache_entry}
    """
    cache = {}
    hadiths = load_hadith_data(book_id)

    if not hadiths:
        print(f"  ⚠ No hadiths loaded for {book_id}")
        return cache

    book_config = BOOKS[book_id]
    hadith_by_num = {}
    for h in hadiths:
        num = h.get("hadithnumber", h.get("hadithNumber", h.get("number", 0)))
        text = h.get("text", h.get("arabic", ""))
        hadith_by_num[num] = text

    count_with_sharh = 0
    for num, sharh_text in sharh_map.items():
        hadith_text = hadith_by_num.get(num, "")
        if not hadith_text:
            continue

        # Truncate explanation to reasonable size for mobile
        # Classical sharh can be extremely long (pages per hadith)
        # Take first 3000 chars as key summary, store full text separately
        max_chars = 5000
        sharh_truncated = sharh_text[:max_chars]
        if len(sharh_text) > max_chars:
            sharh_truncated += f"\n\n[...المزيد في المصدر الأصلي — {len(sharh_text)} حرف]"

        key = f"{book_id}:{num}"
        cache[key] = {
            "q": _extract_query(hadith_text),
            "t": hadith_text[:500],
            "e": sharh_truncated,  # explanation from classical source
            "g": "",  # grading already known
            "_source": f"{book_config['sharh_name']} ({book_config['sharh_author_ar']})",
            "_ok": True,
        }
        count_with_sharh += 1

    total = len(hadith_by_num)
    print(f"  {book_id}: {count_with_sharh}/{total} hadiths with sharh "
          f"({100*count_with_sharh/total:.0f}%)")
    return cache


def _extract_query(text: str, max_words: int = 8) -> str:
    """Extract a search query from hadith text."""
    clean = re.sub(r'[ً-ٰ]', '', text).strip()
    words = clean.split()

    for i in range(len(words)):
        segment = ' '.join(words[i:])
        if re.search(r'سَمِعْتُ|يَقُولُ|أَنَّ.*رَسُول|عَنِ.*النَّبِيّ|قَالَ.*رَسُول|إِنَّ',
                     segment):
            return ' '.join(words[i:][:max_words])

    if len(words) > 8:
        return ' '.join(words[5:15])
    return ' '.join(words[:max_words])


def merge_with_dorar(classical_cache: dict, dorar_cache: dict) -> dict:
    """
    Merge classical sharh with Dorar cache.
    - Dorar's concise summaries take priority for 'e' (explanation) field
    - If Dorar has no explanation, use classical sharh's 'e'
    - Always keep Dorar's grading ('g') if present
    - Preserve classical _source metadata
    """
    merged = dict(dorar_cache)  # start with Dorar data

    for key, entry in classical_cache.items():
        if key not in merged or not merged[key].get('_ok'):
            # No Dorar entry — use classical directly
            merged[key] = entry
            continue

        dorar_entry = merged[key]
        classical_entry = entry

        # If Dorar has explanation, keep it (concise + modern Arabic)
        # If not, use classical explanation
        if not dorar_entry.get('e', '').strip():
            dorar_entry['e'] = classical_entry.get('e', '')
            dorar_entry['_classical_source'] = classical_entry.get('_source', '')

        # Always keep Dorar grading
        # Add classical source as enrichment
        if not dorar_entry.get('g', '').strip():
            dorar_entry['g'] = classical_entry.get('g', '')

    return merged


# ── Main Pipeline ─────────────────────────────────────────────────

def cmd_download(args):
    """Download sharh texts from OpenITI."""
    print("📥 Downloading classical sharh texts...\n")
    DATA_DIR.mkdir(exist_ok=True)

    for book_id, config in BOOKS.items():
        print(f"📖 {config['book_display']}")
        print(f"   Sharh: {config['sharh_name']} by {config['sharh_author']}")
        local = DATA_DIR / config["local_file"]
        download_file(config["url"], local)
        print()

    print("✅ Downloads complete.")


def cmd_parse(args):
    """Parse downloaded texts into per-hadith dictionaries."""
    print("📝 Parsing sharh texts...\n")

    for book_id, config in BOOKS.items():
        local = DATA_DIR / config["local_file"]
        if not local.exists():
            print(f"⚠ {config['book_display']}: file not downloaded. Run --download first.")
            continue

        print(f"📖 {config['book_display']}")
        print(f"   Parsing {config['sharh_name']} ({local.stat().st_size / 1024 / 1024:.1f} MB)...")

        text = local.read_text(encoding='utf-8')

        if book_id == "bukhari":
            sharh_map = parse_fath_bari(text)
        else:
            sharh_map = parse_sharh_nawawi(text)

        # Save intermediate parsed output
        out_file = DATA_DIR / f"{book_id}_parsed.json"
        with open(out_file, 'w', encoding='utf-8') as f:
            # Convert int keys to str for JSON
            json.dump({str(k): v for k, v in sharh_map.items()}, f,
                      ensure_ascii=False, indent=2)

        total_hadiths = len(sharh_map)
        avg_len = sum(len(v) for v in sharh_map.values()) / max(total_hadiths, 1)
        print(f"   ✓ {total_hadiths} hadiths parsed, avg {avg_len:.0f} chars each")
        print()

    print("✅ Parsing complete.")


def cmd_merge(args):
    """Merge parsed sharh with existing Dorar cache."""
    print("🔀 Merging classical sharh with existing cache...\n")

    dorar_cache = load_existing_cache()
    print(f"📦 Existing Dorar cache: {len(dorar_cache)} entries")

    all_classical = {}
    for book_id in BOOKS:
        parsed_file = DATA_DIR / f"{book_id}_parsed.json"
        if not parsed_file.exists():
            print(f"⚠ {book_id}: no parsed data. Run --parse first.")
            continue

        with open(parsed_file, 'r', encoding='utf-8') as f:
            sharh_map_raw = json.load(f)

        # Convert str keys back to int
        sharh_map = {int(k): v for k, v in sharh_map_raw.items()}

        print(f"📖 {book_id}: {len(sharh_map)} parsed entries → building cache...")
        classical_cache = build_cache(book_id, sharh_map)
        all_classical.update(classical_cache)

    print(f"\n🕌 Classical sharh: {len(all_classical)} total entries")

    # Merge
    merged = merge_with_dorar(all_classical, dorar_cache)

    # Stats
    with_sharh = sum(1 for v in merged.values() if v.get('e', '').strip())
    with_grading = sum(1 for v in merged.values() if v.get('g', '').strip())
    classical_count = sum(1 for v in merged.values()
                          if v.get('_classical_source', ''))
    dorar_count = sum(1 for v in merged.values()
                      if v.get('_classical_source', '') == '' and v.get('_ok'))

    print(f"  With explanation (sharh): {with_sharh}")
    print(f"  With grading: {with_grading}")
    print(f"  From classical sources: {classical_count}")
    print(f"  From Dorar: {dorar_count}")

    # Save
    out_path = OUTPUT_FILE
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    size_mb = os.path.getsize(out_path) / (1024 * 1024)
    print(f"\n💾 Saved: {out_path} ({size_mb:.1f} MB)")
    print("✅ Merge complete.")


def cmd_status(args):
    """Show current status."""
    print("📊 Sharh Cache Status\n")

    # Downloads
    print("Downloads:")
    for book_id, config in BOOKS.items():
        local = DATA_DIR / config["local_file"]
        status = f"✓ {local.stat().st_size / 1024 / 1024:.1f} MB" if local.exists() else "✗ not downloaded"
        print(f"  {book_id}: {status}")

    print()

    # Parsed
    print("Parsed:")
    for book_id in BOOKS:
        parsed = DATA_DIR / f"{book_id}_parsed.json"
        if parsed.exists():
            with open(parsed, 'r', encoding='utf-8') as f:
                data = json.load(f)
            print(f"  {book_id}: ✓ {len(data)} hadiths")
        else:
            print(f"  {book_id}: ✗ not parsed")

    print()

    # Final cache
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
            cache = json.load(f)
        size_kb = os.path.getsize(OUTPUT_FILE) / 1024
        books = defaultdict(int)
        for key in cache:
            parts = key.split(':')
            if len(parts) == 2:
                books[parts[0]] += 1
        print(f"Cache ({OUTPUT_FILE}): {len(cache)} entries, {size_kb:.0f} KB")
        for book, count in sorted(books.items()):
            print(f"  {book}: {count}")
    else:
        print(f"Cache ({OUTPUT_FILE}): not yet created")


def main():
    parser = argparse.ArgumentParser(
        description="Extract classical hadith sharh from OpenITI corpus"
    )
    parser.add_argument("--download", action="store_true",
                        help="Download sharh texts from OpenITI")
    parser.add_argument("--parse", action="store_true",
                        help="Parse downloaded texts into per-hadith dicts")
    parser.add_argument("--merge", action="store_true",
                        help="Merge with existing Dorar cache")
    parser.add_argument("--all", action="store_true",
                        help="Run download + parse + merge")
    parser.add_argument("--status", action="store_true",
                        help="Show current status")

    args = parser.parse_args()

    if args.status:
        return cmd_status(args)

    if args.all:
        args.download = args.parse = args.merge = True

    if not any([args.download, args.parse, args.merge]):
        parser.print_help()
        print("\nTip: use --all to run the full pipeline")
        return

    start = time.time()

    if args.download:
        cmd_download(args)

    if args.parse:
        cmd_parse(args)

    if args.merge:
        cmd_merge(args)

    elapsed = time.time() - start
    print(f"\n⏱ Total time: {elapsed:.0f}s")


if __name__ == "__main__":
    main()
