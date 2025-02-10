import 'package:flutter/material.dart';
import 'package:graduation_project/pages/loggin.dart';
import 'package:graduation_project/pages/sign_up.dart';

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
            Image.asset('assets/logo.png', width: 220, height: 220), // Logo

            SizedBox(height: 80), // Spacing

          ElevatedButton(
           onPressed: () {
              // Navigate to Sign In Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),
              );
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900, 
                padding: EdgeInsets.symmetric(horizontal: 150, vertical: 5), 
                textStyle: TextStyle(fontSize: 15, color: Colors.white), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), 
                ),
              ),
              child: Text("Sign Up",style: TextStyle(color:Colors.white ),),
            ),


            SizedBox(height: 20), // Spacing

            ElevatedButton(
              onPressed: () {
                // Navigate to Login Page
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 150, vertical: 5), 
                 textStyle: TextStyle(fontSize: 15,color: Colors.white), 
                 shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12), 
                   ),
              ),
              
              child: Text("Login",style: TextStyle(color: Colors.blue.shade900),),
            ),
          ],
        ),
      ),
    );
  }
}
