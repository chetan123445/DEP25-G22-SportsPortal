import 'package:flutter/material.dart';
import '../admin/AddEventPage.dart';

void main() {
  runApp(AdminDashboard());
}

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'name': 'Add Event Manager', 'icon': Icons.supervisor_account},
    {'name': 'Add Event', 'icon': Icons.event},
    {'name': 'Manage Event', 'icon': Icons.edit_calendar},
    {'name': 'Manage Event Managers', 'icon': Icons.admin_panel_settings},
    {'name': 'My Activity', 'icon': Icons.timeline}, // Added new category
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20), // Top padding
              CircleAvatar(
                radius: 40, // Reduced from 50
                backgroundImage: AssetImage('assets/profile.png'),
              ),
              SizedBox(height: 10),
              Text(
                "Puneet Goyal",
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

  CategoryTile({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == 'Add Event') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEventPage()),
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
