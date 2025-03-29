import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FrequencySelectionPage.dart'; // Import Frequency Selection Page

class MedicationDetailsPage extends StatefulWidget {
  final String medId;

  const MedicationDetailsPage({Key? key, required this.medId}) : super(key: key);

  @override
  _MedicationDetailsPageState createState() => _MedicationDetailsPageState();
}

class _MedicationDetailsPageState extends State<MedicationDetailsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? medData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicationData();
  }

  Future<void> _loadMedicationData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('meds')
          .doc(widget.medId)
          .get();
      if (snapshot.exists) {
        setState(() {
          medData = snapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          medData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error loading medication data: $e");
    }
  }

  Future<void> _updateData(String field, String newValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('meds')
          .doc(widget.medId)
          .update({field: newValue});
      setState(() {
        medData?[field] = newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$field updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error updating $field: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Dynamic

        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (medData == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text(
            "Medication not found.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              icon: Icons.calendar_today,
              title: "Frequency",
              value: "${medData!['frequency'] ?? 'N/A'}",
              field: "frequency",
              isFrequency: true,
            ),
            _buildSection(
              icon: Icons.alarm,
              title: "Reminder Time",
              value: "${medData!['reminderTime'] ?? 'N/A'}",
              field: "reminderTime",
            ),
            _buildSection(
              icon: Icons.straighten,
              title: "Unit",
              value: "${medData!['unit'] ?? 'N/A'}",
              field: "unit",
            ),
            _buildDropdownSection(
              icon: Icons.fastfood,
              title: "Intake Advice",
              field: "intakeAdvice",
              value: medData!['intakeAdvice'] ?? 'None',
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete, color: Colors.white),
          label: const Text(
            "Delete Medication",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
  void _confirmDelete() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Delete Medication"),
        content: const Text("Are you sure you want to delete this medication?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMedication(); // Call the delete function
            },
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );
}
Future<void> _deleteMedication() async {
  try {
    await FirebaseFirestore.instance
        .collection('meds')
        .doc(widget.medId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Medication deleted successfully!"),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.of(context).pop(); // Navigate back after deletion
  } catch (e) {
    print("Error deleting medication: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to delete medication."),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Widget _buildSection({
    required IconData icon,
    required String title,
    required String value,
    required String field,
    bool isFrequency = false,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blueAccent),
          onPressed: () {
            if (isFrequency) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FrequencySelectionPage(
                    initialFrequency: value,
                    onSave: (newFrequency) {
                      _updateData(field, newFrequency);
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDropdownSection({
  required IconData icon,
  required String title,
  required String field,
  required String value,
}) {
  List<String> intakeOptions = ["None", "Before Meal", "After Meal", "With Meal", "Custom"];
  
  TextEditingController customController = TextEditingController(
    text: (value == "Custom" && medData?['customIntakeAdvice'] != null)
        ? medData!['customIntakeAdvice']
        : '',
  );

  return Card(
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: DropdownButton<String>(
            value: intakeOptions.contains(value) ? value : "Custom",
            isExpanded: true,
            items: intakeOptions.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue == "Custom") {
                _showCustomInputDialog(field, customController);
              } else if (newValue != null) {
                _updateData(field, newValue);
              }
            },
          ),
        ),
        if (value == "Custom") 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              medData?['customIntakeAdvice'] ?? 'Enter your custom advice',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
      ],
    ),
  );
}
void _showCustomInputDialog(String field, TextEditingController controller) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Enter Custom Intake Advice"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Write your intake advice..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String customAdvice = controller.text.trim();
              if (customAdvice.isNotEmpty) {
                _updateData("intakeAdvice", "Custom");
                _updateData("customIntakeAdvice", customAdvice);
              }
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}


  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("Medication Details"),
      backgroundColor: Colors.white,
      elevation: 1,
    );
  }
}
