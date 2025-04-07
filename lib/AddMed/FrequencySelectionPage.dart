import 'package:flutter/material.dart';

class FrequencySelectionPage extends StatefulWidget {
  final String initialFrequency;
  final List<String>? initialSpecificDays;
  final Function(Map<String, dynamic>) onSave;

  const FrequencySelectionPage({
    Key? key,
    required this.initialFrequency,
    this.initialSpecificDays,
    required this.onSave,
  }) : super(key: key);

  @override
  _FrequencySelectionPageState createState() => _FrequencySelectionPageState();
}

class _FrequencySelectionPageState extends State<FrequencySelectionPage> {
  String selectedFrequency = "";
  List<String> selectedDays = [];

  @override
  void initState() {
    super.initState();
    selectedFrequency = widget.initialFrequency;
    selectedDays = widget.initialSpecificDays ?? [];
  }

  Future<void> _showDaysOfWeekPicker() async {
    final daysOfWeek = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select days"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: daysOfWeek
                      .map((day) => CheckboxListTile(
                    title: Text(day),
                    value: selectedDays.contains(day),
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        if (value == true) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  ))
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.pop(context, selectedDays);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        selectedDays = result;
        selectedFrequency = "specific days";
      });
    } else {
      setState(() {
        selectedFrequency = "";
        selectedDays.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Frequency",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOption("once a day"),
            _buildOption("twice a day"),
            _buildOption("3 times a day"),
            _buildOption("Specific days of the week"),
            _buildOption("On demand (no reminder needed)"),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (selectedFrequency == "specific days" && selectedDays.isNotEmpty) {
              widget.onSave({"specificDays": selectedDays, "frequency": null});
            } else {
              widget.onSave({"frequency": selectedFrequency, "specificDays": null});
            }
            Navigator.pop(context);
          },
          child: const Text("Confirm"),
        ),
      ),
    );
  }

  Widget _buildOption(String value) {
    return ListTile(
      title: Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: selectedFrequency,
        onChanged: (String? newValue) async {
          if (newValue == "Specific days of the week") {
            await _showDaysOfWeekPicker();
          } else {
            setState(() {
              selectedFrequency = newValue!;
              selectedDays.clear();
              if (selectedFrequency == "once a day") {
                selectedFrequency = "once a day";
              } else if (selectedFrequency == "twice a day") {
                selectedFrequency = "twice a day";
              } else if (selectedFrequency == "3 times a day") {
                selectedFrequency = "3 times a day";
              } else if (selectedFrequency == "On demand (no reminder needed)") {
                selectedFrequency = "on demand";
              }
            });
          }
        },
      ),
    );
  }
}
