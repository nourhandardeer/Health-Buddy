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
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User not logged in'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  String uid = user.uid;

  try {
    // Save medication for the current user
    DocumentReference docRef = await _firestore.collection('meds').add({
      'name': medicationController.text,
      'unit': selectedUnit,
      'userId': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    String docId = docRef.id; // Capture the document ID

    /// ---------------- Step 1: Save for Emergency Contacts ----------------
    QuerySnapshot emergencyContactsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('emergencyContacts')
        .get();

    List<String> emergencyContacts = emergencyContactsSnapshot.docs
        .map((doc) => doc['phone'] as String)
        .toList();

    // Query users who match the emergency contacts (batch query for efficiency)
    if (emergencyContacts.isNotEmpty) {
      QuerySnapshot emergencyUsersSnapshot = await _firestore
          .collection('users')
          .where('phone', whereIn: emergencyContacts)
          .get();

      for (var emergencyUserDoc in emergencyUsersSnapshot.docs) {
        String emergencyUserId = emergencyUserDoc.id;

        if (emergencyUserId != uid) {
          await _firestore.collection('meds').add({
            'name': medicationController.text,
            'unit': selectedUnit,
            'userId': emergencyUserId,
            'linkedFrom': uid, // Tracks the original user
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }

  // Step 2: Reverse Check (Save for the Original User)
QuerySnapshot reverseEmergencyContactsSnapshot = await _firestore
    .collection('users')
    .where('phone', isEqualTo: user.phoneNumber) // Find the current user by phone
    .get();

for (var reverseDoc in reverseEmergencyContactsSnapshot.docs) {
  String originalUserId = reverseDoc.id; // This is the original user (A)

  // Prevent adding the same medication twice for the current user
  if (originalUserId == uid) {
    continue; // Skip if the current user is the same as the reverse lookup user
  }

  // Fetch A's emergency contacts subcollection
  QuerySnapshot originalUserEmergencyContacts = await _firestore
      .collection('users')
      .doc(originalUserId)
      .collection('emergencyContacts')
      .where('phone', isEqualTo: user.phoneNumber) // Check if B is an emergency contact of A
      .get();

  if (originalUserEmergencyContacts.docs.isNotEmpty) {
    await _firestore.collection('meds').add({
      'name': medicationController.text,
      'unit': selectedUnit,
      'userId': originalUserId, // Save for the original user (A)
      'linkedFrom': uid, // Tracks the emergency contact (B) who added it
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}



    // Navigate to TimesPage after saving
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimesPage(
          medicationName: medicationController.text,
          selectedUnit: selectedUnit!,
          documentId: docId,
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
