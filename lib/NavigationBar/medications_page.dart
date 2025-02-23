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
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      title: const Text("My Medications", style: TextStyle(color: Colors.black)),
    ),
    body: Column(
      children: [
        Expanded(child: _buildMedicationsList()), // Makes the list take up remaining space
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMedicationPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Add Medication",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}


  /// **Fetch Medications from Firebase**
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
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text("Error fetching medications", style: TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var medications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            var med = medications[index];
            var medData = med.data() as Map<String, dynamic>;

            return Card(
              color: Colors.grey[200],
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.blue),
                title: Text(
                  medData["medicationName"] ?? "Unknown Medication",
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
                subtitle: Text(
                  "Frequency: ${medData['selectedFrequency'] ?? 'N/A'}\nTime: ${medData['reminderTime'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicationDetailsPage(medData: medData),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// **Empty State UI**
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
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// **Medication Details Page**
class MedicationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> medData;

  const MedicationDetailsPage({super.key, required this.medData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection("Medication Name", "${medData['medicationName'] ?? 'Unknown'}", false),
            _buildSection("Frequency", "${medData['selectedFrequency'] ?? 'Daily'}", false),
            _buildSection("Time", "${medData['reminderTime'] ?? '08:00'}", false),
            _buildSection("Unit", "${medData['selectedUnit'] ?? 'Pills'}", false),
            _buildSection("Pills Left", "${medData['currentInventory'] ?? 'N/A'}", false),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(
                child: Text("Edit Medication", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String value, bool editable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[700])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          if (editable)
            const Icon(Icons.edit, color: Colors.brown),
        ],
      ),
    );
  }
}
