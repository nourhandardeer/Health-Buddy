import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graduation_project/home.dart';

import '../EmergencyContactHelper.dart';


class ProfileSetupPage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  const ProfileSetupPage({
    Key? key,
    required this.userId,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _illnessesController = TextEditingController();
  List<Map<String, String>> emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
  }

  void _saveProfile() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = widget.userId; // Get user ID

      User? user = FirebaseAuth.instance.currentUser; // Get logged-in user
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in!')),
        );
        return;
      }
      String defaultProfileImage = "images/user.png";

      await firestore.collection('users').doc(userId).set({
        'email': user.email, // Save email
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'profileImage': _profileImage != null
            ? _profileImage!.path
            : defaultProfileImage, // Store image path or empty
        'age': _ageController.text.trim(),
        'illnesses': _illnessesController.text.trim(),
        'emergencyContacts': emergencyContacts, // Store list of contacts
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully!')),
      );

      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomeScreen()), // Ensure HomeScreen() is implemented
      );
    } catch (error) {
      print("Error saving profile: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile. Try again!")),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      print("No image selected."); // Debugging message
      return; // Stop execution if no image was picked
    }

    setState(() {
      _profileImage = File(pickedFile.path);
    });
  }

  // void _addEmergencyContact() {
  //   // showDialog(
  //   //   context: context,
  //   //   builder: (context) {
  //   //     TextEditingController nameController = TextEditingController();
  //   //     TextEditingController phoneController = TextEditingController();
  //   //     TextEditingController relationController = TextEditingController();
  //   //     return AlertDialog(
  //   //       title: Text("Add Emergency Contact"),
  //   //       content: Column(
  //   //         mainAxisSize: MainAxisSize.min,
  //   //         children: [
  //   //           TextField(
  //   //               controller: nameController,
  //   //               decoration: InputDecoration(labelText: "Name")),
  //   //           TextField(
  //   //               controller: phoneController,
  //   //               decoration: InputDecoration(labelText: "Phone"),
  //   //               keyboardType: TextInputType.phone),
  //   //           TextField(
  //   //               controller: relationController,
  //   //               decoration: InputDecoration(labelText: "Relation")),
  //   //         ],
  //   //       ),
  //   //       actions: [
  //   //         TextButton(
  //   //           onPressed: () {
  //   //             Navigator.pop(context);
  //   //           },
  //   //           child: Text("Cancel"),
  //   //         ),
  //   //         TextButton(
  //   //           onPressed: () {
  //   //             setState(() {
  //   //               emergencyContacts.add({
  //   //                 "name": nameController.text,
  //   //                 "phone": phoneController.text,
  //   //                 "relation": relationController.text,
  //   //               });
  //   //             });
  //   //             Navigator.pop(context);
  //   //           },
  //   //           child: Text("Add"),
  //   //         ),
  //   //       ],
  //   //     );
  //   //   },
  //   // );
  //   EmergencyContactHelper.addEmergencyContact(context, (newContact) async {
  //     setState(() {
  //       emergencyContacts.add(newContact);
  //     });
  //   });
  // }
  void _addEmergencyContact() {
    EmergencyContactHelper.addEmergencyContact(context, (newContact) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // Reference to the emergencyContacts subcollection
        CollectionReference emergencyContactsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emergencyContacts');

        await emergencyContactsRef.add(newContact);

        setState(() {
          emergencyContacts.add(newContact);
        });

        print("Emergency contact added successfully.");
      } catch (e) {
        print("Error adding contact: $e");
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile Setup")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) as ImageProvider
                    : AssetImage("images/user.png"), // Default profile pic
                child: _profileImage == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
                controller: _ageController,
                decoration: InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number),
            TextField(
                controller: _illnessesController,
                decoration: InputDecoration(labelText: "Illnesses"),
                maxLines: 3),
            SizedBox(height: 20),
            Text("Emergency Contacts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(emergencyContacts[index]["name"]!),
                    subtitle: Text(
                        "${emergencyContacts[index]["relation"]!} - ${emergencyContacts[index]["phone"]!}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          emergencyContacts.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addEmergencyContact,
              child: Text("Add Emergency Contact"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
