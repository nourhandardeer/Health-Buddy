import 'package:flutter/material.dart';
import 'date.dart';

class TimesPage extends StatefulWidget {
  @override
  _TimesPageState createState() => _TimesPageState();
}

class _TimesPageState extends State<TimesPage> {
  String? selectedFrequency;
  final Map<String, String> customDetails = {};

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
  ];

  bool showMoreOptions = false;

  void _askForDetails(String frequency) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter details for $frequency"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter details (e.g., every 3 days)"
            ),
            keyboardType: TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  customDetails[frequency] = controller.text;
                  selectedFrequency = "$frequency - ${controller.text}";
                });
                Navigator.pop(context);
              },
              child: Text("OK"),
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
                          customDetails.containsKey(frequency)
                              ? "$frequency - ${customDetails[frequency]}"
                              : frequency,
                          style: const TextStyle(fontSize: 16),
                        ),
                        value: customDetails.containsKey(frequency)
                            ? "$frequency - ${customDetails[frequency]}"
                            : frequency,
                        groupValue: selectedFrequency,
                        onChanged: (value) {
                          if (value == "specific days of the week" ||
                              value == "Every x days" ||
                              value == "Every x weeks" ||
                              value == "Every x months") {
                            _askForDetails(value!);
                          } else {
                            setState(() {
                              selectedFrequency = value;
                            });
                          }
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
