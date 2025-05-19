import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();

  static bool _isInitialized = false;
  static const String _prefsKey = "notifications_enabled";

  // ✅ Initialization
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    await _initTTS();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
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

  // ✅ Preferences Logic
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    bool enabled =
        prefs.getBool(_prefsKey) ?? true; // Default to true if not set
    print(
        "Notifications Enabled: $enabled"); // Debugging line to print the state
    return enabled;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
      print("🔕 Notifications disabled");
    } else {
      print("🔔 Notifications enabled");
    }
  }

  // ✅ Single Notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? ttsMessage,
    bool speakImmediately = false,
  }) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

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

    if (speakImmediately && ttsMessage != null) {
      await _speakMessage(ttsMessage);
    }
  }

  // ✅ Instant Notification
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? ttsMessage,
  }) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

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
      0,
      title,
      body,
      platformDetails,
      payload: ttsMessage,
    );

    if (ttsMessage != null) {
      await _speakMessage(ttsMessage);
    }
  }

  // ✅ Repeated Notification
  static Future<void> scheduleRepeatedNotification({
    required String baseId,
    required String title,
    required String body,
    required String ttsMessage,
    required DateTime startTime,
    required int repeatCount,
    required Duration interval,
  }) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

    try {
      for (int i = 0; i < repeatCount; i++) {
        final int id = generateNotificationId(baseId, i);
        print("Generated ID: $id for base $baseId");

        final scheduledTime = startTime.add(interval * i);
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
      }
    } catch (e) {
      print("❌ Failed to schedule repeated notification: $e");
    }
  }

  static Future<void> scheduleDailyMedReminders(String uid) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

    print("🔄 Starting to schedule daily medication reminders for user: $uid");

    final medsSnapshot = await FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: uid)
        .get();
    print("📂 Medications fetched: ${medsSnapshot.docs.length}");

    final now = DateTime.now();
    final timeFormat = DateFormat.jm(); // Format for parsing "06:46 AM"

    for (final doc in medsSnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('reminderTimes')) {
        print("⚠️ Skipping '${doc.id}': No 'reminderTimes' field found.");
        continue;
      }
      final reminderTimes = data['reminderTimes'] as List<dynamic>;

      for (int i = 0; i < reminderTimes.length; i++) {
        final timeString = reminderTimes[i] as String;

        final time = timeFormat.parse(timeString);

        final medName = data['name'] ?? 'Medication Reminder';
        final docId = doc.id;
        final dosage = data['dosage'] ?? 'Dosage not specified';
        final selectedUnit = data['unit'] ?? 'Unit not specified';

        DateTime scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        print("⏰ Now: $now");
        print("⏰ Initial scheduled time: $scheduledDateTime");

        if (scheduledDateTime.isBefore(now)) {
          print(
              "⏭ Reminder time has already passed today. Scheduling for tomorrow instead.");
          scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
        }

        print("📅 Final scheduled time: $scheduledDateTime");

        await scheduleRepeatedNotification(
          baseId: "${docId}_${i + 1}",
          title: 'Time for $medName',
          body:"Time to take ${dosage} ${selectedUnit} of ${medName}",
          startTime: scheduledDateTime,
          ttsMessage: "It's time to take your medicine: please take ${dosage} ${selectedUnit} of ${medName}.",
          repeatCount: 3,
          interval: const Duration(minutes: 1),
        );
        print("🗓 Scheduling notification for '$medName'");
        print("📅 Scheduled time: $scheduledDateTime");
        print("🔔 Notification ID: ${docId}_${i + 1}");
      }
    }
  }

  // ✅ Cancel Helpers
  static int generateNotificationId(String medId, int index) {
    return "$medId\_$index".hashCode.abs() % 100000;
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelRepeatedNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  static Future<void> cancelSingleReminderNotifications(String baseId) async {
    if (!_isInitialized) await initialize();

    try {
      final repeatCountPerReminder = 3;

      for (int j = 0; j < repeatCountPerReminder; j++) {
        int id = generateNotificationId(baseId, j);
        print("Cancelling ID: $id for base $baseId");
        await _notificationsPlugin.cancel(id);
      }

      print("✅ Cancelled notifications of $baseId");
    } catch (e) {
      print("❌ Error cancelling single reminder notifications: $e");
    }
  }
}
