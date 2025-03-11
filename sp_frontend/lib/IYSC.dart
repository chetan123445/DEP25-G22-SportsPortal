import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome package
import 'field_athletics.dart'; // Import the FieldAthleticsPage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'iysc_events_page.dart'; // Import the new IYSCEventsPage

class IYSCPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          children: [
            _buildEventCard(context, Icons.sports_cricket, 'Cricket', onTap: () => _fetchIYSCEvents(context, 'Cricket')),
            _buildEventCard(context, Icons.sports_soccer, 'Football', onTap: () => _fetchIYSCEvents(context, 'Football')),
            _buildEventCard(context, Icons.sports_tennis, 'Table Tennis', onTap: () => _fetchIYSCEvents(context, 'Table Tennis')),
            _buildEventCard(context, Icons.sports_tennis, 'Tennis', onTap: () => _fetchIYSCEvents(context, 'Tennis')),
            _buildEventCard(context, Icons.sports_hockey, 'Hockey', onTap: () => _fetchIYSCEvents(context, 'Hockey')),
            _buildEventCard(context, Icons.directions_run, 'Field Athletics', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FieldAthleticsPage()),
              );
            }),
            _buildEventCard(context, FontAwesomeIcons.dumbbell, 'Weightlifting', onTap: () => _fetchIYSCEvents(context, 'Weightlifting')),
            _buildEventCard(context, FontAwesomeIcons.weight, 'Powerlifting', onTap: () => _fetchIYSCEvents(context, 'Powerlifting')),
            _buildEventCard(context, FontAwesomeIcons.chess, 'Chess', onTap: () => _fetchIYSCEvents(context, 'Chess')),
            _buildEventCard(context, FontAwesomeIcons.feather, 'Badminton', onTap: () => _fetchIYSCEvents(context, 'Badminton')), // Badminton icon
            _buildEventCard(context, FontAwesomeIcons.basketballBall, 'Basketball', onTap: () => _fetchIYSCEvents(context, 'Basketball')), // Basketball icon
            _buildEventCard(context, FontAwesomeIcons.volleyballBall, 'Volleyball', onTap: () => _fetchIYSCEvents(context, 'Volleyball')), // Volleyball icon
          ],
        ),
      ),
    );
  }

  Future<void> _fetchIYSCEvents(BuildContext context, String type) async {
    final response = await http.get(Uri.parse('http://localhost:5000/get-iysc-events?type=$type'));
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final events = responseBody['data'];
      if (events is List) {
        if (events.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No events found for $type')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IYSCEventsPage(events: events)),
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

  Widget _buildEventCard(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
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
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}