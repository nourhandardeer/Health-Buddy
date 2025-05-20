import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> updatePatientLocation() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await firestore.collection('users').doc(user.uid).update({
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      print("Patient location updated.");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  Future<String?> saveData({
    required String collection,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User not logged in'), backgroundColor: Colors.red),
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
        const SnackBar(
            content: Text('Error saving data'), backgroundColor: Colors.red),
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
    return null;
  }
  Future<List<String>> getLinkedUserIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    final Set<String> linkedUserIds = {};

    String currentUserId = user.uid;
    linkedUserIds.add(currentUserId);

    // Get phone number of the current user
    DocumentSnapshot userDoc = await firestore.collection('users').doc(currentUserId).get();
    String? phoneNumber = userDoc['phone'];

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      String? linkedPatientId = await getOriginalPatientId(phoneNumber);
      if (linkedPatientId != null) {
        linkedUserIds.add(linkedPatientId);
      }
    }
    List<String> emergencyContacts = await getEmergencyUserIds(currentUserId);
    linkedUserIds.addAll(emergencyContacts);

    return linkedUserIds.toList();
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
  Future<List<QueryDocumentSnapshot>> getAppointments(List<String> linkedUserIds) async {
    if (linkedUserIds.isEmpty) return [];

    List<QuerySnapshot> snapshots = await Future.wait(
      linkedUserIds.map((id) => firestore
          .collection('appointments')
          .where('linkedUserIds', arrayContains: id)
          .get()),
    );

    final allDocs = snapshots.expand((s) => s.docs).toList();

    // Deduplicate by document ID
    final uniqueDocs = {
      for (var doc in allDocs) doc.id: doc
    }.values.toList();

    return uniqueDocs;
  }

  // Future<List<QueryDocumentSnapshot>> getAppointments(List<String> linkedUserIds) async {
  //   if (linkedUserIds.isEmpty) {
  //     print("DEBUG: No linked users found. Skipping database query.");
  //     return [];
  //   }
  //
  //   List<QuerySnapshot> snapshots = await Future.wait(
  //     linkedUserIds.map((id) {
  //       return firestore
  //           .collection('appointments')
  //           .where('linkedUserIds', arrayContains: id)
  //           .get();
  //     }),
  //   );
  //
  //   // Flatten the results into a single list
  //   return snapshots.expand((snapshot) => snapshot.docs).toList();
  // }

  Future<List<QueryDocumentSnapshot>> getDoctors(List<String> linkedUserIds) async {
    if (linkedUserIds.isEmpty) return [];

    List<QuerySnapshot> snapshots = await Future.wait(
      linkedUserIds.map((id) => firestore
          .collection('doctors')
          .where('linkedUserIds', arrayContains: id)
          .get()),
    );

    final allDocs = snapshots.expand((s) => s.docs).toList();

    // Deduplicate by document ID
    final uniqueDocs = {
      for (var doc in allDocs) doc.id: doc
    }.values.toList();

    return uniqueDocs;
  }

  // Future<List<QueryDocumentSnapshot>> getDoctors(List<String> linkedUserIds) async {
  //   if (linkedUserIds.isEmpty) {
  //     print("DEBUG: No linked users found. Skipping database query.");
  //     return [];
  //   }
  //
  //   List<QuerySnapshot> snapshots = await Future.wait(
  //     linkedUserIds.map((id) {
  //       return firestore
  //           .collection('doctors')
  //           .where('linkedUserIds', arrayContains: id)
  //           .get();
  //     }),
  //   );
  //
  //   return snapshots.expand((snapshot) => snapshot.docs).toList();
  // }


  Future<bool> isEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is null");
      return false;
    }

    // Fetch phone number from Firestore user doc
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final phone = userDoc.data()?['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      print("Phone is null or empty from Firestore user doc: $phone");
      return false;
    }

    print("Checking emergencyContacts for doc id: $phone");
    final snapshot = await FirebaseFirestore.instance
        .collection('emergencyContacts')
        .doc(phone)
        .get();

    print("Document exists? ${snapshot.exists}");
    return snapshot.exists;
  }




}
