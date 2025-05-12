import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_buddy/auth.dart';
import 'package:health_buddy/pages/loggin.dart';
import 'package:health_buddy/pages/profile_setup.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,10}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      String firstName = firstNameController.text.trim();
      String lastName = lastNameController.text.trim();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      String phone = phoneController.text.trim();

      String? errorMsg = await Auth().createUserWithEmailAndPassword(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );

      if (errorMsg == null) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await checkAndLinkEmergencyContact(user); // optional if needed
          _onSignupSuccess(user.uid, firstName, lastName, phone);
        }
      } else {
        setState(() {
          errorMessage = errorMsg;
        });
      }

    } catch (e) {
      print("Registration error: $e"); // Add this
      setState(() {
        errorMessage = "An unexpected error occurred.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });

  }
  }

  void _onSignupSuccess(
      String userId, String firstName, String lastName, String phone) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupPage(
          userId: userId,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        ),
      ),
    );
  }

  Future<void> checkAndLinkEmergencyContact(User user) async {
    try {
      DocumentSnapshot contactDoc = await FirebaseFirestore.instance
          .collection('emergencyContacts')
          .doc(user.phoneNumber)
          .get();

      if (contactDoc.exists) {
        String patientId = contactDoc['linkedPatientId'];
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'linkedPatientId': patientId,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error checking emergency contact linkage: \$e");
    }
  }
  Future<void> _checkIfEmailVerified() async {
    try {
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      // Re-sign in the user
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Save to Firestore
        await Auth().saveUserToFirestore(
          uid: refreshedUser.uid,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: refreshedUser.email!,
          phone: phoneController.text.trim(),
        );

        // Link emergency contact if applicable
        await checkAndLinkEmergencyContact(refreshedUser);

        // Proceed to the next screen
        _onSignupSuccess(
          refreshedUser.uid,
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          phoneController.text.trim(),
        );
      } else {
        setState(() {
          errorMessage = "Email not verified yet. Please check again.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Login failed. Please try again.";
      });
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred.";
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Create an Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Sign Up',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.blue.shade900)),
                  const SizedBox(height: 16),
                  Image.asset('images/logo2.jpeg', width: 200, height: 200),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    firstNameController,
                    'First Name',
                    'Enter your first name',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  _buildTextFormField(
                    lastNameController,
                    'Last Name',
                    'Enter your last name',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  _buildTextFormField(
                    emailController,
                    'Email',
                    'Enter your email',
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextFormField(
                    passwordController,
                    'Password',
                    'Enter your password',
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  _buildTextFormField(
                    phoneController,
                    'Phone',
                    'Enter your phone number',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  if (errorMessage != null && errorMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Sign Up",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
              // Navigate to Login Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}


