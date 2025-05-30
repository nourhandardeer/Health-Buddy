import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

        final user = _firebaseAuth.currentUser;

        if (user != null ) {
          // Save user data to Firestore
          await saveUserToFirestore(
            uid: user.uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
          );

          // Schedule notifications for user’s medications
          await _scheduleUserAppointment(user.uid);

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

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,

  }) async {
    UserCredential userCredential =
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );


    // **Fetch and schedule only the logged-in user's medication reminders**
    await _scheduleUserAppointment(userCredential.user!.uid);

    return userCredential;
  }

  /// Sign out and cancel any pending notifications
  Future<void> signOut() async {
    
    await NotificationService.cancelAllNotifications();
    print("🔔 Attempting to cancel tracked notifications...");
    await NotificationService.cancelTrackedNotifications();
  
    await _firebaseAuth.signOut();
    print("👤 User signed out and all notifications cleared.");
  }

  /// Schedule notifications for the logged-in user’s appointments
  Future<void> _scheduleUserAppointment(String userId) async {
  final appointmentSnapshot = await FirebaseFirestore.instance
      .collection('appointments')
      .where('linkedUserIds', arrayContains: userId)
      .get();

  for (final doc in appointmentSnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;

    if (data.containsKey('appointmentDate') && data.containsKey('appointmentTime')) {
      try {
        final String dateStr = data['appointmentDate']; // e.g., '2025-05-28'
        final String timeStr = data['appointmentTime'];  // e.g., '11:40 PM'

        // Combine and parse date + time
        final DateTime appointmentDateTime = DateFormat('yyyy-MM-dd hh:mm a')
            .parse('$dateStr $timeStr');

        final DateTime reminderTime = appointmentDateTime.subtract(const Duration(minutes: 60));

        if (reminderTime.isAfter(DateTime.now())) {
          final String doctorName = data['doctorName'] ?? 'Unknown';

          await NotificationService.scheduleNotification(
            id: appointmentDateTime.millisecondsSinceEpoch.remainder(100000),
            title: 'Appointment Reminder',
            bodyEn: 'You have an appointment with Dr. $doctorName at $timeStr',
            bodyAr: 'لديك موعد مع الدكتور $doctorName في الساعة $timeStr',
            scheduledTime: reminderTime,
            ttsMessageEn: 'Reminder! Appointment with Dr. $doctorName at $timeStr.',
            ttsMessageAr: 'تذكير! لديك موعد مع الدكتور $doctorName في الساعة $timeStr.',
          );
        }
      } catch (e) {
        print('Failed to parse appointment: $e');
      }
    }
  }
}


  /// Convert time string like "08:00 AM" to today's DateTime
 /* DateTime _parseTime(String timeString) {
    final parts = timeString.split(" ");
    final timeParts = parts[0].split(":");

    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    if (parts[1] == "PM" && hour != 12) hour += 12;
    if (parts[1] == "AM" && hour == 12) hour = 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }*/
}
