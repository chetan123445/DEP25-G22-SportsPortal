import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Profile.dart';
import 'home.dart';
import 'constants.dart'; // Import the constants file
import 'FullImageScreen.dart';

class EditProfileScreen extends StatefulWidget {
  final String email;
  final String name;
  final String mobileNo;
  final String dob;
  final String degree;
  final String department;
  final String currentYear;
  final String? profilePicture;

  EditProfileScreen({
    required this.email,
    required this.name,
    required this.mobileNo,
    required this.dob,
    required this.degree,
    required this.department,
    required this.currentYear,
    this.profilePicture,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _currentYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _mobileNoController.text = widget.mobileNo;
    _dobController.text = widget.dob;
    _degreeController.text = widget.degree;
    _departmentController.text = widget.department;
    _currentYearController.text = widget.currentYear;
  }

  Future<void> _updateProfile() async {
    try {
      final Map<String, dynamic> updateData = {
        'email': widget.email,
        if (_nameController.text.isNotEmpty) 'name': _nameController.text,
        if (_mobileNoController.text.isNotEmpty) 'mobileNo': _mobileNoController.text,
        if (_dobController.text.isNotEmpty) 'DOB': _dobController.text,
        if (_degreeController.text.isNotEmpty) 'Degree': _degreeController.text,
        if (_departmentController.text.isNotEmpty) 'Department': _departmentController.text,
        if (_currentYearController.text.isNotEmpty) 
          'CurrentYear': int.tryParse(_currentYearController.text) ?? _currentYearController.text,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(email: widget.email),
          ),
          (route) => false,
        );
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
      body: Column(
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
                backgroundImage: AssetImage('assets/profile.png'), // Always show asset image
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Username
                      buildTextField(
                        "Edit name",
                        "Enter your new username",
                        _nameController,
                      ),
                      SizedBox(height: 10),

                      // Date of Birth
                      buildTextField(
                        "Date of Birth",
                        "Enter your DOB",
                        _dobController,
                      ),
                      SizedBox(height: 10),

                      // Phone Number
                      buildTextField(
                        "Phone Number",
                        "Enter your new phone number",
                        _mobileNoController,
                      ),
                      SizedBox(height: 10),

                      // Degree
                      buildTextField(
                        "Degree",
                        "Enter your degree",
                        _degreeController,
                      ),
                      SizedBox(height: 10),

                      // Department
                      buildTextField(
                        "Department",
                        "Enter your department",
                        _departmentController,
                      ),
                      SizedBox(height: 10),

                      // Current Year
                      buildTextField(
                        "Current Year",
                        "Enter your current year",
                        _currentYearController,
                      ),
                      SizedBox(height: 10),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            "Update",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          ),
        ),
      ],
    );
  }
}
