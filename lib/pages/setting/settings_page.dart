import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/pages/EditProfilePage.dart';
import 'package:graduation_project/pages/loggin.dart';
import 'package:graduation_project/pages/splash_screen.dart';
import 'package:graduation_project/pages/EmergencyContactPage.dart';
import 'package:graduation_project/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'ChangePasswordPage.dart'; // Import the ChangePasswordPage
import 'SetPinPage.dart'; // Import the SetPinPage (you can create this page for setting the PIN)

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            trailing: Switch(value: true, onChanged: (bool value) {}),
          ),
          Divider(),

          // Emergency Contacts
          ListTile(
            leading: Icon(Icons.phone, color: Colors.red),
            title: Text('Emergency Contacts'),
            subtitle: Text('Manage emergency numbers'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EmergencyContactPage()));
            },
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
  Future<void> deleteAccountAndData(String password) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userId = user.uid;

    try {
      // 🔐 Re-authenticate user before deletion (required by Firebase)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 🗑️ 1. Delete Firestore user data
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // 🗑️ 2. Delete subcollections like emergencyContacts or medications
      final subcollections = ['emergencyContacts', 'medications'];
      for (final sub in subcollections) {
        final subDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(sub)
            .get();

        for (final doc in subDocs.docs) {
          await doc.reference.delete();
        }
      }

      // 🗑️ 3. Delete from emergency_contacts if phone is listed
      final phone = user.phoneNumber; // Or retrieve from Firestore
      if (phone != null && phone.isNotEmpty) {
        final emergencyRef = FirebaseFirestore.instance.collection('emergency_contacts').doc(phone);
        final emergencyDoc = await emergencyRef.get();
        if (emergencyDoc.exists) {
          await emergencyRef.delete();
        }
      }

      // 🔥 4. Delete from Firebase Auth
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
