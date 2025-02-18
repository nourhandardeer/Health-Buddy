import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/NavigationBar/home_page.dart';
import 'package:graduation_project/NavigationBar/manage_page.dart';
import 'package:graduation_project/NavigationBar/medications_page.dart';
import 'package:graduation_project/NavigationBar/refills_page.dart';
import 'package:graduation_project/pages/profile_page.dart';
import 'package:graduation_project/pages/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// Navigation pages
  final List<Widget> _pages = [
    const HomePage(),
    const RefillsPage(),
    const MedicationsPage(),
    const ManagePage(),
  ];

  /// Switch between bottom navigation pages
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

   Widget _buildTitle() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Guest',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        } else if (snapshot.hasError) {
          return const Text('Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        } else {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = "${data['firstName']} ${data['lastName']}";
          return Text(fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
        }
      },
    );
  }

  /// Store completed medications
  Set<String> completedMedications = {};
  Widget _buildMedicationsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          "Please log in to view medications.",
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _getLinkedPatientId(user.uid), // Get the patient's ID for emergency contacts
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text(
              "Error fetching patient data",
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        String patientId = snapshot.data!; // Patient's ID

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('medications')
              .doc(patientId) // Use the patient's UID
              .collection('user_medications')
              .snapshots(),
          builder: (context, medSnapshot) {
            if (medSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (medSnapshot.hasError || !medSnapshot.hasData || medSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No medications found",
                  style: TextStyle(color: Colors.black),
                ),
              );
            }

            var medications = medSnapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                var med = medications[index];
                var medData = med.data() as Map<String, dynamic>;
                String medId = med.id;

                bool isCompleted = completedMedications.contains(medId);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        medData['reminderTime'] ?? "00:00",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Medication Card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Pill Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medication,
                                  color: Colors.redAccent,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Medication Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medData['name'] ?? "Unknown",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      "${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Circular Checkbox (Toggle state)
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            if (isCompleted) {
                              completedMedications.remove(medId);
                            } else {
                              completedMedications.add(medId);
                            }
                          });

                          // Update Firestore
                          await FirebaseFirestore.instance
                              .collection('medications')
                              .doc(patientId) // Update the patient's record
                              .collection('user_medications')
                              .doc(medId)
                              .update({'completed': !isCompleted});
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent, width: 2),
                            color: isCompleted ? Colors.redAccent : Colors.transparent,
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  /// Fetch the linked patient ID for an emergency contact, or return their own ID if they are a patient
  Future<String?> _getLinkedPatientId(String uid) async {
    try {
      // Check if the user is a patient
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('linkedPatientId')) {
          return userData['linkedPatientId']; // Return the patient's ID
        }
      }

      // If no linkedPatientId found, return the logged-in user's ID (they are the patient)
      return uid;
    } catch (e) {
      print("Error fetching linked patient ID: $e");
      return null;
    }
  }

  // /// Fetch and display medications
  // Widget _buildMedicationsList() {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     return const Center(
  //       child: Text(
  //         "Please log in to view medications.",
  //         style: TextStyle(color: Colors.black),
  //       ),
  //     );
  //   }
  //
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('medications')
  //         .doc(user.uid)
  //         .collection('user_medications')
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //       if (snapshot.hasError) {
  //         return const Center(
  //           child: Text(
  //             "Error fetching medications",
  //             style: TextStyle(color: Colors.black),
  //           ),
  //         );
  //       }
  //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //         return const Center(
  //           child: Text(
  //             "No medications found",
  //             style: TextStyle(color: Colors.black),
  //           ),
  //         );
  //       }
  //
  //       var medications = snapshot.data!.docs;
  //
  //       return ListView.builder(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemCount: medications.length,
  //         itemBuilder: (context, index) {
  //           var med = medications[index];
  //           var medData = med.data() as Map<String, dynamic>;
  //           String medId = med.id;
  //
  //           bool isCompleted = completedMedications.contains(medId);
  //
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //             child: Row(
  //               children: [
  //
  //                 Text(
  //                   medData['reminderTime'] ?? "00:00", // Fetch reminderTime instead of 00:00
  //                   style: const TextStyle(
  //                     fontSize: 18,
  //                     color: Colors.black,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //
  //                 // 💊 Medication Card
  //                 Expanded(
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(20),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.grey.shade300,
  //                           blurRadius: 8,
  //                           spreadRadius: 2,
  //                         ),
  //                       ],
  //                     ),
  //                     padding: const EdgeInsets.all(16),
  //                     child: Row(
  //                       children: [
  //                         // Pill Icon
  //                         Container(
  //                           padding: const EdgeInsets.all(10),
  //                           decoration: BoxDecoration(
  //                             color: Colors.redAccent.withOpacity(0.2),
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: const Icon(
  //                             Icons.medication,
  //                             color: Colors.redAccent,
  //                             size: 30,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 12),
  //
  //                         // Medication Details
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 medData['name'] ?? "Unknown",
  //                                 style: const TextStyle(
  //                                   fontSize: 18,
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Colors.black,
  //                                 ),
  //                               ),
  //                               Text(
  //                                 "${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
  //                                 style: const TextStyle(
  //                                   fontSize: 14,
  //                                   color: Colors.black,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(width: 12),
  //
  //                 // 🔘 Circular Checkbox (Toggle state)
  //                 GestureDetector(
  //                   onTap: () async {
  //                     setState(() {
  //                       if (isCompleted) {
  //                         completedMedications.remove(medId);
  //                       } else {
  //                         completedMedications.add(medId);
  //                       }
  //                     });
  //
  //                     // Update Firestore
  //                     await FirebaseFirestore.instance
  //                         .collection('medications')
  //                         .doc(user.uid)
  //                         .collection('user_medications')
  //                         .doc(medId)
  //                         .update({'completed': !isCompleted});
  //                   },
  //                   child: Container(
  //                     width: 26,
  //                     height: 26,
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: Colors.redAccent, width: 2),
  //                       color: isCompleted ? Colors.redAccent : Colors.transparent,
  //                     ),
  //                     child: isCompleted
  //                         ? const Icon(Icons.check, color: Colors.white, size: 18)
  //                         : null,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle, size: 40, color: Colors.black),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
          },
        ),
        title: _buildTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'images/photo1.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
                _buildMedicationsList(),
              ],
            ),
          ),
          const RefillsPage(),
          const MedicationsPage(),
          const ManagePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_mode), label: 'Refills'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_liquid_outlined), label: 'Medications'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Manage'),
        ],
      ),
    );
  }
}
