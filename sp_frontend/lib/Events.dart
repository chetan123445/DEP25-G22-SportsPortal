import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Add this import for date formatting

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
  String selectedGender = 'All';
  String selectedSport = 'All';
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    String query = searchQuery.isNotEmpty ? '?search=$searchQuery' : '';
    if (selectedGender != 'All') {
      query += '&gender=$selectedGender';
    }
    if (selectedSport != 'All') {
      query += '&sport=$selectedSport';
    }
    if (selectedDateRange != null) {
      query +=
          '&startDate=${DateFormat('yyyy-MM-dd').format(selectedDateRange!.start)}';
      query +=
          '&endDate=${DateFormat('yyyy-MM-dd').format(selectedDateRange!.end)}';
    }

    final liveResponse = await http.get(
      Uri.parse('http://localhost:5000/live-events$query'),
    );
    final upcomingResponse = await http.get(
      Uri.parse('http://localhost:5000/upcoming-events$query'),
    );
    final pastResponse = await http.get(
      Uri.parse('http://localhost:5000/past-events$query'),
    );

    if (liveResponse.statusCode == 200 &&
        upcomingResponse.statusCode == 200 &&
        pastResponse.statusCode == 200) {
      setState(() {
        liveEvents = json.decode(liveResponse.body);
        upcomingEvents = json.decode(upcomingResponse.body);
        pastEvents = json.decode(pastResponse.body);
      });
    } else {
      print('Failed to load events');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Live'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by gender or type',
                border: OutlineInputBorder(),
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
                _buildEventsList(context, liveEvents),
                _buildEventsList(context, upcomingEvents),
                _buildEventsList(context, pastEvents),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<dynamic> events) {
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
  ) {
    bool isFavorite = false;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.blue.shade200],
          ),
        ),
        child: Column(
          children: [
            Text(
              eventType,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),

            // Teams
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(team1, textAlign: TextAlign.center)),
                Expanded(child: Text(team2, textAlign: TextAlign.center)),
              ],
            ),
            SizedBox(height: 8.0),

            // Date and Time
            Column(
              children: [
                Text(date, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8.0),

            // Type and Gender
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(gender, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8.0),

            // Fixed Venue Layout
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Venue: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    WidgetSpan(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 200),
                        child: Text(
                          venue,
                          style: TextStyle(fontWeight: FontWeight.normal),
                          overflow: TextOverflow.clip,
                          softWrap: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.0),

            // Favorite Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.yellow : null,
                  ),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                ),
                if (type.toLowerCase() == 'live') BlinkingLiveIndicator(),
              ],
            ),
          ],
        ),
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
    _controller = AnimationController(duration: Duration(seconds: 1), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: Icon(Icons.circle, color: Colors.red));
  }
}
