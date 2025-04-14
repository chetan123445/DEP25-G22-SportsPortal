import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import for file picker
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:io'; // Import for File
import 'dart:convert'; // Import for JSON encoding
import '../constants.dart'; // Import the constants file

class AddGalleryPage extends StatefulWidget {
  final String email;
  final String name;

  AddGalleryPage({required this.email, required this.name});

  @override
  _AddGalleryPageState createState() => _AddGalleryPageState();
}

class _AddGalleryPageState extends State<AddGalleryPage> {
  List<PlatformFile> selectedFiles = [];
  bool isUploading = false;

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image, // Restrict to image files
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files;
      });
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/add-image'), // Replace with your backend API URL
      );

      request.files.add(
        http.MultipartFile(
          'image', // Key for the image in the backend
          File(file.path!).readAsBytes().asStream(),
          File(file.path!).lengthSync(),
          filename: file.name,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 201) {
        print('Image uploaded successfully: ${file.name}');
      } else {
        print('Failed to upload image: ${file.name}');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> _uploadAllFiles() async {
    setState(() {
      isUploading = true;
    });

    for (var file in selectedFiles) {
      await _uploadFile(file);
    }

    setState(() {
      isUploading = false;
      selectedFiles.clear(); // Clear the list after uploading
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All files uploaded successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Gallery Pics'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Makes the text and back arrow visible
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _selectFiles,
              child: Text('Select Images'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: selectedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.image, color: Colors.white),
                    title: Text(
                      selectedFiles[index].name,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: selectedFiles.isNotEmpty ? _uploadAllFiles : null,
                    child: Text('Upload Images'),
                  ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}