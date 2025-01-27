import 'package:flutter/material.dart';
import 'package:graduation_project/pages/add_appointment.dart';
import 'package:graduation_project/pages/add_pharmacy.dart';


class ManagePage extends StatelessWidget {
  const ManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         
          Image.asset(
            'images/photo2.png', 
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          const Text(
            ' Add your preferred pharmacy and keep track of your appointments ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,), textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))),
             ),
            onPressed: () { _showBottomSheet(context); },
            child:const Text('Start Now'),
          ),
          
          

        ],
      ),
    );
  }
}
 void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Add Appointment'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAppointment(),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.local_pharmacy),
                title: const Text('Add Pharmacy'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPharmacy(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              
              TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 10, horizontal: 20))
                ),
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 20)),
              ),
            ],
          ),
        );
      },
    );
  }
