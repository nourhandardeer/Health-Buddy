import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  late Timer _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Start fade-in animation
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Navigate to home after 3 seconds
    _navigationTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer.cancel(); // Prevent timer from firing after dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.brown.shade100, // Change background color if needed
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2), // Smooth fade-in effect
          opacity: _opacity,
          child: Image.asset(
            'images/logo.png',
            width: 200,
            height: 200,
          ), // Logo image
        ),
      ),
    );
  }
}
