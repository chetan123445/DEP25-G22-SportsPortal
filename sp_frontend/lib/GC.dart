import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'gc_events.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gc_events.dart';
import 'constants.dart';

class GCPage extends StatefulWidget {
  @override
  _GCPageState createState() => _GCPageState();
}

class _GCPageState extends State<GCPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final events = [
      {'icon': FontAwesomeIcons.gamepad, 'title': 'eSports'},
      {'icon': FontAwesomeIcons.masksTheater, 'title': 'cultural'},
      {'icon': FontAwesomeIcons.microchip, 'title': 'technical'},
      {'icon': FontAwesomeIcons.bookOpen, 'title': 'literary'},
      {'icon': FontAwesomeIcons.futbol, 'title': 'sports'},
    ];

    final filteredEvents =
        events
            .where(
              (event) => (event['title'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 79, 188, 247),
                Color.fromARGB(255, 142, 117, 205),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'GC Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search your Event',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                children:
                    filteredEvents.map((event) {
                      return _buildEventCard(
                        context,
                        event['icon'] as IconData,
                        event['title'] as String,
                        onTap:
                            () => _fetchGCEvents(
                              context,
                              event['title'] as String,
                            ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchGCEvents(BuildContext context, String MainType) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      print('Fetching GC events for MainType: $MainType');
      final response = await http.get(
        Uri.parse('$baseUrl/get-gc-events?MainType=$MainType'),
        headers: {'Content-Type': 'application/json'},
      );

      // Hide loading indicator
      Navigator.pop(context);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final events = responseData['data'];

        if (events == null) {
          throw Exception('No data field in response');
        }

        if (events is List && events.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GCEventsPage(events: events),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No events found for $MainType'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching GC events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading events: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEventCard(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(16.0),
                child: Icon(icon, size: 48.0, color: Colors.black),
              ),
              SizedBox(height: 8.0),
              Text(
                title,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
