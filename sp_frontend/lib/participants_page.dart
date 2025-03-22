import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart'; // Import baseUrl

class ParticipantsPage extends StatefulWidget {
  final String eventId;

  ParticipantsPage({required this.eventId});

  @override
  _ParticipantsPageState createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  List<Map<String, dynamic>> teamDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-event-participants/${widget.eventId}'),
      );

      if (response.statusCode == 200) {
        final participants = json.decode(response.body)['participants'];
        if (participants is List) {
          setState(() {
            teamDetails = participants.cast<Map<String, dynamic>>();
            isLoading = false;
          });
        }
      } else {
        print('Failed to load participants: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching participants: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Participants')),
      body: Container(
        color: Colors.white, // Set background color to white
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : teamDetails.isEmpty
                ? Center(child: Text('No participants found'))
                : ListView.separated(
                  itemCount: teamDetails.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16.0),
                  itemBuilder: (context, index) {
                    final team = teamDetails[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          // Apply gradient to the box
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade200,
                            Colors.blue.shade200,
                            Colors.pink.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.black), // Black border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team ${index + 1}: ${team['teamName'] ?? 'No Name'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Participants:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Divider(
                            color: Colors.black45, // Dashed line
                            thickness: 1.0,
                            height: 1.0,
                          ),
                          SizedBox(height: 8.0),
                          ...?team['members']?.asMap().entries.map<Widget>((
                            entry,
                          ) {
                            final memberIndex = entry.key + 1;
                            final member = entry.value;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width:
                                            30.0, // Fixed width for serial number
                                        child: Text(
                                          '$memberIndex.',
                                          style: TextStyle(fontSize: 14.0),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10.0,
                                      ), // Space between serial number and name
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          member['name'],
                                          style: TextStyle(fontSize: 14.0),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10.0,
                                      ), // Space between name and email
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          member['email'],
                                          style: TextStyle(fontSize: 14.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (entry.key < team['members'].length - 1)
                                  Divider(
                                    color: Colors.black45, // Light black line
                                    thickness: 1.0,
                                  ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
