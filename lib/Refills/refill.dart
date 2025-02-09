import 'package:flutter/material.dart';
import 'package:graduation_project/NavigationBar/home_page.dart';
import 'package:graduation_project/NavigationBar/medications_page.dart';
import 'package:graduation_project/NavigationBar/manage_page.dart';
import 'package:graduation_project/Refills/refill_details.dart'; // Import the new page

class RefillPage extends StatefulWidget {
  const RefillPage({super.key});

  @override
  _RefillPageState createState() => _RefillPageState();
}

class _RefillPageState extends State<RefillPage> {
  int _selectedIndex = 1; // Default index for the RefillsPage
  List<Map<String, String>> people = [
    {
      "name": "Vitamin C",
      "time": "Daily, 9 AM",
      "pills": "29 pills left",
    },
    {
      "name": "Vitamin ",
      "time": "Daily, 9 AM",
      "pills": "29 pills left",
    },
  ];
  // List of pages for the bottom navigation bar
  final List<Widget> _pages = [
    const HomePage(),
    const MedicationsPage(), // Ensure these pages are correctly defined elsewhere in your project
    const ManagePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      // Column(
      //   children: [
      //     // Full-width Box acting as a button to navigate to RefillDetails
      //     GestureDetector(
      //       onTap: () {
      //         // Navigate to the RefillDetails page when the box is tapped
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => const RefillDetails()),
      //         );
      //       },
      //       child: Container(
      //         width: double.infinity,  // Ensures the container takes the full screen width
      //         padding: const EdgeInsets.all(16.0),
      //         color: Colors.grey[200],
      //         child: const Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               "Medication name",
      //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      //             ),
      //             SizedBox(height: 8),
      //             Text(
      //               "Time",
      //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      //             ),
      //             SizedBox(height: 8),
      //             Text(
      //               "Number of pills",
      //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      //             ),
      //             SizedBox(height: 16),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
      ListView.separated(
        itemCount: people.length,
        separatorBuilder: (context, index) => Divider(thickness: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          var person = people[index];
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              leading: Image.asset("images/drugs.png"),
              trailing: const Icon(Icons.notifications, size: 35,) ,
              title: Text(
                person["name"]!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Text(person["time"]!, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(person["pills"]!, style: TextStyle(fontSize: 14, color: Colors.blue)),
                ],
              ),
              onTap: () {
                Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RefillDetails(person: person)),
                            );
              },
            ),
          );
        },
      ),
    );
  }
}

