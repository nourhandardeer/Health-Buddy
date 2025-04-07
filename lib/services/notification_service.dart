import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();

  static bool _isInitialized = false;

  // Initialize both notifications and TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Set up TTS
    await _initTTS();

    // Set up notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print("Notification tapped! Payload: ${response.payload}");
        if (response.payload != null && response.payload!.isNotEmpty) {
          await _speakMessage(response.payload!);
        }
      },
    );

    _isInitialized = true;
  }

  static Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  static Future<void> _speakMessage(String message) async {
    try {
      if (!_isInitialized) await initialize();
      await _tts.speak(message);
    } catch (e) {
      print("Error speaking message: $e");
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? ttsMessage,
    bool speakImmediately = false,
  }) async {
    if (!_isInitialized) await initialize();

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_channel_id',
      'Medication Reminders',
      channelDescription: 'Channel for medication reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: ttsMessage,
    );

    // Speak immediately if requested (for testing or immediate reminders)
    if (speakImmediately && ttsMessage != null) {
      await _speakMessage(ttsMessage);
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? ttsMessage,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_channel_id',
      'Instant Notifications',
      channelDescription: 'Channel for instant notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0, // ID 0 for instant notifications
      title,
      body,
      platformDetails,
      payload: ttsMessage,
    );

    if (ttsMessage != null) {
      await _speakMessage(ttsMessage);
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
