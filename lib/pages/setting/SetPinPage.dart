import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SetPinPage extends StatefulWidget {
  @override
  _SetPinPageState createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final TextEditingController _pinController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinSet();
  }

  Future<void> _checkIfPinSet() async {
    String? storedPin = await _secureStorage.read(key: 'pin');
    setState(() {
      _isPinSet = storedPin != null;
    });
  }

  Future<void> _setPin() async {
    String pin = _pinController.text;

    if (pin.length == 4) {
      await _secureStorage.write(key: 'pin', value: pin);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN set successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN must be 4 digits!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter a 4-digit PIN'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setPin,
              child: Text('Set PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
