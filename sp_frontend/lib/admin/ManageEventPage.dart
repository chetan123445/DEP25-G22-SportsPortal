import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'package:flutter/foundation.dart'; // Add this for listEquals
import '../PlayerProfilePage.dart'; // Add this import

class ManageEventPage extends StatefulWidget {
  final String email;
  final String name;

  ManageEventPage({required this.email, required this.name});

  @override
  _ManageEventPageState createState() => _ManageEventPageState();
}

class _ManageEventPageState extends State<ManageEventPage> {
  List<dynamic> allEvents = [];
  String searchQuery = '';
  Map<String, dynamic> filters = {'eventType': [], 'gender': [], 'year': []};

  @override
  void initState() {
    super.initState();
    fetchAllEvents();
  }

  Future<void> fetchAllEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/all-events'));

      if (response.statusCode == 200) {
        List<dynamic> events = json.decode(response.body);

        if (searchQuery.isNotEmpty) {
          final searchTerms =
              searchQuery
                  .toLowerCase()
                  .split(',')
                  .map((e) => e.trim())
                  .toList();
          events =
              events.where((event) {
                return searchTerms.any((term) {
                  // Search in team names
                  final team1 = event['team1']?.toString().toLowerCase() ?? '';
                  final team2 = event['team2']?.toString().toLowerCase() ?? '';

                  // Search in date and time
                  final eventDate =
                      event['date']?.toString().split('T')[0].toLowerCase() ??
                      '';
                  final eventTime =
                      event['time']?.toString().toLowerCase() ?? '';

                  // Search in other fields
                  final venue = event['venue']?.toString().toLowerCase() ?? '';
                  final eventType =
                      event['eventType']?.toString().toLowerCase() ?? '';
                  final gender =
                      event['gender']?.toString().toLowerCase() ?? '';

                  return team1.contains(term) ||
                      team2.contains(term) ||
                      eventDate.contains(term) ||
                      eventTime.contains(term) ||
                      venue.contains(term) ||
                      eventType.contains(term) ||
                      gender.contains(term);
                });
              }).toList();
        }

        setState(() {
          allEvents = events;
        });
        print(
          'Fetched ${allEvents.length} events after filtering',
        ); // Debug log
      } else {
        print('Error: ${response.statusCode}'); // Debug log
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _updateTeamPlayers(
    String teamId,
    List<Map<String, dynamic>> players,
  ) async {
    try {
      print('Updating team $teamId with ${players.length} players');
      final response = await http.put(
        Uri.parse('$baseUrl/team/$teamId/players'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'players': players}),
      );

      if (response.statusCode != 200) {
        print('Error response: ${response.body}');
        throw Exception(
          'Failed to update team players: ${response.statusCode}',
        );
      }

      print('Team update response: ${response.body}');
    } catch (e) {
      print('Error updating team players: $e');
      rethrow;
    }
  }

  Future<String?> _createNewTeam(
    String teamName,
    List<Map<String, dynamic>> players,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-team'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'teamName': teamName, 'members': players}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['_id'];
      }
      return null;
    } catch (e) {
      print('Error creating team: $e');
      return null;
    }
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final Map<String, dynamic> originalEvent = Map.from(event);
    List<Map<String, dynamic>> eventManagers = [];
    List<Map<String, dynamic>> teamsList = [];

    // For GC events, fetch teams data
    if (event['eventType'] == 'GC') {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/gc-event/${event['_id']}/teams'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            // Preserve existing team IDs when mapping
            teamsList = List<Map<String, dynamic>>.from(
              data['teams'].map(
                (team) => {
                  '_id': team['_id'],
                  'teamName': team['teamName'],
                  'members': List<Map<String, dynamic>>.from(team['members']),
                },
              ),
            );
          });
          print('Fetched ${teamsList.length} teams with details');
        }
      } catch (e) {
        print('Error fetching team details: $e');
      }
    }

    if (event['eventManagers'] != null) {
      eventManagers = List<Map<String, dynamic>>.from(
        event['eventManagers'].map((m) => Map<String, dynamic>.from(m)),
      );
    }

    // Controllers for common fields
    final venueController = TextEditingController(text: event['venue']);
    final timeController = TextEditingController(text: event['time']);
    final dateController = TextEditingController(
      text: event['date']?.toString().split('T')[0],
    );
    final descriptionController = TextEditingController(
      text: event['description'] ?? '',
    );
    final genderController = TextEditingController(text: event['gender']);
    final winnerController = TextEditingController(text: event['winner'] ?? '');

    // Add non-GC teams section
    if (event['eventType'] != 'GC') {
      // Fetch team details for non-GC events
      try {
        final response = await http.get(
          Uri.parse(
            '$baseUrl/event/${event['_id']}/${event['eventType']}/teams',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          event['team1Details'] = data['team1']['details'];
          event['team2Details'] = data['team2']['details'];
        }
      } catch (e) {
        print('Error fetching team details: $e');
      }
    }

    // Create a map for updates
    Map<String, dynamic> updates = {};

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Event',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Common fields
                      _buildEditField('Venue', venueController),
                      _buildEditField('Time', timeController),
                      _buildEditField('Date (YYYY-MM-DD)', dateController),
                      _buildEditField('Description', descriptionController),
                      _buildEditField('Gender', genderController),
                      _buildEditField(
                        'Winner',
                        winnerController,
                        hintText: 'Leave empty if not decided',
                      ),

                      // GC Event Teams Section
                      if (event['eventType'] == 'GC') ...[
                        SizedBox(height: 20),
                        Text(
                          'Teams',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Show existing teams
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: teamsList.length,
                          itemBuilder: (context, teamIndex) {
                            final team = teamsList[teamIndex];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ExpansionTile(
                                title: Text(team['teamName'] ?? 'Unnamed Team'),
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: (team['members'] as List).length,
                                    itemBuilder: (context, playerIndex) {
                                      final player =
                                          team['members'][playerIndex];
                                      return ListTile(
                                        leading: Icon(Icons.person),
                                        title: Text(player['name'] ?? ''),
                                        subtitle: Text(player['email'] ?? ''),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              team['members'].removeAt(
                                                playerIndex,
                                              );
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.add),
                                          label: Text('Add Player'),
                                          onPressed: () async {
                                            final result = await showDialog<
                                              Map<String, dynamic>
                                            >(
                                              context: context,
                                              builder:
                                                  (context) =>
                                                      _AddPlayerDialog(),
                                            );
                                            if (result != null) {
                                              setState(() {
                                                if (team['members'] == null) {
                                                  team['members'] = [];
                                                }
                                                team['members'].add(result);
                                              });
                                            }
                                          },
                                        ),
                                        SizedBox(height: 8),
                                        TextButton.icon(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          label: Text('Delete Team'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              teamsList.removeAt(teamIndex);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Add new team button
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add New Team'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final result =
                                await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => _AddGCTeamDialog(),
                                );
                            if (result != null) {
                              setState(() {
                                // Add new team to existing list without affecting others
                                teamsList = List.from(teamsList)..add({
                                  'teamName': result['teamName'],
                                  'members': result['members'],
                                });
                              });
                            }
                          },
                        ),
                      ],

                      // Non-GC Event Teams Section
                      if (event['eventType'] != 'GC') ...[
                        SizedBox(height: 20),
                        Text(
                          'Teams',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Team 1 Section
                        Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            title: Text(event['team1'] ?? 'Team 1'),
                            children: [
                              _buildTeamPlayersSection(
                                event['team1'],
                                (event['team1Details']?['members'] ?? [])
                                    .cast<Map<String, dynamic>>(),
                                (index) {
                                  setState(() {
                                    if (event['team1Details'] == null) {
                                      event['team1Details'] = {'members': []};
                                    }
                                    event['team1Details']['members'].removeAt(
                                      index,
                                    );
                                  });
                                },
                                () async {
                                  final result =
                                      await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder:
                                            (context) => _AddPlayerDialog(),
                                      );
                                  if (result != null) {
                                    setState(() {
                                      if (event['team1Details'] == null) {
                                        event['team1Details'] = {'members': []};
                                      }
                                      event['team1Details']['members'].add(
                                        result,
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // Team 2 Section
                        Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            title: Text(event['team2'] ?? 'Team 2'),
                            children: [
                              _buildTeamPlayersSection(
                                event['team2'],
                                (event['team2Details']?['members'] ?? [])
                                    .cast<Map<String, dynamic>>(),
                                (index) {
                                  setState(() {
                                    if (event['team2Details'] == null) {
                                      event['team2Details'] = {'members': []};
                                    }
                                    event['team2Details']['members'].removeAt(
                                      index,
                                    );
                                  });
                                },
                                () async {
                                  final result =
                                      await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder:
                                            (context) => _AddPlayerDialog(),
                                      );
                                  if (result != null) {
                                    setState(() {
                                      if (event['team2Details'] == null) {
                                        event['team2Details'] = {'members': []};
                                      }
                                      event['team2Details']['members'].add(
                                        result,
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Event Managers Section
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Event Managers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add Manager'),
                            onPressed: () async {
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder:
                                        (context) => _AddEventManagerDialog(),
                                  );
                              if (result != null) {
                                setState(() {
                                  eventManagers.add(result);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: eventManagers.length,
                        itemBuilder: (context, index) {
                          final manager = eventManagers[index];
                          return ListTile(
                            title: Text(manager['name'] ?? ''),
                            subtitle: Text(manager['email'] ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  eventManagers.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              // Collect updates
                              if (venueController.text != event['venue'])
                                updates['venue'] = venueController.text;
                              if (timeController.text != event['time'])
                                updates['time'] = timeController.text;
                              if (dateController.text !=
                                  event['date']?.toString().split('T')[0])
                                updates['date'] = dateController.text;
                              if (descriptionController.text !=
                                  event['description'])
                                updates['description'] =
                                    descriptionController.text;
                              if (genderController.text != event['gender'])
                                updates['gender'] = genderController.text;
                              if (winnerController.text !=
                                  (event['winner'] ?? ''))
                                updates['winner'] =
                                    winnerController.text.isEmpty
                                        ? null
                                        : winnerController.text;

                              // Add team updates for non-GC events
                              if (event['eventType'] != 'GC') {
                                updates['team1Details'] = event['team1Details'];
                                updates['team2Details'] = event['team2Details'];
                              }

                              // Add team updates for GC events
                              if (event['eventType'] == 'GC') {
                                updates['teams'] = teamsList;
                              }

                              // Always include event managers in updates
                              updates['eventManagers'] = eventManagers;

                              // Rest of the update logic
                              try {
                                final response = await http.patch(
                                  Uri.parse('$baseUrl/update-event'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'eventId': event['_id'],
                                    'eventType': event['eventType'],
                                    'updates': updates,
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  Map<String, dynamic> updatedEvent = json
                                      .decode(response.body);
                                  print(
                                    'Updated event: ${updatedEvent['winner']}',
                                  ); // Debug log

                                  // Create notification message based on event type
                                  String notificationMessage;
                                  if (event['eventType'] == 'GC') {
                                    notificationMessage =
                                        'GC event details have been updated';
                                  } else {
                                    notificationMessage =
                                        '${event['team1']} vs ${event['team2']} - ${event['eventType']} event details have been updated';
                                  }

                                  // Send notification about event update
                                  await http.post(
                                    Uri.parse('$baseUrl/notifications/send'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: json.encode({
                                      'message': notificationMessage,
                                      'eventType': event['eventType'],
                                      'date': dateController.text,
                                      'time': timeController.text,
                                      'venue': venueController.text,
                                      'team1':
                                          event['eventType'] == 'GC'
                                              ? null
                                              : event['team1'],
                                      'team2':
                                          event['eventType'] == 'GC'
                                              ? null
                                              : event['team2'],
                                    }),
                                  );

                                  fetchAllEvents(); // Refresh the list
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Event updated successfully',
                                      ),
                                    ),
                                  );
                                } else {
                                  print(
                                    'Error updating event: ${response.body}',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update event'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating event'),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Update',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildGCTeamSection(
    Map<String, dynamic> team, {
    required Function(Map<String, dynamic>) onUpdateTeam,
    required Function() onDeleteTeam,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: team['teamName'],
              decoration: InputDecoration(labelText: 'Team Name'),
              onChanged: (value) {
                team['teamName'] = value;
                onUpdateTeam(team);
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: (team['members'] as List).length,
              itemBuilder: (context, index) {
                final player = team['members'][index];
                return ListTile(
                  title: Text(player['name']),
                  subtitle: Text(player['email']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      team['members'].removeAt(index);
                      onUpdateTeam(team);
                    },
                  ),
                );
              },
            ),
            ButtonBar(
              children: [
                TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Player'),
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => _AddPlayerDialog(),
                    );
                    if (result != null) {
                      team['members'].add(result);
                      onUpdateTeam(team);
                    }
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Delete Team'),
                  onPressed: onDeleteTeam,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Delete Event', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this event?\nThis will also delete all associated team details.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        // For GC events, we need to delete associated teams from participants array
        if (event['eventType'] == 'GC' && event['participants'] != null) {
          // Delete each team in the participants array
          for (var teamId in event['participants']) {
            try {
              await http.delete(
                Uri.parse('$baseUrl/team/${teamId.toString()}'),
              );
            } catch (e) {
              print('Error deleting team $teamId: $e');
            }
          }
        }

        final response = await http.delete(
          Uri.parse(
            '$baseUrl/delete-event/${event['_id']}/${event['eventType']}',
          ),
        );

        if (response.statusCode == 200) {
          // Create notification message based on event type
          String notificationMessage;
          if (event['eventType'] == 'GC') {
            notificationMessage = 'GC event has been cancelled';
          } else {
            notificationMessage =
                '${event['team1']} vs ${event['team2']} - ${event['eventType']} event has been cancelled';
          }

          // Send notification about event deletion
          await http.post(
            Uri.parse('$baseUrl/notifications/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'message': notificationMessage,
              'eventType': event['eventType'],
              'date': event['date']?.toString().split('T')[0] ?? 'N/A',
              'time': event['time'] ?? 'N/A',
              'venue': event['venue'] ?? 'N/A',
              'team1': event['eventType'] == 'GC' ? null : event['team1'],
              'team2': event['eventType'] == 'GC' ? null : event['team2'],
            }),
          );

          await fetchAllEvents(); // Refresh the list
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Event deleted successfully')));
        } else {
          throw Exception('Failed to delete event');
        }
      } catch (e) {
        print('Error deleting event: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting event')));
      }
    }
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildTeamPlayersSection(
    String teamName,
    List<Map<String, dynamic>> players,
    Function(int) onDelete,
    Function() onAdd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Players ($teamName)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          constraints: BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                title: Text(player['name'] ?? ''),
                subtitle: Text(player['email'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    print('Deleting player at index $index'); // Debug print
                    onDelete(index);
                  },
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          child: Text('Add Player'),
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showEventManagers(List<dynamic> managers, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Event Managers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  if (managers.isEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        'No Event Manager',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: managers.length,
                        itemBuilder: (context, index) {
                          final manager = managers[index];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PlayerProfilePage(
                                          playerName:
                                              manager['name'] ?? 'Unknown',
                                          playerEmail: manager['email'] ?? '',
                                        ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    manager['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Events'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Gradient Circles Background
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: Text(
                                      'Search Tips',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'You can search multiple fields at once by separating them with commas.\n\n'
                                      'Example: "male, basketball, 2024-03-20"\n\n'
                                      'Searchable fields:\n'
                                      '• Team names\n'
                                      '• Event type\n'
                                      '• Gender (male/female/neutral)\n'
                                      '• Date (YYYY-MM-DD)\n'
                                      '• Venue',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          'OK',
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText:
                                  'Search multiple fields (separate by comma)',
                              labelStyle: TextStyle(color: Colors.white),
                              hintText:
                                  'Search by team, venue, date, type, gender...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                              // Add debounce to avoid too many requests
                              Future.delayed(Duration(milliseconds: 300), () {
                                if (searchQuery == value) {
                                  fetchAllEvents();
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: allEvents.length,
                  itemBuilder: (context, index) {
                    final event = allEvents[index];
                    return _buildEventCard(context, event);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Card(
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        decoration: BoxDecoration(
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Type and Gender Row at top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          event['eventType'] ?? 'Unknown Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          event['gender'] ?? 'Unspecified',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Teams
                  Center(
                    child:
                        event['eventType'] == 'GC'
                            ? Container()
                            : // Don't show teams for GC events
                            Text(
                              '${event['team1']} vs ${event['team2']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                  ),
                  SizedBox(height: 12),

                  // Date and Time
                  Center(
                    child: Text(
                      '${event['date']?.toString().split('T')[0]} | ${event['time']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Venue
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Venue: ${event['venue']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Description (if available)
                  if (event['description'] != null &&
                      event['description'].toString().isNotEmpty)
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 8.0),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Description: ${event['description']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Bottom row with Event Managers and Edit/Delete buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Event Managers Container
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black),
                        ),
                        child: InkWell(
                          onTap:
                              () => _showEventManagers(
                                event['eventManagers'] ?? [],
                                context,
                              ),
                          child: Row(
                            children: [
                              Icon(Icons.people, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Event Managers',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Edit Button
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editEvent(event),
                          ),
                          // Delete Button
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(event),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEventManagerDialog extends StatelessWidget {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Event Manager'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _emailController.text.isNotEmpty) {
              Navigator.pop(context, <String, dynamic>{
                'name': _nameController.text,
                'email': _emailController.text,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class _AddPlayerDialog extends StatelessWidget {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Player'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _emailController.text.isNotEmpty) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'email': _emailController.text,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class _AddGCTeamDialog extends StatelessWidget {
  final teamNameController = TextEditingController();
  final List<Map<String, dynamic>> players = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Team'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamNameController,
              decoration: InputDecoration(labelText: 'Team Name'),
            ),
            SizedBox(height: 16),
            Text('Players:'),
            ...players
                .map(
                  (player) => ListTile(
                    title: Text(player['name']),
                    subtitle: Text(player['email']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => players.remove(player),
                    ),
                  ),
                )
                .toList(),
            ElevatedButton(
              child: Text('Add Player'),
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => _AddPlayerDialog(),
                );
                if (result != null) {
                  players.add(result);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text('Add Team'),
          onPressed: () {
            if (teamNameController.text.isNotEmpty && players.isNotEmpty) {
              Navigator.pop(context, {
                'teamName': teamNameController.text,
                'members': players,
              });
            }
          },
        ),
      ],
    );
  }
}
