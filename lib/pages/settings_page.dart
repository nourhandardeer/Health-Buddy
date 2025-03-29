import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/pages/EditProfilePage.dart';
import 'package:graduation_project/pages/loggin.dart';
import 'package:graduation_project/pages/splash_screen.dart';
import 'EmergencyContactPage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage()));

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
              Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyContactPage()));

            },
          ),
          Divider(),

          // Security Settings
          ListTile(
            leading: Icon(Icons.lock, color: Colors.purple),
            title: Text('Security'),
            subtitle: Text('Change password, set PIN'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to security settings
            },
          ),
          Divider(),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(Icons.dark_mode, color: Colors.black),
            title: Text('Dark Mode'),
            trailing: Switch(value: false, onChanged: (bool value) {}),
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
}

