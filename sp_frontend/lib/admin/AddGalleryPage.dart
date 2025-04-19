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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('All files uploaded successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Gallery Pics'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient Circles Background
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: 50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Main Content
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade200,
                    Colors.blue.shade200,
                    Colors.pink.shade100,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Let's add more pics",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.photo_library),
                    label: Text('Select Images'),
                    onPressed: _selectFiles,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  if (selectedFiles.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(Icons.image),
                            title: Text(selectedFiles[index].name),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    isUploading
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                          icon: Icon(Icons.upload),
                          label: Text('Upload Images'),
                          onPressed: _uploadAllFiles,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
