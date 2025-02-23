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
  String? _linkedPatientName;
  String? _userId;
  List<Map<String, dynamic>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkIfEmergencyContact();
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
          _userId = user.uid;
          _fullName = "${data['firstName']} ${data['lastName']}";
          _profileImageUrl = data['profileImage'] ?? "images/user.png";
          _age = data['age'] ?? "Unknown";
          _illnesses = data['illnesses'] ?? "No illnesses specified";
        });

        _fetchEmergencyContacts(user.uid);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> _fetchEmergencyContacts(String userId) async {
    try {
      QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .get();

      List<Map<String, dynamic>> contacts = contactsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "name": data["name"] ?? "Unknown",
          "phone": data["phone"] ?? "No phone",
          "relation": data["relation"] ?? "No relation",
        };
      }).toList();

      setState(() {
        _emergencyContacts = contacts;
      });
    } catch (e) {
      print("Error fetching emergency contacts: $e");
    }
  }

  Future<void> _checkIfEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      String? userPhone = userDoc['phone'];

      if (userPhone == null || userPhone.isEmpty) {
        print("User phone number is missing.");
        return;
      }

      QuerySnapshot usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        String userId = doc.id;

        QuerySnapshot emergencyContactsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('emergencyContacts')
            .where('phone', isEqualTo: userPhone)
            .get();

        if (emergencyContactsSnapshot.docs.isNotEmpty) {
          setState(() {
            _linkedPatientName = "${doc['firstName']} ${doc['lastName']}";
          });
          return; // Stop searching once found
        }
      }
    } catch (e) {
      print("Error checking emergency contact status: $e");
    }
  }

  void _deleteEmergencyContact(Map<String, dynamic> contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergencyContacts')
          .where('phone', isEqualTo: contact['phone'])
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('emergencyContacts')
          .doc(contact['phone'])
          .delete();

      setState(() {
        _emergencyContacts.remove(contact);
      });

      print("Contact deleted successfully.");
    } catch (e) {
      print("Error deleting contact: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _profileImageUrl.startsWith('http')
                    ? NetworkImage(_profileImageUrl)
                    : AssetImage("images/user.png"),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: 16),
              Text(
                _fullName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Age: $_age | $_illnesses',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 16),
              if (_linkedPatientName != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "You are an emergency contact for **$_linkedPatientName**.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

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
                          contact["name"],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                        Text('${contact["relation"]} - ${contact["phone"]}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteEmergencyContact(contact),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
