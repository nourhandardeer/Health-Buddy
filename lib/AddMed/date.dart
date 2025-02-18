import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'refillrequest.dart';

class DatePage extends StatefulWidget {
  final String medicationName;
  final String selectedUnit;
  final String selectedFrequency;
  final String documentId; // Receive document ID

  const DatePage({
    Key? key,
    required this.medicationName,
    required this.selectedUnit,
    required this.selectedFrequency,
    required this.documentId,
  }) : super(key: key);

  @override
  _DatePageState createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  int selectedHour = 8;
  int selectedMinute = 0;
  bool isAM = true;

  Future<void> saveReminderTime() async {
    String formattedTime = "${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} ${isAM ? 'AM' : 'PM'}";

    try {
      await FirebaseFirestore.instance.collection('medications').doc(widget.documentId).update({
        'reminderTime': formattedTime,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RefillRequest(
              medicationName: widget.medicationName,
              selectedUnit: widget.selectedUnit,
              selectedFrequency: widget.selectedFrequency,
              reminderTime: formattedTime,
              documentId: widget.documentId, // Pass document ID
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving time: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Reminder Time"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "When would you like to be reminded?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Time Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: selectedHour - 1),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        selectedHour = (index ) % 23 == 0 ? 24 : (index ) % 23;
                      });
                    },
                    children: List<Widget>.generate(23, (int index) => Center(child: Text((index).toString().padLeft(2, '0')))),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(":", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),

                // Minutes Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: selectedMinute ~/ 5),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        selectedMinute = index * 5;
                      });
                    },
                    children: List<Widget>.generate(12, (int index) => Center(child: Text((index * 5).toString().padLeft(2, '0')))),
                  ),
                ),
                const SizedBox(width: 8),

                // AM/PM Selector
                
              ],
            ),
          ],
        ),
      ),

      // Save & Next Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: saveReminderTime, // Save time and navigate
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Next",
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
