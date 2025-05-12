import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/services/firestore_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:graduation_project/NavigationBar/manage_page.dart';
import 'package:graduation_project/NavigationBar/medications_page.dart';
import 'package:graduation_project/NavigationBar/refills_page.dart';
import 'package:graduation_project/pages/profile_page.dart';
import 'package:graduation_project/pages/setting/settings_page.dart';

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
  final FirestoreService _firestoreService = FirestoreService();

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

  Widget _buildUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Guest',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black));
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black));
        } else if (snapshot.hasError) {
          return const Text('Error',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black));
        }

        final document = snapshot.data;

        if (document == null || !document.exists) {
          return const Text('User',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black));
        }

        final data = document.data() as Map<String, dynamic>;
        final fullName = "${data['firstName']} ${data['lastName']}";

        return Text(fullName,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black));
      },
    );
  }

  Widget _buildUserImage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('images/user.png'),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('images/user.png'),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final profileImage = data['profileImage'] ?? '';

        if (profileImage == null || profileImage.isEmpty || profileImage == 'images/user.png') {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('images/user.png'),
          );
        }

        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          backgroundImage: NetworkImage(profileImage),
        );
      },
    );
  }

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

        final today = DateTime.now();
        final isToday = isSameDay(selectedDay, today);

        print("📅 Selected day: $selectedDay — isToday: $isToday");

        if (isToday) {
          print("🔁 Calling loadTakenMedsForToday()");
          loadTakenMedsForToday();
        } else {
          print("🔁 Calling loadTakenMedsForDate()");
          loadTakenMedsForDate(selectedDay);
        }
      },
      calendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.saturday,
      headerVisible: false,
    );
  }

  Stream<List<QueryDocumentSnapshot>> fetchAppointmentsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('linkedUserIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs); // Convert snapshot to list of docs
  }

  Widget _buildAppointmentsWithinTwoDaysRange() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: fetchAppointmentsCollection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading appointments"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No appointments found"));
        }

        final appointments = snapshot.data!;
        final selectedDate = _selectedDay ?? _focusedDay;
        final selectedDay =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        //   final oneDayBefore = selectedDay.subtract(const Duration(days: 1));
        final oneDayAfter = selectedDay.add(const Duration(days: 1));

        List<QueryDocumentSnapshot> filteredAppointments = [];
        List<String> reminders = [];

        for (var appointment in appointments) {
          final data = appointment.data() as Map<String, dynamic>;
          final appointmentDateStr = data['appointmentDate'];
          if (appointmentDateStr == null) continue;

          try {
            final appointmentDate = DateTime.parse(appointmentDateStr);
            final appointmentDay = DateTime(appointmentDate.year,
                appointmentDate.month, appointmentDate.day);

            if (appointmentDay == selectedDay) {
              filteredAppointments.add(appointment);
            }

            if (appointmentDay == oneDayAfter) {
              final doctorName = data['doctorName'] ?? 'Unknown';
              final appointmentTime = data['appointmentTime'] ?? 'Unknown';
              reminders.add(
                  "you have an appointment tomorrow with Dr. $doctorName at $appointmentTime");
            }
          } catch (e) {
            print(" Error parsing date: $appointmentDateStr — $e");
            continue;
          }
        }

        if (filteredAppointments.isEmpty && reminders.isEmpty) {
          return const Center(child: Text("No appointments for this day"));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  children: reminders.map((msg) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.yellow.shade700),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final data =
                    filteredAppointments[index].data() as Map<String, dynamic>;

                final doctorName = data['doctorName'] ?? 'Unknown';
                final appointmentDate = data['appointmentDate'] ?? 'N/A';
                final appointmentTime = data['appointmentTime'] ?? 'N/A';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      leading: const Icon(Icons.calendar_month,
                          size: 40, color: Colors.blue),
                      title: Text("Dr. $doctorName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date: $appointmentDate"),
                          Text("Time: $appointmentTime"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ================ Medications ===================
  Stream<List<QueryDocumentSnapshot>> fetchMedsCollectionAll() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: user.uid) // Filter meds for user
        .snapshots()
        .map((snapshot) => snapshot.docs); // Convert snapshot to list of docs
  }

  Widget _buildMedicationsList() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: fetchMedsCollectionAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading medications"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No medications found"));
        }

        var medications = snapshot.data!;
        final selectedDate = _selectedDay ?? _focusedDay;
        final today = DateTime.now();
        bool isToday = isSameDay(selectedDate, today);

        var filteredMeds = medications.where((doc) {
          var medData = doc.data() as Map<String, dynamic>;
          String frequency =
              (medData['frequency'] ?? '').toString().toLowerCase();

          final selectedDate = _selectedDay ?? _focusedDay;
          final todayName = getDayName(selectedDate.weekday);
          final medId = doc.id;

          if (frequency == 'once a week') {
            String? onceAWeekDay = medData['onceAWeekDay'];
            if (onceAWeekDay == null || onceAWeekDay != todayName) {
              return false;
            }
            if (_medTakenStatus.containsKey(medId) &&
                _medTakenStatus[medId] == true) {
              return false;
            }
            return true;
          }

          if (medData.containsKey('specificDays')) {
            List<dynamic> specificDays = medData['specificDays'];
            if (specificDays.isNotEmpty && !specificDays.contains(todayName)) {
              return false;
            }
            if (_medTakenStatus.containsKey(medId) &&
                _medTakenStatus[medId] == true) {
              return false;
            }
            return true;
          }

          if (frequency == 'once a day') {
            if (_medTakenStatus.containsKey('${medId}_1') &&
                _medTakenStatus['${medId}_1'] == true) {
              return false;
            }
            return true;
          }

          if (frequency == 'twice a day') {
            if ((_medTakenStatus['${medId}_1'] ?? false) &&
                (_medTakenStatus['${medId}_2'] ?? false)) {
              return false;
            }
            return true;
          }

          if (frequency == '3 times a day') {
            if ((_medTakenStatus['${medId}_1'] ?? false) &&
                (_medTakenStatus['${medId}_2'] ?? false) &&
                (_medTakenStatus['${medId}_3'] ?? false)) {
              return false;
            }
            return true;
          }

          // default fallback
          if (_medTakenStatus.containsKey(medId) &&
              _medTakenStatus[medId] == true) {
            return false;
          }

          return true;
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredMeds.length,
          itemBuilder: (context, index) {
            var med = filteredMeds[index];
            var medData = med.data() as Map<String, dynamic>;

            String frequency =
                (medData['frequency'] ?? '').toString().toLowerCase();
            String rawTime = "";
            String doseKey = med.id;

            if (frequency == "twice a day") {
              if (!(_medTakenStatus['${med.id}_1'] ?? false)) {
                rawTime = medData['reminderTime1'] ?? "";
                doseKey = '${med.id}_1';
              } else {
                rawTime = medData['reminderTime2'] ?? "";
                doseKey = '${med.id}_2';
              }
            } else if (frequency == "3 times a day") {
              if (!(_medTakenStatus['${med.id}_1'] ?? false)) {
                rawTime = medData['reminderTime1'] ?? "";
                doseKey = '${med.id}_1';
              } else if (!(_medTakenStatus['${med.id}_2'] ?? false)) {
                rawTime = medData['reminderTime2'] ?? "";
                doseKey = '${med.id}_2';
              } else {
                rawTime = medData['reminderTime3'] ?? "";
                doseKey = '${med.id}_3';
              }
            } else {
              rawTime = medData['reminderTime1'] ?? "";
              doseKey = '${med.id}_1';
            }

            String timeText = formatReminderTime(rawTime);

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      if (!(_medTakenStatus[doseKey] ?? false) &&
                          isSameDay(
                              _selectedDay ?? _focusedDay, DateTime.now()))
                        Checkbox(
                          value: false,
                          onChanged: (bool? value) async {
                            if (value == null || !value) return;

                            setState(() {
                              _medTakenStatus[doseKey] = true;
                            });

                            final dosageStr = medData['dosage'].toString();
                            await markMedicationAsTaken(doseKey, dosageStr);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text(medData['name'] ?? "Medication Info"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Dosage: ${medData['dosage']} ${medData['unit']}"),
                                  const SizedBox(height: 8),
                                  Text("Frequency: ${medData['frequency']}"),
                                  const SizedBox(height: 8),
                                  if (medData['notes'] != null &&
                                      medData['notes'].toString().isNotEmpty)
                                    Text("Notes: ${medData['notes']}"),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Close"),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
                              child: const Icon(Icons.medication,
                                  color: Colors.redAccent, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(medData['name'] ?? "Unknown",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                  Text(
                                      "${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                  if (medData['intakeAdvice'] != null &&
                                      medData['intakeAdvice']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Advice: ${medData['intakeAdvice']}",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.teal),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Frequency: ${medData['frequency'] ?? 'Specific Days'}",
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  bool isFutureDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
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

  void loadTakenMedsForToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month}-${now.day}";

    try {
      List<String> linkedUsers = await _firestoreService.getLinkedUserIds();
      print("load taken meds for $linkedUsers");

      for (String userId in linkedUsers) {
        QuerySnapshot snapshot = await _firestoreService.firestore
            .collection('users')
            .doc(userId) // 🔹 Use the correct userId (linked patient/emergency)
            .collection('medsTaken')
            .where('date', isEqualTo: todayDate)
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            for (var doc in snapshot.docs) {
              final doseKey = doc['medId'];
              _medTakenStatus[doseKey] = true;
            }
          });
        }
      }
    } catch (e) {
      print("Error loading taken medications: $e");
    }
  }

  Future<void> markMedicationAsTaken(String doseKey, String dosageStr) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month}-${now.day}";

    try {
      String? docId = await _firestoreService.saveData(
        collection: 'users/${user.uid}/medsTaken',
        data: {
          'medId': doseKey,
          'takenAt': now,
          'date': todayDate,
        },
        context: context,
      );

      if (docId == null) return;

      if (mounted) {
        setState(() {
          _medTakenStatus[doseKey] = true;
        });
      }

      final baseMedId = doseKey.contains('_') ? doseKey.split('_')[0] : doseKey;
      final medDocRef =
          FirebaseFirestore.instance.collection('meds').doc(baseMedId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final medSnapshot = await transaction.get(medDocRef);
        if (!medSnapshot.exists) return;

        final medData = medSnapshot.data() as Map<String, dynamic>;
        final currentInventory = (medData['currentInventory'] ?? 0).toDouble();
        final dosage = double.tryParse(dosageStr) ?? 0;
        final newInventory =
            (currentInventory - dosage).clamp(0, double.infinity);

        transaction.update(medDocRef, {'currentInventory': newInventory});
      });
    } catch (e) {
      print('Error updating medication: $e');
    }
  }

  Future<void> loadTakenMedsForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = "${date.year}-${date.month}-${date.day}";
    print("🔄 Loading taken meds for $dateStr");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medsTaken')
          .where('date', isEqualTo: dateStr)
          .get();

      setState(() {
        _medTakenStatus.clear();
        for (var doc in snapshot.docs) {
          final doseKey = doc['medId'];
          _medTakenStatus[doseKey] = true;
        }
      });
    } catch (e) {
      print("⚠️ Error loading taken medications for $dateStr: $e");
    }
  }

  Widget _homeScreenContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 10),
          const Text("Medications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildMedicationsList(),
          const SizedBox(height: 20),
          const Text("Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildAppointmentsWithinTwoDaysRange(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: _buildUserImage(),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildUserName()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homeScreenContent(),
          const RefillsPage(),
          const MedicationsPage(),
          ManagePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_mode), label: 'Refills'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication_liquid_outlined),
              label: 'Medications'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Manage'),
        ],
      ),
    );
  }
}
