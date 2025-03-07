import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> liveEvents = [];
  List<dynamic> upcomingEvents = [];
  List<dynamic> pastEvents = [];

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
    final liveResponse = await http.get(Uri.parse('http://localhost:5000/live-events'));
    final upcomingResponse = await http.get(Uri.parse('http://localhost:5000/upcoming-events'));
    final pastResponse = await http.get(Uri.parse('http://localhost:5000/past-events'));

    if (liveResponse.statusCode == 200 && upcomingResponse.statusCode == 200 && pastResponse.statusCode == 200) {
      setState(() {
        liveEvents = json.decode(liveResponse.body);
        upcomingEvents = json.decode(upcomingResponse.body);
        pastEvents = json.decode(pastResponse.body);
      });
      print('Live Events: $liveEvents');
      print('Upcoming Events: $upcomingEvents');
      print('Past Events: $pastEvents');
    } else {
      // Handle error
      print('Failed to load events');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 79, 188, 247), Color.fromARGB(255, 142, 117, 205)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Live'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(context, liveEvents),
          _buildEventsList(context, upcomingEvents),
          _buildEventsList(context, pastEvents),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<dynamic> events) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(
            context,
            event['type'] ?? 'No Type',
            event['date']?.split('T')[0] ?? 'No Date', // Trim the date part
            event['time'] ?? 'No Time',
            event['venue'] ?? 'No Venue',
            event['description'] ?? 'No Description',
            event['winner'],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    String type,
    String date,
    String time,
    String venue,
    String description,
    String? winner,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle event tap
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Type:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(type),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(date),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Time:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(time),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Venue:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(venue),
                  ],
                ),
                SizedBox(height: 8.0),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14.0),
                  maxLines: null,
                ),
                if (winner != null) ...[
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text(
                        'Winner:',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text(winner),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}