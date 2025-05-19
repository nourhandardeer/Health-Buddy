import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_buddy/pages/EditProfilePage.dart';
import 'package:health_buddy/pages/loggin.dart';
import 'package:health_buddy/pages/splash_screen.dart';
import 'package:health_buddy/pages/EmergencyContactPage.dart';
import 'package:health_buddy/services/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import 'ChangePasswordPage.dart'; // Import the ChangePasswordPage
import 'SetPinPage.dart'; // Import the SetPinPage (you can create this page for setting the PIN)
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences


class SettingsPage extends StatefulWidget  {
  const SettingsPage({super.key});

   @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isEmergency = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _checkIfEmergencyContact();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }
  Future<void> _checkIfEmergencyContact() async {
    bool isEmergency = await FirestoreService().isEmergencyContact();
    setState(() {
      _isEmergency = isEmergency;

    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notifications_enabled', value);
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Section
          ListTile(
            leading: Icon(Icons.person, color: Colors.blue),
            title: Text('Edit Profile'),
            subtitle: Text('Change name, email, and photo'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()));
            },
          ),
          Divider(),

          // Notification Settings
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.orange),
            title: Text('Notifications'),
            subtitle: Text('Manage alerts and reminders'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (bool value) {
                _toggleNotifications(value);
              },
            ),
          ),
          Divider(),

          // Emergency Contacts
          ListTile(
            leading: Icon(Icons.phone, color: Colors.red),
            title: Text('Emergency Contacts'),
            subtitle: Text('Manage emergency numbers'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (_isEmergency) {
                // Show alert dialog
                showDialog(
                  context: context,
                  builder: (context) =>
                      AlertDialog(
                        title: Text('Action not allowed'),
                        content: Text(
                            'You cannot add emergency contacts because you are already an emergency contact.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                );
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EmergencyContactPage()));
              };
            }

          ),
          Divider(),

          // Security Settings (Change Password or Set PIN)
          ListTile(
            leading: Icon(Icons.lock, color: Colors.purple),
            title: Text('Security'),
            subtitle: Text('Change password or set PIN'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showSecurityOptions(context);
            },
          ),
          Divider(),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(Icons.dark_mode, color: Colors.black),
            title: Text('Dark Mode'),
            trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                }),
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Delete my account'),
            onTap: () async {
              final passwordController = TextEditingController();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Account Deletion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Please enter your password to delete your account.'),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await deleteAccountAndData(passwordController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully')),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incorrect password')),
                  );
                }
              }
            },

          ),
          Divider(),

          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () async {
              // Sign out from Firebase
              await FirebaseAuth.instance.signOut();
              // Navigate to the login screen after signing out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
        ],
      ),

    );
  }
  // Future<void> deleteAccountAndData(String password) async {
  //   final user = FirebaseAuth.instance.currentUser;
  //
  //   if (user == null) return;
  //
  //   final userId = user.uid;
  //
  //   try {
  //     final credential = EmailAuthProvider.credential(
  //       email: user.email!,
  //       password: password,
  //     );
  //     await user.reauthenticateWithCredential(credential);
  //
  //     await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  //
  //
  //     final subcollections = ['emergencyContacts'];
  //     for (final sub in subcollections) {
  //       final subDocs = await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(userId)
  //           .collection(sub)
  //           .get();
  //
  //       for (final doc in subDocs.docs) {
  //         await doc.reference.delete();
  //       }
  //     }
  //     DocumentSnapshot userDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();
  //     if (!userDoc.exists || userDoc['phone'] == null) return;
  //     String phone = userDoc['phone'];
  //     if (phone != null && phone.isNotEmpty) {
  //       final emergencyRef = FirebaseFirestore.instance.collection('emergencyContacts').doc(phone);
  //       final emergencyDoc = await emergencyRef.get();
  //       if (emergencyDoc.exists) {
  //         await emergencyRef.delete();
  //       }
  //     }
  //     final medsQuery = await FirebaseFirestore.instance.collection('meds').get();
  //     for (final doc in medsQuery.docs) {
  //       final data = doc.data();
  //       final List<dynamic>? linkedUserIds = data['linkedUserIds'];
  //       if (linkedUserIds != null && linkedUserIds.contains(userId)) {
  //         // Option 1: Remove the userId from the array
  //         await doc.reference.update({
  //           'linkedUserIds': FieldValue.arrayRemove([userId])
  //         });
  //
  //         // Option 2 (optional): If array becomes empty, delete the document
  //         final updatedDoc = await doc.reference.get();
  //         final updatedLinkedUserIds = updatedDoc.data()?['linkedUserIds'];
  //         if (updatedLinkedUserIds == null || updatedLinkedUserIds.isEmpty) {
  //           await doc.reference.delete();
  //         }
  //       }
  //     }
  //
  //     // 🔥 4. Delete from Firebase Auth
  //     await user.delete();
  //
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'requires-recent-login') {
  //       throw Exception('Please log in again to delete your account.');
  //     } else {
  //       throw Exception('Failed to delete account: ${e.message}');
  //     }
  //   } catch (e) {
  //     throw Exception('Unexpected error: $e');
  //   }
  // }
  Future<void> deleteAccountAndData(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      // 🔐 Reauthenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 📄 Get user document & phone
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      final userData = userDoc.data();
      final phone = userData?['phone'];

      // 🧹 1. Delete from emergencyContacts subcollection by phone
      if (phone != null && phone.toString().isNotEmpty) {
        final contactsQuery = await userDocRef
            .collection('emergencyContacts')
            .where('phone', isEqualTo: phone)
            .get();

        for (final doc in contactsQuery.docs) {
          await doc.reference.delete();
        }
      }

      // 🧹 2. Delete from medsTaken subcollection (clean linkedUserIds)
      final medsTakenDocs = await userDocRef.collection('medsTaken').get();
      for (final doc in medsTakenDocs.docs) {
        final data = doc.data();
        final List<dynamic>? linkedUserIds = data['linkedUserIds'];

        if (linkedUserIds != null && linkedUserIds.contains(userId)) {
          await doc.reference.update({
            'linkedUserIds': FieldValue.arrayRemove([userId]),
          });

          final updatedDoc = await doc.reference.get();
          final updatedLinkedUserIds = updatedDoc.data()?['linkedUserIds'];
          if (updatedLinkedUserIds == null || updatedLinkedUserIds.isEmpty) {
            await doc.reference.delete();
          }
        } else {
          await doc.reference.delete();
        }
      }

      // 🗑️ 3. Delete user document
      await userDocRef.delete();

      // 🗑️ 4. Delete from top-level emergencyContacts/{phone}
      if (phone != null && phone.toString().isNotEmpty) {
        final emergencyRef = FirebaseFirestore.instance.collection('emergencyContacts').doc(phone.toString());
        final emergencyDoc = await emergencyRef.get();
        if (emergencyDoc.exists) {
          await emergencyRef.delete();
        }
      }

      // 🧹 5. Clean top-level meds, doctors, appointments
      final topLevelCollections = ['meds', 'doctors', 'appointments'];
      for (final collectionName in topLevelCollections) {
        final querySnapshot = await FirebaseFirestore.instance.collection(collectionName).get();
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final List<dynamic>? linkedUserIds = data['linkedUserIds'];

          if (linkedUserIds != null && linkedUserIds.contains(userId)) {
            await doc.reference.update({
              'linkedUserIds': FieldValue.arrayRemove([userId]),
            });

            final updatedDoc = await doc.reference.get();
            final updatedLinkedUserIds = updatedDoc.data()?['linkedUserIds'];
            if (updatedLinkedUserIds == null || updatedLinkedUserIds.isEmpty) {
              await doc.reference.delete();
            }
          }
        }
      }

      // 🔥 6. Delete Firebase Auth user
      await user.delete();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please log in again to delete your account.');
      } else {
        throw Exception('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }


  // Function to show the Security options dialog
  void _showSecurityOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.lock_open, color: Colors.blue),
              title: Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.pin, color: Colors.green),
              title: Text('Set PIN'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetPinPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
