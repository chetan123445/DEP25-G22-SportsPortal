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
import 'Gallery.dart'; // Import the GalleryPage
import 'dart:async';
import 'SettingsPage.dart'; // Import the SettingsPage
import 'widgets/privacy_policy.dart'; // Import the PrivacyPolicyPage
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(SportsPortalApp());
}

class CustomSpacer extends StatelessWidget {
  final double width;
  final double height;

  const CustomSpacer({this.width = 0, this.height = 0, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height);
  }
}

class CustomRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const CustomRow({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator({Key? key}) : super(key: key);

  @override
  _LiveIndicatorState createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const CustomRow(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.live_tv, color: Colors.white, size: 16),
            CustomSpacer(width: 4),
            Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  String? _profilePic;
  List<dynamic> liveEvents = [];
  IO.Socket? socket;
  bool hasLiveEvents = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveEvents();
    _connectToSocket();
    _fetchAndSetProfilePic();
  }

  void _connectToSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket?.connect();

    socket?.on('score-update', (data) {
      if (mounted) {
        _updateLiveScore(data);
      }
    });

    socket?.on('event-status-update', (data) {
      if (mounted) {
        _handleEventStatusUpdate(data);
      }
    });
  }

  void _handleEventStatusUpdate(dynamic data) {
    if (data['status'] == 'completed') {
      setState(() {
        // Remove the event from live events
        liveEvents.removeWhere((event) => event['_id'] == data['eventId']);
        hasLiveEvents = liveEvents.isNotEmpty;
      });
    }
  }

  Future<void> _fetchUpdatedEvent(String eventId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/event/$eventId'));
      if (response.statusCode == 200) {
        final updatedEvent = json.decode(response.body);

        if (mounted) {
          setState(() {
            // Remove existing event if present
            liveEvents.removeWhere((event) => event['_id'] == eventId);

            // Add updated event if it's live
            if (updatedEvent['status'] == 'live') {
              // Insert at the beginning of the list for immediate visibility
              liveEvents.insert(0, updatedEvent);
              hasLiveEvents = true;

              // Update page controller to show the new event
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }

              // Join socket room for the new live event
              socket?.emit('join-event', eventId);
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching updated event: $e');
    }
  }

  Future<void> _fetchLiveEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/live-events'));
      if (response.statusCode == 200) {
        final events = json.decode(response.body);
        if (mounted) {
          setState(() {
            liveEvents =
                events.where((event) => event['eventType'] != 'GC').toList();
            hasLiveEvents = liveEvents.isNotEmpty;
            if (hasLiveEvents) {
              _timer?.cancel(); // Stop image carousel if there are live events
            } else {
              _startAutoPlay(); // Start carousel if no live events
            }
          });

          // Join socket room for each live event
          liveEvents.forEach((event) {
            socket?.emit('join-event', event['_id']);
          });
        }
      }
    } catch (e) {
      print('Error fetching live events: $e');
    }
  }

  Widget _buildLiveEventCard(dynamic event) {
    if (event == null) {
      // Display for no live events
      return Container(
        decoration: BoxDecoration(
          color: Color(
            0xFF2196F3,
          ).withOpacity(0.15), // Match the new blue color
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_outlined,
                size: 50,
                color: Colors.blue.shade900,
              ),
              SizedBox(height: 16),
              Text(
                'No Live Events',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for live sports updates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    String eventType = event['eventType'];
    String displayType = eventType;
    if (eventType == 'IYSC') {
      displayType += ' - ${event['type'] ?? 'Unknown Type'}';
    }

    late Widget scoreDisplay;

    // Add event type header
    Widget header = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, // Changed from Colors.white.withOpacity(0.2)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        displayType,
        style: TextStyle(
          color: Colors.black, // Changed from Colors.black54
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // Update text styles for cricket scores
    if (eventType == 'IRCC' ||
        (eventType == 'IYSC' && event['type']?.toLowerCase() == 'cricket')) {
      final team1Score = Map<String, dynamic>.from(event['team1Score'] ?? {});
      final team2Score = Map<String, dynamic>.from(event['team2Score'] ?? {});

      scoreDisplay = Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              Colors
                  .blue[100], // Changed from Color(0xFFA1D6B2) to match sports events box color
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Team 1
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event['team1']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${team1Score['runs'] ?? 0}/${team1Score['wickets'] ?? 0}\n(${team1Score['overs'] ?? 0}.${team1Score['balls'] ?? 0})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // VS
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            // Team 2
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event['team2']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${team2Score['runs'] ?? 0}/${team2Score['wickets'] ?? 0}\n(${team2Score['overs'] ?? 0}.${team2Score['balls'] ?? 0})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (eventType == 'PHL' ||
        eventType == 'BasketBrawl' ||
        (eventType == 'IYSC' && event['type']?.toLowerCase() != 'cricket')) {
      final team1Score = getSafeScore(event['team1Score']);
      final team2Score = getSafeScore(event['team2Score']);
      final score1 =
          eventType == 'PHL'
              ? event['team1Goals'] ?? 0
              : team1Score['goals'] ?? 0;
      final score2 =
          eventType == 'PHL'
              ? event['team2Goals'] ?? 0
              : team2Score['goals'] ?? 0;

      // Add rounds history for IYSC non-cricket events
      Widget? roundsHistory;
      if (eventType == 'IYSC' && event['type']?.toLowerCase() != 'cricket') {
        final team1Score = Map<String, dynamic>.from(event['team1Score'] ?? {});
        final team2Score = Map<String, dynamic>.from(event['team2Score'] ?? {});

        // Extract round history from both teams' scores
        final team1RoundHistory = List<Map<String, dynamic>>.from(
          team1Score['roundHistory'] ?? [],
        );
        final team2RoundHistory = List<Map<String, dynamic>>.from(
          team2Score['roundHistory'] ?? [],
        );

        // Only create roundsHistory widget if there are actual rounds to display
        if (team1RoundHistory.isNotEmpty && team2RoundHistory.isNotEmpty) {
          roundsHistory = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Previous Rounds',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: team1RoundHistory.length,
                  itemBuilder: (context, index) {
                    final team1Round = team1RoundHistory[index];
                    final team2Round = team2RoundHistory[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            Colors
                                .white, // Changed from Colors.white.withOpacity(0.1)
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors
                                      .white, // Changed from Colors.blue.shade700
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Round ${index + 1}',
                              style: TextStyle(
                                color:
                                    Colors.black, // Changed from Colors.black54
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${team1Round['score'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Colors
                                                .black54, // Changed from Colors.white
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Colors
                                            .black54, // Changed from Colors.white70
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${team2Round['score'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Colors
                                                .black54, // Changed from Colors.white
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }
      }

      scoreDisplay = Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              Colors
                  .blue[100], // Changed from Color(0xFFA1D6B2) to match sports events box color
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (roundsHistory != null) roundsHistory,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Team 1
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${event['team1']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$score1',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // VS
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                // Team 2
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${event['team2']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$score2',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      scoreDisplay = Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFFA1D6B2), // New color
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100]?.withOpacity(
          0.95,
        ), // Changed from black to light blue
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    header, // Add the header here
                    if (eventType == 'IYSC' &&
                        event['type']?.toLowerCase() != 'cricket' &&
                        event['roundScores'] != null)
                      Container(
                        height: 50,
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (event['roundScores'] as List).length,
                          itemBuilder: (context, index) {
                            final roundScore = event['roundScores'][index];
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Round ${index + 1}',
                                    style: TextStyle(
                                      color:
                                          Colors
                                              .black54, // Changed from Colors.white
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${roundScore['team1Score']} - ${roundScore['team2Score']}',
                                    style: TextStyle(
                                      color:
                                          Colors
                                              .black54, // Changed from Colors.white
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    scoreDisplay,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(top: 10, right: 10, child: _LiveIndicator()),
        ],
      ),
    );
  }

  void _updateLiveScore(dynamic data) {
    setState(() {
      int index = liveEvents.indexWhere(
        (event) => event['_id'] == data['eventId'],
      );
      if (index != -1) {
        final eventType = liveEvents[index]['eventType'];

        if (eventType == 'PHL') {
          // Update PHL scores using team1Goals and team2Goals
          liveEvents[index]['team1Goals'] = data['team1Goals'];
          liveEvents[index]['team2Goals'] = data['team2Goals'];
        } else if (eventType == 'BasketBrawl') {
          // Handle BasketBrawl scores using team1Score and team2Score
          liveEvents[index]['team1Score'] =
              data['team1Score'] is int
                  ? {'goals': data['team1Score']}
                  : Map<String, dynamic>.from(data['team1Score']);

          liveEvents[index]['team2Score'] =
              data['team2Score'] is int
                  ? {'goals': data['team2Score']}
                  : Map<String, dynamic>.from(data['team2Score']);
        } else {
          // Handle other events (IRCC, IYSC)
          if (data['team1Score'] != null) {
            liveEvents[index]['team1Score'] = Map<String, dynamic>.from(
              data['team1Score'],
            );
          }
          if (data['team2Score'] != null) {
            liveEvents[index]['team2Score'] = Map<String, dynamic>.from(
              data['team2Score'],
            );
          }
        }
      }
    });
  }

  Future<void> _startAutoPlay() {
    _timer?.cancel(); // Cancel any existing timer
    return Future.value();
  }

  Future<void> _fetchAndSetProfilePic() async {
    final profilePic = await _fetchProfilePic(widget.email);
    setState(() {
      _profilePic = profilePic; // Store the fetched profile picture
    });
  }

  Future<String?> _fetchProfilePic(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile?email=$email'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'][0]['ProfilePic'] ?? null; // Base64 string
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
        builder:
            (context) => NotificationsPage(
              email: widget.email,
              onNotificationsUpdated: () {
                // Force rebuild to refresh notification count
                setState(() {});
              },
            ),
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
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
                      right: 6, // Adjusted position
                      top: 6, // Adjusted position
                      child: Container(
                        padding: EdgeInsets.all(1), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(
                            6,
                          ), // Smaller radius
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12, // Reduced width
                          minHeight: 12, // Reduced height
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8, // Smaller font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(email: widget.email),
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      _profilePic != null
                          ? MemoryImage(
                            base64Decode(_profilePic!.split(',')[1]),
                          )
                          : AssetImage('assets/profile.png') as ImageProvider,
                  backgroundColor: Colors.transparent,
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
              onTap: () {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayersPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(email: widget.email),
                  ),
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
              height: 225,
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
                      itemCount: hasLiveEvents ? liveEvents.length : 1,
                      itemBuilder: (context, index) {
                        if (hasLiveEvents) {
                          return _buildLiveEventCard(liveEvents[index]);
                        }
                        return _buildLiveEventCard(null);
                      },
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          hasLiveEvents ? liveEvents.length : 1,
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
                          CustomRow(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'Events',
                                  Icons.sports_soccer,
                                  EventsPage(),
                                ),
                              ),
                              const CustomSpacer(width: 10),
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
                          const CustomSpacer(height: 10),
                          CustomRow(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'IRCC',
                                  Icons.sports_cricket,
                                  IRCCPage(),
                                ),
                              ),
                              const CustomSpacer(width: 10),
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
                          const CustomSpacer(height: 10),
                          CustomRow(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'BasketBrawl',
                                  Icons.sports_basketball,
                                  BasketBrawlPage(),
                                ),
                              ),
                              const CustomSpacer(width: 10),
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
                          const CustomSpacer(height: 10),
                          CustomRow(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildAnimatedCard(
                                  'My Events',
                                  Icons.event_available,
                                  MyEventsPage(email: widget.email),
                                ),
                              ),
                              const CustomSpacer(width: 10),
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

  // Add this helper method
  Map<String, dynamic> getSafeScore(dynamic score) {
    if (score == null) return {'goals': 0};
    if (score is int) return {'goals': score};
    return Map<String, dynamic>.from(score);
  }

  Widget _buildAnimatedCard(String title, IconData icon, Widget page) {
    return Card(
      elevation: 4,
      color: Colors.blue[100], // Light blue background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            ),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: CustomRow(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue.shade900),
              const CustomSpacer(width: 15),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800, // Bolder text
                    color: Colors.black, // Black text color
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
