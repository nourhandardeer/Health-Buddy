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
            Text('Welcome back'),
            const Text('Login'),
            Image.asset('assets/logo.png', width: 200, height: 200), // Logo
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your Password',
                border: OutlineInputBorder(),
              ),
            ),
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
                  backgroundColor: Colors.blue,
                ),
                child: Text("Login"))
          ],
        ),
      ),
    );
  }
}
