import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart'; // Ensure this points to your NotificationService file

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String?> createUserWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone
      });

      return null; // No error, success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,

  }) async {
    UserCredential userCredential =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // **Cancel any previous notifications before scheduling new ones**
    await NotificationService.cancelAllNotifications();

    // **Fetch and schedule only the logged-in user's medication reminders**
    await _scheduleUserMedications(userCredential.user!.uid);

    return userCredential;
  }

  Future<void> signOut() async {
    // Cancel all scheduled notifications when user logs out
    await NotificationService.cancelAllNotifications();

    await _firebaseAuth.signOut();
  }

  /// **Fetch medications for the logged-in user and schedule notifications**
  Future<void> _scheduleUserMedications(String userId) async {
    print("Fetching medications for user: $userId");

    QuerySnapshot medsSnapshot = await FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: userId)
        .get();

    if (medsSnapshot.docs.isEmpty) {
      print("No medications found for user: $userId");
    } else {
      for (var doc in medsSnapshot.docs) {
        print("Med found: ${doc.data()}");
      }
    }

    for (var doc in medsSnapshot.docs) {
      Map<String, dynamic> medData = doc.data() as Map<String, dynamic>;
      print(
          "Fetched Medication: ${medData['medicationName']}, Time: ${medData['reminderTime1']}");

      if (medData.containsKey('reminderTime1')) {
        DateTime scheduledTime = _parseTime(medData['reminderTime1']);
        print("Scheduled Time: $scheduledTime");

        if (scheduledTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleNotification(
            id: doc.hashCode,
            title: "Medication Reminder",
            body: "Time to take ${medData['dosage']} ${medData['unit']} of ${medData['name']}",
            scheduledTime: scheduledTime,
            ttsMessage:
                "It is time to take your medicine. Please take ${medData['dosage']} ${medData['unit']} of ${medData['name']}.",
          );
          
          print("Notification scheduled.");
        } else {
          print("Skipped past notification.");
        }
      }
    }
  }

  /// **Converts reminder time (e.g., "08:00 AM") into a DateTime object**
  DateTime _parseTime(String timeString) {
    List<String> parts = timeString.split(" ");
    List<String> timeParts = parts[0].split(":");

    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    if (parts[1] == "PM" && hour != 12) {
      hour += 12;
    } else if (parts[1] == "AM" && hour == 12) {
      hour = 0;
    }

    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
