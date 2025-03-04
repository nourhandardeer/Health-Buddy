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

    DateTime today = DateTime.now();
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
        const SnackBar(content: Text("ypu have taken this mediction today")),
      );
      return;
    }

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
      'lastTakenDate': Timestamp.fromDate(today),
    });

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم تناول الدواء! المتبقي: $updatedInventory")),
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

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('meds')
        .where('userId', isEqualTo: user.uid)
        .snapshots(),
    builder: (context, medSnapshot) {
      if (medSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (medSnapshot.hasError || !medSnapshot.hasData || medSnapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text("No medications found", style: TextStyle(color: Colors.black)),
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
              onTap: () => _showMedicationDetails(context, medId, medData), // Show modal on tap
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
                              decoration: alreadyTakenToday ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          Text(
                            "${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                            style: TextStyle(
                              fontSize: 14,
                              decoration: alreadyTakenToday ? TextDecoration.lineThrough : TextDecoration.none,
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
                              color: alreadyTakenToday ? Colors.blue : Colors.black, width: 2),
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
}



void _showMedicationDetails(BuildContext context, String medId, Map<String, dynamic> medData) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Medication Icon
                  const Icon(Icons.medical_services, size: 40, color: Colors.blue),

                  // Delete Button (Trash Icon)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                    onPressed: () {
                      _deleteMedication(medId, context); // Call delete function
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
                  "frequency: ${medData['frequency'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
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
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "unit: 1${medData['unit'] ?? 'pill(s)'}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),

              // "Mark as Taken" Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    takeMedication(medId, medData);
                    Navigator.pop(context); // Close modal after action
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

              // "Close" Button
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