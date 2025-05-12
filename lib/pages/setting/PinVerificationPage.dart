import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_buddy/NavigationBar/home_page.dart';
import 'package:health_buddy/home.dart';

class PinVerificationPage extends StatefulWidget {
  @override
  _PinVerificationPageState createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  final TextEditingController _pinController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool _isLoading = false;

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    String? storedPin = await _secureStorage.read(key: 'pin');
    String enteredPin = _pinController.text;

    if (storedPin != null && storedPin == enteredPin) {
      // If PIN matches, navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // Show error message if PIN doesn't match
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect PIN, please try again.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter your PIN'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyPin,
                    child: Text('Verify PIN'),
                  ),
          ],
        ),
      ),
    );
  }
}
