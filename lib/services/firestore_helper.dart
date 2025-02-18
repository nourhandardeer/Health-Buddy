import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreHelper {
  // Get the ID of the patient linked to the emergency contact
  static Future<String?> getLinkedPatientId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('emergencyContacts', arrayContains: {'email': user.email})
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Return the patient’s user ID
      }
    } catch (e) {
      print("Error fetching linked patient: $e");
    }

    return null;
  }
}
