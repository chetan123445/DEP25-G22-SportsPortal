import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'package:intl/intl.dart';
import 'IRCCEventDetailsPage.dart';
import 'PHLEventDetailsPage.dart';
import 'BasketBrawlEventDetailsPage.dart';
import 'PlayerProfilePage.dart';
import 'team_details_page.dart';
import 'participants_page.dart';

class PlayerEventsPage extends StatefulWidget {
  final String playerName;
  final String playerEmail;

  PlayerEventsPage({required this.playerName, required this.playerEmail});

  @override
  _PlayerEventsPageState createState() => _PlayerEventsPageState();
}

class _PlayerEventsPageState extends State<PlayerEventsPage> {
  List<dynamic> allEvents = [];
  List<dynamic> filteredEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayerEvents();
  }

  Future<void> _fetchPlayerEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-events?email=${widget.playerEmail}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allEvents = data['events'] ?? [];
          filteredEvents = allEvents;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching events: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterEvents(String query) {
    setState(() {
      filteredEvents =
          allEvents.where((event) {
            final searchStr = query.toLowerCase();
            return (event['eventType']?.toString().toLowerCase() ?? '')
                    .contains(searchStr) ||
                (event['venue']?.toString().toLowerCase() ?? '').contains(
                  searchStr,
                ) ||
                (event['team1']?.toString().toLowerCase() ?? '').contains(
                  searchStr,
                ) ||
                (event['team2']?.toString().toLowerCase() ?? '').contains(
                  searchStr,
                );
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.playerName}'s Events",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Make back arrow white
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Events',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterEvents,
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredEvents.isEmpty
                    ? Center(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Text(
                          'No Events found for this player',
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
                        return Card(
                          elevation: 3.0,
                          margin: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
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
                            padding: EdgeInsets.all(12.0),
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
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      event['eventType'] ?? 'Unknown Event',
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
                                if (event['eventType'] != 'GC' &&
                                    event['team1'] != null &&
                                    event['team2'] != null)
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
                                                      (context) => AlertDialog(
                                                        title: Text(
                                                          'Team Details Not Available',
                                                        ),
                                                        content: Text(
                                                          'Team member details for "${event['team1']}" have not been added yet.',
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
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => TeamDetailsPage(
                                                          teamId:
                                                              event['team1Details']['_id'], // Access the _id field
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              event['team1'],
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
                                                      (context) => AlertDialog(
                                                        title: Text(
                                                          'Team Details Not Available',
                                                        ),
                                                        content: Text(
                                                          'Team member details for "${event['team2']}" have not been added yet.',
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
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => TeamDetailsPage(
                                                          teamId:
                                                              event['team2Details']['_id'], // Access the _id field
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              event['team2'],
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
                                if (event['eventType'] == 'GC')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                                          eventId: event['_id'],
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
                                      event['date']?.split('T')[0] ?? 'TBD',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      event['time'] ?? 'TBD',
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
                                    'Venue: ${event['venue'] ?? 'TBD'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Add Description if available
                                if (event['description'] != null &&
                                    event['description'].isNotEmpty)
                                  Column(
                                    children: [
                                      SizedBox(height: 4.0),
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
                                          'Description: ${event['description']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: 12.0),
                                // Remove all buttons section
                                SizedBox(height: 4.0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
