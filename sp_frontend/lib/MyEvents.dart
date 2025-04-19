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
  bool isLoading = true; // Add loading state

  Future<List<dynamic>> _fetchMyEvents(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-events?email=$email'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['events'] ?? [];
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true; // Show loading state while fetching
    });

    try {
      final events = await _fetchMyEvents(widget.email);
      if (mounted) {
        setState(() {
          allEvents = events;
          filteredEvents = events;
          isLoading = false; // Hide loading state after fetch completes
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading state even if there's an error
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchUpdatedEventDetails(
    String eventType,
    String eventId,
  ) async {
    try {
      // Fix the URL for BasketBrawl events
      final urlPath =
          eventType == 'Basket Brawl' ? 'basketbrawl' : eventType.toLowerCase();
      final response = await http.get(
        Uri.parse('$baseUrl/$urlPath/event/$eventId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (eventType == 'IRCC') {
          // Parse IRCC scores correctly
          final event = data['event'];
          if (event['team1Score'] != null) {
            event['team1Score'] = {
              'runs':
                  int.tryParse(
                    event['team1Score']['scoreString'].split('/')[0],
                  ) ??
                  0,
              'wickets':
                  int.tryParse(
                    event['team1Score']['scoreString'].split('/')[1],
                  ) ??
                  0,
              'overs':
                  int.tryParse(
                    event['team1Score']['oversString'].split('.')[0],
                  ) ??
                  0,
              'balls':
                  int.tryParse(
                    event['team1Score']['oversString'].split('.')[1],
                  ) ??
                  0,
            };
          }
          if (event['team2Score'] != null) {
            event['team2Score'] = {
              'runs':
                  int.tryParse(
                    event['team2Score']['scoreString'].split('/')[0],
                  ) ??
                  0,
              'wickets':
                  int.tryParse(
                    event['team2Score']['scoreString'].split('/')[1],
                  ) ??
                  0,
              'overs':
                  int.tryParse(
                    event['team2Score']['oversString'].split('.')[0],
                  ) ??
                  0,
              'balls':
                  int.tryParse(
                    event['team2Score']['oversString'].split('.')[1],
                  ) ??
                  0,
            };
          }
          return event;
        }
        return data['event'];
      }
      throw Exception('Failed to fetch event details');
    } catch (e) {
      print('Error fetching event details: $e');
      throw e;
    }
  }

  void _showEventDetails(Map<String, dynamic> event) async {
    final eventType = event['eventType'];

    if (['IYSC', 'GC'].contains(eventType)) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Event Details'),
              content: Text(
                'Event details feature for $eventType events will be available soon.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    try {
      final updatedEvent = await _fetchUpdatedEventDetails(
        eventType,
        event['_id'],
      );

      if (!mounted) return;

      switch (eventType) {
        case 'IRCC':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => IRCCEventDetailsPage(
                    event: updatedEvent,
                    isReadOnly: true,
                  ),
            ),
          );
          break;
        case 'PHL':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PHLEventDetailsPage(
                    event: updatedEvent,
                    isReadOnly: true,
                  ),
            ),
          );
          break;
        case 'Basket Brawl':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BasketBrawlEventDetailsPage(
                    event: updatedEvent,
                    isReadOnly: true,
                  ),
            ),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load event details')));
    }
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
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading your events...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : filteredEvents.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: Colors.green,
                                width: 1.5,
                              ),
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
                        ],
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
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      alignment: WrapAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.people, size: 16),
                                          label: Text('Event Managers'),
                                          onPressed: () {
                                            final eventManagers =
                                                event['eventManagers'];
                                            if (eventManagers == null ||
                                                eventManagers.isEmpty) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: Text(
                                                        'No Event Managers',
                                                      ),
                                                      content: Text(
                                                        'No event managers have been assigned to this event.',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                          child: Text('OK'),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              return;
                                            }

                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    content: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.0,
                                                            ),
                                                        gradient: LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end:
                                                              Alignment
                                                                  .bottomRight,
                                                          colors: [
                                                            Colors
                                                                .purple
                                                                .shade200,
                                                            Colors
                                                                .blue
                                                                .shade200,
                                                            Colors
                                                                .pink
                                                                .shade100,
                                                          ],
                                                        ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16.0,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Event Managers',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),
                                                          ...List<Widget>.from(
                                                            eventManagers.map((
                                                              manager,
                                                            ) {
                                                              return ListTile(
                                                                leading: CircleAvatar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue
                                                                          .shade100,
                                                                  child: Icon(
                                                                    Icons
                                                                        .person,
                                                                    color:
                                                                        Colors
                                                                            .blue,
                                                                  ),
                                                                ),
                                                                title: Text(
                                                                  manager['name'] ??
                                                                      'Unknown',
                                                                ),
                                                                subtitle: Text(
                                                                  manager['email'] ??
                                                                      '',
                                                                ),
                                                                onTap: () {
                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (
                                                                            context,
                                                                          ) => PlayerProfilePage(
                                                                            playerName:
                                                                                manager['name'],
                                                                            playerEmail:
                                                                                manager['email'],
                                                                          ),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            }),
                                                          ),
                                                          SizedBox(height: 16),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.black,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            child: Text(
                                                              'Close',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.orange.shade200,
                                            foregroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          icon: Icon(
                                            Icons.info_outline,
                                            size: 16,
                                          ),
                                          label: Text('Event Details'),
                                          onPressed:
                                              () => _showEventDetails(event),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.orange.shade200,
                                            foregroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          icon: Icon(
                                            Icons.emoji_events,
                                            size: 16,
                                          ),
                                          label: Text('View Result'),
                                          onPressed: () {
                                            String message = '';
                                            DateTime eventDate = DateTime.parse(
                                              event['date'],
                                            );
                                            DateTime now = DateTime.now();

                                            if (eventDate.year == now.year &&
                                                eventDate.month == now.month &&
                                                eventDate.day == now.day) {
                                              message =
                                                  'Match is live, results will be updated soon';
                                            } else if (eventDate.isAfter(now)) {
                                              message =
                                                  'Match has not started yet';
                                            } else {
                                              if (event['winner'] == null ||
                                                  event['winner'].isEmpty) {
                                                message =
                                                    'No results available';
                                              } else if (event['winner'] ==
                                                  'Draw') {
                                                message =
                                                    'Match ended in a draw';
                                              } else {
                                                message =
                                                    '${event['winner']} won this match!';
                                              }
                                            }

                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: Text('Match Status'),
                                                    content: Text(message),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.orange.shade200,
                                            foregroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.0),
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
