import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'gc_events.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gc_events.dart';
import 'constants.dart';

class GCPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          children: [
            _buildEventCard(
              context,
              FontAwesomeIcons.gamepad,
              'eSports',
              onTap: () => _fetchGCEvents(context, 'eSports'),
            ),
            _buildEventCard(
              context,
              FontAwesomeIcons.masksTheater,
              'cultural',
              onTap: () => _fetchGCEvents(context, 'cultural'),
            ),
            _buildEventCard(
              context,
              FontAwesomeIcons.microchip,
              'technical',
              onTap: () => _fetchGCEvents(context, 'technical'),
            ),
            _buildEventCard(
              context,
              FontAwesomeIcons.bookOpen,
              'literary',
              onTap: () => _fetchGCEvents(context, 'literary'),
            ),
            _buildEventCard(
              context,
              FontAwesomeIcons.futbol,
              'sports',
              onTap: () => _fetchGCEvents(context, 'sports'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchGCEvents(BuildContext context, String MainType) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get-gc-events?MainType=$MainType'),
    );
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final events = responseBody['data'];
      if (events is List) {
        if (events.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No events found for $MainType')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GCEventsPage(events: events),
            ),
          );
        }
      } else {
        print('Unexpected response format');
      }
    } else {
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
