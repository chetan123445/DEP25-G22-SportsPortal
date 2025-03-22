import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart'; // Import the baseUrl

class TeamDetailsPage extends StatefulWidget {
  final String teamId;

  TeamDetailsPage({required this.teamId});

  @override
  _TeamDetailsPageState createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  Map<String, dynamic>? teamDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    try {
      print('Fetching details for teamId: ${widget.teamId}');
      final response = await http.get(
        Uri.parse('$baseUrl/get-team-details/${widget.teamId}'), // Use baseUrl
      );

      if (response.statusCode == 200) {
        setState(() {
          teamDetails = json.decode(response.body)['team'];
          isLoading = false;
        });
      } else {
        print('Failed to load team details');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching team details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team Details')),
      body: Container(
        decoration: BoxDecoration(
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
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : teamDetails == null
                ? Center(child: Text('Failed to load team details'))
                : ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Team Name: ',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${teamDetails!['teamName']}',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue, // Changed color to blue
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Divider(
                      color: Colors.black,
                      thickness: 2.0,
                      indent: 0,
                      endIndent: 0,
                      height: 20,
                    ),
                    Text(
                      'Players:',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (teamDetails!['members'] == null ||
                        teamDetails!['members'].isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'No team members have been added yet.',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                      )
                    else
                      ...teamDetails!['members'].asMap().entries.map<Widget>((
                        entry,
                      ) {
                        int index = entry.key + 1;
                        var member = entry.value;
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color:
                                Colors
                                    .lightGreen
                                    .shade100, // Changed color to light green
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$index.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  member['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  softWrap: true,
                                ),
                              ),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  member['email'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
      ),
    );
  }
}
