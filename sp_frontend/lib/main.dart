//flutter pub run flutter_launcher_icons:main   ...use this command if u changed app logo
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'login.dart'; // Import the LoginPage
import 'IYSC.dart'; // Import the IYSCPage
import 'Events.dart'; // Import the EventsPage
import 'GC.dart'; // Import the GCPage
import 'IRCC.dart'; // Import the IRCCPage
import 'PHL.dart'; // Import the PHLPage
import 'BasketBrawl.dart'; // Import the BasketBrawlPage
import 'PlayersPage.dart'; // Import the PlayersPage
import 'Gallery.dart'; // Import the GalleryPage
import 'widgets/privacy_policy.dart'; // Import the PrivacyPolicyPage

void main() {
  runApp(SportsPortalApp());
}

class SportsPortalApp extends StatelessWidget {
  Future<Widget> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final emailId = prefs.getString('email');

    if (userId != null && emailId != null) {
      return HomePage(email: emailId);
    }
    return MainPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _checkLoginState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          return snapshot.data ?? MainPage();
        },
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  final bool isLoggedIn = false; // Change this based on user authentication

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch phone $phoneNumber';
    }
  }

  void _launchEmail(String emailAddress) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email $emailAddress';
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text))
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied to clipboard: $text'),
              duration: Duration(seconds: 2),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to copy: $error'),
              duration: Duration(seconds: 2),
            ),
          );
        });
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
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child:
                isLoggedIn
                    ? CircleAvatar(
                      backgroundColor: Colors.blue.shade200,
                      child: Text("XA"),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
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
                // Navigate to EventsPage
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
                // Navigate to IYSCPage
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
                // Navigate to IRCCPage
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
                // Navigate to PHLPage
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
                // Navigate to BasketBrawlPage
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
                // Navigate to IYSCPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_album),
              title: Text('Gallery'),
              onTap: () {
                // Navigate to GalleryPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GalleryPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Players'),
              onTap: () {
                // Navigate to PlayersPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayersPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text('Privacy Policy'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
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
        child: Column(
          children: [
            SizedBox(height: 16),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade500, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white70],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                  child: Text(
                    'SportEve',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height:
                        300, // Adjust this value to make image smaller/larger
                    width:
                        300, // Adjust this value to make image smaller/larger
                    child: Image.asset(
                      'assets/pngsport.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.contact_support_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('+916377418791')),
                        ),
                    onLongPress:
                        () => _copyToClipboard(context, '+916377418791'),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.phone, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Contact', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('sporteveiitropar@gmail.com')),
                        ),
                    onLongPress:
                        () => _copyToClipboard(
                          context,
                          'sporteveiitropar@gmail.com',
                        ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.email, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Email', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('https://www.iitrpr.ac.in')),
                        ),
                    onLongPress:
                        () => _copyToClipboard(
                          context,
                          'https://www.iitrpr.ac.in',
                        ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.web, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Website', style: TextStyle(color: Colors.white)),
                      ],
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
}
