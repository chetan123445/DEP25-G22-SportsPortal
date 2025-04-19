import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'AdminProfilePage.dart';

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
  List<String> currentAdmins = [];
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchCurrentAdmins();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
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

  Future<void> _fetchCurrentAdmins() async {
    setState(() {
      isLoading = true; // Set loading to true before fetching
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/current-admins'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentAdmins = List<String>.from(data['admins']);
          isLoading = false; // Set loading to false after data is loaded
        });
      }
    } catch (e) {
      print('Error fetching current admins: $e');
      setState(() {
        isLoading = false; // Set loading to false even if there's an error
      });
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
        _fetchCurrentAdmins();
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
        _fetchCurrentAdmins();
      } else {
        final data = json.decode(response.body);
        _showResponseDialog(data['message'] ?? 'Error removing admin');
      }
    } catch (e) {
      _showResponseDialog('Error removing admin: $e');
    }
  }

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
                Navigator.of(context).pop();
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
        title: Text('Add/Remove Admin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Container(
                      constraints: BoxConstraints(maxWidth: 600),
                      padding: EdgeInsets.all(20),
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
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: Colors.black87,
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Enter Email',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildActionButton(
                                onPressed: () {
                                  if (_emailController.text.isNotEmpty) {
                                    _addAdmin(_emailController.text);
                                  }
                                },
                                icon: Icons.add,
                                label: 'Add Admin',
                                color: Colors.green,
                              ),
                              _buildActionButton(
                                onPressed: () {
                                  if (_emailController.text.isNotEmpty) {
                                    _removeAdmin(_emailController.text);
                                  }
                                },
                                icon: Icons.remove_circle,
                                label: 'Remove Admin',
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildAdminsList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsList() {
    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Admins',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (isLoading) ...[
            // Show loading spinner
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Loading admins...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (currentAdmins.isEmpty) ...[
            // Show no admins message with icon
            Center(
              child: Column(
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'No admins found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: currentAdmins.length,
              itemBuilder: (context, index) {
                return _buildAdminTile(currentAdmins[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(String email) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(email),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminProfilePage(email: email),
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Remove Admin'),
                      content: Text(
                        'Are you sure you want to remove $email as admin?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _removeAdmin(email);
                          },
                          child: Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
