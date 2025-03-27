import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart'; // Import the baseUrl
import 'PlayerProfilePage.dart'; // Import the PlayerProfilePage

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
      appBar: AppBar(
        title: Text('Team Details'),
        // Removed PopupMenuButton
      ),
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
                            color: Colors.blue,
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
                    SizedBox(height: 8.0),
                    CustomPaint(
                      size: Size(double.infinity, 1),
                      painter: DashPainter(), // Dotted line
                    ),
                    Container(
                      color: Colors.white, // Background color below the line
                      child: Column(
                        children:
                            teamDetails!['members'].asMap().entries.map<
                              Widget
                            >((entry) {
                              int index = entry.key + 1;
                              var member = entry.value;
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
                                  ), // Player box gradient
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
                                      CrossAxisAlignment
                                          .center, // Vertically align items
                                  children: [
                                    Text(
                                      '$index.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        member['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                                  (context) =>
                                                      PlayerProfilePage(
                                                        playerName:
                                                            member['name'],
                                                        playerEmail:
                                                            member['email'] ??
                                                            'N/A',
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
                                            shape:
                                                BoxShape
                                                    .circle, // Circular shape
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.5,
                                                ),
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
                            }).toList(),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
