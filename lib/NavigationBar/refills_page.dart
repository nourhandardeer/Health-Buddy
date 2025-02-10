import 'package:flutter/material.dart';


class RefillsPage extends StatefulWidget {
  _RefillsState createState() => _RefillsState();
}

var size, height, width;

class _RefillsState extends State<RefillsPage> {
  List<Map<String, String>> people = [
    {
      "name": "Vitamin C",
      "time": "Daily, 9 AM",
      "pills": "29 pills left",
    },
    {
      "name": "Vitamin C",
      "time": "Daily, 9 AM",
      "pills": "29 pills left",
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
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
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => refill_details(person: person),
                //   ),
                // );
              },
            ),
          );
        },
            ),
          );
       // },
     // ),


    
  }
}

