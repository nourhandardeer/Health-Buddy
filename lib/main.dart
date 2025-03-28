import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project/pages/splash_screen.dart';
import 'package:graduation_project/home.dart';
import 'package:firebase_auth/firebase_auth.dart';



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

  runApp(
    DevicePreview(
      enabled: true, 
      builder: (context) => MyApp(), 
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      home: AuthCheck(), //SplashScreen(),
      // initialRoute: 'home',m
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show loading
        }
        if (snapshot.hasData) {
          return HomeScreen(); // Redirect to dashboard if user is logged in
        } else {
          return SplashScreen(); // Redirect to login screen if no user
        }
      },
    );
  }
}
