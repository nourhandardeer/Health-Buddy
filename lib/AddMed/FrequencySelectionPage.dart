import 'package:flutter/material.dart';

class FrequencySelectionPage extends StatefulWidget {
  final String initialFrequency;
  final Function(String) onSave;

  const FrequencySelectionPage({Key? key, required this.initialFrequency, required this.onSave})
      : super(key: key);

  @override
  _FrequencySelectionPageState createState() => _FrequencySelectionPageState();
}

class _FrequencySelectionPageState extends State<FrequencySelectionPage> {
  String selectedFrequency = "";

  @override
  void initState() {
    super.initState();
    selectedFrequency = widget.initialFrequency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Frequency",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOption("Daily, X times a day"),
            _buildOption("Interval"),
            _buildOption("Specific days of the week"),
            _buildOption("Cyclic mode"),
            _buildOption("On demand (no reminder needed)"),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            widget.onSave(selectedFrequency);
            Navigator.pop(context);
          },
          child: const Text("Confirm"),
        ),
      ),
    );
  }

  Widget _buildOption(String value) {
    return ListTile(
      title: Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedFrequency,
        onChanged: (String? newValue) {
          setState(() {
            selectedFrequency = newValue!;
          });
        },
      ),
    );
  }
}
