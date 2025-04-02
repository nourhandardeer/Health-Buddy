import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:graduation_project/pages/splash_screen.dart';
import 'package:graduation_project/home.dart';
import 'package:graduation_project/services/notification_service.dart';
import 'package:graduation_project/services/theme_provider.dart';
import 'package:graduation_project/pages/setting/PinVerificationPage.dart'; // Import the PIN verification page

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
      create: (context) => ThemeProvider(),
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
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black), 
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black), 
        ),
        colorScheme: const ColorScheme.light(
          background: Colors.white,
          onBackground: Colors.black,
        ),
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), 
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white), 
        ),
        colorScheme: const ColorScheme.dark(
          background: Colors.black,
          onBackground: Colors.white,
        ),
      ),

      home: const AuthCheck(), // Home check
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

        // Check if the PIN is set before navigating to HomeScreen
        return FutureBuilder<bool>(
          future: _checkIfPinSet(),
          builder: (context, pinSnapshot) {
            if (pinSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (pinSnapshot.hasData && pinSnapshot.data == true) {
              // Show PIN verification page if the PIN is set
              return  PinVerificationPage();
            }

            // If no PIN is set, navigate directly to the home screen
            return snapshot.hasData ? const HomeScreen() : const SplashScreen();
          },
        );
      },
    );
  }

  Future<bool> _checkIfPinSet() async {
    final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
    String? storedPin = await _secureStorage.read(key: 'pin');
    return storedPin != null;
  }
}
