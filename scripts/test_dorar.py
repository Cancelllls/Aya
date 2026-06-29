import requests

# Test Takhrij
r1 = requests.get('https://dorar.net/dorar_api.json?skey=إنما الأعمال بالنيات')
print("Takhrij:", r1.text[:200])

# Test Sharh (is there a sharh parameter?)
# Looking at Dorar API docs online, people often use `https://dorar.net/dorar_api.json?skey=xxx` 
# Some APIs are `https://dorar.net/dorar_api.json?skey=xxx&type=sharh`
r2 = requests.get('https://dorar.net/dorar_api.json?skey=إنما الأعمال بالنيات&type=sharh')
print("Type=sharh:", r2.text[:200])

r3 = requests.get('https://dorar.net/api/hadith?skey=إنما الأعمال بالنيات')
print("API/hadith:", r3.text[:200])
