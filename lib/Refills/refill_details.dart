// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:graduation_project/home.dart';

// class RefillDetails extends StatefulWidget {
//   final Map<String, dynamic> medData;
//   const RefillDetails({super.key, required this.medData});

//   @override
//   _RefillDetailsState createState() => _RefillDetailsState();
// }

// class _RefillDetailsState extends State<RefillDetails> {
//   late int _currentInventory;
//   late int _reminderAmount;
//   bool _reminderOn = true;

//   @override
//   void initState() {
//     super.initState();
//     _currentInventory = widget.medData['pillsLeft'] ?? 0;
//     _reminderAmount = 10;
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
//         .collection('users')
//         .doc(user.uid)
//         .collection('medications')
//         .doc(widget.medData['id'])
//         .update({'pillsLeft': _currentInventory}).then((_) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//         (Route<dynamic> route) => false,
//       );
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
//             const Text("Manage your medication supply and refill reminders."),
//             const SizedBox(height: 20),
            
//             Text("Current Inventory: $_currentInventory pills"),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () => _updateInventory(10),
//               child: const Text("Add 10 Pills"),
//             ),
//             ElevatedButton(
//               onPressed: () => _updateInventory(20),
//               child: const Text("Add 20 Pills"),
//             ),
            
//             SwitchListTile(
//               title: const Text("Enable refill reminders"),
//               value: _reminderOn,
//               onChanged: (value) {
//                 setState(() {
//                   _reminderOn = value;
//                 });
//               },
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
