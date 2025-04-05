import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      List<String> linkedUsers = await getLinkedUserIds();
      String patientId = linkedUsers.first; // Use first ID as patientId
      print(linkedUsers);
      // Save data with linkedUserIds array
      DocumentReference docRef = await firestore.collection(collection).add({
        ...data,
        'linkedUserIds': linkedUsers,
        'linkedFrom': patientId,
        'createdBy': user.uid,
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


  Future<String?> getOriginalPatientId(String emergencyContactPhone) async {
    try {
      QuerySnapshot querySnapshot = await firestore
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

  Future<List<String>> getLinkedUserIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    String currentUserId = user.uid;
    DocumentSnapshot userDoc = await firestore.collection('users').doc(currentUserId).get();
    String? phoneNumber = userDoc['phone'];

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print("DEBUG: Phone number missing for user -> $currentUserId");
      return [currentUserId];
    }

    String? linkedPatientId = await getOriginalPatientId(phoneNumber);
    if (linkedPatientId != null) {
      print("DEBUG: User is an emergency contact. Linked patient -> $linkedPatientId");
      return [linkedPatientId, currentUserId];
    }

    return await getEmergencyUserIds(currentUserId);
  }

  Future<List<String>> getEmergencyUserIds(String patientId) async {
    List<String> emergencyContactUserIds = [patientId];
    try {
      // Fetch emergency contacts from user's subcollection
      QuerySnapshot emergencyContactsSnapshot = await firestore
          .collection('users')
          .doc(patientId)
          .collection('emergencyContacts')
          .get();

      for (var doc in emergencyContactsSnapshot.docs) {
        String phoneNumber = doc['phone'];

        // Find the user ID of the emergency contact
        QuerySnapshot userSnapshot = await firestore
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
    return firestore
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
      return firestore
          .collection('appointments')
          .where('linkedUserIds', arrayContains: id)
          .snapshots();
    }).toList();

    print("DEBUG: Fetching appointments separately for each linked user.");

    return Stream.fromIterable(streams).asyncExpand((event) => event);
  }

}