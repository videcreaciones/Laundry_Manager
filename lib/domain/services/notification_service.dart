import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
  }

  static Future<void> scheduleReminder({
    required String garmentId,
    required String garmentName,
    required int daysFromNow,
  }) async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(days: daysFromNow));

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      garmentId.hashCode,
      'Recordatorio de lavado',
      'Es hora de lavar: $garmentName',
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
