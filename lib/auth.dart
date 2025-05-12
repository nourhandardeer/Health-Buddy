// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/notification_service.dart'; // Ensure this points to your NotificationService file
//
// class Auth {
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//
//   User? get currentUser => _firebaseAuth.currentUser;
//   Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
//
//   Future<String?> createUserWithEmailAndPassword({
//     required String firstName,
//     required String lastName,
//     required String email,
//     required String password,
//     required String phone,
//   }) async {
//     try {
//       UserCredential userCredential =
//           await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       await userCredential.user?.sendEmailVerification();
//       // Save user data to Firestore
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .set({
//         'firstName': firstName,
//         'lastName': lastName,
//         'email': email,
//         'phone': phone
//       });
//
//       return null; // No error, success
//     } on FirebaseAuthException catch (e) {
//       return e.message; // Return error message
//     }
//   }
//
//   Future<UserCredential> signInWithEmailAndPassword({
//     required String email,
//     required String password,
//     required String phone,
//   }) async {
//     UserCredential userCredential =
//         await _firebaseAuth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     if (!userCredential.user!.emailVerified) {
//       await FirebaseAuth.instance.signOut();
//       throw FirebaseAuthException(
//         code: 'email-not-verified',
//         message: 'Please verify your email before logging in.',
//
//       );
//     }
//
//     // **Cancel any previous notifications before scheduling new ones**
//     await NotificationService.cancelAllNotifications();
//
//     // **Fetch and schedule only the logged-in user's medication reminders**
//     await _scheduleUserMedications(userCredential.user!.uid);
//
//     return userCredential;
//   }
//
//   Future<void> signOut() async {
//     // Cancel all scheduled notifications when user logs out
//     await NotificationService.cancelAllNotifications();
//
//     await _firebaseAuth.signOut();
//   }
//
//   /// **Fetch medications for the logged-in user and schedule notifications**
//   Future<void> _scheduleUserMedications(String userId) async {
//     print("Fetching medications for user: $userId");
//
//     QuerySnapshot medsSnapshot = await FirebaseFirestore.instance
//         .collection('meds')
//         .where('linkedUserIds', arrayContains: userId)
//         .get();
//
//     if (medsSnapshot.docs.isEmpty) {
//       print("No medications found for user: $userId");
//     } else {
//       for (var doc in medsSnapshot.docs) {
//         print("Med found: ${doc.data()}");
//       }
//     }
//
//     for (var doc in medsSnapshot.docs) {
//       Map<String, dynamic> medData = doc.data() as Map<String, dynamic>;
//       print(
//           "Fetched Medication: ${medData['medicationName']}, Time: ${medData['reminderTime1']}");
//
//       if (medData.containsKey('reminderTime1')) {
//         DateTime scheduledTime = _parseTime(medData['reminderTime1']);
//         print("Scheduled Time: $scheduledTime");
//
//         if (scheduledTime.isAfter(DateTime.now())) {
//           await NotificationService.scheduleNotification(
//             id: doc.hashCode,
//             title: "Medication Reminder",
//             body: "Time to take ${medData['dosage']} ${medData['unit']} of ${medData['name']}",
//             scheduledTime: scheduledTime,
//             ttsMessage:
//                 "It is time to take your medicine. Please take ${medData['dosage']} ${medData['unit']} of ${medData['name']}.",
//           );
//
//           print("Notification scheduled.");
//         } else {
//           print("Skipped past notification.");
//         }
//       }
//     }
//   }
//
//   /// **Converts reminder time (e.g., "08:00 AM") into a DateTime object**
//   DateTime _parseTime(String timeString) {
//     List<String> parts = timeString.split(" ");
//     List<String> timeParts = parts[0].split(":");
//
//     int hour = int.parse(timeParts[0]);
//     int minute = int.parse(timeParts[1]);
//
//     if (parts[1] == "PM" && hour != 12) {
//       hour += 12;
//     } else if (parts[1] == "AM" && hour == 12) {
//       hour = 0;
//     }
//
//     DateTime now = DateTime.now();
//     return DateTime(now.year, now.month, now.day, hour, minute);
//   }
// }

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/notification_service.dart';
//
// class Auth {
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
//
//   User? get currentUser => _firebaseAuth.currentUser;
//   Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
//
//   /// Creates a new user account and sends email verification.
//   /// Firestore data should be saved after email verification.
//   Future<String?> createUserWithEmailAndPassword({
//     required String firstName,
//     required String lastName,
//     required String email,
//     required String password,
//     required String phone,
//   }) async {
//     try {
//       UserCredential userCredential =
//       await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       await userCredential.user?.sendEmailVerification();
//
//       // Do not write to Firestore here. Wait until email is verified.
//       return null;
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     }
//   }
//
//   /// Call this after verifying that the email has been confirmed
//   Future<void> saveUserToFirestore({
//     required String uid,
//     required String firstName,
//     required String lastName,
//     required String email,
//     required String phone,
//   }) async {
//     await FirebaseFirestore.instance.collection('users').doc(uid).set({
//       'firstName': firstName,
//       'lastName': lastName,
//       'email': email,
//       'phone': phone,
//     });
//   }
//
//   /// Signs in the user, verifies email status, and schedules medication reminders
//   Future<UserCredential> signInWithEmailAndPassword({
//     required String email,
//     required String password,
//     required String phone,
//   }) async {
//     UserCredential userCredential =
//     await _firebaseAuth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//
//     if (!userCredential.user!.emailVerified) {
//       await _firebaseAuth.signOut();
//       throw FirebaseAuthException(
//         code: 'email-not-verified',
//         message: 'Please verify your email before logging in.',
//       );
//     }
//
//     // Cancel any previous notifications before scheduling new ones
//     await NotificationService.cancelAllNotifications();
//
//     // Fetch and schedule the logged-in user's medication reminders
//     await _scheduleUserMedications(userCredential.user!.uid);
//
//     return userCredential;
//   }
//
//   /// Signs out the current user and cancels all notifications
//   Future<void> signOut() async {
//     await NotificationService.cancelAllNotifications();
//     await _firebaseAuth.signOut();
//   }
//
//   /// Fetch medications for the user and schedule notifications
//   Future<void> _scheduleUserMedications(String userId) async {
//     print("Fetching medications for user: $userId");
//
//     QuerySnapshot medsSnapshot = await FirebaseFirestore.instance
//         .collection('meds')
//         .where('linkedUserIds', arrayContains: userId)
//         .get();
//
//     if (medsSnapshot.docs.isEmpty) {
//       print("No medications found for user: $userId");
//     } else {
//       for (var doc in medsSnapshot.docs) {
//         Map<String, dynamic> medData = doc.data() as Map<String, dynamic>;
//         print(
//             "Fetched Medication: ${medData['medicationName']}, Time: ${medData['reminderTime1']}");
//
//         if (medData.containsKey('reminderTime1')) {
//           DateTime scheduledTime = _parseTime(medData['reminderTime1']);
//           print("Scheduled Time: $scheduledTime");
//
//           if (scheduledTime.isAfter(DateTime.now())) {
//             await NotificationService.scheduleNotification(
//               id: doc.hashCode,
//               title: "Medication Reminder",
//               body:
//               "Time to take ${medData['dosage']} ${medData['unit']} of ${medData['name']}",
//               scheduledTime: scheduledTime,
//               ttsMessage:
//               "It is time to take your medicine. Please take ${medData['dosage']} ${medData['unit']} of ${medData['name']}.",
//             );
//             print("Notification scheduled.");
//           } else {
//             print("Skipped past notification.");
//           }
//         }
//       }
//     }
//   }
//
//   /// Converts a 12-hour time string like "08:00 AM" into a DateTime object for today
//   DateTime _parseTime(String timeString) {
//     List<String> parts = timeString.split(" ");
//     List<String> timeParts = parts[0].split(":");
//
//     int hour = int.parse(timeParts[0]);
//     int minute = int.parse(timeParts[1]);
//
//     if (parts[1] == "PM" && hour != 12) {
//       hour += 12;
//     } else if (parts[1] == "AM" && hour == 12) {
//       hour = 0;
//     }
//
//     DateTime now = DateTime.now();
//     return DateTime(now.year, now.month, now.day, hour, minute);
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Create account and send verification email (Firestore write happens later)
  Future<String?> createUserWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();
      /// Call this after verifying the user's email
      Future<void> verifyAndCompleteSetup({
        required String firstName,
        required String lastName,
        required String email,
        required String phone,
      }) async {
        final user = _firebaseAuth.currentUser;

        if (user != null && user.emailVerified) {
          // Save user data to Firestore
          await saveUserToFirestore(
            uid: user.uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
          );

          // Schedule notifications for user’s medications
          await _scheduleUserMedications(user.uid);

          // Navigate to home page or main screen
          // Example:
          // Navigator.pushReplacementNamed(context, '/home');
        } else {
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before completing the setup.',
          );
        }
      }

      // Return the user credential so the app can navigate to the email verification screen
      return null;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    }
  }

  /// Call this only after verifying that the user’s email is verified
  Future<void> saveUserToFirestore({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    });
  }

  /// Sign in, check email verification, and schedule reminders
  // Future<UserCredential> signInWithEmailAndPassword({
  //   required String email,
  //   required String password,
  //   required String phone,
  //
  // }) async {
  //   final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
  //     email: email,
  //     password: password,
  //   );
  //
  //   if (!userCredential.user!.emailVerified) {
  //     await _firebaseAuth.signOut();
  //     throw FirebaseAuthException(
  //       code: 'email-not-verified',
  //       message: 'Please verify your email before logging in.',
  //     );
  //   }
  //
  //   // Cancel old notifications before setting new ones
  //   await NotificationService.cancelAllNotifications();
  //   await _scheduleUserMedications(userCredential.user!.uid);
  //
  //   return userCredential;
  // }
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

  /// Sign out and cancel any pending notifications
  Future<void> signOut() async {
    await NotificationService.cancelAllNotifications();
    await _firebaseAuth.signOut();
  }

  /// Schedule notifications for the logged-in user’s medications
  Future<void> _scheduleUserMedications(String userId) async {
    final medsSnapshot = await FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: userId)
        .get();

    for (final doc in medsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data.containsKey('reminderTime1')) {
        final DateTime scheduledTime = _parseTime(data['reminderTime1']);

        if (scheduledTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleNotification(
            id: doc.hashCode,
            title: "Medication Reminder",
            body: "Time to take ${data['dosage']} ${data['unit']} of ${data['name']}",
            scheduledTime: scheduledTime,
            ttsMessage:
            "It is time to take your medicine. Please take ${data['dosage']} ${data['unit']} of ${data['name']}.",
          );
        }
      }
    }
  }

  /// Convert time string like "08:00 AM" to today's DateTime
  DateTime _parseTime(String timeString) {
    final parts = timeString.split(" ");
    final timeParts = parts[0].split(":");

    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    if (parts[1] == "PM" && hour != 12) hour += 12;
    if (parts[1] == "AM" && hour == 12) hour = 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
