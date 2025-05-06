import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadImage extends StatefulWidget {
  @override
  _UploadImageState createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  String? imageUrl;

  Future<void> uploadImageToCloudinary() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    String cloudName = "defwfev8k";
    String uploadPreset = "Health_Buddy";

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resData = await response.stream.bytesToString();
      final jsonRes = json.decode(resData);
      setState(() {
        imageUrl = jsonRes['secure_url'];
      });
      print('Uploaded: ${jsonRes['secure_url']}');
    } else {
      print('Upload failed: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload to Cloudinary")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: uploadImageToCloudinary,
              child: Text("Upload Image"),
            ),
            if (imageUrl != null) Image.network(imageUrl!)
          ],
        ),
      ),
    );
  }
}
