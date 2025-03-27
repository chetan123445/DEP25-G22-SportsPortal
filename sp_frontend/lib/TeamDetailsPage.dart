import 'package:flutter/material.dart';
import 'PlayerProfilePage.dart'; // Import the PlayerProfilePage

class TeamDetailsPage extends StatelessWidget {
  final Map<String, dynamic> teamDetails;

  const TeamDetailsPage({Key? key, required this.teamDetails})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team Details')),
      body: Column(
        children: [
          Container(
            // Gradient background up to "Players:" text
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      '${teamDetails['teamName']}',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Players:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Divider(
                  color: Colors.black, // Divider line below "Players:"
                  thickness: 1.5,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              // White background below the divider
              color: Colors.white,
              child: ListView.builder(
                itemCount: teamDetails['members'].length,
                itemBuilder: (context, index) {
                  final member = teamDetails['members'][index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(12.0),
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
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween, // Ensure proper alignment
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Vertically align items
                      children: [
                        Text(
                          '${index + 1}.',
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
                        MouseRegion(
                          cursor:
                              SystemMouseCursors
                                  .click, // Show hand cursor on hover
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PlayerProfilePage(
                                        playerName: member['name'],
                                        playerEmail: member['email'] ?? 'N/A',
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color:
                                    Colors
                                        .orange
                                        .shade200, // Orange color for "Profile"
                                shape: BoxShape.circle, // Circular shape
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person, // Profile icon
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
