import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'date.dart';
import 'refillrequest.dart';

class TimesPage extends StatefulWidget {
  final String medicationName;
  final String selectedUnit;
  final String documentId;
  final String startDate;
  final String dosage;

  const TimesPage({
    Key? key,
    required this.medicationName,
    required this.selectedUnit,
    required this.documentId,
    required this.startDate,
    required this.dosage,
  }) : super(key: key);

  @override
  _TimesPageState createState() => _TimesPageState();
}

class _TimesPageState extends State<TimesPage> {
  String? selectedFrequency;
  bool showOtherOptions = false;

  final List<String> frequencyOptions = [
    "Once a day",
    "Twice a day",
    "3 times a day",
    "Once a week",
    "Specific days of the week",
    "Only as needed",
  ];

  bool _isLoading = false;

  Future<void> saveFrequency() async {
    if (selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a frequency')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('meds')
          .doc(widget.documentId)
          .update({
        'frequency': selectedFrequency,
        'isAsNeeded': selectedFrequency == "Only as needed",
        'timestamp': FieldValue.serverTimestamp(),
        'startDate': 'Saturday',
      });

      if (mounted) {
        // Only as needed ➡ RefillRequest
        if (selectedFrequency == "Only as needed") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RefillRequest(
                medicationName: widget.medicationName,
                selectedUnit: widget.selectedUnit,
                selectedFrequency: selectedFrequency!,
                reminderTime: "As Needed",
                documentId: widget.documentId,
              ),
            ),
          );
        }

        // Specific days or recurring ➡ DatePage
        else if (selectedFrequency == "Specific days of the week") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DatePage(
                medicationName: widget.medicationName,
                selectedUnit: widget.selectedUnit,
                selectedFrequency: selectedFrequency!,
                documentId: widget.documentId,
                dosage: widget.dosage,
              ),
            ),
          );
        }

        // باقي التكرارات ➡ DatePage
        else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DatePage(
                medicationName: widget.medicationName,
                selectedUnit: widget.selectedUnit,
                selectedFrequency: selectedFrequency!,
                documentId: widget.documentId,
                dosage: widget.dosage,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving frequency: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleOtherOptions() {
    setState(() {
      showOtherOptions = !showOtherOptions;
      selectedFrequency = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Select Frequency",
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How often do you take this medication?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ...frequencyOptions.map((frequency) {
                    return RadioListTile<String>(
                      title: Text(frequency),
                      value: frequency,
                      groupValue: selectedFrequency,
                      onChanged: (value) {
                        if (value == "Other") {
                          _toggleOtherOptions();
                        } else {
                          setState(() {
                            selectedFrequency = value;
                            showOtherOptions = false;
                          });
                        }
                      },
                    );
                  }).toList(),
                  if (showOtherOptions) ...[
                    const Divider(),
                    const Text(
                      "Other Options",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // ...otherOptions.map((option) {
                    //   return ListTile(
                    //     title: Text(option),
                    //     trailing: selectedFrequency == option
                    //         ? const Icon(Icons.check_circle, color: Colors.blue)
                    //         : null,
                    //     onTap: () {
                    //       // لما يدوس على Every X ➡ يروح مباشرة على DatePage
                    //       if (option == "Every X days" ||
                    //           option == "Every X weeks" ||
                    //           option == "Every X months") {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (context) => DatePage(
                    //               medicationName: widget.medicationName,
                    //               selectedUnit: widget.selectedUnit,
                    //               selectedFrequency: option,
                    //               documentId: widget.documentId,
                    //             ),
                    //           ),
                    //         );
                    //       }

                    // Specific days of the week ➡ يروح مباشرة على DatePage
                    // else if (option == "Specific days of the week") {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => DatePage(
                    //         medicationName: widget.medicationName,
                    //         selectedUnit: widget.selectedUnit,
                    //         selectedFrequency: option,
                    //         documentId: widget.documentId,
                    //       ),
                    //     ),
                    //   );
                    // }

                    //       else {
                    //         setState(() {
                    //           selectedFrequency = option;
                    //           showOtherOptions = false;
                    //         });
                    //       }
                    //     },
                    //   );
                    // }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : selectedFrequency != null
                  ? saveFrequency
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
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
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  "Next",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
