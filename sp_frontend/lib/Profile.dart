import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'EditProfile.dart';
import 'home.dart';
import 'constants.dart'; // Import the constants file
import 'FullImageScreen.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Import jwt_decoder package
import 'adminDashboard.dart';

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
  bool isAdmin = false; // Add isAdmin variable
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _currentYearController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _checkAdminStatus(); // Check admin status
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

  Future<void> _checkAdminStatus() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-admin'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'email': widget.email}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String token = data['token'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        setState(() {
          isAdmin = decodedToken['isAdmin'] ?? false;
        });
      } else {
        throw Exception('Failed to verify admin status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying admin status: $e')),
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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-pic'),
      );

      request.fields['email'] = widget.email;
      request.files.add(
        await http.MultipartFile.fromPath('profilePic', image.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Ensure the `ProfilePic` field is treated as a String
        if (data['data'] != null && data['data']['ProfilePic'] is String) {
          setState(() {
            profilePic = data['data']['ProfilePic'];
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture uploaded successfully')),
        );

        // Refresh profile data
        _fetchProfileData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Failed to upload profile picture',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  Future<void> _removeProfilePic() async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/remove-profile-pic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          profilePic = '';
          _image = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture removed successfully')),
        );
      } else {
        throw Exception('Failed to remove profile picture');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing profile picture: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    try {
      final Map<String, dynamic> updateData = {
        'email': widget.email,
        if (_nameController.text.isNotEmpty) 'name': _nameController.text,
        if (_phoneNumberController.text.isNotEmpty)
          'mobileNo': _phoneNumberController.text,
        if (_dobController.text.isNotEmpty) 'DOB': _dobController.text,
        if (_degreeController.text.isNotEmpty) 'Degree': _degreeController.text,
        if (_departmentController.text.isNotEmpty)
          'Department': _departmentController.text,
        if (_currentYearController.text.isNotEmpty) ...{
          'CurrentYear':
              int.tryParse(_currentYearController.text) ??
              _currentYearController.text,
        },
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
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
            if (profilePic.isNotEmpty || _image != null) ...[
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePic();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _showFullImage() {
    if (profilePic.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullImageScreen(
                imageUrl:
                    profilePic.startsWith('data:image')
                        ? profilePic
                        : '$baseUrl/$profilePic',
              ),
        ),
      );
    }
  }

  ImageProvider _getImageProvider(String imageData) {
    if (imageData.startsWith('data:image')) {
      // Handle base64 image data
      String base64Image = imageData.split(',')[1];
      return MemoryImage(base64Decode(base64Image));
    }
    // Fallback to network image
    return NetworkImage('$baseUrl/$imageData');
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
                        GestureDetector(
                          onTap: _showFullImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                _image != null
                                    ? FileImage(_image!)
                                    : profilePic.isNotEmpty
                                    ? _getImageProvider(profilePic)
                                    : AssetImage(
                                          'assets/profile.png',
                                        ) // Fallback image
                                        as ImageProvider,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: MouseRegion(
                            cursor:
                                SystemMouseCursors
                                    .click, // Change cursor to hand
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
                          readOnly: true, // Make the field read-only
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
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.admin_panel_settings,
                            color: Colors.teal,
                          ),
                          title: Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward,
                            color: Colors.teal,
                          ),
                          onTap: () {
                            if (isAdmin) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AdminDashboard(
                                        email: widget.email,
                                        name: name,
                                      ),
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                    content: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
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
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Icon(
                                              Icons.admin_panel_settings,
                                              size: 48,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Not an Admin',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'You currently don\'t have admin privileges. To request admin access, please contact to below email:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Email:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: SelectableText(
                                                    'sporteveiitropar@gmail.com',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black87,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: Text(
                                                'Got it',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
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

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Image(
          image:
              imageUrl.startsWith('data:image')
                  ? MemoryImage(base64Decode(imageUrl.split(',')[1]))
                  : NetworkImage(imageUrl) as ImageProvider,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
