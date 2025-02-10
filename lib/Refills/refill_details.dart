import 'package:flutter/material.dart';

class RefillDetails extends StatefulWidget {
  const RefillDetails({super.key, required Map<String, String> person});

  @override
  _RefillDetailsState createState() => _RefillDetailsState();
}

class _RefillDetailsState extends State<RefillDetails> {
  int _currentInventory = 29; // Default inventory count
  int _reminderAmount = 10; // Default reminder amount
  bool _reminderOn = true; // Toggle switch for reminders

  // Function to show the bottom sheet
  void _showAddPackageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddPillOption(10),
              _buildAddPillOption(20),
              _buildAddPillOption(30),
              _buildAddPillOption(40),
              _buildAddPillOption(50),
              const Divider(),
              ListTile(
                title: const Text("Custom amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onTap: _showCustomAmountDialog,
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to add a fixed number of pills
  Widget _buildAddPillOption(int pills) {
    return ListTile(
      title: Text("Add $pills pills", style: const TextStyle(fontSize: 16)),
      onTap: () {
        setState(() {
          _currentInventory += pills;
        });
        Navigator.pop(context); // Close bottom sheet
      },
    );
  }

  // Function to show a dialog for custom input
  void _showCustomAmountDialog() {
    Navigator.pop(context); // Close bottom sheet
    TextEditingController _customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter custom amount"),
          content: TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter number of pills"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                int? newPills = int.tryParse(_customController.text);
                if (newPills != null && newPills > 0) {
                  setState(() {
                    _currentInventory += newPills;
                  });
                  Navigator.pop(context); // Close dialog
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
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
        title: const Text("Refills"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "Vitamin C",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Subtitle
            const Text(
              "Set up the current supply of your medication and get reminders to refill.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Current Inventory Dropdown
            const Text(
              "Current Inventory",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
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
            ),
            const SizedBox(height: 16),

            // "+ Add new package" Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showAddPackageSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                child: const Text("+ Add new package"),
              ),
            ),
            const SizedBox(height: 24),

            // Reminder Switch
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

            // "Remind me at" Dropdown (SEPARATE FROM INVENTORY)
            const Text(
              "Remind me at",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _reminderAmount, // DIFFERENT VALUE
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
            ),
            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Logic to save the settings
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
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
