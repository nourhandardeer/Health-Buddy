import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'times.dart';
import 'date.dart';

class AddMedicationPage extends StatefulWidget {
  @override
  _AddMedicationPageState createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final TextEditingController medicationController = TextEditingController();
  String? selectedUnit;

  final List<String> units = [
    "Pills", "Ampoules", "Tablets", "Capsules", "IU", "Application", "Drop",
    "Gram", "Injection", "Milligram", "Milliliter", "MM", "Packet", "Pessary",
    "Piece", "Portion", "Puff", "Spray", "Suppository", "Teaspoon",
    "Vaginal Capsule", "Vaginal Suppository", "Vaginal Tablet", "MG"
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveMedicationData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      try {
        // Save data in the "meds" collection with an added "userId" field.
        DocumentReference docRef = await _firestore.collection('meds').add({
          'name': medicationController.text,
          'unit': selectedUnit,
          'userId': uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        String docId = docRef.id; // Capture the document ID

        // Navigate to TimesPage after saving and pass the documentId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TimesPage(
              medicationName: medicationController.text,
              selectedUnit: selectedUnit!,
              documentId: docId, // Now accepted by TimesPage
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which medication would you like to set the reminder for?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: medicationController,
              decoration: InputDecoration(
                labelText: "Medication Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Select Unit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: selectedUnit,
              hint: const Text("Choose a unit"),
              items: units
                  .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                  .toList(),
              onChanged: (value) => setState(() => selectedUnit = value),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (medicationController.text.isNotEmpty && selectedUnit != null) {
              _saveMedicationData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a medication name and select a unit'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text(
            "Next",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
