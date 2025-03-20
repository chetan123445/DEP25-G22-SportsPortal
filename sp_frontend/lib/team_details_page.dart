import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeamDetailsPage extends StatelessWidget {
  final String teamId;

  TeamDetailsPage({required this.teamId});

  Future<Map<String, dynamic>> fetchTeamDetails() async {
    final response = await http.get(
      Uri.parse('http://<your-server-url>/get-team-details/$teamId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['team'];
    } else {
      throw Exception('Failed to load team details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchTeamDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final teamDetails = snapshot.data!;
            return Container(
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Name: ${teamDetails['teamName']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Players:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: (teamDetails['members'] as List).length,
                        separatorBuilder:
                            (context, index) => Divider(color: Colors.black),
                        itemBuilder: (context, index) {
                          final member = teamDetails['members'][index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 16),
                                Expanded(child: Text(member['name'])),
                                Text(member['email']),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
