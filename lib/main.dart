import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:graduation_project/pages/splash_screen.dart';

void main() {
  runApp(  DevicePreview(
      enabled: true, // Set to false in production
      builder: (context) => MyApp(), // Your main app widget
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
      home: SplashScreen(),
      // initialRoute: 'home',mjjj
      
   
    );
  }
}



 





 