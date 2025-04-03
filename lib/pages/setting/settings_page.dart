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
