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
      String searchParam = Uri.encodeComponent(searchQuery);
      final response = await http.get(
        Uri.parse('$baseUrl/all-events?search=$searchParam'),
      );

      if (response.statusCode == 200) {
        setState(() {
          allEvents = json.decode(response.body);
        });
        print('Fetched ${allEvents.length} events'); // Debug log
      } else {
        print('Error: ${response.statusCode}'); // Debug log
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _showFilterDialog() async {
    // Copy from Events.dart _showFilterDialog implementation
    // ...existing code from Events.dart...
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    // Store the original values for comparison
    final Map<String, dynamic> originalEvent = Map.from(event);
    final TextEditingController team1Controller = TextEditingController(
      text: event['team1'],
    );
    final TextEditingController team2Controller = TextEditingController(
      text: event['team2'],
    );
    final TextEditingController venueController = TextEditingController(
      text: event['venue'],
    );
    final TextEditingController timeController = TextEditingController(
      text: event['time'],
    );
    final TextEditingController dateController = TextEditingController(
      text: event['date']?.toString().split('T')[0],
    );
    final TextEditingController descriptionController = TextEditingController(
      text: event['description'] ?? '',
    );
    final TextEditingController genderController = TextEditingController(
      text: event['gender'],
    );
    List<Map<String, dynamic>> eventManagers = [];
    if (event['eventManagers'] != null) {
      eventManagers = List<Map<String, dynamic>>.from(
        event['eventManagers'].map(
          (manager) => Map<String, dynamic>.from(manager),
        ),
      );
    }

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

                      // Edit form fields
                      _buildEditField('Team 1', team1Controller),
                      _buildEditField('Team 2', team2Controller),
                      _buildEditField('Venue', venueController),
                      _buildEditField('Time', timeController),
                      _buildEditField('Date (YYYY-MM-DD)', dateController),
                      _buildEditField('Description', descriptionController),
                      _buildEditField('Gender', genderController),

                      // Event Managers Section
                      SizedBox(height: 16),
                      Text(
                        'Event Managers',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: eventManagers.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(eventManagers[index]['name'] ?? ''),
                              subtitle: Text(
                                eventManagers[index]['email'] ?? '',
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    eventManagers.removeAt(index);
                                    // Update the original event immediately
                                    event['eventManagers'] = List.from(
                                      eventManagers,
                                    );
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        child: Text('Add Event Manager'),
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => _AddEventManagerDialog(),
                          );
                          if (result != null) {
                            setState(() {
                              eventManagers.add(result);
                              // Update the original event immediately
                              event['eventManagers'] = List.from(eventManagers);
                            });
                          }
                        },
                      ),

                      SizedBox(height: 16),
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
                              // Collect only changed fields
                              Map<String, dynamic> updates = {};

                              if (team1Controller.text !=
                                  originalEvent['team1'])
                                updates['team1'] = team1Controller.text;
                              if (team2Controller.text !=
                                  originalEvent['team2'])
                                updates['team2'] = team2Controller.text;
                              if (venueController.text !=
                                  originalEvent['venue'])
                                updates['venue'] = venueController.text;
                              if (timeController.text != originalEvent['time'])
                                updates['time'] = timeController.text;
                              if (dateController.text !=
                                  originalEvent['date']?.toString().split(
                                    'T',
                                  )[0])
                                updates['date'] = dateController.text;
                              if (descriptionController.text !=
                                  originalEvent['description'])
                                updates['description'] =
                                    descriptionController.text;
                              if (genderController.text !=
                                  originalEvent['gender'])
                                updates['gender'] = genderController.text;
                              if (!listEquals(
                                eventManagers.map((e) => e.toString()).toList(),
                                (originalEvent['eventManagers'] ?? [])
                                    .map((e) => e.toString())
                                    .toList(),
                              )) {
                                updates['eventManagers'] = eventManagers;
                              }

                              if (updates.isNotEmpty) {
                                try {
                                  final response = await http.patch(
                                    Uri.parse('$baseUrl/update-event'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: json.encode({
                                      'eventId': event['_id'],
                                      'eventType': event['eventType'],
                                      'updates': updates,
                                    }),
                                  );

                                  if (response.statusCode == 200) {
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
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No changes made')),
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

  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
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
                    child: Text(
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

                  // Bottom row with Event Managers and Edit button
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
                      // Edit Button
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editEvent(event),
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
