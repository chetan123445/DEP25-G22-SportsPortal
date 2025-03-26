import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../services/event_services.dart';
import '../adminDashboard.dart';

class AddEventPage extends StatefulWidget {
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
  String? selectedMainType;  // For GC option
  String? selectedType;      // For IYSC option
  
  // Event type dropdown options
  final List<String> eventTypeOptions = ['GC', 'IYSC', 'IRCC', 'PHL', 'Basket Brawl'];
  final List<String> gcMainTypeOptions = ['Cultural', 'Technical', 'Literacy', 'Sports', 'eSports'];
  final List<String> iyscTypeOptions = [
    'Cricket', 'Football', 'Table Tennis', 'Tennis', 'Hockey', 
    'Field Athletics', 'Weightlifting', 'Powerlifting', 
    'Chess', 'Badminton', 'Basketball', 'Volleyball'
  ];

  List<TeamMember> _team1Members = [];
  List<TeamMember> _team2Members = [];
  final FocusNode _dropdownFocusNode = FocusNode();
  bool _isDropdownFocused = false;

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
    _dropdownFocusNode.dispose();
    super.dispose();
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
            color: Colors.grey,  // Always grey border for container
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
                errorText: _showValidationErrors && member.name.isEmpty ? 'Name is required' : null,
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
                errorText: _showValidationErrors && member.email.isEmpty ? 'Email is required' : null,
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

  Future<void> _addEvent() async {
    setState(() {
      _showValidationErrors = true;  // Show validation errors on submit
    });
    
    // Add validation for team members before form validation
    bool teamMembersValid = true;
    String errorMessage = '';

    // Validate team 1 members
    for (int i = 0; i < _team1Members.length; i++) {
      if (_team1Members[i].name.isEmpty || _team1Members[i].email.isEmpty) {
        teamMembersValid = false;
        errorMessage = 'Please fill both name and email for all Team 1 members';
        break;
      }
    }

    // Validate team 2 members
    for (int i = 0; i < _team2Members.length; i++) {
      if (_team2Members[i].name.isEmpty || _team2Members[i].email.isEmpty) {
        teamMembersValid = false;
        errorMessage = 'Please fill both name and email for all Team 2 members';
        break;
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
        Team? team1Details = _team1Members.isNotEmpty
            ? Team(teamName: _team1, members: _team1Members)
            : null;
            
        Team? team2Details = _team2Members.isNotEmpty
            ? Team(teamName: _team2, members: _team2Members)
            : null;

        bool success = await EventServices.addEvent(
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
        );

        // First navigate back to AdminDashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
        
        // Then show the response dialog
        if (success) {
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
                          items: eventTypeOptions.map((String item) {
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
                              
                              // Set _type automatically for IRCC, PHL and Basket Brawl
                              if (value == 'IRCC') {
                                _type = 'cricket';
                              } else if (value == 'PHL') {
                                _type = 'hockey';
                              } else if (value == 'Basket Brawl') {
                                _type = 'basketball';  // Fixed spelling here
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
                            items: gcMainTypeOptions.map((String item) {
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
                                _type = value as String;
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
                            items: iyscTypeOptions.map((String item) {
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
                  SizedBox(height: 10),
                  TextFormField(
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addEvent,
                    child: Text('Add Event'),
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