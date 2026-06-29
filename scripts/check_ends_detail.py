with open('lib/screens/settings_screen.dart', 'r') as f:
    lines = f.readlines()
def p(name, end):
    print(f"{name} ends near {end}:")
    for i in range(end-2, end+3):
        print(f"  {i}: {lines[i].strip()}")

p("voice_preview", 1072)
p("adhan_reciters", 1252)
p("battery_opt", 1425)
p("support", 1515)
p("app_info", 1571)
