import urllib.request
import json

url = "https://www.mp3quran.net/api/v3/reciters?language=ar"
req = urllib.request.Request(url)
with urllib.request.urlopen(req) as response:
    data = json.loads(response.read().decode())

rewayat = {
    'warsh': 'ورش',
    'qaloon': 'قالون',
    'shuba': 'شعبة',
    'duri': 'الدوري',
    'susi': 'السوسي',
    'bazzi': 'البزي',
    'qunbul': 'قنبل',
    'hisham': 'هشام',
    'ibn-dhakwan': 'ابن ذكوان'
}

found = {}

# Prefer Husary (حفص, ورش, قالون, الدوري) if possible
for reciter in data['reciters']:
    if 'الحصري' in reciter['name']:
        for moshaf in reciter['moshaf']:
            for k, v in rewayat.items():
                if v in moshaf['name'] and k not in found:
                    found[k] = moshaf['server']

for reciter in data['reciters']:
    for moshaf in reciter['moshaf']:
        for k, v in rewayat.items():
            if v in moshaf['name'] and k not in found:
                found[k] = moshaf['server']

for k, v in found.items():
    print(f"      case '{k}': return '{v}$surahPadded.mp3';")

