import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AddRemoveAdminPage extends StatefulWidget {
  final String email;
  final String name;

  AddRemoveAdminPage({required this.email, required this.name});

  @override
  _AddRemoveAdminPageState createState() => _AddRemoveAdminPageState();
}

class _AddRemoveAdminPageState extends State<AddRemoveAdminPage> {
  final TextEditingController _emailController = TextEditingController();
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'), // Backend endpoint to fetch users
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = List<String>.from(data['users'].map((user) => user['email']));
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _addAdmin(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-admin'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 201) {
        _showResponseDialog('Admin added successfully');
      } else {
        final data = json.decode(response.body);
        _showResponseDialog(data['message'] ?? 'Error adding admin');
      }
    } catch (e) {
      _showResponseDialog('Error adding admin: $e');
    }
  }

  Future<void> _removeAdmin(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/remove-admin'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        _showResponseDialog('Admin removed successfully');
      } else {
        final data = json.decode(response.body);
        _showResponseDialog(data['message'] ?? 'Error removing admin');
      }
    } catch (e) {
      _showResponseDialog('Error removing admin: $e');
    }
  }

  // Method to show a dialog box with the response message
  void _showResponseDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Response'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add/Remove Admin',
          style: TextStyle(color: Colors.white), // Ensure text is visible
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Back button
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Enter Email',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_emailController.text.isNotEmpty) {
                  _addAdmin(_emailController.text);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Admin'),
                  SizedBox(width: 5), // Space between text and icon
                  Icon(Icons.add, color: Colors.green), // Green plus mark
                ],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_emailController.text.isNotEmpty) {
                  _removeAdmin(_emailController.text);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Remove Admin'),
                  SizedBox(width: 5), // Space between text and icon
                  Icon(Icons.close, color: Colors.red), // Red cross mark
                ],
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white), // Changed to white
            ),
          ],
        ),
      ),
    );
  }
}