import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/AddMed/addmed.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background
      appBar: AppBar(
        
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Black icons
      ),
      body: _buildMedicationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedicationPage()),
          );
        },
        backgroundColor: Colors.blue, // Blue for better visibility
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Fetch & display medications for the logged-in user
  Widget _buildMedicationsList() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          "Please log in to view medications.",
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medications')
          .doc(user.uid)
          .collection('user_medications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text("Error fetching medications", style: TextStyle(color: Colors.black)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(); // Show "Add Medications" UI if no data
        }

        var medications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            var med = medications[index];
            var medData = med.data() as Map<String, dynamic>;

            return Card(
              color: Colors.grey[200], // Light grey card
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.blue), // Blue icon
                title: Text(
                  medData["name"] ?? "Unknown Medication",
                  style: const TextStyle(color: Colors.black, fontSize: 18), // Black text
                ),
                subtitle: Text(
                  "Daily — ${medData['time'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.grey[700]), 
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue[100], 
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${medData["pillsLeft"] ?? 0} ",
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// UI when no medications exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'images/syringe.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 50),
          Text(
            "Add your meds to be reminded on time and\ntrack your health",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]), // Dark grey text
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMedicationPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Blue button
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              "Add a med",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
