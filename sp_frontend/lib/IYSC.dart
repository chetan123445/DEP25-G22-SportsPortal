import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome package
import 'field_athletics.dart'; // Import the FieldAthleticsPage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'iysc_events_page.dart'; // Import the new IYSCEventsPage
import 'constants.dart'; // Import the baseUrl

class IYSCPage extends StatefulWidget {
  @override
  _IYSCPageState createState() => _IYSCPageState();
}

class _IYSCPageState extends State<IYSCPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final events = [
      {'icon': Icons.sports_cricket, 'title': 'Cricket'},
      {'icon': Icons.sports_soccer, 'title': 'Football'},
      {'icon': Icons.sports_tennis, 'title': 'Table Tennis'},
      {'icon': Icons.sports_tennis, 'title': 'Tennis'},
      {'icon': Icons.sports_hockey, 'title': 'Hockey'},
      {'icon': Icons.directions_run, 'title': 'Field Athletics'},
      {'icon': FontAwesomeIcons.dumbbell, 'title': 'Weightlifting'},
      {'icon': FontAwesomeIcons.weight, 'title': 'Powerlifting'},
      {'icon': FontAwesomeIcons.chess, 'title': 'Chess'},
      {'icon': FontAwesomeIcons.feather, 'title': 'Badminton'},
      {'icon': FontAwesomeIcons.basketballBall, 'title': 'Basketball'},
      {'icon': FontAwesomeIcons.volleyballBall, 'title': 'Volleyball'},
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
              'IYSC Events',
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
              decoration: InputDecoration(
                hintText: 'Search your Sport',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  filteredEvents.isEmpty
                      ? Center(
                        child: Text(
                          'No such sport found',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        children:
                            filteredEvents.map((event) {
                              return _buildEventCard(
                                context,
                                event['icon'] as IconData,
                                event['title'] as String,
                                onTap: () {
                                    _fetchIYSCEvents(
                                      context,
                                      event['title'] as String,
                                    );
                                  },
                              );
                            }).toList(),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchIYSCEvents(BuildContext context, String type) async {
    // Convert type to lowercase before sending to API
    final normalizedType = type.toLowerCase();
    final response = await http.get(
      Uri.parse('$baseUrl/get-iysc-events?type=$normalizedType'),
    );
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final events = responseBody['data'];
      if (events is List) {
        if (events.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No events found for $type')));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IYSCEventsPage(events: events),
            ),
          );
        }
      } else {
        print('Unexpected response format');
      }
    } else {
      // Handle error
      print('Failed to load events');
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
