import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project/pages/splash_screen.dart';
import 'package:graduation_project/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBXfH6mUgdeFBSy3qlPHoSAA2eJGv3sELo",
            authDomain: "graduationproject-c5dba.firebaseapp.com",
            projectId: "graduationproject-c5dba",
            storageBucket: "graduationproject-c5dba.firebasestorage.app",
            messagingSenderId: "132666813360",
            appId: "1:132666813360:web:00b2bbc028c381d9360475",
            measurementId: "G-BBCMQ12SM8"));
  } else {
    await Firebase.initializeApp();
  }

  
  await initializeNotifications();

  runApp(
    DevicePreview(
      enabled: true, // Set to false in production
      builder: (context) => MyApp(),
    ),
  );
}


Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

 
  showTestNotification();
}


Future<void> showTestNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channel_id',
    'Test Channel',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Hello!',
    'This is a test notification',
    platformDetails,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomeScreen(); 
        } else {
          return SplashScreen(); 
        }
      },
    );
  }
}
