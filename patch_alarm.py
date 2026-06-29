import re

with open('lib/services/notification_service.dart', 'r') as f:
    text = f.read()

# Replace exactAllowWhileIdle with alarmClock
text = text.replace('AndroidScheduleMode.exactAllowWhileIdle', 'AndroidScheduleMode.alarmClock')

# For AndroidAlarmManager.oneShotAt, we need to add alarmClock: true
# It looks like:
#                   exact: true,
#                   wakeup: true,
# Let's replace that with:
#                   exact: true,
#                   wakeup: true,
#                   alarmClock: true,
text = text.replace('                  exact: true,\n                  wakeup: true,', '                  exact: true,\n                  wakeup: true,\n                  alarmClock: true,')

# Wait, check if there are others that might not have exact indentation
text = re.sub(r'exact:\s*true,\s*wakeup:\s*true,', r'exact: true,\n                  wakeup: true,\n                  alarmClock: true,', text)

with open('lib/services/notification_service.dart', 'w') as f:
    f.write(text)

print("Patched alarms.")
