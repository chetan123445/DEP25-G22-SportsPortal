import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../services/event_services.dart';
import '../adminDashboard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'dart:async';

class EventServices {
  static Future<bool> addGCEvent({
    required String gender,
    required String eventType,
    required String mainType,
    required String type,
    required DateTime date,
    required String time,
    required String venue,
    String? description,
    String? winner,
    required List<Map<String, dynamic>> participants,
    List<EventManager>? eventManagers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-GCevent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'MainType': mainType, // Corrected field name
          'eventType': eventType,
          'type': type,
          'gender': gender,
          'date': date.toIso8601String(),
          'time': time,
          'venue': venue,
          'description': description,
          'winner': winner,
          'participants':
              participants
                  .map(
                    (participant) => {
                      'teamName': participant['teamName'],
                      'members':
                          participant['members']
                              .map(
                                (member) => {
                                  'name': member['name'],
                                  'email': member['email'],
                                },
                              )
                              .toList(),
                    },
                  )
                  .toList(),
          'eventManagers':
              eventManagers
                  ?.map((e) => {'name': e.name, 'email': e.email})
                  .toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('GC Event added successfully');
        return true;
      } else {
        print('Failed to add GC Event: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding GC Event: $e');
      return false;
    }
  }

  static Future<bool> addEvent({
    required String gender,
    required String eventType,
    String? mainType,
    required String type,
    required DateTime date,
    required String time,
    required String venue,
    String? description,
    String? winner,
    required String team1,
    required String team2,
    Team? team1Details,
    Team? team2Details,
    List<EventManager>? eventManagers,
  }) async {
    try {
      // Determine the correct endpoint based on the event type
      String endpoint;
      switch (eventType) {
        case 'IYSC':
          endpoint = '/add-IYSCevent';
          break;
        case 'IRCC':
          endpoint = '/add-IRCCevent';
          break;
        case 'PHL':
          endpoint = '/add-PHLevent';
          break;
        case 'Basket Brawl':
          endpoint = '/add-BasketBrawlevent';
          break;
        default:
          throw Exception('Invalid event type');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'gender': gender,
          'eventType': eventType,
          'mainType': mainType,
          'type': type,
          'date': date.toIso8601String(),
          'time': time,
          'venue': venue,
          'description': description,
          'winner': winner,
          'team1': team1,
          'team2': team2,
          'team1Details':
              team1Details != null
                  ? {
                    'teamName': team1Details.teamName,
                    'members':
                        team1Details.members
                            .map((m) => {'name': m.name, 'email': m.email})
                            .toList(),
                  }
                  : null,
          'team2Details':
              team2Details != null
                  ? {
                    'teamName': team2Details.teamName,
                    'members':
                        team2Details.members
                            .map((m) => {'name': m.name, 'email': m.email})
                            .toList(),
                  }
                  : null,
          'eventManagers':
              eventManagers
                  ?.map((e) => {'name': e.name, 'email': e.email})
                  .toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Event added successfully');
        return true;
      } else {
        print('Failed to add Event: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding Event: $e');
      return false;
    }
  }
}

class EventManager {
  String name;
  String email;

  EventManager({required this.name, required this.email});
}

class AddEventPage extends StatefulWidget {
  final String email;
  final String name;

  AddEventPage({required this.email, required this.name});

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _eventType = '';
  String _type = '';
  DateTime? _date;
  String _time = '';
  String _venue = '';
  String? _description;
  String? _winner;
  String _team1 = '';
  String _team2 = '';
  String? selectedGender;
  bool _showValidationErrors = false;

  // Event type dropdown variables
  String? selectedEventType;
  String? selectedMainType; // For GC option
  String? selectedType; // For the Type dropdown
  final TextEditingController _customTypeController =
      TextEditingController(); // For custom type input

  // Event type dropdown options
  final List<String> eventTypeOptions = [
    'GC',
    'IYSC',
    'IRCC',
    'PHL',
    'Basket Brawl',
  ];
  final List<String> gcMainTypeOptions = [
    'Cultural',
    'Technical',
    'Literacy',
    'Sports',
    'eSports',
  ];
  final List<String> iyscTypeOptions = [
    'Cricket',
    'Football',
    'Table Tennis',
    'Tennis',
    'Hockey',
    'Field Athletics',
    'Weightlifting',
    'Powerlifting',
    'Chess',
    'Badminton',
    'Basketball',
    'Volleyball',
  ];

  // Define the options for each Main Type
  final Map<String, List<String>> typeOptions = {
    'eSports': ['BGMI', 'COD', 'Other'],
    'Cultural': ['Dancing', 'Singing', 'Other'],
    'Technical': ['Coding', 'Hackathon', 'Other'],
    'Literacy': ['Poetry', 'Other'],
    'Sports': [
      'Cricket',
      'Football',
      'Table Tennis',
      'Tennis',
      'Hockey',
      'Field Athletics',
      'Weightlifting',
      'Powerlifting',
      'Chess',
      'Badminton',
      'Basketball',
      'Volleyball',
      'Other',
    ],
  };

  List<TeamMember> _team1Members = [];
  List<TeamMember> _team2Members = [];
  List<EventManager> _eventManagers = [];
  final FocusNode _dropdownFocusNode = FocusNode();
  bool _isDropdownFocused = false;

  // Add TextEditingControllers
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _team1Controller = TextEditingController();
  final TextEditingController _team2Controller = TextEditingController();

  // Add this to your state variables
  List<Map<String, dynamic>> participants = []; // List to store participants
  final TextEditingController _teamNameController =
      TextEditingController(); // Controller for team name
  final List<TextEditingController> _memberNameControllers =
      []; // Controllers for member names
  final List<TextEditingController> _memberEmailControllers =
      []; // Controllers for member emails

  @override
  void initState() {
    super.initState();
    _dropdownFocusNode.addListener(() {
      setState(() {
        _isDropdownFocused = _dropdownFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _venueController.dispose();
    _descriptionController.dispose();
    _team1Controller.dispose();
    _team2Controller.dispose();
    _customTypeController.dispose();
    _dropdownFocusNode.dispose();
    _teamNameController.dispose();
    _memberNameControllers.forEach((controller) => controller.dispose());
    _memberEmailControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Function to add a new participant
  void _addParticipant() {
    setState(() {
      participants.add({'teamName': '', 'members': []});
      _memberNameControllers.add(TextEditingController());
      _memberEmailControllers.add(TextEditingController());
    });
  }

  // Function to remove a participant
  void _removeParticipant(int index) {
    setState(() {
      participants.removeAt(index);
    });
  }

  // Function to add a member to a participant
  void _addMember(int participantIndex) {
    setState(() {
      participants[participantIndex]['members'].add({'name': '', 'email': ''});
      _memberNameControllers.add(TextEditingController());
      _memberEmailControllers.add(TextEditingController());
    });
  }

  // Function to remove a member from a participant
  void _removeMember(int participantIndex, int memberIndex) {
    setState(() {
      participants[participantIndex]['members'].removeAt(memberIndex);
    });
  }

  List<Widget> _buildTeamMembersList(bool isTeam1) {
    List<TeamMember> members = isTeam1 ? _team1Members : _team2Members;
    return members.asMap().entries.map((entry) {
      int index = entry.key;
      TeamMember member = entry.value;

      return Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey, // Always grey border for container
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Member ${index + 1}",
                  style: TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _removeTeamMember(index, isTeam1),
                ),
              ],
            ),
            TextFormField(
              initialValue: member.name,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name *',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                errorText:
                    _showValidationErrors && member.name.isEmpty
                        ? 'Name is required'
                        : null,
              ),
              onChanged: (value) {
                _updateTeamMember(index, isTeam1, name: value);
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: member.email,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email *',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                errorText:
                    _showValidationErrors && member.email.isEmpty
                        ? 'Email is required'
                        : null,
              ),
              onChanged: (value) {
                _updateTeamMember(index, isTeam1, email: value);
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildEventManagersList() {
    return _eventManagers.asMap().entries.map((entry) {
      int index = entry.key;
      EventManager manager = entry.value;

      return Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Event Manager ${index + 1}",
                  style: TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _removeEventManager(index),
                ),
              ],
            ),
            TextFormField(
              initialValue: manager.name,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name *',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _eventManagers[index].name = value;
                });
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: manager.email,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email *',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _eventManagers[index].email = value;
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  void _addTeamMember(bool isTeam1) {
    setState(() {
      if (isTeam1) {
        _team1Members.add(TeamMember(name: '', email: ''));
      } else {
        _team2Members.add(TeamMember(name: '', email: ''));
      }
    });
  }

  void _removeTeamMember(int index, bool isTeam1) {
    setState(() {
      if (isTeam1) {
        _team1Members.removeAt(index);
      } else {
        _team2Members.removeAt(index);
      }
    });
  }

  void _updateTeamMember(
    int index,
    bool isTeam1, {
    String? name,
    String? email,
    String? userId,
  }) {
    if (isTeam1) {
      if (name != null) _team1Members[index].name = name;
      if (email != null) _team1Members[index].email = email;
      if (userId != null) _team1Members[index].userId = userId;
    } else {
      if (name != null) _team2Members[index].name = name;
      if (email != null) _team2Members[index].email = email;
      if (userId != null) _team2Members[index].userId = userId;
    }
  }

  void _addEventManager() {
    setState(() {
      _eventManagers.add(EventManager(name: '', email: ''));
    });
  }

  void _removeEventManager(int index) {
    setState(() {
      _eventManagers.removeAt(index);
    });
  }

  Future<void> _addEvent() async {
    setState(() {
      _showValidationErrors = true;
    });

    // Check common required fields
    List<String> missingFields = [];

    if (selectedGender == null) {
      missingFields.add('Gender Category');
    }

    if (selectedEventType == null) {
      missingFields.add('Event Type');
    }

    if (selectedEventType == 'GC' && selectedMainType == null) {
      missingFields.add('Main Type');
    }

    if (selectedEventType == 'IYSC' && selectedType == null) {
      missingFields.add('Sport Type');
    }

    if (_date == null) {
      missingFields.add('Date');
    }

    if (_time.isEmpty) {
      missingFields.add('Time');
    }

    _venue = _venueController.text;
    if (_venue.isEmpty) {
      missingFields.add('Venue');
    }

    // Check fields specific to event type
    if (selectedEventType == 'GC') {
      // For GC events, check participants
      if (participants.isEmpty) {
        missingFields.add('Participants (at least one team)');
      } else {
        // Check if each participant has team name
        for (int i = 0; i < participants.length; i++) {
          if (participants[i]['teamName'] == null ||
              participants[i]['teamName'].isEmpty) {
            missingFields.add('Team name for Participant ${i + 1}');
          }
        }
      }
    } else {
      // For other event types, check team1 and team2
      _team1 = _team1Controller.text;
      if (_team1.isEmpty) {
        missingFields.add('Team 1 Name');
      }

      _team2 = _team2Controller.text;
      if (_team2.isEmpty) {
        missingFields.add('Team 2 Name');
      }
    }

    // If any required fields are missing, show them all in one dialog
    if (missingFields.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Missing Fields'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please fill in the following required fields:'),
                SizedBox(height: 10),
                ...missingFields
                    .map(
                      (field) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(field),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
            backgroundColor: Colors.grey[900],
            titleTextStyle: TextStyle(color: Colors.red, fontSize: 20),
            contentTextStyle: TextStyle(color: Colors.white70),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    // GC doesn't need team member validation
    bool teamMembersValid = true;
    String errorMessage = '';

    if (selectedEventType != 'GC') {
      // Validate team 1 members only if there are any
      if (_team1Members.isNotEmpty) {
        for (var member in _team1Members) {
          if (member.name.isEmpty || member.email.isEmpty) {
            teamMembersValid = false;
            errorMessage =
                'Please fill both name and email for all Team 1 members';
            break;
          }
        }
      }

      // Validate team 2 members only if there are any
      if (teamMembersValid && _team2Members.isNotEmpty) {
        for (var member in _team2Members) {
          if (member.name.isEmpty || member.email.isEmpty) {
            teamMembersValid = false;
            errorMessage =
                'Please fill both name and email for all Team 2 members';
            break;
          }
        }
      }
    } else {
      // Validate participants for GC events
      for (var participant in participants) {
        for (var member in participant['members']) {
          if (member['name'].isEmpty || member['email'].isEmpty) {
            teamMembersValid = false;
            errorMessage =
                'Please fill both name and email for all team members';
            break;
          }
        }
        if (!teamMembersValid) break;
      }
    }

    // Validate event managers only if there are any
    if (teamMembersValid && _eventManagers.isNotEmpty) {
      for (var manager in _eventManagers) {
        if (manager.name.isEmpty || manager.email.isEmpty) {
          teamMembersValid = false;
          errorMessage =
              'Please fill both name and email for all Event Managers';
          break;
        }
      }
    }

    if (!teamMembersValid) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Validation Error'),
            content: Text(errorMessage),
            backgroundColor: Colors.grey[900],
            titleTextStyle: TextStyle(color: Colors.red, fontSize: 20),
            contentTextStyle: TextStyle(color: Colors.white70),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        bool success;

        if (selectedEventType == 'GC') {
          // For GC events, use participants structure
          success = await EventServices.addGCEvent(
            gender: selectedGender!,
            eventType: _eventType,
            mainType: selectedMainType!,
            type: _type,
            date: _date!,
            time: _time,
            venue: _venue,
            description: _description,
            winner: _winner,
            participants: participants,
            eventManagers: _eventManagers.isNotEmpty ? _eventManagers : null,
          );
        } else {
          // For other event types, use team1 and team2 structure
          Team? team1Details =
              _team1Members.isNotEmpty
                  ? Team(teamName: _team1, members: _team1Members)
                  : null;

          Team? team2Details =
              _team2Members.isNotEmpty
                  ? Team(teamName: _team2, members: _team2Members)
                  : null;

          success = await EventServices.addEvent(
            gender: selectedGender!,
            eventType: _eventType,
            mainType: selectedMainType,
            type: _type,
            date: _date!,
            time: _time,
            venue: _venue,
            description: _description,
            winner: _winner,
            team1: _team1,
            team2: _team2,
            team1Details: team1Details,
            team2Details: team2Details,
            eventManagers: _eventManagers.isNotEmpty ? _eventManagers : null,
          );
        }

        if (success) {
          // Format date and time properly for the notification
          final formattedDate =
              _date != null
                  ? "${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}"
                  : 'N/A';

          // Format time to ensure it has proper padding
          final List<String> timeParts = _time.split(':');
          final formattedTime =
              timeParts.length == 2
                  ? "${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}"
                  : _time;

          // Create notification message based on event type
          String notificationMessage;
          if (selectedEventType == 'GC') {
            notificationMessage =
                'New GC event added: ${selectedMainType} - ${_type}';
          } else {
            notificationMessage =
                'New event added: ${_team1} vs ${_team2} - ${selectedEventType}';
          }

          // Send notifications to all users with formatted date and time
          await http.post(
            Uri.parse('$baseUrl/notifications/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'message': notificationMessage,
              'eventType': selectedEventType,
              'date': formattedDate,
              'time': formattedTime,
              'venue': _venue,
              // Only include team names for non-GC events
              'team1': selectedEventType != 'GC' ? _team1 : null,
              'team2': selectedEventType != 'GC' ? _team2 : null,
              // Include main type and type for GC events
              'mainType': selectedEventType == 'GC' ? selectedMainType : null,
              'type': _type,
            }),
          );

          // First navigate back to AdminDashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      DashboardScreen(email: widget.email, name: widget.name),
            ),
          );

          // Then show the response dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Event added successfully!'),
                backgroundColor: Colors.grey[900],
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                contentTextStyle: TextStyle(color: Colors.white70),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to add event: ${e.toString()}'),
              backgroundColor: Colors.grey[900],
              titleTextStyle: TextStyle(color: Colors.red, fontSize: 20),
              contentTextStyle: TextStyle(color: Colors.white70),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        DashboardScreen(email: widget.email, name: widget.name),
              ),
            );
          },
        ),
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
          Positioned(
            bottom: -70,
            left: 50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Main Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    "Add Event",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Gender Category Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'Gender Category',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton2(
                          value: selectedGender,
                          style: TextStyle(color: Colors.white),
                          isExpanded: true,
                          underline: Container(), // Remove default underline
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          iconStyleData: IconStyleData(
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ),
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            height: 56,
                          ),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          items: [
                            DropdownMenuItem(
                              value: 'boys',
                              child: Text(
                                'Boys',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'girls',
                              child: Text(
                                'Girls',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'group',
                              child: Text(
                                'Group Event',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value as String?;
                            });
                          },
                          hint: Text(
                            'Select an option',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Event Type Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'Event Type',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton2(
                          value: selectedEventType,
                          style: TextStyle(color: Colors.white),
                          isExpanded: true,
                          underline: Container(), // Remove default underline
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          iconStyleData: IconStyleData(
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ),
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            height: 56,
                          ),
                          menuItemStyleData: MenuItemStyleData(height: 40),
                          items:
                              eventTypeOptions.map((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEventType = value as String?;
                              _eventType = value as String;
                              // Reset secondary selections when main type changes
                              selectedMainType = null;
                              selectedType = null;

                              // Clear participants when switching event types
                              if (value != 'GC') {
                                participants.clear();
                              }

                              // Set _type automatically for IRCC, PHL and Basket Brawl
                              if (value == 'IRCC') {
                                _type = 'cricket';
                              } else if (value == 'PHL') {
                                _type = 'hockey';
                              } else if (value == 'Basket Brawl') {
                                _type = 'basketball';
                              }
                            });
                          },
                          hint: Text(
                            'Select event type',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Conditional Main Type dropdown for GC
                  if (selectedEventType == 'GC') ...[
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Main Type',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton2(
                            value: selectedMainType,
                            style: TextStyle(color: Colors.white),
                            isExpanded: true,
                            underline: Container(),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            iconStyleData: IconStyleData(
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                            buttonStyleData: ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 56,
                            ),
                            menuItemStyleData: MenuItemStyleData(height: 40),
                            items:
                                gcMainTypeOptions.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMainType = value as String?;
                                // Don't set _type here since we need the sub-type
                              });
                            },
                            hint: Text(
                              'Select main type',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Conditional Type dropdown for GC
                  if (selectedEventType == 'GC' &&
                      selectedMainType != null) ...[
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Type',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton2(
                            value: selectedType,
                            style: TextStyle(color: Colors.white),
                            isExpanded: true,
                            underline: Container(),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            iconStyleData: IconStyleData(
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                            buttonStyleData: ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 56,
                            ),
                            menuItemStyleData: MenuItemStyleData(height: 40),
                            items:
                                (typeOptions[selectedMainType] ?? []).map((
                                  String item,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value as String?;
                                if (selectedType != 'Other') {
                                  _type = selectedType!;
                                  _customTypeController
                                      .clear(); // Clear custom type input if not "Other"
                                }
                              });
                            },
                            hint: Text(
                              'Select type',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedType == 'Other') ...[
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _customTypeController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Custom Type',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _type =
                                value; // Update the _type variable with the custom input
                          });
                        },
                      ),
                    ],
                  ],

                  // Conditional Type dropdown for IYSC
                  if (selectedEventType == 'IYSC') ...[
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Type',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton2(
                            value: selectedType,
                            style: TextStyle(color: Colors.white),
                            isExpanded: true,
                            underline: Container(),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            iconStyleData: IconStyleData(
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                            buttonStyleData: ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 56,
                            ),
                            menuItemStyleData: MenuItemStyleData(height: 40),
                            items:
                                iyscTypeOptions.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value as String?;
                                _type = value as String;
                              });
                            },
                            hint: Text(
                              'Select type',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Participants section - only show for GC
                  if (selectedEventType == 'GC') ...[
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'Participants',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...participants.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> participant = entry.value;

                          return Container(
                            margin: EdgeInsets.only(bottom: 15),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Team ${index + 1}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed:
                                          () => _removeParticipant(index),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  initialValue: participant['teamName'],
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Team Name *',
                                    labelStyle: TextStyle(color: Colors.white),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      participants[index]['teamName'] = value;
                                    });
                                  },
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'Members',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ...(participant['members'] as List)
                                    .asMap()
                                    .entries
                                    .map((memberEntry) {
                                      int memberIndex = memberEntry.key;
                                      Map<String, dynamic> member =
                                          memberEntry.value;

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade700,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Member ${memberIndex + 1}",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed:
                                                      () => _removeMember(
                                                        index,
                                                        memberIndex,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            TextFormField(
                                              initialValue: member['name'],
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Name *',
                                                labelStyle: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  participants[index]['members'][memberIndex]['name'] =
                                                      value;
                                                });
                                              },
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              initialValue: member['email'],
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Email *',
                                                labelStyle: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  participants[index]['members'][memberIndex]['email'] =
                                                      value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList(),
                                SizedBox(height: 10),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.add),
                                  label: Text('Add Member'),
                                  onPressed: () => _addMember(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Participant'),
                          onPressed: _addParticipant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                _date = picked;
                              });
                            }
                          },
                          child: Text(
                            _date != null
                                ? '${_date!.year}-${_date!.month}-${_date!.day}'
                                : 'Select Date',
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _time = '${picked.hour}:${picked.minute}';
                              });
                            }
                          },
                          child: Text(_time.isEmpty ? 'Select Time' : _time),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _venueController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Venue',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter venue';
                      }
                      return null;
                    },
                    onSaved: (value) => _venue = value!,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    onSaved: (value) => _description = value,
                  ),

                  // Team 1 and Team 2 sections - only show for non-GC events
                  if (selectedEventType != null &&
                      selectedEventType != 'GC') ...[
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _team1Controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Team 1',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter team 1';
                        }
                        return null;
                      },
                      onSaved: (value) => _team1 = value!,
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Team 1 Members",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._buildTeamMembersList(true),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add Team 1 Member'),
                      onPressed: () {
                        _addTeamMember(true);
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _team2Controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Team 2',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter team 2';
                        }
                        return null;
                      },
                      onSaved: (value) => _team2 = value!,
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Team 2 Members",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._buildTeamMembersList(false),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add Team 2 Member'),
                      onPressed: () {
                        _addTeamMember(false);
                      },
                    ),
                  ],

                  SizedBox(height: 20),
                  Text(
                    "Event Managers (Optional)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ..._buildEventManagersList(),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Event Manager'),
                    onPressed: _addEventManager,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addEvent,
                    child: Text('Add Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
