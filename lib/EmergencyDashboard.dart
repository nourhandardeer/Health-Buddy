import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_helper.dart';

class EmergencyDashboard extends StatefulWidget {
  @override
  _EmergencyDashboardState createState() => _EmergencyDashboardState();
}

class _EmergencyDashboardState extends State<EmergencyDashboard> {
  String? linkedPatientId;
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    _fetchLinkedPatient();
  }

  Future<void> _fetchLinkedPatient() async {
    String? patientId = await FirestoreHelper.getLinkedPatientId();
    if (patientId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      if (doc.exists) {
        setState(() {
          linkedPatientId = patientId;
          patientData = doc.data() as Map<String, dynamic>;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patient Data")),
      body: patientData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Name: ${patientData!['name']}", style: TextStyle(fontSize: 20)),
            Text("Email: ${patientData!['email']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Medications:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...((patientData!['medications'] as List<dynamic>?)
                ?.map((med) => Text("- ${med['name']}, Dosage: ${med['dosage']}"))
                .toList() ??
                []),
          ],
        ),
      ),
    );
  }
}
