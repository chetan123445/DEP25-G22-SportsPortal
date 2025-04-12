import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart'; // Import constants for baseUrl
import 'package:intl/intl.dart'; // Import for date formatting
import 'IRCCEventDetailsPage.dart';
import 'PHLEventDetailsPage.dart';
import 'BasketBrawlEventDetailsPage.dart';
import 'PlayerProfilePage.dart';
import 'team_details_page.dart'; // Import TeamDetailsPage
import 'participants_page.dart';

class MyEventsPage extends StatefulWidget {
  final String email;

  MyEventsPage({required this.email});

  @override
  _MyEventsPageState createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List<dynamic> allEvents = [];
  List<dynamic> filteredEvents = [];
  String searchQuery = '';

  Future<List<dynamic>> _fetchMyEvents(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-events?email=$email'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Print event data to debug
        print('Fetched events data: ${data['events']}');
        return data['events'] ?? [];
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    return [];
  }

  String _formatDate(String date) {
    // Remove the timestamp from the date
    return date.split('T')[0];
  }

  bool _isLiveEvent(String eventDate) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return eventDate == today;
  }

  void _filterEvents(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredEvents =
          allEvents.where((event) {
            final team1 = (event['team1'] ?? '').toLowerCase();
            final team2 = (event['team2'] ?? '').toLowerCase();
            final venue = (event['venue'] ?? '').toLowerCase();
            final date = _formatDate(event['date'] ?? '').toLowerCase();
            final time = (event['time'] ?? '').toLowerCase();
            final eventType = (event['eventType'] ?? '').toLowerCase();

            return team1.contains(searchQuery) ||
                team2.contains(searchQuery) ||
                venue.contains(searchQuery) ||
                date.contains(searchQuery) ||
                time.contains(searchQuery) ||
                eventType.contains(searchQuery);
          }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchMyEvents(widget.email).then((events) {
      setState(() {
        allEvents = events;
        filteredEvents = events;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Events', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white), // Make back arrow white
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterEvents,
            ),
          ),
          Expanded(
            child:
                filteredEvents.isEmpty
                    ? Center(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Text(
                          'No Events found for you',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        final eventName = event['eventType'] ?? 'Unknown Event';
                        final eventDate = _formatDate(
                          event['date'] ?? 'Unknown Date',
                        );
                        final eventTime = event['time'] ?? 'Unknown Time';
                        final eventVenue = event['venue'] ?? 'Unknown Venue';
                        final team1 = event['team1'] ?? 'Team 1';
                        final team2 = event['team2'] ?? 'Team 2';
                        final eventDescription = event['description'];
                        final isLive = _isLiveEvent(eventDate);

                        return Stack(
                          children: [
                            Card(
                              elevation: 3.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
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
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Event Type in the center of the box
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 3.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Text(
                                          eventName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.0),
                                    // Team Names (Exclude for "GC" events)
                                    if (eventName != 'GC')
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (event['team1Details'] ==
                                                      null) {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: Text(
                                                              'Team Details Not Available',
                                                            ),
                                                            content: Text(
                                                              'Team member details for "$team1" have not been added yet.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child: Text(
                                                                  'OK',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => TeamDetailsPage(
                                                              teamId:
                                                                  event['team1Details']['_id'], // Get the _id field
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  team1,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
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
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (event['team2Details'] ==
                                                      null) {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: Text(
                                                              'Team Details Not Available',
                                                            ),
                                                            content: Text(
                                                              'Team member details for "$team2" have not been added yet.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child: Text(
                                                                  'OK',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => TeamDetailsPage(
                                                              teamId:
                                                                  event['team2Details']['_id'], // Get the _id field
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  team2,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 8.0),
                                    // View Participants for "GC" events
                                    if (eventName == 'GC')
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            ParticipantsPage(
                                                              eventId:
                                                                  event['_id'],
                                                            ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'View Participants',
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 8.0),
                                    // Date & Time Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          eventDate,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          eventTime,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.0),
                                    // Venue Box
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        'Venue: $eventVenue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    // Description (if available)
                                    if (eventDescription != null &&
                                        eventDescription.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 3.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Text(
                                          'Description: $eventDescription',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: 12.0),
                                    // Remove all buttons section
                                    SizedBox(height: 4.0),
                                  ],
                                ),
                              ),
                            ),
                            // Blinking Live Indicator
                            if (isLive)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: BlinkingLiveIndicator(),
                              ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
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
