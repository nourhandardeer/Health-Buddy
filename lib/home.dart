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
  final List<Widget> _pages = [
    const HomePage(),
    const RefillsPage(),
    const MedicationsPage(),
    const ManagePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
Future<void> takeMedication(String medId, Map<String, dynamic> medData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day); // Remove time details
    DateTime? lastTakenDate;

    if (medData['lastTakenDate'] != null) {
        lastTakenDate = (medData['lastTakenDate'] as Timestamp).toDate();
    }

    bool alreadyTakenToday =
        lastTakenDate != null &&
        lastTakenDate.year == today.year &&
        lastTakenDate.month == today.month &&
        lastTakenDate.day == today.day;

    if (alreadyTakenToday) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have already taken this medication today.")),
        );
        return;
    }

    // ✅ Handle inventory (if exists)
    bool hasInventory = medData.containsKey('currentInventory') && medData['currentInventory'] != null;
    if (hasInventory) {
        int currentInventory = medData['currentInventory'] is String
            ? int.tryParse(medData['currentInventory']) ?? 0
            : medData['currentInventory'] ?? 0;
        int dosage = medData['dosage'] is String
            ? int.tryParse(medData['dosage']) ?? 1
            : medData['dosage'] ?? 1;

        if (currentInventory <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Out of stock! You need to refill.")),
            );
            return;
        }

        int updatedInventory = currentInventory - dosage;

        await FirebaseFirestore.instance.collection('meds').doc(medId).update({
            'currentInventory': updatedInventory,
            'lastTakenDate': Timestamp.fromDate(today), // Save only the date
        });

    } else {
        await FirebaseFirestore.instance.collection('meds').doc(medId).update({
            'lastTakenDate': Timestamp.fromDate(today), // Save only the date
        });
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medication has been taken!")),
    );
}


  Widget _buildTitle() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text(
        'Guest',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'Loading...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        } else if (snapshot.hasError) {
          return const Text(
            'Error',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'User',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        } else {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = "${data['firstName']} ${data['lastName']}";
          return Text(
            fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          );
        }
      },
    );
  }

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

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
    builder: (context, userSnapshot) {
      if (userSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
        return const Center(
          child: Text("Error loading user data", style: TextStyle(color: Colors.red)),
        );
      }

      var userData = userSnapshot.data!.data() as Map<String, dynamic>;

      List<String> emergencyUserIds = (userData['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('meds')
              .where('userId', isEqualTo: user.uid)
              .get(),
          FirebaseFirestore.instance
              .collection('meds')
              .where('originalUserEmergencyContacts', arrayContains: user.uid)
              .get(),
          FirebaseFirestore.instance
              .collection('meds')
              .where('emergencyUserIds', arrayContains: user.uid)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text("Error loading medications", style: TextStyle(color: Colors.red)),
            );
          }

          List<QueryDocumentSnapshot> medications = [
            ...snapshot.data![0].docs,
            ...snapshot.data![1].docs,
            ...snapshot.data![2].docs
          ];

          if (medications.isEmpty) {
            return const Center(
              child: Text("No medications found", style: TextStyle(color: Colors.black)),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              var med = medications[index];
              var medData = med.data() as Map<String, dynamic>;
              String medId = med.id;

              DateTime today = DateTime.now();
              DateTime? lastTakenDate;
              if (medData['lastTakenDate'] != null) {
                lastTakenDate = (medData['lastTakenDate'] as Timestamp).toDate();
              }

              bool alreadyTakenToday = lastTakenDate != null &&
                  lastTakenDate.year == today.year &&
                  lastTakenDate.month == today.month &&
                  lastTakenDate.day == today.day;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => _showMedicationDetails(context, medId, medData),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: alreadyTakenToday ? Colors.blue : Colors.black,
                        width: alreadyTakenToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.medication, size: 30, color: Colors.black),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medData['name'] ?? "Unknown",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration: alreadyTakenToday
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              Text(
                                "${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: alreadyTakenToday
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: alreadyTakenToday ? null : () => takeMedication(medId, medData),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: alreadyTakenToday ? Colors.blue : Colors.black,
                                  width: 2),
                              color: alreadyTakenToday ? Colors.blue : Colors.transparent,
                            ),
                            child: alreadyTakenToday
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}









void _showMedicationDetails(BuildContext context, String medId, Map<String, dynamic> medData) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime? lastTakenDate;

  if (medData['lastTakenDate'] != null) {
    lastTakenDate = (medData['lastTakenDate'] as Timestamp).toDate();
  }

  String takenAtText = "Not yet taken";
  if (lastTakenDate != null) {
    if (lastTakenDate.year == today.year &&
        lastTakenDate.month == today.month &&
        lastTakenDate.day == today.day) {
      // Show only the time if taken today
      takenAtText = "${lastTakenDate.hour.toString().padLeft(2, '0')}:${lastTakenDate.minute.toString().padLeft(2, '0')}";
    } else {
      // Show only the date if taken on a previous day
      takenAtText = "${lastTakenDate.year}-${lastTakenDate.month.toString().padLeft(2, '0')}-${lastTakenDate.day.toString().padLeft(2, '0')}";
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.medical_services, size: 40, color: Colors.blue),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                    onPressed: () {
                      _deleteMedication(medId, context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  medData['name'] ?? "Unknown Medication",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  "Frequency: ${medData['frequency'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Scheduled at: ${medData['reminderTime'] ?? 'N/A'}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Taken at: $takenAtText",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Unit: ${medData['unit'] ?? 'pill(s)'}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Intake Advice: ${medData['intakeAdvice'] ?? ''}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    takeMedication(medId, medData);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Mark as Taken"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.black, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



void _deleteMedication(String medId, BuildContext context) async {
  try {
    await FirebaseFirestore.instance.collection('meds').doc(medId).delete();
    Navigator.pop(context); // Close modal after deleting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Medication deleted successfully!")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error deleting medication: $e")),
    );
  }
}






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
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfilePage()));
          },
        ),
        title: _buildTitle(),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              }),
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
                          const Icon(Icons.image_not_supported,
                              size: 100, color: Colors.grey),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_mode), label: 'Refills'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication_liquid_outlined), label: 'Medications'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Manage'),
        ],
      ),
    );
  }
}