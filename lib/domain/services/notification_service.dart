import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundry_manager/domain/value_objects/wash_reminder.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales. No conoce nada de navegacion/UI a
/// proposito (mantiene la capa de dominio libre de go_router) — quien
/// quiera reaccionar a que se toco una notificacion escucha
/// [NotificationService.tappedGarmentId].
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Se actualiza con el id de la prenda cuando el usuario toca una
  /// notificacion de recordatorio (app en foreground/background).
  static final ValueNotifier<String?> tappedGarmentId = ValueNotifier(null);

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          tappedGarmentId.value = payload;
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Si la app se abrio directamente al tocar una notificacion (estaba
  /// cerrada), devuelve el id de la prenda de esa notificacion.
  static Future<String?> consumeLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  static Future<void> scheduleReminder({
    required String garmentId,
    required String garmentName,
    required WashReminder reminder,
  }) async {
    final scheduledDate =
        tz.TZDateTime.from(reminder.nextOccurrence(), tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _notificationId(garmentId),
      'Recordatorio de lavado',
      'Es hora de lavar: $garmentName',
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Inexacto: no requiere el permiso especial de alarmas exactas de
      // Android 12+, tolera algunos minutos de margen — de sobra para un
      // recordatorio de lavado.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: reminder.type == WashReminderType.monthlyOnDay
          ? DateTimeComponents.dayOfMonthAndTime
          : null,
      payload: garmentId,
    );
  }

  static Future<void> cancelReminder(String garmentId) async {
    await _plugin.cancel(_notificationId(garmentId));
  }

  static int _notificationId(String garmentId) => garmentId.hashCode;
}
