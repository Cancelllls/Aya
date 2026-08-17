import '../core/adhan_native_controller.dart';

class AlarmHealthService {
  static Future<Map<String, dynamic>> checkHealth() async {
    final alarms = await AdhanNativeController.instance.getScheduledAlarms();

    int activeCount = 0;
    int pastCount = 0;

    for (final alarm in alarms) {
      final bool isPast = alarm['isPast'] as bool? ?? false;
      if (isPast) {
        pastCount++;
        final int? id = alarm['id'] as int?;
        if (id != null) {
          await AdhanNativeController.instance.cancelAlarm(id: id);
        }
      } else {
        activeCount++;
      }
    }

    return {
      'total': alarms.length,
      'active': activeCount,
      'cleanedPast': pastCount,
      'isHealthy': activeCount >= 5,
    };
  }
}
