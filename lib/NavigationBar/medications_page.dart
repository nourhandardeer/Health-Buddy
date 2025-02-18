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
      ),
      body: _buildMedicationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedicationPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
                  medData["name"] ?? "Unknown Medication",
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
                subtitle: Text(
                  "Daily — ${medData['time'] ?? 'N/A'}",
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

class MedicationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> medData;

  const MedicationDetailsPage({super.key, required this.medData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication Schedule"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection("Frequency", "${medData['frequency'] ?? 'Daily, X times a day'}", true),
            _buildSection("Duration", "${medData['duration'] ?? 'No end date'}", true),
            _buildReminderSection(),
            _buildWeekendToggle(),
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
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          if (editable)
            Icon(Icons.edit, color: Colors.brown),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Reminder details", style: TextStyle(color: Colors.grey[700])),
          ListTile(
            leading: Icon(Icons.remove_circle, color: Colors.red),
            title: Text("Time: ${medData['time'] ?? '08:00'}", style: TextStyle(fontSize: 16)),
            trailing: Text("${medData['pillsLeft'] ?? '1'} pill(s)"),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add, color: Colors.green),
            label: Text("Add reminder time"),
          )
        ],
      ),
    );
  }

  Widget _buildWeekendToggle() {
    return ListTile(
      title: Text("Different times on weekends", style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Saturday and Sunday"),
      trailing: Switch(value: false, onChanged: (val) {}),
    );
  }
}
