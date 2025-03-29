import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'package:graduation_project/pages/splash_screen.dart';
import 'package:graduation_project/home.dart';
import 'package:graduation_project/services/notification_service.dart';
import 'package:graduation_project/services/theme_provider.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyBXfH6mUgdeFBSy3qlPHoSAA2eJGv3sELo",
            authDomain: "graduationproject-c5dba.firebaseapp.com",
            projectId: "graduationproject-c5dba",
            storageBucket: "graduationproject-c5dba.firebasestorage.app",
            messagingSenderId: "132666813360",
            appId: "1:132666813360:web:00b2bbc028c381d9360475",
            measurementId: "G-BBCMQ12SM8",
          )
        : null,
  );

  await NotificationService.initialize();
  await initializeNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider()..loadTheme(),
      child: DevicePreview(
        enabled: !kReleaseMode, // Disable in production
        builder: (context) => const MyApp(),
      ),
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

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // Keeps splash screen until Firebase loads
        }
        return snapshot.hasData ? const HomeScreen() : const SplashScreen();
      },
    );
  }
}