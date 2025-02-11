import 'package:flutter/material.dart';
import 'package:graduation_project/home.dart'; // Import HomeScreen

class RefillDetails extends StatefulWidget {
  const RefillDetails({super.key});

  @override
  _RefillDetailsState createState() => _RefillDetailsState();
}

class _RefillDetailsState extends State<RefillDetails> {
  int _currentInventory = 29; // Default inventory count
  int _reminderAmount = 10; // Default reminder amount
  bool _reminderOn = true; // Toggle switch for reminders

  void _saveSettings() {
    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Settings saved successfully!"),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to HomeScreen with index 0 (Home tab selected)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false, // Removes all previous screens from the stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Refill Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.person["name"] ?? "No Name",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.person["time"] ?? "No Time",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              widget.person["pills"] ?? "No Pills Info",
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 16),

            const Text(
              "Current Inventory",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _currentInventory,
              isExpanded: true,
              underline: const SizedBox(),
              items: List.generate(100, (index) => index + 1)
                  .map((value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text("$value pills"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _currentInventory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Remind me to refill",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _reminderOn,
                  onChanged: (value) {
                    setState(() {
                      _reminderOn = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              "Remind me at",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _reminderAmount,
              isExpanded: true,
              underline: const SizedBox(),
              items: List.generate(100, (index) => index + 1)
                  .map((value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text("$value pills"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _reminderAmount = value!;
                });
              },
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
