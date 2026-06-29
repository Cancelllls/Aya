with open('lib/services/notification_service.dart', 'r') as f:
    text = f.read()

# Replace duplicated alarmClock: true
text = text.replace('                  alarmClock: true,\n                  alarmClock: true,', '                  alarmClock: true,')

# Wait, the other ones had indentation mess up
#                       exact: true,
#                   wakeup: true,
#                   alarmClock: true,
# Let's fix the indentation
text = text.replace('                  wakeup: true,\n                  alarmClock: true,', '                      wakeup: true,\n                      alarmClock: true,')

with open('lib/services/notification_service.dart', 'w') as f:
    f.write(text)

print("Fixed formatting.")
