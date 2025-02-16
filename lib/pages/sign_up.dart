import 'package:flutter/material.dart';
import 'package:graduation_project/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/auth.dart';
import 'package:graduation_project/pages/profile_setup.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage = '';

  Future<void> _register() async {
    try {
      String firstName = firstNameController.text.trim();
      String lastName = lastNameController.text.trim();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      // Firebase Auth - Create User
      String? errorMsg = await Auth().createUserWithEmailAndPassword(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (errorMsg == null) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Save basic user details in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Navigate to Profile Setup Page
          _onSignupSuccess(user.uid, firstName, lastName);
        } else {
          setState(() {
            errorMessage = "Signup failed. Please try again.";
          });
        }
      } else {
        setState(() {
          errorMessage = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _onSignupSuccess(String userId, String firstName, String lastName) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileSetupPage(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Create an Account', style: TextStyle(fontSize: 29, color: Colors.blue.shade900)),
              Text('Sign Up', style: TextStyle(fontSize: 19, color: Colors.blue.shade900)),
              Image.asset('images/logo.png', width: 200, height: 200),

              // First Name Field
              _buildTextField(firstNameController, 'First Name', 'Enter your first name'),

              // Last Name Field
              _buildTextField(lastNameController, 'Last Name', 'Enter your last name'),

              // Email Field
              _buildTextField(emailController, 'Email', 'Enter your email', isEmail: true),

              // Password Field
              _buildTextField(passwordController, 'Password', 'Enter your password', isPassword: true),

              // Error message
              if (errorMessage != null && errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 10),

              // Sign Up Button
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 10),
                  textStyle: const TextStyle(fontSize: 15, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 10),

              // Navigate to Login Screen
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isPassword = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18, color: Colors.black),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }
}
