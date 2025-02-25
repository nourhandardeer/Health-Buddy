import 'package:flutter/material.dart';

class FrequencySelectionPage extends StatefulWidget {
  const FrequencySelectionPage({Key? key}) : super(key: key);

  @override
  _FrequencySelectionPageState createState() => _FrequencySelectionPageState();
}

class _FrequencySelectionPageState extends State<FrequencySelectionPage> {
  String selectedFrequency = "";
  bool isIntervalEnabled = false;
  String intervalMode = "Every X hours";
  int intervalValue = 6;

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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOption(
              title: "Daily, X times a day",
              value: "Daily, X times a day",
            ),
            _buildOption(
              title: "Interval",
              value: "Interval",
              isInterval: true,
            ),
            if (isIntervalEnabled) _buildIntervalOptions(),
            _buildOption(
              title: "Specific days of the week",
              value: "Specific days of the week",
            ),
            _buildOption(
              title: "Cyclic mode",
              value: "Cyclic mode",
            ),
            _buildOption(
              title: "On demand (no reminder needed)",
              value: "On demand (no reminder needed)",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String value,
    bool isInterval = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        subtitle: isInterval
            ? const Text(
                "e.g. once every second day, once every 6 hours",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            : null,
        value: isInterval ? isIntervalEnabled : selectedFrequency == value,
        activeColor: Colors.green,
        onChanged: (bool isSelected) {
          setState(() {
            if (isInterval) {
              isIntervalEnabled = isSelected;
              selectedFrequency = isSelected ? value : "";
            } else {
              selectedFrequency = isSelected ? value : "";
              isIntervalEnabled = false;
            }
          });
        },
      ),
    );
  }

  Widget _buildIntervalOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Interval",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "e.g. once every second day, once every 6 hours",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildIntervalModeButton("Every X hours"),
              _buildIntervalModeButton("Every X days"),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Remind every",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 3,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      intervalValue = index + 1;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                    childCount: 24,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Text(
                  intervalMode.contains("hours") ? " hours" : " days",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalModeButton(String mode) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          intervalMode = mode;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            intervalMode == mode ? Colors.orange : Colors.grey[300],
        foregroundColor:
            intervalMode == mode ? Colors.white : Colors.grey[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(mode),
    );
  }
}
