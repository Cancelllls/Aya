import requests
import json
import os

editions = [
    'shuba',
    'duri',
    'susi',
    'bazzi',
    'qunbul',
    'hisham',
    'ibn-dhakwan'
]

os.makedirs('assets/quran', exist_ok=True)

for ed in editions:
    print(f"Downloading {ed}...")
    response = requests.get(f'http://api.alquran.cloud/v1/quran/quran-{ed}')
    if response.status_code != 200:
        print(f"Failed to fetch {ed}")
        continue
    
    data = response.json()['data']['surahs']
    out = []
    global_ayah_id = 1
    
    for surah in data:
        sura_no = surah['number']
        sura_name_en = surah['englishName']
        sura_name_ar = surah['name']
        
        for ayah in surah['ayahs']:
            out.append({
                "id": global_ayah_id,
                "jozz": ayah['juz'],
                "page": str(ayah['page']),
                "sura_no": sura_no,
                "sura_name_en": sura_name_en,
                "sura_name_ar": sura_name_ar,
                "line_start": 0,
                "line_end": 0,
                "aya_no": ayah['numberInSurah'],
                "aya_text": ayah['text']
            })
            global_ayah_id += 1
            
    with open(f'assets/quran/{ed}.json', 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=4)
    print(f"{ed}.json generated successfully.")

