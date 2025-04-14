import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'package:intl/intl.dart';
import 'PlayerProfilePage.dart';
import 'PHLEventDetailsPage.dart';
import 'BasketBrawlEventDetailsPage.dart'; // Add this import
import 'IRCCEventDetailsPage.dart'; // Add this import

class ManagingEventsPage extends StatefulWidget {
  final String email;

  ManagingEventsPage({required this.email});

  @override
  _ManagingEventsPageState createState() => _ManagingEventsPageState();
}

class _ManagingEventsPageState extends State<ManagingEventsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? managedEvents;
  bool isLoading = true;
  String searchQuery = '';
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    ); // 5 tabs for different event types
    fetchManagedEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchManagedEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/managed-events?email=${widget.email}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          managedEvents = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load managed events');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editEvent(String eventType, dynamic event) async {
    final TextEditingController venueController = TextEditingController(
      text: event['venue'],
    );
    final TextEditingController dateController = TextEditingController(
      text:
          event['date'] != null
              ? DateFormat('yyyy-MM-dd').format(DateTime.parse(event['date']))
              : '',
    );
    final TextEditingController timeController = TextEditingController(
      text: event['time'],
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Event Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(labelText: 'Venue'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: 'e.g. 2025-04-15',
                  ),
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      timeController.text =
                          '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                    }
                  },
                  child: IgnorePointer(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(labelText: 'Time'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate date format before saving
                try {
                  if (dateController.text.isNotEmpty) {
                    DateTime.parse(dateController.text);
                  }
                  Navigator.of(context).pop({
                    'venue': venueController.text,
                    'date': dateController.text,
                    'time': timeController.text,
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid date in YYYY-MM-DD format',
                      ),
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        // First update the event
        final response = await http.patch(
          Uri.parse('$baseUrl/update-event-details?email=${widget.email}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'eventType': eventType,
            'eventId': event['_id'],
            'venue': result['venue'],
            'date': result['date'],
            'time': result['time'],
          }),
        );

        if (response.statusCode == 200) {
          // Then send notification about the update
          final notificationResponse = await http.post(
            Uri.parse('$baseUrl/notifications/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'message':
                  '${event['team1']} vs ${event['team2']} - ${eventType} event details have been updated',
              'eventType': eventType,
              'date': result['date'],
              'time': result['time'], // Use the time from dialog result
              'venue': result['venue'],
              'team1': event['team1'],
              'team2': event['team2'],
            }),
          );

          if (notificationResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Event updated and notification sent')),
            );
          } else {
            print('Failed to send notification');
          }

          fetchManagedEvents(); // Refresh the events list
        } else {
          throw Exception('Failed to update event: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating event: $e')));
      }
    }
  }

  bool _eventMatchesSearch(dynamic event) {
    final query = searchQuery.toLowerCase();
    if (query.isEmpty) return true;

    return event['eventType']?.toString().toLowerCase().contains(query) ==
            true ||
        event['date']?.toString().toLowerCase().contains(query) == true ||
        event['time']?.toString().toLowerCase().contains(query) == true ||
        event['venue']?.toString().toLowerCase().contains(query) == true ||
        event['team1']?.toString().toLowerCase().contains(query) == true ||
        event['team2']?.toString().toLowerCase().contains(query) == true;
  }

  bool isEventLive(String? dateStr) {
    if (dateStr == null) return false;
    final eventDate = DateTime.parse(dateStr).toLocal();
    final today = DateTime.now();
    return eventDate.year == today.year &&
        eventDate.month == today.month &&
        eventDate.day == today.day;
  }

  Widget _buildEventCard(String eventType, dynamic event) {
    try {
      bool isLive = isEventLive(event['date']);
      return InkWell(
        onTap: () {
          if (eventType == 'PHL') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PHLEventDetailsPage(event: event),
              ),
            );
          } else if (eventType == 'BasketBrawl') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BasketBrawlEventDetailsPage(event: event),
              ),
            );
          } else if (eventType == 'IRCC') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IRCCEventDetailsPage(event: event),
              ),
            );
          }
        },
        child: Card(
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
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          event['eventType']?.toString() ?? 'Unknown Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    if (eventType == 'GC')
                      Container(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '${event['MainType'] ?? ''} - ${event['type'] ?? ''}',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (event['team1'] != null || event['team2'] != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event['team1']?.toString() ?? 'TBA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
                              event['team2']?.toString() ?? 'TBA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          event['date'] != null
                              ? DateFormat(
                                'yyyy-MM-dd',
                              ).format(DateTime.parse(event['date']))
                              : 'No date',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event['time']?.toString() ?? 'No time',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event['type']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event['gender']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0),
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
                        'Venue: ${event['venue']?.toString() ?? 'TBA'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (event['description'] != null &&
                        event['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          event['description'].toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            if (event['eventManagers'] == null ||
                                (event['eventManagers'] as List).isEmpty) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('No Event Managers'),
                                      content: Text(
                                        'No event managers have been assigned to this event.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
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
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people,
                                                size: 24,
                                                color: Colors.black,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Event Managers',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List<Widget>.from(
                                                (event['eventManagers']
                                                        as List<dynamic>)
                                                    .map(
                                                      (manager) => Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 4.0,
                                                            ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      context,
                                                                    ) => PlayerProfilePage(
                                                                      playerName:
                                                                          manager['name'] ??
                                                                          'Unknown',
                                                                      playerEmail:
                                                                          manager['email'] ??
                                                                          '',
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors
                                                                      .orange
                                                                      .shade200,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    5,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                CircleAvatar(
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
                                                                SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  manager['name'] ??
                                                                      'Unknown',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Colors
                                                                            .black,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Text(
                              'Event Managers',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _editEvent(eventType, event),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Text(
                              'Edit Event',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (eventType == 'PHL') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PHLEventDetailsPage(event: event),
                                ),
                              );
                            } else if (eventType == 'BasketBrawl') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BasketBrawlEventDetailsPage(
                                        event: event,
                                      ),
                                ),
                              );
                            } else if (eventType == 'IRCC') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          IRCCEventDetailsPage(event: event),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Text(
                              'Manage Event',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0),
                  ],
                ),
                if (isLive)
                  Positioned(left: 8, bottom: 8, child: BlinkingDot()),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building event card: $e');
      return Card(
        child: ListTile(
          title: Text('Error displaying event'),
          subtitle: Text('Please try again later'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Managing Events'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade200,
                Colors.blue.shade200,
                Colors.pink.shade100,
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'IYSC'),
            Tab(text: 'GC'),
            Tab(text: 'IRCC'),
            Tab(text: 'PHL'),
            Tab(text: 'BasketBrawl'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search by event type, date, time, venue, or team names',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : managedEvents == null
                    ? Center(child: Text('You are not an event manager'))
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventTypeList('IYSC'),
                        _buildEventTypeList('GC'),
                        _buildEventTypeList('IRCC'),
                        _buildEventTypeList('PHL'),
                        _buildEventTypeList('BasketBrawl'),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeList(String eventType) {
    final events = managedEvents?[eventType] ?? [];
    final filteredEvents = events.where(_eventMatchesSearch).toList();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          'No $eventType events to manage',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(eventType, filteredEvents[index]);
      },
    );
  }
}

class BlinkingDot extends StatefulWidget {
  @override
  _BlinkingDotState createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
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
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
