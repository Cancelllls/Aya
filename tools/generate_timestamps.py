#!/usr/bin/env python3
"""Fast Python script to fetch remaining QDC timestamps using ThreadPoolExecutor."""

import json, os, sys, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.request import urlopen
from urllib.error import URLError

BASE = "https://api.qurancdn.com/api/qdc/audio/reciters"
OUT = "assets/timestamps"

# Only reciters that don't already have 114 files
RECITERS = {
    10: "ar.ayyoub",
    11: "ar.hudhaify",
    8: "ar.minshawimujawwad",
    9: "ar.minshawi",
}

def count_existing(reciter):
    d = os.path.join(OUT, reciter)
    if not os.path.isdir(d):
        return 0
    return len([f for f in os.listdir(d) if f.endswith('.json')])

def fetch_one(qdc_id, reciter, surah):
    out_file = os.path.join(OUT, reciter, f"{surah}.json")
    os.makedirs(os.path.dirname(out_file), exist_ok=True)

    url = f"{BASE}/{qdc_id}/audio_files?chapter={surah}&segments=true"
    try:
        resp = urlopen(url, timeout=15)
        data = json.loads(resp.read().decode())
        af = data.get("audio_files", [])
        if not af:
            return surah, "no audio_files"

        timings = af[0].get("verse_timings", [])
        if not timings:
            return surah, "no timings"

        out = {}
        if af[0].get("audio_url"):
            out["audio_url"] = af[0]["audio_url"]
        for t in timings:
            ayah = t["verse_key"].split(":")[1]
            out[ayah] = [t["timestamp_from"], t["timestamp_to"]]

        with open(out_file, "w") as f:
            json.dump(out, f)
        return surah, f"ok ({len(timings)} ayahs)"
    except URLError as e:
        return surah, f"error: {e}"
    except Exception as e:
        return surah, f"error: {e}"

total = 0
for reciter in RECITERS.values():
    existing = count_existing(reciter)
    remaining = 114 - existing
    total += remaining
    print(f"[{reciter}] {existing}/114 done, {remaining} to fetch")

print(f"\n{total} files to fetch with 8 workers...\n")

start = time.time()
with ThreadPoolExecutor(max_workers=8) as pool:
    futures = {}
    for qdc_id, reciter in RECITERS.items():
        existing = count_existing(reciter)
        for surah in range(1, 115):
            out_file = os.path.join(OUT, reciter, f"{surah}.json")
            if os.path.exists(out_file):
                continue
            futures[pool.submit(fetch_one, qdc_id, reciter, surah)] = (reciter, surah)

    done = 0
    for fut in as_completed(futures):
        reciter, surah = futures.pop(fut)
        surah, status = fut.result()
        done += 1
        if done % 20 == 0:
            print(f"  [{done/total*100:.0f}%] {done}/{total}")
        elif "error" in status:
            print(f"  [{reciter}] surah {surah}: {status}")

elapsed = time.time() - start
print(f"\nDone in {elapsed:.0f}s!")
for reciter in RECITERS.values():
    print(f"  {reciter}: {count_existing(reciter)}/114")
