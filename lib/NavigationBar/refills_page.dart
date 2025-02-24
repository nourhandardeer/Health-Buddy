import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Refills/refill_details.dart';

class RefillsPage extends StatefulWidget {
  const RefillsPage({super.key});

  @override
  _RefillsState createState() => _RefillsState();
}

class _RefillsState extends State<RefillsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    final CollectionReference _refillsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications');

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _refillsCollection.where('pillsLeft', isLessThanOrEqualTo: 5).snapshots(),
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
            itemCount: documents.length,
            separatorBuilder: (context, index) =>
                const Divider(thickness: 1, color: Colors.grey),
            itemBuilder: (context, index) {
              var data = documents[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 20),
                  leading: Image.asset("images/drugs.png",
                      width: 50, height: 50, fit: BoxFit.cover),
                  trailing: const Icon(Icons.notifications, size: 35),
                  title: Text(
                    data["name"] ?? "Unknown Medication",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Time: ${data["time"] ?? "Not set"}",
                          style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      Text("Pills left: ${data["pillsLeft"] ?? "N/A"}",
                          style: const TextStyle(fontSize: 14, color: Colors.blue)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RefillDetails(medData: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
