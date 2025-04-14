import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart'; // Import the constants file

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> galleryImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGalleryImages();
  }

  Future<void> _fetchGalleryImages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-images'), // Replace with your backend API URL
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          galleryImages = data.map((image) => image['image'] as String).toList();
          isLoading = false;
        });
      } else {
        print('Failed to fetch gallery images');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching gallery images: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Makes the text and back arrow visible
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/galleryBackground.jpg', // Path to the background image
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                if (isLoading)
                  Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (galleryImages.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No images available',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of images per row
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: galleryImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showImageDialog(galleryImages[index]);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: MemoryImage(base64Decode(galleryImages[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String base64Image) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(base64Decode(base64Image)),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}