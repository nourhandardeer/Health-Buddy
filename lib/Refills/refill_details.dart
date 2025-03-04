import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RefillDetailsPage extends StatefulWidget {
  final Map<String, dynamic> medData;

  const RefillDetailsPage({Key? key, required this.medData}) : super(key: key);

  @override
  _RefillDetailsPageState createState() => _RefillDetailsPageState();
}

class _RefillDetailsPageState extends State<RefillDetailsPage> {
  Position? _currentPosition;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _openGoogleMaps() async {
    if (_currentPosition == null) return;
    String url =
        "https://www.google.com/maps/search/pharmacy/@${_currentPosition!.latitude},${_currentPosition!.longitude},14z";

    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medData["name"] ?? "Medication Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset("images/drugs.png", width: 100, height: 100),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.medical_services, "Medication",
                        widget.medData["name"] ?? "Unknown"),
                    _buildDetailRow(Icons.format_list_numbered, "Dosage",
                        widget.medData["dosage"] ?? "Not specified"),
                    _buildDetailRow(Icons.inventory, "Current Inventory",
                        "${widget.medData["currentInventory"] ?? "0"} ${widget.medData["unit"] ?? ""}"),
                    _buildDetailRow(Icons.access_time, "Reminder Time",
                        widget.medData["reminderTime"] ?? "Not set"),
                    _buildDetailRow(Icons.date_range, "Next Refill Date",
                        widget.medData["nextRefillDate"] ?? "Not available"),
                    _buildDetailRow(Icons.person, "Doctor’s Notes",
                        widget.medData["doctorNotes"] ?? "No notes available"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pharmacy Locator Section
            const Text(
              "Find a Nearby Pharmacy",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Google Map Preview
            _currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("userLocation"),
                            position: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            infoWindow: const InfoWindow(title: "You are here"),
                          ),
                        },
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // Buttons Section
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Open Google Maps"),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue),
                    onPressed: _openGoogleMaps,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.local_pharmacy),
                    label: const Text("Find a Pharmacy"),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green),
                    onPressed: _openGoogleMaps,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}





