# Ramadan Features & Islamic Events

## Scope
Add Ramadan-specific notifications (Imsak, Iftar) and Islamic holiday reminders.

## Settings (Storage keys, all `defaultValue: true`)
- `ramadan_imsak_enabled` — Enable Imsak alarm during Ramadan
- `ramadan_imsak_offset` — Minutes before Fajr (default: 0)
- `ramadan_iftar_enabled` — Enable Iftar reminder during Ramadan
- `islamic_events_enabled` — Enable Islamic holiday reminders

## Audio
| Event | Audio |
|-------|-------|
| Imsak (Suhoor) | `default_adhan` (same as adhan) |
| Iftar | `iftar_dua.mp3` (new file in res/raw/) |
| Islamic events | Standard notification channel (no custom audio) |

## Implementation

### notification_service.dart
- In `schedulePrayerAlarms`: after scheduling regular prayer alarms, check if `hijriMonth == 9`. If yes, schedule:
  - Imsak: at Fajr time minus offset, using same notification channel as adhan
  - Iftar: at Maghrib time, using `iftar_dua` sound
- IDs: Imsak = notificationId + 7000, Iftar = notificationId + 8000
- In `scheduleDailyReminders`: if `islamic_events_enabled`, schedule fixed-date reminders

### Islamic events (fixed Hijri dates)
- 1st Muharram (Islamic New Year)
- 10th Muharram (Ashura)
- 27th Rajab (Isra & Miraj)
- 15th Sha'ban (Nisf Sha'ban)
- 1st-30th Ramadan (covered by Imsak/Iftar)
- 27th Ramadan (Laylatul Qadr — special reminder)
- 1st Shawwal (Eid al-Fitr)
- 9th Dhul Hijjah (Day of Arafah)
- 10th Dhul Hijjah (Eid al-Adha)

### settings_notifications.dart
- Add Ramadan section with Imsak toggle + offset dropdown, Iftar toggle
- Add Islamic Events toggle
- All conditional on `_isRamadan` state check from Hijri calendar

## Testing
- Verify Hijri month detection works with current date
- Verify Imsak/Iftar notifications schedule correctly
- Verify Islamic event dates map to correct Gregorian dates
- Verify settings toggles work
- Verify audio playback uses correct files

## Migration
- New storage keys need no migration (defaults handle missing keys)
- `iftar_dua.mp3` must be added to `res/raw/` and bundled as asset
