import 'package:flutter/material.dart';
import 'package:graduation_project/home.dart';

class SignUpScreen extends StatelessWidget {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Create an Account',
                style: TextStyle(fontSize: 29, color: Colors.blue.shade900)),
            Text('Sign Up',
                style: TextStyle(fontSize: 19, color: Colors.blue.shade900)),
            Image.asset('assets/logo.png', width: 200, height: 200), // Logo
            
            // First Name Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
              child: TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(fontSize: 18, color: Colors.black),
                  hintText: 'Enter your first name',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),

            // Last Name Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
              child: TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(fontSize: 18, color: Colors.black),
                  hintText: 'Enter your last name',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),

            // Email Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(fontSize: 18, color: Colors.black),
                  hintText: 'Please enter your email address',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),

            // Password Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
              child: TextField(
                controller: passwordController,
                obscureText: true, // Hide password input
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(fontSize: 18, color: Colors.black38),
                  hintText: 'Enter your Password',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),

            SizedBox(height: 10),

            // Sign Up Button
            ElevatedButton(
              onPressed: () {
                String firstName = firstNameController.text;
                String lastName = lastNameController.text;
                String email = emailController.text;
                String password = passwordController.text;
                
                print('First Name: $firstName');
                print('Last Name: $lastName');
                print('Email: $email');
                print('Password: $password');
                
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                padding: EdgeInsets.symmetric(horizontal: 120, vertical: 10),
                textStyle: TextStyle(fontSize: 15, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Sign Up", style: TextStyle(color: Colors.white)),
            ),

            SizedBox(height: 10),

            // Navigate to Login
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Go back to LoginScreen
              },
              child: Text(
                "Already have an account? Login",
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
