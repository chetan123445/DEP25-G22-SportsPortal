import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'EditProfile.dart';
import 'home.dart';
import 'constants.dart'; // Import the constants file

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
  String profilePic = ""; // Add profilePic variable
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
          '$baseUrl/profile?email=${widget.email}', // Use baseUrl to fetch profile data
        ),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          name =
              data['data'][0]['name'] ?? ""; // Extract name from the response
          mobileNo = data['data'][0]['mobileNo']?.toString() ?? "";
          dob =
              data['data'][0]['DOB']?.split('T')[0] ??
              ""; // Extract only the date part
          degree = data['data'][0]['Degree'] ?? "";
          department = data['data'][0]['Department'] ?? "";
          currentYear = data['data'][0]['CurrentYear']?.toString() ?? "";
          profilePic =
              data['data'][0]['ProfilePic'] ?? ""; // Extract profilePic
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
      _uploadProfilePic(_image!);
    }
  }

  Future<void> _uploadProfilePic(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/uploadProfilePic'),
      );
      request.fields['email'] = widget.email;
      request.files.add(
        await http.MultipartFile.fromPath('profilePic', image.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        setState(() {
          profilePic = data['data']['ProfilePic'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(email: widget.email),
              ),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit), // Pencil Icon for Edit
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditProfileScreen(
                        email: widget.email,
                        name: name,
                        mobileNo: mobileNo,
                        dob: dob,
                        degree: degree,
                        department: department,
                        currentYear: currentYear,
                        profilePicture: _image?.path,
                      ),
                ),
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
                                  : profilePic.isNotEmpty
                                  ? NetworkImage('$baseUrl/$profilePic')
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