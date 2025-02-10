import 'package:flutter/material.dart';
import 'package:graduation_project/home.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Welcome back',style: TextStyle(fontSize: 29,color: Colors.blue.shade900),),
            Text('Login',style: TextStyle(fontSize: 19,color: Colors.blue.shade900),),
            Image.asset('assets/logo.png', width: 200, height: 200), // Logo
       Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
  child: TextField(
    controller: emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: InputDecoration(
      labelText: 'Email',
      labelStyle: TextStyle(fontSize: 18, color: Colors.black), // Style for label
      hintText: 'Please enter your email address',
      hintStyle: TextStyle(fontSize: 16, color: Colors.grey), // Style for hint text
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        borderSide: BorderSide(color: Colors.red, width: 2), // Border color & width
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey, width: 1.5), // Default border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2.5), // Focused border
      ),
      filled: true,
      fillColor: Colors.white, // Background color
    ),
    style: TextStyle(fontSize: 18, color: Colors.black), // Text input style
  ),
),

            SizedBox(height: 20),
           Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
  child: TextField(
    controller: passwordController,
    obscureText: true, // Hide password input
    decoration: InputDecoration(
      labelText: 'Password',
      labelStyle: TextStyle(fontSize: 18, color: Colors.black), // Style for label
      hintText: 'Enter your Password',
      hintStyle: TextStyle(fontSize: 16, color: Colors.grey), // Style for hint text
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        borderSide: BorderSide(color: Colors.grey, width: 2), // Border color & width
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey, width: 1.5), // Default border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2.5), // Focused border
      ),
      filled: true,
      fillColor: Colors.white, // Background color
    ),
    style: TextStyle(fontSize: 18, color: Colors.black), // Text input style
  ),
),

            SizedBox(height: 10,),
            ElevatedButton(
                onPressed: () {
                  String email = emailController.text;
                  String password = passwordController.text;
                  print('Email:$email');
                  print('password:$password');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                    padding: EdgeInsets.symmetric(horizontal: 150, vertical: 5), 
                 textStyle: TextStyle(fontSize: 15,color: Colors.white), 
                 shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12), 
                   ),
                ),
                child: Text("Login",style: TextStyle(color: Colors.white),))
          ],
        ),
      ),
    );
  }
}
