import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
void main() {
  tz.initializeTimeZones();
  print(tz.getLocation('Africa/Cairo'));
}
