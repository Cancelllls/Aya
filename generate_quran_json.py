import json
import os

surahs = []
with open('database/surah.json', 'r') as f:
    data = json.load(f)
    surahs = data['data']

with open('assets/quran/surahs.json', 'w') as f:
    json.dump(surahs, f)

quran_data = []
for i in range(1, 115):
    try:
        with open(f'database/surah/{i}/editions/quran-uthmani,en.sahih,ar.muyassar.json', 'r') as f:
            data = json.load(f)
            quran_data.append(data['data'])
    except Exception as e:
        print(f"Error for {i}: {e}")

with open('assets/quran/quran_hafs.json', 'w') as f:
    json.dump(quran_data, f)
