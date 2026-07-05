import urllib.request
import json
import os
import time

base_dir = "database"
os.makedirs(base_dir, exist_ok=True)

# 1. Download Surah List
print("Downloading Surah List...")
try:
    url = "https://api.alquran.cloud/v1/surah"
    req = urllib.request.Request(url, headers={'User-Agent': 'AyaApp/1.0'})
    with urllib.request.urlopen(req) as response:
        data = response.read()
    with open(f"{base_dir}/surah.json", "wb") as f:
        f.write(data)
except Exception as e:
    print("Error:", e)

tafsirs = [
    'ar.muyassar',
    'ar.jalalayn',
    'ar.qurtubi',
    'ar.miqbas',
    'ar.waseet',
    'ar.baghawi'
]

# 2. Download Surah Details
print("Downloading Surah Details (684 files)...")
for surah in range(1, 115):
    surah_dir = f"{base_dir}/surah/{surah}/editions"
    os.makedirs(surah_dir, exist_ok=True)
    
    for tafsir in tafsirs:
        editions = f"quran-uthmani,en.sahih,{tafsir}"
        file_path = f"{surah_dir}/{editions}.json"
        
        if os.path.exists(file_path):
            continue
            
        url = f"https://api.alquran.cloud/v1/surah/{surah}/editions/{editions}"
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'AyaApp/1.0'})
            with urllib.request.urlopen(req) as response:
                data = response.read()
            with open(file_path, "wb") as f:
                f.write(data)
            time.sleep(0.05) # Prevent rate limiting
        except Exception as e:
            print(f"Error on Surah {surah}, Tafsir {tafsir}: {e}")

print("Done downloading AlQuran Cloud data.")
