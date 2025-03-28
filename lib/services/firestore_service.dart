import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Saves medication or appointment data under the correct user (patient or emergency contact).
  Future<String?> saveData({
    required String collection,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
      );
      return null;
    }

    try {
      String currentUserId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      String? phoneNumber = userDoc['phone']; // Fetch user's phone number

      if (phoneNumber == null || phoneNumber.isEmpty) {
        print("DEBUG: Phone number is missing or invalid.");

      }

      String? linkedPatientId = await getOriginalPatientId(phoneNumber!);
      List<String> linkedUsers = [];
      if (linkedPatientId != null) {
        print("DEBUG: Linked patient found -> $linkedPatientId");
        //current user is emergency
        linkedUsers.add(linkedPatientId); // Add the patient ID if available
      }
      else {
        print("DEBUG: No linked patient found for phone number -> $phoneNumber");
        //current user isn't emergency
        // Fetch emergency contact IDs from subcollection or linked collection
        List<String> emergencyContactIds = await getEmergencyUserIds(currentUserId);
        linkedUsers.addAll(emergencyContactIds);
        print(emergencyContactIds);
      }
      linkedUsers.add(currentUserId); // Always add the emergency contact's ID


      // Use the patient ID if the user is an emergency contact
      String patientId = linkedPatientId ?? currentUserId;


      print("DEBUG: Final linked users -> $linkedUsers");

      // Save data with linkedUserIds array
      DocumentReference docRef = await _firestore.collection(collection).add({
        ...data,
        'linkedUserIds': linkedUsers, // Store both patient and emergency contacts
        'linkedFrom': patientId,   // Store the original patient ID
        'createdBy': currentUserId,  // Track who added the data
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print("Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  /// 🔹 Finds the original patient's ID if the logged-in user is an emergency contact.
  Future<String?> getOriginalPatientId(String emergencyContactPhone) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('emergencyContacts')
          .where('phone', isEqualTo: emergencyContactPhone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['linkedPatientId'];
      }
    } catch (e) {
      print("Error fetching original patient ID: $e");
    }
    return null; // No linked patient found
  }
  Future<List<String>> getEmergencyUserIds(String patientId) async {
    List<String> emergencyContactUserIds = [patientId];
    try {
      // Fetch emergency contacts from user's subcollection
      QuerySnapshot emergencyContactsSnapshot = await _firestore
          .collection('users')
          .doc(patientId)
          .collection('emergencyContacts')
          .get();

      for (var doc in emergencyContactsSnapshot.docs) {
        String phoneNumber = doc['phone'];

        // Find the user ID of the emergency contact
        QuerySnapshot userSnapshot = await _firestore
            .collection('users')
            .where('phone', isEqualTo: phoneNumber)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          emergencyContactUserIds.add(userSnapshot.docs.first.id);
        }
      }
    } catch (e) {
      print("Error fetching emergency contact IDs -> $e");
    }
    return emergencyContactUserIds;
  }
  Future<QuerySnapshot> getMedications(List<String> linkedUserIds) {
    return _firestore
        .collection('meds')
        .where('linkedUserIds', arrayContainsAny: linkedUserIds)
        .get();
  }
  Stream<QuerySnapshot> getAppointmentsStream(List<String> linkedUserIds) {
    if (linkedUserIds.isEmpty) {
      print("DEBUG: No linked users found. Skipping database query.");
      return const Stream.empty();
    }

    List<Stream<QuerySnapshot>> streams = linkedUserIds.map((id) {
      return _firestore
          .collection('appointments')
          .where('linkedUserIds', arrayContains: id)
          .snapshots();
    }).toList();

    print("DEBUG: Fetching appointments separately for each linked user.");

    return Stream.fromIterable(streams).asyncExpand((event) => event);
  }

}