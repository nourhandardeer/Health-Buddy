import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Refills/refill_details.dart';
// import 'refill_detail';

class RefillsPage extends StatefulWidget {
  const RefillsPage({Key? key}) : super(key: key);

  @override
  _RefillsPageState createState() => _RefillsPageState();
}

class _RefillsPageState extends State<RefillsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          "Please log in to view refills.",
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: const Text("Refills Needed"),
      ),
      body: _buildRefillsList(user.uid),
    );
  }

  Widget _buildRefillsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('meds')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var documents = snapshot.data?.docs;
        if (documents == null || documents.isEmpty) {
          return const Center(child: Text("No refills needed"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          separatorBuilder: (context, index) =>
              const Divider(thickness: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            var data = documents[index].data() as Map<String, dynamic>;
            String inventoryStr = data['currentInventory']?.trim() ?? '0';
            int inventory = int.tryParse(inventoryStr) ?? 0;

            return Card(
              color: Colors.grey[200],
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Image.asset(
                  "images/drugs.png",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                trailing: const Icon(Icons.notifications, size: 35),
                title: Text(
                  data["name"] ?? "Unknown Medication",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Inventory: ${inventory} ${data["unit"] ?? ""}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      "Reminder Time: ${data["reminderTime"] ?? "Not set"}",
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RefillDetailsPage(medData: data),
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
}
