import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, bool> _medTakenStatus = {};

  @override
  void initState() {
    super.initState();
    loadTakenMedsForToday();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ================ user name===================
  Widget _buildUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Guest',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black));
        } else if (snapshot.hasError) {
          return const Text('Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black));
        }

        final document = snapshot.data;

        if (document == null || !document.exists) {
          return const Text('User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black));
        }

        final data = document.data() as Map<String, dynamic>;
        final fullName = "${data['firstName']} ${data['lastName']}";

        return Text(fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black));
      },
    );
  }

  // ================ Calendar ===================
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.saturday,
      headerVisible: false,
    );
  }
  
  Stream<QuerySnapshot> fetchAppointmentsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user found");
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchAppointmentsCollection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Appointments Error: ${snapshot.error}');
          return const Center(child: Text("Error loading appointments"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No appointments found"));
        }

        var appointments = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            var appointment = appointments[index];
            var data = appointment.data() as Map<String, dynamic>;

            String appointmentDate = data['appointmentDate'] ?? 'N/A';
            String appointmentTime = data['appointmentTime'] ?? 'N/A';
            String doctorName = data['doctorName'] ?? 'N/A';
            // String location = data['location'] ?? 'N/A';
            String specialty = data['specialty'] ?? 'N/A';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, size: 40, color: Colors.blue),
                  title: Text("Dr. $doctorName"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: $appointmentDate"),
                      Text("Time: $appointmentTime"),
                      // Text("Location: $location"),
                      Text("Specialty: $specialty"),
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

  // ================ Medications ===================
  Stream<QuerySnapshot> fetchMedsCollectionAll() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('meds')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Widget _buildMedicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchMedsCollectionAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading medications"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No medications found"));
        }

        var medications = snapshot.data!.docs;

        String selectedDayName = _selectedDay != null
            ? getDayName(_selectedDay!.weekday).toLowerCase()
            : getDayName(_focusedDay.weekday).toLowerCase();

        var filteredMeds = medications.where((doc) {
          var medData = doc.data() as Map<String, dynamic>;

          String? frequency = medData['frequency'];
          List<dynamic>? specificDays = medData['specificDays'];
          String? recurringType = medData['recurringType'];
          int? recurringValue = medData['recurringValue'];

          if (frequency != null && frequency.isNotEmpty) {
            String freq = frequency.toLowerCase();
            if (freq == 'once a day' || freq == 'twice a day' || freq == '3 times a day') {
              return true;
            }
            if (freq == 'once a week') {
              String onceAWeekDay = (medData['onceAWeekDay'] ?? '').toString().toLowerCase();
              return onceAWeekDay == selectedDayName;
            }
            return false;
          }

          if (specificDays != null && specificDays.isNotEmpty) {
            String today = getDayName((_selectedDay ?? _focusedDay).weekday);
            return specificDays.contains(today);
          }

          if (recurringType != null && recurringValue != null) {
            if (medData['startDate'] == null) {
              return false;
            }

            DateTime startDate = (medData['startDate'] as Timestamp).toDate();
            DateTime selectedDate = _selectedDay ?? _focusedDay;
            Duration diff = selectedDate.difference(startDate);
            int diffValue = 0;

            switch (recurringType.toLowerCase()) {
              case 'day':
                diffValue = diff.inDays;
                break;
              case 'week':
                diffValue = (diff.inDays / 7).floor();
                break;
              case 'month':
                diffValue = ((selectedDate.year - startDate.year) * 12 +
                    selectedDate.month -
                    startDate.month);
                break;
              default:
                return false;
            }

            return diffValue >= 0 && diffValue % recurringValue == 0;
          }

          return false;
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredMeds.length,
          itemBuilder: (context, index) {
            var med = filteredMeds[index];
            var medData = med.data() as Map<String, dynamic>;

            String rawTime = medData['reminderTime1'] ?? "";
            String timeText = formatReminderTime(rawTime);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isTodaySelected())
                        Checkbox(
                          value: _medTakenStatus[med.id] ?? false,
                          onChanged: (_medTakenStatus[med.id] ?? false)
                              ? null
                              : (bool? value) async {
                                  if (value == null || !value) return;

                                  setState(() {
                                    _medTakenStatus[med.id] = true;
                                  });

                                  final dosageStr = medData['dosage'].toString();
                                  await markMedicationAsTaken(med.id, dosageStr);
                                },
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medication, color: Colors.redAccent, size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(medData['name'] ?? "Unknown",
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                Text("${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                                    style: const TextStyle(fontSize: 14, color: Colors.black)),
                                const SizedBox(height: 4),
                                Text("Frequency: ${medData['frequency'] ?? 'N/A'}",
                                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool isTodaySelected() {
    final today = DateTime.now();
    return _selectedDay == null
        ? isSameDay(_focusedDay, today)
        : isSameDay(_selectedDay!, today);
  }

  String getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String formatReminderTime(String time) {
    if (time.isEmpty) return "";
    time = time.toUpperCase();
    if (time.contains('AM') || time.contains('PM')) {
      time = time.replaceAll('AM', ' AM').replaceAll('PM', ' PM');
    }
    return time.trim();
  }

  Future<void> loadTakenMedsForToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month}-${now.day}";

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medsTaken')
        .where('date', isEqualTo: todayDate)
        .get();

    setState(() {
      for (var doc in snapshot.docs) {
        final medId = doc['medId'];
        _medTakenStatus[medId] = true;
      }
    });
  }

  Future<void> markMedicationAsTaken(String medId, String dosageStr) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medsTaken')
          .doc('${medId}_${now.toIso8601String()}')
          .set({
        'medId': medId,
        'takenAt': now,
        'date': "${now.year}-${now.month}-${now.day}",
      });

      final medDocRef = FirebaseFirestore.instance.collection('meds').doc(medId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final medSnapshot = await transaction.get(medDocRef);
        if (!medSnapshot.exists) return;

        final medData = medSnapshot.data() as Map<String, dynamic>;
        final currentInventory = (medData['currentInventory'] ?? 0).toDouble();
        final dosage = double.tryParse(dosageStr) ?? 0;

        final newInventory = (currentInventory - dosage).clamp(0, double.infinity);

        transaction.update(medDocRef, {'currentInventory': newInventory});
      });
    } catch (e) {
      print('Error updating inventory: $e');
    }
  }

  Widget _homeScreenContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 10),
          const Text("Medications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildMedicationsList(),
          const SizedBox(height: 20),
          const Text("Appointments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildAppointmentsList(),
        ],
      ),
    );
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
          },
        ),
        title: _buildUserName(),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.black), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              }),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homeScreenContent(),
          const RefillsPage(),
          const MedicationsPage(),
          const ManagePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
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
