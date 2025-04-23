import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'main.dart'; // Add this import at the top

class SettingsPage extends StatefulWidget {
  final String email;
  SettingsPage({required this.email});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _alternativeEmailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _alternativeEmailOtp;
  String? userId;
  String? _alternativeEmail; // Add new state variable
  bool _isAlternativeEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadAlternativeEmail(); // Add this
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  // Add this method
  Future<void> _loadAlternativeEmail() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-alternative-email/${widget.email}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _alternativeEmail = data['alternativeEmail'];
        });
      }
    } catch (e) {
      print('Error loading alternative email: $e');
    }
  }

  void _clearTextFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _alternativeEmailController.clear();
    _otpController.clear();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _alternativeEmailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 6 || password.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password length must be between 6 and 15 characters'),
        ),
      );
      return false;
    }

    if (!RegExp(
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$',
    ).hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password must contain:\n• At least one letter\n• At least one number\n• At least one special character',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('New passwords do not match!')));
      return;
    }

    if (!_validatePassword(_newPasswordController.text)) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/changePassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'oldPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to change password'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateAlternativeEmail() async {
    if (_alternativeEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an alternative email')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'), // Changed to use signup endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _alternativeEmailController.text,
          'isAlternativeEmail': true, // Add this flag
          'name': '', // Required by signup endpoint
          'password': '', // Required by signup endpoint
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _alternativeEmailOtp = data['otp'];
        _showOtpVerificationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending verification email')),
      );
    }
  }

  Future<void> _verifyAlternativeEmail() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-alternative-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _alternativeEmailController.text,
          'otp': _otpController.text,
          'mainEmail': widget.email, // Add this line
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _alternativeEmail = _alternativeEmailController.text;
          _isAlternativeEmailVerified = true;
        });
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
        _loadAlternativeEmail(); // Reload the alternative email
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Error verifying OTP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying alternative email')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Account deleted successfully')));

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
    }
  }

  Future<void> _sendAlternativeEmailOtp() async {
    if (_alternativeEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an alternative email')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-alternative-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _alternativeEmailController.text}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        _showOtpVerificationDialog();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending verification email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(16.0),
          padding: EdgeInsets.all(24.0),
          constraints: BoxConstraints(maxWidth: 600), // Reduced max width
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
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingCard(
                icon: Icons.lock,
                title: 'Change Password',
                onTap: () => _showChangePasswordDialog(),
              ),
              SizedBox(height: 16),
              _buildSettingCard(
                icon: Icons.alternate_email,
                title: 'Alternative Email',
                onTap: () => _showAlternativeEmailDialog(),
              ),
              SizedBox(height: 16),
              _buildSettingCard(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                onTap: () => _showDeleteAccountDialog(),
                isDelete: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60, // Reduced height for rectangular shape
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDelete ? Colors.red : Colors.black,
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isDelete ? Colors.red : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    _clearTextFields();
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
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
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: !_isOldPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Old Password',
                        labelStyle: TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isOldPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed:
                              () => setState(() {
                                _isOldPasswordVisible = !_isOldPasswordVisible;
                              }),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed:
                              () => setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              }),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed:
                              () => setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              }),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _changePassword,
                          child: Text(
                            'Change Password',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    ).then((_) => _clearTextFields());
  }

  void _showAlternativeEmailDialog() {
    // If alternative email exists, just show it
    if (_alternativeEmail != null && _alternativeEmail!.isNotEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Alternative Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your alternative email:'),
                  SizedBox(height: 8),
                  Text(
                    _alternativeEmail!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('Would you like to change it?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showNewAlternativeEmailDialog();
                  },
                  child: Text('Yes'),
                ),
              ],
            ),
      );
    } else {
      _showNewAlternativeEmailDialog();
    }
  }

  void _showNewAlternativeEmailDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Alternative Email'),
            content: TextField(
              controller: _alternativeEmailController,
              decoration: InputDecoration(
                labelText: 'Enter alternative email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _sendAlternativeEmailOtp(),
                child: Text('Send OTP'),
              ),
            ],
          ),
    );
  }

  void _showOtpVerificationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Verify Alternative Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please enter the OTP sent to your alternative email'),
                SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _verifyAlternativeEmail();
                },
                child: Text('Verify'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Account'),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }
}
