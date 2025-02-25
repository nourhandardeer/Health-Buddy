// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class RefillDetails extends StatefulWidget {
//   final Map<String, dynamic> medData;
//   const RefillDetails({super.key, required this.medData});

//   @override
//   _RefillDetailsState createState() => _RefillDetailsState();
// }

// class _RefillDetailsState extends State<RefillDetails> {
//   late int _currentInventory;

//   @override
//   void initState() {
//     super.initState();
//     _currentInventory = int.tryParse(widget.medData['currentInventory'].trim()) ?? 0;
//   }

//   void _updateInventory(int amount) {
//     setState(() {
//       _currentInventory += amount;
//     });
//   }

//   void _saveRefillData() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     FirebaseFirestore.instance
//         .collection('meds')
//         .doc(widget.medData['id'])
//         .update({'currentInventory': _currentInventory.toString()}).then((_) {
//       Navigator.of(context).pop();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Refill Details"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.medData['name'] ?? "Unknown Medication",
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text("Current Inventory: $_currentInventory ${widget.medData['unit']}"),
//             const SizedBox(height: 8),
//             Text("Frequency: ${widget.medData['frequency'] ?? 'N/A'}"),
//             const SizedBox(height: 8),
//             Text("Reminder Time: ${widget.medData['reminderTime'] ?? 'Not set'}"),
//             const SizedBox(height: 8),
//             Text("Reminder Status: ${widget.medData['remindMeWhen'] ?? 'N/A'}"),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => _updateInventory(10),
//               child: const Text("Add 10 Pills"),
//             ),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: _saveRefillData,
//               child: const Text("Save Changes"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
