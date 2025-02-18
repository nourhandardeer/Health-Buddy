import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Refills/refill_details.dart'; // Import RefillDetails Page

class RefillsPage extends StatefulWidget {
  const RefillsPage({super.key});

  @override
  _RefillsState createState() => _RefillsState();
}

class _RefillsState extends State<RefillsPage> {
  final CollectionReference _refillsCollection =
      FirebaseFirestore.instance.collection('medications'); // Reference to Firestore Collection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _refillsCollection.snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Loading indicator
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}")); // Handle errors
          }

          var documents = snapshot.data?.docs;
          if (documents == null || documents.isEmpty) {
            return const Center(child: Text("No refills available"));
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
                    data["name"] ?? "Unknown",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["time"] ?? "Time not set",
                          style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      Text(data["pills"] ?? "Pill count not available",
                          style: const TextStyle(fontSize: 14, color: Colors.blue)),
                    ],
                  ),
                 
                ),
              );
            },
          );
        },
      ),
    );
  }
}
