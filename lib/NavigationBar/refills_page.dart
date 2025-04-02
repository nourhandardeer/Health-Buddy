import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/Refills/refill_details.dart';
import 'package:graduation_project/services/notification_service.dart'; // Import NotificationService
import 'package:intl/intl.dart';

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

            int inventory = (data['currentInventory'] is int)
                ? data['currentInventory'] as int
                : (data['currentInventory'] as double?)?.toInt() ?? 0;

            String reminderTime1 = data["reminderTime1"] ?? "Not set";
            String reminderTime2 = data["reminderTime2"] ?? "Not set";

            // Convert reminder times to DateTime objects
            DateTime? scheduledTime1;
            DateTime? scheduledTime2;

            if (reminderTime1 != "Not set") {
              scheduledTime1 = _convertTimeToDateTime(reminderTime1);
            }

            if (reminderTime2 != "Not set") {
              scheduledTime2 = _convertTimeToDateTime(reminderTime2);
            }

            // Schedule notifications if inventory is low
            if (inventory < 5) {
              if (scheduledTime1 != null) {
                NotificationService.scheduleNotification(
                  id: index,
                  title: "Refill Reminder: ${data["name"]}",
                  body: "Your medication inventory is low! Please refill soon.",
                  scheduledTime: scheduledTime1,
                );
              }

              if (scheduledTime2 != null) {
                NotificationService.scheduleNotification(
                  id: index + 1, // Unique ID for this notification
                  title: "Refill Reminder: ${data["name"]}",
                  body: "Your medication inventory is low! Please refill soon.",
                  scheduledTime: scheduledTime2,
                );
              }
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
                      "Reminder Time: $reminderTime1 and $reminderTime2",
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

  DateTime _convertTimeToDateTime(String timeStr) {
    DateFormat format = DateFormat("hh:mm a");
    DateTime time = format.parse(timeStr);
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }
}
