import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/pages/EmergencyContactPage.dart';
import '../EmergencyContactHelper.dart';
import '../services/firestore_service.dart';
import 'times.dart';

class AddMedicationPage extends StatefulWidget {
  @override
  _AddMedicationPageState createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final TextEditingController medicationController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String? selectedUnit;
  int dosage = 1;

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
      const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
    );
    return;
  }
  String uid = user.uid;
  String docId = ""; // تعريف docId بدون تحديده مباشرة

  try {
    // **تحقق مما إذا كان هناك دواء بنفس الاسم لنفس المستخدم**
    QuerySnapshot existingMeds = await FirebaseFirestore.instance
        .collection('meds')
        .where('userId', isEqualTo: uid)
        .where('name', isEqualTo: medicationController.text)
        .get();

    if (existingMeds.docs.isNotEmpty) {
      docId = existingMeds.docs.first.id; // إذا كان موجودًا، استخدم نفس الـ docId
      print("⚠️ الدواء موجود بالفعل، سيتم التحديث فقط.");

      // **تحديث فقط بدون فقدان البيانات السابقة**
      await FirebaseFirestore.instance.collection('meds').doc(docId).update({
        'unit': selectedUnit,
        'dosage': dosage,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      docId = FirebaseFirestore.instance.collection('meds').doc().id; // إنشاء ID جديد إذا لم يكن موجودًا

      // **جلب emergencyUserIds و originalUserEmergencyContacts**
      QuerySnapshot emergencyContactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .get();

      List<String> emergencyContacts = emergencyContactsSnapshot.docs
          .map((doc) => doc['phone'] as String)
          .toList();

      List<String> emergencyUserIds = [];

      if (emergencyContacts.isNotEmpty) {
        QuerySnapshot emergencyUsersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', whereIn: emergencyContacts)
            .get();

        emergencyUserIds = emergencyUsersSnapshot.docs.map((doc) => doc.id).toList();
      }

      // جلب الـ originalUserEmergencyContacts
      QuerySnapshot reverseEmergencyContactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: user.phoneNumber)
          .get();

      List<String> originalUserEmergencyContacts = [];

      for (var reverseDoc in reverseEmergencyContactsSnapshot.docs) {
        String originalUserId = reverseDoc.id;
        if (originalUserId == uid) continue;

        QuerySnapshot originalUserEmergencyContactsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(originalUserId)
            .collection('emergencyContacts')
            .where('phone', isEqualTo: user.phoneNumber)
            .get();

        if (originalUserEmergencyContactsSnapshot.docs.isNotEmpty) {
          originalUserEmergencyContacts.add(originalUserId);
        }
      }

      // **حفظ البيانات في Firestore لأول مرة**
      await FirebaseFirestore.instance.collection('meds').doc(docId).set({
        'name': medicationController.text,
        'unit': selectedUnit,
        'dosage': dosage,
       // 'userId': finalUserId, // ✅ Use the correct patient ID
        'timestamp': FieldValue.serverTimestamp(),
       // 'linkedUserIds': linkedUsers,
      },
    );

    if (docId != null) {
      print("DEBUG: Medication saved with doc ID -> $docId");
      _navigateToTimesPage(docId);
    } else {
      print("Failed to retrieve document ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    print("Error saving medication: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving data: $e'), backgroundColor: Colors.red),
    );
  }
 }

  // Future<void> _saveMedicationData() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
  //     );
  //     return;
  //   }
  //
  //   String uid = user.uid;
  //   String docId = ""; // تعريف docId بدون تحديده مباشرة
  //
  //   try {
  //     // **تحقق مما إذا كان هناك دواء بنفس الاسم لنفس المستخدم**
  //     QuerySnapshot existingMeds = await FirebaseFirestore.instance
  //         .collection('meds')
  //         .where('userId', isEqualTo: uid)
  //         .where('name', isEqualTo: medicationController.text)
  //         .get();
  //
  //     if (existingMeds.docs.isNotEmpty) {
  //       docId = existingMeds.docs.first.id; // إذا كان موجودًا، استخدم نفس الـ docId
  //       print("⚠️ الدواء موجود بالفعل، سيتم التحديث فقط.");
  //
  //       // **تحديث فقط بدون فقدان البيانات السابقة**
  //       await FirebaseFirestore.instance.collection('meds').doc(docId).update({
  //         'unit': selectedUnit,
  //         'dosage': dosage,
  //         'timestamp': FieldValue.serverTimestamp(),
  //       });
  //     } else {
  //       docId = FirebaseFirestore.instance.collection('meds').doc().id; // إنشاء ID جديد إذا لم يكن موجودًا
  //
  //       // **جلب emergencyUserIds و originalUserEmergencyContacts**
  //       QuerySnapshot emergencyContactsSnapshot = await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(uid)
  //           .collection('emergencyContacts')
  //           .get();
  //
  //       List<String> emergencyContacts = emergencyContactsSnapshot.docs
  //           .map((doc) => doc['phone'] as String)
  //           .toList();
  //
  //       List<String> emergencyUserIds = [];
  //
  //       if (emergencyContacts.isNotEmpty) {
  //         QuerySnapshot emergencyUsersSnapshot = await FirebaseFirestore.instance
  //             .collection('users')
  //             .where('phone', whereIn: emergencyContacts)
  //             .get();
  //
  //         emergencyUserIds = emergencyUsersSnapshot.docs.map((doc) => doc.id).toList();
  //       }
  //
  //       // جلب الـ originalUserEmergencyContacts
  //       QuerySnapshot reverseEmergencyContactsSnapshot = await FirebaseFirestore.instance
  //           .collection('users')
  //           .where('phone', isEqualTo: user.phoneNumber)
  //           .get();
  //
  //       List<String> originalUserEmergencyContacts = [];
  //
  //       for (var reverseDoc in reverseEmergencyContactsSnapshot.docs) {
  //         String originalUserId = reverseDoc.id;
  //         if (originalUserId == uid) continue;
  //
  //         QuerySnapshot originalUserEmergencyContactsSnapshot = await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(originalUserId)
  //             .collection('emergencyContacts')
  //             .where('phone', isEqualTo: user.phoneNumber)
  //             .get();
  //
  //         if (originalUserEmergencyContactsSnapshot.docs.isNotEmpty) {
  //           originalUserEmergencyContacts.add(originalUserId);
  //         }
  //       }
  //
  //       // **حفظ البيانات في Firestore لأول مرة**
  //       await FirebaseFirestore.instance.collection('meds').doc(docId).set({
  //         'name': medicationController.text,
  //         'unit': selectedUnit,
  //         'userId': uid,
  //         'dosage': dosage,
  //         'timestamp': FieldValue.serverTimestamp(),
  //         'linkedFrom': uid,
  //         'emergencyUserIds': emergencyUserIds,
  //         'originalUserEmergencyContacts': originalUserEmergencyContacts,
  //       });
  //     }
  //
  //     // الانتقال للصفحة التالية
  //     _navigateToTimesPage(docId);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error saving data: $e'), backgroundColor: Colors.red),
  //     );
  //   }
  // }



  void _navigateToTimesPage(String docId) {
    try {
      if (selectedUnit != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TimesPage(
              medicationName: medicationController.text,
              selectedUnit: selectedUnit!,
              documentId: docId,
              startDate: '',
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Navigation Error: $e");
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
            const Text(
              "Select Dosage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: dosage > 1
                      ? () => setState(() => dosage--)
                      : null,
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 30),
                ),


                Text(
                  "$dosage ${selectedUnit ?? ''}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),


                IconButton(
                  onPressed: dosage < 10
                      ? () => setState(() => dosage++)
                      : null,
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                ),
              ],
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
             // _navigateToTimesPage(docId)
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
