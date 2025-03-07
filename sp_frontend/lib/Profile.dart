import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'EditProfile.dart';

class ProfileScreen extends StatefulWidget {
  final String email; // Add email parameter

  ProfileScreen({required this.email}); // Update constructor

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  String name = "";
  String mobileNo = "";
  String dob = "";
  String degree = "";
  String department = "";
  String currentYear = "";
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:5000/profile?email=${widget.email}', // Use email to fetch profile data
        ),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          name = data['data'][0]['name'] ?? ""; // Extract name from the response
          mobileNo = data['data'][0]['mobileNo']?.toString() ?? "";
          dob = data['data'][0]['DOB'] ?? "";
          degree = data['data'][0]['Degree'] ?? "";
          department = data['data'][0]['Department'] ?? "";
          currentYear = data['data'][0]['CurrentYear']?.toString() ?? "";
          _phoneNumberController.text = mobileNo;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile data: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit), // Pencil Icon for Edit
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
          ),
        ],
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
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _image != null
                                  ? FileImage(_image!)
                                  : AssetImage('assets/profile.png')
                                      as ImageProvider,
                          backgroundColor: Colors.white,
                        ),
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty) ...[
                        Text(
                          "Name",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: name),
                          decoration: InputDecoration(
                            hintText: "Enter your name",
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 10),
                      ],
                      if (widget.email.isNotEmpty) ...[
                        Text(
                          "Email",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: widget.email),
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 10),
                      ],
                      if (mobileNo.isNotEmpty) ...[
                        Text(
                          "Mobile Number",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            hintText: "Enter your mobile number",
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                      if (dob.isNotEmpty) ...[
                        Text(
                          "Date of Birth",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: dob),
                          decoration: InputDecoration(
                            hintText: "Enter your date of birth",
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 10),
                      ],
                      if (degree.isNotEmpty) ...[
                        Text(
                          "Degree",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: degree),
                          decoration: InputDecoration(
                            hintText: "Enter your degree",
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 10),
                      ],
                      if (department.isNotEmpty) ...[
                        Text(
                          "Department",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: department),
                          decoration: InputDecoration(
                            hintText: "Enter your department",
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 10),
                      ],
                      if (currentYear.isNotEmpty) ...[
                        Text(
                          "Current Year",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: TextEditingController(text: currentYear),
                          decoration: InputDecoration(
                            hintText: "Enter your current year",
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
