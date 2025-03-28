import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/pages/add_appointment.dart';
import 'package:graduation_project/pages/add_pharmacy.dart';

import '../services/firestore_service.dart';

class ManagePage extends StatelessWidget {
   ManagePage({super.key});
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    void _showAppointmentDetails(BuildContext context, String doctorName,
        String doctorPhone, String specialty, String location, String notes,
        String appointmentDate, String appointmentTime) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("👨‍⚕️ $doctorName",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📅 Date: $appointmentDate",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("📝 Time: $appointmentTime",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("📞 Phone: $doctorPhone",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("🩺 Specialty: $specialty",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("📍 Location: $location",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("📝 Notes: $notes", style: const TextStyle(fontSize: 16)),

              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    "Close", style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
          child: Text("Please log in to see your appointments."));
    }
    return FutureBuilder<List<String>>(
        future: _firestoreService.getEmergencyUserIds(user.uid),
        builder: (context, linkedUsersSnapshot) {
          if (linkedUsersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (linkedUsersSnapshot.hasError || !linkedUsersSnapshot.hasData) {
            return const Center(
              child: Text(
                "Error loading user data.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          List<String> linkedUserIds = linkedUsersSnapshot.data!;
          print("DEBUG: Linked user IDs -> $linkedUserIds");
             return StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getAppointmentsStream(linkedUserIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text(
                    "Error loading appointments.",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              var hasAppointments = snapshot.hasData &&
                  snapshot.data!.docs.isNotEmpty;

              return Scaffold(
                body: hasAppointments
                    ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var appointment = snapshot.data!.docs[index];
                    String appointmentId = appointment.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.blue),
                        trailing: IconButton(onPressed: () =>
                            deleteAppointment(appointmentId, context),
                            icon: const Icon(Icons.delete, color: Colors.red,)),
                        title: Text(
                          appointment['doctorName'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Date: ${appointment['appointmentDate']} | Time: ${appointment['appointmentTime']}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          _showAppointmentDetails(
                            context,
                            appointment['doctorName'],
                            appointment['doctorPhone'],
                            appointment['specialty'],
                            appointment['location'],
                            appointment['notes'],
                            appointment['appointmentDate'],
                            appointment['appointmentTime'],
                          );
                        },
                      ),

                    );
                  },
                )
                    : _buildEmptyState(context),

                floatingActionButton: FloatingActionButton(
                  backgroundColor: Colors.blue,
                  onPressed: () => _showBottomSheet(context),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              );
            },
          );
        });
  }
 Future <void> deleteAppointment(String appointmentId, BuildContext context) async {
   try {
     User? user = FirebaseAuth.instance.currentUser;
     if (user == null) return;

     FirebaseFirestore firestore = FirebaseFirestore.instance;

     // Get the appointment document
     DocumentSnapshot appointmentSnapshot =
     await firestore.collection('appointments').doc(appointmentId).get();

     if (!appointmentSnapshot.exists) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Appointment not found')),
       );
       return;
     }
     await firestore.collection('appointments').doc(appointmentId).delete();

     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Appointment deleted successfully!'),
         backgroundColor: Colors.red,
       ),
     );
   }
   catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error: ${e.toString()}')),
     );
   }
 }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'images/photo2.png',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage your healthcare easily! Add your preferred pharmacy and track your appointments.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _showBottomSheet(context),
            child: const Text('Get Started', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose an Option',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: const Text('Add Appointment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddAppointment()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_pharmacy, color: Colors.green),
                title: const Text('Add Pharmacy'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPharmacy()),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }

}
