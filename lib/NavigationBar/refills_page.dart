import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Refills/refill_details.dart';
import 'package:graduation_project/services/notification_service.dart'; // Import NotificationService

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildRefillsList(user.uid),
    );
  }

  Widget _buildRefillsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('meds')
          .where('linkedUserIds', arrayContains: userId)
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
            debugPrint("Medication Name: ${data['name']}");

            int inventory = (data['currentInventory'] is int)
                ? data['currentInventory'] as int
                : (data['currentInventory'] as double?)?.toInt() ?? 0;

            String reminderTime = data["reminderTime"] ?? "Not set";

            // Convert reminderTime to DateTime object
            DateTime? scheduledTime;
            if (reminderTime != "Not set") {
              List<String> timeParts = reminderTime.split(":");
              if (timeParts.length == 2) {
                int hour = int.tryParse(timeParts[0]) ?? 0;
                int minute = int.tryParse(timeParts[1]) ?? 0;
                DateTime now = DateTime.now();
                scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
                  print("Scheduled Notification for: $scheduledTime");

              }
            }

            // Schedule notification if inventory is low
            if (inventory < 5 && scheduledTime != null) {
              NotificationService.scheduleNotification(
                id: index, // Unique ID for each notification
                title: "Refill Reminder: ${data["name"]}",
                body: "Your medication inventory is low! Please refill soon.",
                scheduledTime: scheduledTime,
              );
            }

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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Inventory: ${inventory} ${data["unit"] ?? ""}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      "Reminder Time: $reminderTime",
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
