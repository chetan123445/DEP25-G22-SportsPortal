import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'services/favorite_service.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: EventsPage()));
}

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> liveEvents = [];
  List<dynamic> upcomingEvents = [];
  List<dynamic> pastEvents = [];
  String searchQuery = '';
  bool showFavoritesOnly = false;
  Map<String, bool> favoriteStatus = {};
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserId();
    await fetchEvents();
  }

  Future<void> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      print('Retrieved userId from SharedPreferences: $storedUserId');

      if (storedUserId != null && storedUserId.isNotEmpty) {
        setState(() {
          userId = storedUserId;
        });
      } else {
        print('No valid user ID found in SharedPreferences');
      }
    } catch (e) {
      print('Error getting userId: $e');
    }
  }

  Future<void> _loadFavoriteStatus(List<dynamic> events) async {
    if (userId == null || userId!.isEmpty || events.isEmpty) {
      print(
        'Cannot load favorites: userId=$userId, events.length=${events.length}',
      );
      return;
    }

    print('Loading favorites for user: $userId');
    try {
      for (var event in events) {
        if (event['_id'] == null) continue;

        String eventId = event['_id'];
        String eventType = event['eventType'] ?? 'Unknown';
        print('Checking favorite for event: $eventId of type: $eventType');

        bool isFavorite = await FavoriteService.verifyFavorite(
          eventType,
          eventId,
          userId!,
        );
        print('Favorite status for $eventId: $isFavorite');

        if (mounted) {
          setState(() {
            favoriteStatus[eventId] = isFavorite;
          });
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(
    String eventId,
    String eventType,
    bool currentStatus,
  ) async {
    if (userId == null) return;

    bool success;
    if (currentStatus) {
      success = await FavoriteService.removeFavorite(
        eventType,
        eventId,
        userId!,
      );
    } else {
      success = await FavoriteService.addFavorite(eventType, eventId, userId!);
    }

    if (success && mounted) {
      setState(() {
        favoriteStatus[eventId] = !currentStatus;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    String query = searchQuery.isNotEmpty ? '?search=$searchQuery' : '';

    final liveResponse = await http.get(
      Uri.parse('$baseUrl/live-events$query'),
    );
    final upcomingResponse = await http.get(
      Uri.parse('$baseUrl/upcoming-events$query'),
    );
    final pastResponse = await http.get(
      Uri.parse('$baseUrl/past-events$query'),
    );

    if (liveResponse.statusCode == 200 &&
        upcomingResponse.statusCode == 200 &&
        pastResponse.statusCode == 200) {
      setState(() {
        liveEvents = json.decode(liveResponse.body);
        upcomingEvents = json.decode(upcomingResponse.body);
        pastEvents = json.decode(pastResponse.body);
      });

      // Load favorites for all event lists
      await _loadFavoriteStatus(liveEvents);
      await _loadFavoriteStatus(upcomingEvents);
      await _loadFavoriteStatus(pastEvents);
    } else {
      print('Failed to load events');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        actions: [
          IconButton(
            icon: Icon(Icons.star, color: Colors.yellow, size: 30),
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Live'), Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search), // Added search icon
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  fetchEvents();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(context, liveEvents, isLive: true),
                _buildEventsList(context, upcomingEvents),
                _buildEventsList(context, pastEvents),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    List<dynamic> events, {
    bool isLive = false,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'No events found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(
            context,
            event['team1'] ?? 'Team 1',
            event['team2'] ?? 'Team 2',
            event['date']?.split('T')[0] ?? 'No Date',
            event['time'] ?? 'No Time',
            event['type'] ?? 'No Type',
            event['gender'] ?? 'Unknown',
            event['venue'] ?? 'No Venue',
            event['eventType'] ?? 'No Event Type',
            isLive,
            event['_id'], // Pass the event ID
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    String team1,
    String team2,
    String date,
    String time,
    String type,
    String gender,
    String venue,
    String eventType,
    bool isLive,
    String eventId, // Add eventId parameter
  ) {
    bool isFavorite = favoriteStatus[eventId] ?? false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(8.0),
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
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 8.0,
            ), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensures a minimal height layout
              children: [
                // Event Type
                Text(
                  eventType,
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),

                // Teams Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        team1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "vs",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        team2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),

                // Date & Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),

                // Type & Gender Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      gender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),

                // Venue Box
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Venue: $venue',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 4.0),

                // Favorite Icon & Blinking Live Indicator in Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.yellow : null,
                        size: 20, // Reduced icon size
                      ),
                      onPressed:
                          () => _toggleFavorite(eventId, eventType, isFavorite),
                    ),
                    if (isLive) BlinkingLiveIndicator(), // Blinking Red Circle
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BlinkingLiveIndicator extends StatefulWidget {
  @override
  _BlinkingLiveIndicatorState createState() => _BlinkingLiveIndicatorState();
}

class _BlinkingLiveIndicatorState extends State<BlinkingLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
