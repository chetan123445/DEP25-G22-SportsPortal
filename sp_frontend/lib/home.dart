import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Import the LoginPage
import 'IYSC.dart'; // Import the IYSCPage
import 'Events.dart'; // Import the EventsPage
import 'GC.dart'; // Import the GCPage
import 'IRCC.dart'; // Import the IRCCPage
import 'PHL.dart'; // Import the PHLPage
import 'BasketBrawl.dart'; // Import the BasketBrawlPage
import 'Profile.dart'; // Import the ProfilePage
import 'main.dart'; // Import MainPage
import 'PlayersPage.dart'; // Import the PlayersPage
import 'constants.dart'; // Import the constants file
import 'dart:convert'; // Import for JSON decoding
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'MyEvents.dart'; // Import the MyEventsPage
import 'ManagingEvents.dart'; // Import the ManagingEventsPage
import 'NotificationsPage.dart'; // Import the NotificationsPage
import 'dart:async';

void main() {
  runApp(SportsPortalApp());
}

class SportsPortalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(email: 'sports@iitrpr.ac.in'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String email;
  HomePage({required this.email});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool isMenuHovered = false;

  final List<Map<String, String>> carouselImages = [
    {'path': 'assets/sports1.jpg', 'caption': 'Cricket Championship'},
    {'path': 'assets/sports2.jpg', 'caption': 'Basketball Tournament'},
    {'path': 'assets/sports3.jpg', 'caption': 'Football League'},
    {'path': 'assets/sports4.jpg', 'caption': 'Hockey Tournament'},
    {'path': 'assets/sports5.jpg', 'caption': 'Athletics Meet'},
    {'path': 'assets/sports6.jpg', 'caption': 'Sports Complex'},
    {'path': 'assets/sports7.jpg', 'caption': 'Volleyball Match'},
    {'path': 'assets/sports8.jpg', 'caption': 'Badminton Tournament'},
    {'path': 'assets/sports9.jpg', 'caption': 'Table Tennis'},
    {'path': 'assets/sports10.jpg', 'caption': 'Swimming Championship'},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < carouselImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

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

  Future<List<dynamic>> _fetchNotifications(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
    return [];
  }

  Future<int> _getUnreadNotificationsCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?email=${widget.email}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] ?? 0;
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
    return 0;
  }

  void _showNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(email: widget.email),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MainPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () => _showNotifications(context),
              ),
              FutureBuilder<int>(
                future: _getUnreadNotificationsCount(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! > 0) {
                    return Positioned(
                      right: 6,  // Adjusted position
                      top: 6,    // Adjusted position
                      child: Container(
                        padding: EdgeInsets.all(1),  // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),  // Smaller radius
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,  // Reduced width
                          minHeight: 12, // Reduced height
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,    // Smaller font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: FutureBuilder<String?>(
              future: _fetchProfilePic(widget.email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProfileScreen(email: widget.email),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          '$baseUrl/${snapshot.data}',
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProfileScreen(email: widget.email),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage('assets/profile.png'),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.5,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 96.0,
              child: DrawerHeader(
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
                margin: EdgeInsets.all(0),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.sports_soccer),
              title: Text('Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_kabaddi),
              title: Text('IYSC'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IYSCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_cricket),
              title: Text('IRCC'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IRCCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_hockey),
              title: Text('PHL'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PHLPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_basketball),
              title: Text('BasketBrawl'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BasketBrawlPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events),
              title: Text('GC'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.event_available),
              title: Text('My Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyEventsPage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Managing Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ManagingEventsPage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_album),
              title: Text('Gallery'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Players'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayersPage()),
                );
              },
            ),
            Divider(thickness: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _logout(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Carousel
            Container(
              height: 225, // Reduced from 300 to 225 (3/4 of original height)
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: carouselImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(carouselImages[index]['path']!),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        );
                      },
                    ),
                    // Indicators
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          carouselImages.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sports Events Section
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ), // Reduced horizontal margin
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              width: double.infinity, // Make container full width
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Sports Events',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height:
                        MediaQuery.of(context).size.height -
                        400, // Dynamic height based on screen size
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'Events',
                                  Icons.sports_soccer,
                                  EventsPage(),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'IYSC',
                                  Icons.sports_kabaddi,
                                  IYSCPage(),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'IRCC',
                                  Icons.sports_cricket,
                                  IRCCPage(),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'PHL',
                                  Icons.sports_hockey,
                                  PHLPage(),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'BasketBrawl',
                                  Icons.sports_basketball,
                                  BasketBrawlPage(),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'GC',
                                  Icons.emoji_events,
                                  GCPage(),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'My Events',
                                  Icons.event_available,
                                  MyEventsPage(email: widget.email),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'Players',
                                  Icons.people,
                                  PlayersPage(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(String title, IconData icon, Widget page) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            ),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 80, // Increased height
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.blue.shade700,
              ), // Increased icon size
              SizedBox(width: 15),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, // Increased font size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
