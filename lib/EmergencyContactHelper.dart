import 'package:flutter/material.dart';

class EmergencyContactHelper {
  static void addEmergencyContact(
      BuildContext context,
      Function(Map<String, String>) onContactAdded,
      ) {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController relationController = TextEditingController();
    TextEditingController mailController = TextEditingController();


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Emergency Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: relationController,
                decoration: InputDecoration(labelText: "Relation"),
              ),
              TextField(
                controller: mailController,
                decoration: InputDecoration(labelText: "mail"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Map<String, String> newContact = {
                  "name": nameController.text,
                  "phone": phoneController.text,
                  "relation": relationController.text,
                  "mail": mailController.text
                };
                onContactAdded(newContact);
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }
}
