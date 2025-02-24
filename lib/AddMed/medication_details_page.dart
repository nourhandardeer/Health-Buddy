import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDetailsPage extends StatelessWidget {
  final String medId; // Document ID

  const MedicationDetailsPage({Key? key, required this.medId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Medication Schedule"),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: Text("User not logged in")),
      );
    }

    // Fetch the document from the 'meds' collection using the medId.
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('meds')
          .doc(medId)
          .get(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // Error
        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        // Document not found
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: Text("Medication not found.")),
          );
        }

        // Document exists
        final medData = snapshot.data!.data() as Map<String, dynamic>;

        // Optional: Verify that the medication belongs to the current user.
        if (medData['userId'] != user.uid) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: Text("Unauthorized access.")),
          );
        }

        // Debug: Print document data.
        print('Document data for $medId: $medData');

        return Scaffold(
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection("Frequency", "${medData['frequency'] ?? 'N/A'}"),
                _buildSection("CurrentInventory", "${medData['currentInventory'] ?? 'N/A'}"),
                _buildSection("ReminderTime", "${medData['reminderTime'] ?? 'N/A'}"),
                _buildSection("Unit", "${medData['unit'] ?? 'N/A'}"),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Medication Schedule"),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  Widget _buildSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
