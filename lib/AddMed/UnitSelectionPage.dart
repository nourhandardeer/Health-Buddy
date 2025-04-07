import 'package:flutter/material.dart';

class UnitSelectionPage extends StatelessWidget {
  final String initialUnit;
  final Function(String) onUnitSelected;

  UnitSelectionPage({required this.initialUnit, required this.onUnitSelected});

  final List<String> units = [
    "Pills", "Ampoules", "Tablets", "Capsules", "IU", "Application", "Drop",
    "Gram", "Injection", "Milligram", "Milliliter", "MM", "Packet", "Pessary",
    "Piece", "Portion", "Puff", "Spray", "Suppository", "Teaspoon",
    "Vaginal Capsule", "Vaginal Suppository", "Vaginal Tablet", "MG"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Unit")),
      body: ListView.builder(
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          return ListTile(
            title: Text(unit),
            trailing: unit == initialUnit
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              onUnitSelected(unit);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
