import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  final List<Map<String, String>> emergencyContacts = const [
    {"name": "Sara ahmed", "phone": "+20 100 567 890", "relation": "Sister"},
    {"name": "Dr. Khaled", "phone": "+20 117 654 321", "relation": "Family Doctor"},
    {"name": "Kareem Mohamed", "phone": "+20 155 123 456", "relation": "Son"},
  ];

  Widget _buildUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text(
        'Guest',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'Loading...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        } else if (snapshot.hasError) {
          return const Text(
            'Error',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        } else {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = "${data['firstName']} ${data['lastName']}";
          return Text(
            fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          );
        }
      },
    );
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
              backgroundImage: AssetImage('images/user.png'),
              backgroundColor: Colors.transparent,
            ),
            SizedBox(height: 16),

            // Name
            _buildUserName(),
            SizedBox(height: 4),

            // Age & Health Status
            Text(
              'Age: 78 | Diabetes, Hypertension',
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
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  var contact = emergencyContacts[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.phone, color: Colors.red),
                      title: Text(
                        contact["name"]!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${contact["relation"]} - ${contact["phone"]}'),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
