import 'package:flutter/material.dart';
import 'package:graduation_project/Refills/refill_details.dart'; // Import RefillDetails Page

class RefillsPage extends StatefulWidget {
  const RefillsPage({super.key});

  @override
  _RefillsState createState() => _RefillsState();
}

class _RefillsState extends State<RefillsPage> {
  List<Map<String, String>> people = [
    {
      "name": "Vitamin C",
      "time": "Daily, 9 AM",
      "pills": "29 pills left",
    },
    {
      "name": "Omega 3",
      "time": "Daily, 8 AM",
      "pills": "15 pills left",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemCount: people.length,
        separatorBuilder: (context, index) => const Divider(thickness: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          var person = people[index];
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              leading: Image.asset("images/drugs.png", width: 50, height: 50, fit: BoxFit.cover),
              trailing: const Icon(Icons.notifications, size: 35),
              title: Text(
                person["name"]!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person["time"]!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(person["pills"]!, style: const TextStyle(fontSize: 14, color: Colors.blue)),
                ],
              ),
              onTap: () {
                // Navigate to RefillDetails page with medication details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RefillDetails(person: person),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
