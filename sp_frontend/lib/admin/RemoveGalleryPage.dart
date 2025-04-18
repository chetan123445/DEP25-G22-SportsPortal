import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:sp_frontend/admin/ImagePreviewPage.dart';

class RemoveGalleryPage extends StatefulWidget {
  final String email;
  final String name;

  RemoveGalleryPage({required this.email, required this.name});

  @override
  _RemoveGalleryPageState createState() => _RemoveGalleryPageState();
}

class _RemoveGalleryPageState extends State<RemoveGalleryPage> {
  List<Map<String, dynamic>> images = [];
  List<String> selectedImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-images'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          images =
              data.map((e) => {'id': e['id'], 'image': e['image']}).toList();
          isLoading = false;
        });
      } else {
        print('Failed to fetch images');
      }
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  Future<void> _deleteImages() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete-images'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageIds': selectedImages}),
      );

      if (response.statusCode == 200) {
        setState(() {
          images.removeWhere((image) => selectedImages.contains(image['id']));
          selectedImages.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected images deleted successfully!')),
        );
      } else {
        print('Failed to delete images');
      }
    } catch (e) {
      print('Error deleting images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remove Gallery Images'),
        backgroundColor: Colors.black,
        foregroundColor:
            Colors.white, // Ensures the back icon and text are visible
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final image = images[index];
                        final isSelected = selectedImages.contains(image['id']);
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ImagePreviewPage(
                                      images: images,
                                      initialIndex: index,
                                    ),
                              ),
                            );
                          },
                          onLongPress: () {
                            setState(() {
                              if (isSelected) {
                                selectedImages.remove(image['id']);
                              } else {
                                selectedImages.add(image['id']);
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.red
                                            : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.memory(
                                  base64Decode(image['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: selectedImages.isNotEmpty ? _deleteImages : null,
                    child: Text('Delete Selected Images'),
                  ),
                ],
              ),
      backgroundColor: Colors.black,
    );
  }
}
