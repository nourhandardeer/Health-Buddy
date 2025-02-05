import 'package:flutter/material.dart';
import 'date.dart';

class TimesPage extends StatefulWidget {
  @override
  _TimesPageState createState() => _TimesPageState();
}

class _TimesPageState extends State<TimesPage> {
  String? selectedFrequency; 

  final List<String> commonFrequencies = [
    "Once a day",
    "Twice a day",
  ]; 

  final List<String> additionalFrequencies = [
    "specific days of the week",
    "Every x days",
    "Every x weeks",
    "Every x months",
    "on demand"
  ]; // Additional frequency options

  bool showMoreOptions = false; // Controls visibility of additional options

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How often do you take this med?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ...commonFrequencies.map((frequency) {
                    return RadioListTile<String>(
                      title: Text(
                        frequency,
                        style: const TextStyle(fontSize: 16),
                      ),
                      value: frequency,
                      groupValue: selectedFrequency,
                      onChanged: (value) {
                        setState(() {
                          selectedFrequency = value;
                        });
                      },
                    );
                  }).toList(),
                  ListTile(
                    title: const Text(
                      "I need more options",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    trailing: Icon(
                      showMoreOptions
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.blue,
                    ),
                    onTap: () {
                      setState(() {
                        showMoreOptions = !showMoreOptions;
                      });
                    },
                  ),
                  if (showMoreOptions)
                    ...additionalFrequencies.map((frequency) {
                      return RadioListTile<String>(
                        title: Text(
                          frequency,
                          style: const TextStyle(fontSize: 16),
                        ),
                        value: frequency,
                        groupValue: selectedFrequency,
                        onChanged: (value) {
                          setState(() {
                            selectedFrequency = value;
                          });
                        },
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (selectedFrequency != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DatePage(selectedFrequency: selectedFrequency!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please select a frequency before proceeding',
                    style: TextStyle(fontSize: 16),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Next",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
// "specific days of the week",
//     "Every x days",
//     "Every x weeks",
//     "Every x months",
//     "on demand"
