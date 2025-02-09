import 'package:flutter/material.dart';
import 'package:graduation_project/pages/loggin.dart';
import 'package:graduation_project/pages/sign_in.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.brown.shade100,

      body: Center(
          // Center the entire column
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Image.asset('assets/logo.png', width: 200, height: 200), // Logo

            SizedBox(height: 30), // Spacing

            ElevatedButton(
              onPressed: () {
                // Navigate to Sign In Page
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignInScreen()));
              },
              child: Text("Sign In"),
            ),

            SizedBox(height: 20), // Spacing

            ElevatedButton(
              onPressed: () {
                // Navigate to Login Page
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
