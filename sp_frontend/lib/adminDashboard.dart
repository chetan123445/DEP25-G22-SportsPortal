import 'package:flutter/material.dart';
import '../admin/AddEventPage.dart';
import '../Profile.dart'; // Import ProfileScreen
import 'constants.dart'; // Import the constants file
import 'dart:convert'; // Import for JSON decoding
import 'package:http/http.dart' as http; // Import for HTTP requests

void main() {
  runApp(
    AdminDashboard(email: "user@example.com", name: "John Mcdonald"),
  ); // Example initialization
}

class AdminDashboard extends StatelessWidget {
  final String email;
  final String name;

  AdminDashboard({required this.email, required this.name});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(email: email, name: name),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String email;
  final String name;

  DashboardScreen({required this.email, required this.name});

  Future<String?> _fetchProfilePic(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile?email=$email'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'][0]['ProfilePic'] ?? null;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  final List<Map<String, dynamic>> categories = [
    {'name': 'Add Event and Event Managers', 'icon': Icons.event},
    {'name': 'Manage Event and Event Managers', 'icon': Icons.admin_panel_settings},
    {'name': 'My Activity', 'icon': Icons.timeline}, // Added new category
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Set color to white
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProfileScreen(
                      email: email,
                    ), // Replace with actual email
              ),
            );
          },
        ),
      ),
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20), // Top padding
              FutureBuilder<String?>(
                future: _fetchProfilePic(email),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  } else if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                    return CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        '$baseUrl/${snapshot.data}',
                      ),
                      backgroundColor: Colors.transparent,
                    );
                  } else {
                    return CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(
                        'assets/profile.png',
                      ), // Default image
                      backgroundColor: Colors.transparent,
                    );
                  }
                },
              ),
              SizedBox(height: 10),
              Text(
                name, // Use the name passed from ProfileScreen
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // FIXED: Use Flexible to avoid overflow
              Flexible(
                child: GridView.builder(
                  padding: EdgeInsets.all(15),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2, // Adjusted for better fit
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return CategoryTile(
                      title: categories[index]['name'],
                      icon: categories[index]['icon'],
                      email: email, // Pass email to CategoryTile
                      name: name, // Pass name to CategoryTile
                    );
                  },

                  // Alternative fix (use this instead of Flexible if needed)
                  // shrinkWrap: true,
                  // physics: NeverScrollableScrollPhysics(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String email;
  final String name;

  CategoryTile({
    required this.title,
    required this.icon,
    required this.email,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == 'Add Event and Event Managers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddEventPage(
                    email: email,
                    name: name,
                  ), // Pass name to AddEventPage
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32), // Reduced icon size
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
