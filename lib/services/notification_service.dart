import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
}) async {
  print("Scheduling notification: ID=$id, Title=$title, Time=$scheduledTime");

  tz.initializeTimeZones();
  final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

  await _notificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tzScheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel_id',
        'Medication Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  print("Notification successfully scheduled at $tzScheduledTime");
}


  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
