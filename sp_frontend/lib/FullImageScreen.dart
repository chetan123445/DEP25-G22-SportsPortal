import 'package:flutter/material.dart';

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Picture"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
