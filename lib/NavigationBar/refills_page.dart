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
  final Set<String> _notifiedMeds = {};
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

        var documents = snapshot.data?.docs ?? [];
        if (documents.isEmpty) {
          return const Center(child: Text("No refills needed"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          separatorBuilder: (_, __) => const Divider(thickness: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final data = documents[index].data() as Map<String, dynamic>;
            final medName = data["name"]?.toString() ?? "Unknown Medication";

            // Inventory parsing
            int inventory = 0;
            final inventoryRaw = data['currentInventory'];
            if (inventoryRaw is int) {
              inventory = inventoryRaw;
            } else if (inventoryRaw is double) {
              inventory = inventoryRaw.toInt();
            } else if (inventoryRaw is String) {
              inventory = int.tryParse(inventoryRaw) ?? 0;
            }

            // Reminder threshold
            int remindMeWhen = 5;
            final thresholdRaw = data['remindMeWhen'];
            if (thresholdRaw is String) {
              remindMeWhen = int.tryParse(thresholdRaw) ?? 5;
            } else if (thresholdRaw is num) {
              remindMeWhen = thresholdRaw.toInt();
            }

            final reminderTimeStr = data["reminderTime1"] ?? "Not set";
            DateTime? scheduledTime = reminderTimeStr != "Not set"
                ? _convertTimeToDateTime(reminderTimeStr)
                : null;

            if (inventory > 0 &&
                inventory <= remindMeWhen &&
                !_notifiedMeds.contains(medName)) {
              _notifiedMeds.add(medName);

              final DateTime now = DateTime.now();
              final DateTime notificationTime = now.add(const Duration(seconds: 5));

              NotificationService.scheduleNotification(
                id: medName.hashCode ^ notificationTime.hashCode,
                title: "Refill Reminder: $medName",
                body: "Your medication inventory is low! Please refill soon.",
                ttsMessage: "Your medication $medName inventory is low! Please refill soon.",
                scheduledTime: notificationTime,
                speakImmediately: true,
              );
            }

            return Card(
              color: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Image.asset("images/drugs.png", width: 50, height: 50),
                trailing: const Icon(Icons.notifications, size: 35),
                title: Text(
                  medName,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Inventory: $inventory ${data["unit"] ?? ""}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      "Reminder Time: $reminderTimeStr",
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
    try {
      final format = DateFormat("hh:mm a");
      final time = format.parse(timeStr);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    } catch (_) {
      return DateTime.now();
    }
  }
}