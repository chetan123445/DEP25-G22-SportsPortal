import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:convert';
import 'package:photo_view/photo_view.dart';

class ImagePreviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  ImagePreviewPage({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Preview'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          final image = images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: MemoryImage(base64Decode(image['image'])),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          );
        },
        scrollPhysics: BouncingScrollPhysics(),
        backgroundDecoration: BoxDecoration(color: Colors.black),
      ),
    );
  }
}