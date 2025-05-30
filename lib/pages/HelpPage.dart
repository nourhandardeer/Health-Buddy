import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HelpPage extends StatelessWidget {
  final List<Map<String, String>> helpVideos = [
    {'title': 'Add Appointment', 'path': 'videos/addAppointment.mp4'},
    {'title': 'Add Doctor', 'path': 'videos/addDoctor.mp4'},
    {'title': 'Add Emergency Contact', 'path': 'videos/addEmergencyContact.mp4'},
    {'title': 'Add Medicine', 'path': 'videos/addMed.mp4'},
    {'title': 'Find A Nearby Pharmacy', 'path': 'videos/requestPharmacy.mp4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView.builder(
        itemCount: helpVideos.length,
        itemBuilder: (context, index) {
          return HelpVideoTile(
            title: helpVideos[index]['title']!,
            videoPath: helpVideos[index]['path']!,
          );
        },
      ),
    );
  }
}

class HelpVideoTile extends StatefulWidget {
  final String title;
  final String videoPath;

  const HelpVideoTile({
    Key? key,
    required this.title,
    required this.videoPath,
  }) : super(key: key);

  @override
  _HelpVideoTileState createState() => _HelpVideoTileState();
}

class _HelpVideoTileState extends State<HelpVideoTile> {
  late VideoPlayerController _controller;
  bool _isExpanded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _isInitialized) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
              if (_isExpanded && _isInitialized) ...[
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: VideoPlayer(_controller),
                  ),
                ),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.only(top: 8),
                  colors: VideoProgressColors(
                    playedColor: Colors.teal,
                    bufferedColor: Colors.teal.shade100,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ] else if (_isExpanded && !_isInitialized) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
