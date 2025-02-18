import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = "Loading...";
  String _profileImageUrl = "images/user.png"; // Default image
  String _age = "Unknown";
  String _illnesses = "No illnesses specified";
  List<Map<String, String>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _fullName = "${data['firstName']} ${data['lastName']}";
          _profileImageUrl = data['profileImage'] ?? "images/user.png";
          _age = data['age'] ?? "Unknown";
          _illnesses = data['illnesses'] ?? "No illnesses specified";
          _emergencyContacts = (data['emergencyContacts'] as List<dynamic>?)
                  ?.map((contact) => Map<String, String>.from(contact))
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImageUrl.startsWith('http')
                  ? NetworkImage(_profileImageUrl)
                  : AssetImage("images/user.png"),
              backgroundColor: Colors.transparent,
            ),
            SizedBox(height: 16),

            // Name
            Text(
              _fullName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),

            // Age & Health Status
            Text(
              'Age: $_age | $_illnesses',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),

            // Emergency Contact
            Text(
              'Emergency Contacts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Emergency Contacts List
            Expanded(
              child: _emergencyContacts.isEmpty
                  ? Text("No emergency contacts available.")
                  : ListView.builder(
                      itemCount: _emergencyContacts.length,
                      itemBuilder: (context, index) {
                        var contact = _emergencyContacts[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.phone, color: Colors.red),
                            title: Text(
                              contact["name"]!,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                '${contact["relation"]} - ${contact["phone"]}'),
                            trailing: IconButton(
                              icon: Icon(Icons.call, color: Colors.green),
                              onPressed: () {
                                // Add phone call functionality here
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                // SOS Alert Logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              ),
              child: Text(
                'Emergency Alert',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
