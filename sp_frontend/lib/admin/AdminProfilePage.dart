import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class AdminProfilePage extends StatefulWidget {
  final String email;

  const AdminProfilePage({Key? key, required this.email}) : super(key: key);

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Map<String, dynamic>? adminDetails;
  bool isLoading = true;
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminDetails();
  }

  Future<void> _fetchAdminDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin-profile/${widget.email}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          adminDetails = data;
          isRegistered = true;
          isLoading = false;
        });
      } else {
        setState(() {
          isRegistered = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isRegistered = false;
        isLoading = false;
      });
    }
  }

  ImageProvider _getImageProvider(String imageData) {
    if (imageData.startsWith('data:image')) {
      String base64Image = imageData.split(',')[1];
      return MemoryImage(base64Decode(base64Image));
    }
    return NetworkImage(imageData);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Admin Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Profile'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade200,
                Colors.blue.shade200,
                Colors.pink.shade100,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade200,
                        Colors.blue.shade200,
                        Colors.pink.shade100,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child:
                          isRegistered && adminDetails!['ProfilePic'].isNotEmpty
                              ? ClipOval(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: _getImageProvider(
                                        adminDetails!['ProfilePic'],
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                              : Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name', adminDetails!['Name']),
                      _buildDetailRow(
                        'Email',
                        isRegistered ? adminDetails!['email'] : widget.email,
                      ),
                      if (isRegistered) ...[
                        _buildDetailRow(
                          'Mobile Number',
                          adminDetails!['mobileNo'],
                        ),
                        _buildDetailRow('Date of Birth', adminDetails!['DOB']),
                        _buildDetailRow('Degree', adminDetails!['Degree']),
                        _buildDetailRow(
                          'Department',
                          adminDetails!['Department'],
                        ),
                        _buildDetailRow(
                          'Current Year',
                          adminDetails!['CurrentYear'],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isRegistered) // Show message if user is not registered
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'User is not registered',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    // Convert non-string values to strings and skip empty/null values
    final displayValue =
        value != null && value.toString().isNotEmpty ? value.toString() : null;

    if (displayValue == null)
      return SizedBox.shrink(); // Skip if value is empty

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          Divider(color: Colors.grey), // Add a divider line
          Text(
            displayValue,
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
