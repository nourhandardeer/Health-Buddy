import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _imageOpacity = 0.0;
  Offset _imageOffset = const Offset(0, 0.2);

  double _textOpacity = 0.0;
  Offset _textOffset = const Offset(0, 0.2);

  late Timer _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Animate image first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _imageOpacity = 1.0;
          _imageOffset = Offset.zero;
        });
      }
    });

    // Animate text after image animation (2 seconds after image starts)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _textOpacity = 1.0;
          _textOffset = Offset.zero;
        });
      }
    });

    // Navigate to home after 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSlide(
              offset: _imageOffset,
              duration: const Duration(seconds: 2),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _imageOpacity,
                duration: const Duration(seconds: 2),
                child: Image.asset(
                  'images/MedTrack -logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),

            // No SizedBox here, text directly below image

            AnimatedSlide(
              offset: _textOffset,
              duration: const Duration(seconds: 2),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _textOpacity,
                duration: const Duration(seconds: 1),
                child: const Text(
                  'MedTrack',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PlayfairDisplay',
                    color: Color(0xFF3BB2E9),
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4.0,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
