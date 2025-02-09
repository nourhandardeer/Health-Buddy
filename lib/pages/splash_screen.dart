import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Start fade-in animation
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navigate to home after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.brown.shade100, // Change background color if needed
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2), // Smooth fade-in effect
          opacity: _opacity,
          child: Image.asset('assets/logo.png', width: 200,height: 200,), // Logo image
        ),
      ),
    );
  }
}
