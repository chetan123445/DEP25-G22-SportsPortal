import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'PlayerProfilePage.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// Remove or comment out the timeago import temporarily
// import 'package:timeago/timeago.dart' as timeago;

class PHLEventDetailsPage extends StatefulWidget {
  final dynamic event;
  final bool isReadOnly; // Add this parameter

  PHLEventDetailsPage({
    required this.event,
    this.isReadOnly = false, // Default to false for backward compatibility
  });

  @override
  _PHLEventDetailsPageState createState() => _PHLEventDetailsPageState();
}

class _PHLEventDetailsPageState extends State<PHLEventDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> team1Players = [];
  List<Map<String, dynamic>> team2Players = [];
  List<Map<String, dynamic>> commentary = [];
  List<Map<String, dynamic>> maleStandings = [];
  List<Map<String, dynamic>> femaleStandings = [];
  int team1Goals = 0;
  int team2Goals = 0;
  TextEditingController _commentaryController = TextEditingController();
  bool isMatchLive = false;
  String matchStatus =
      'Not Started'; // Can be 'Not Started', 'Live', 'Completed'
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchEventDetails();
    checkMatchStatus();
    fetchStandings(); // Add this line to fetch standings
    connectToSocket();
  }

  void connectToSocket() {
    socket = IO.io('your_server_url', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.emit('join-event', widget.event['_id']);

    socket.on('score-update', (data) {
      if (data['eventId'] == widget.event['_id']) {
        setState(() {
          team1Goals = data['team1Goals'];
          team2Goals = data['team2Goals'];
        });
      }
    });

    socket.on('commentary-update', (data) {
      if (data['eventId'] == widget.event['_id']) {
        setState(() {
          commentary = List<Map<String, dynamic>>.from(data['commentary']);
        });
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Future<void> fetchEventDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/phl/event/${widget.event['_id']}'), // Updated URL
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          team1Goals = data['event']['team1Goals'] ?? 0;
          team2Goals = data['event']['team2Goals'] ?? 0;
          commentary = List<Map<String, dynamic>>.from(
            data['event']['commentary'].map(
              (c) => {
                'id': c['_id'],
                'text': c['text'],
                'timestamp': c['timestamp'],
              },
            ),
          );
          team1Players = List<Map<String, dynamic>>.from(
            data['event']['team1Players'] ?? [],
          );
          team2Players = List<Map<String, dynamic>>.from(
            data['event']['team2Players'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  Future<void> deleteCommentary(String commentaryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/phl/delete-commentary'), // Updated URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'commentaryId': commentaryId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          commentary.removeWhere((c) => c['id'] == commentaryId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting commentary: $e')));
    }
  }

  Future<void> fetchTeamPlayers() async {
    // Implement API call to fetch team players
    // Update team1Players and team2Players
  }

  Future<void> fetchStandings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/phl/standings'), // Updated URL
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Fetched standings data: $data"); // Add this debug print
        setState(() {
          maleStandings = List<Map<String, dynamic>>.from(
            data['maleStandings'] ?? [],
          );
          femaleStandings = List<Map<String, dynamic>>.from(
            data['femaleStandings'] ?? [],
          );
        });
      } else {
        print(
          "Error fetching standings: ${response.statusCode}",
        ); // Add debug print
      }
    } catch (e) {
      print('Error fetching standings: $e');
    }
  }

  Future<void> addCommentary(String text) async {
    if (text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/phl/add-commentary'), // Updated URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          commentary = List<Map<String, dynamic>>.from(
            data['event']['commentary'].map(
              (c) => {
                'id': c['_id'],
                'text': c['text'],
                'timestamp': c['timestamp'],
              },
            ),
          );
        });
        _commentaryController.clear();
      } else {
        throw Exception('Failed to add commentary');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding commentary: $e')));
    }
  }

  Future<void> checkMatchStatus() async {
    final eventDate = DateTime.parse(widget.event['date']);
    final now = DateTime.now();
    final isToday =
        eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
    final isPast = eventDate.isBefore(DateTime(now.year, now.month, now.day));

    setState(() {
      isMatchLive = isToday;
      if (isToday) {
        matchStatus = 'Live';
      } else if (isPast) {
        matchStatus = 'Completed';
      } else {
        matchStatus = 'Not Started';
      }
    });
  }

  Future<void> updateScore(String team, bool increment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/phl/update-score'), // Updated URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'team': team,
          'increment': increment,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          team1Goals = data['event']['team1Goals'];
          team2Goals = data['event']['team2Goals'];
        });
      } else {
        throw Exception('Failed to update score');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating score: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PHL Event Details'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade200,
                Colors.blue.shade200,
                Colors.pink.shade100,
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          tabs: [
            Tab(
              icon: Icon(Icons.scoreboard, color: Colors.black),
              text: 'Scorecard',
            ),
            Tab(
              icon: Icon(Icons.comment, color: Colors.black),
              text: 'Commentary',
            ),
            Tab(
              icon: Icon(Icons.leaderboard, color: Colors.black),
              text: 'Standings',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(child: _buildScorecardTab()),
            _buildCommentaryTab(),
            _buildStandingsTab(),
          ],
        ),
      ),
    );
  }

  // Update the team players list widget
  Widget _buildTeamPlayersList(List<Map<String, dynamic>> players) {
    if (players.isEmpty) {
      return Center(child: Text('No players available'));
    }
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                player['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                player['email'] ?? '',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlayerProfilePage(
                          playerName: player['name'] ?? 'Unknown',
                          playerEmail: player['email'] ?? '',
                        ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Update TabBar in the scorecard section
  Widget _buildScorecardTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Match Status with Animation
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isMatchLive
                    ? Colors.green.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMatchLive ? Icons.live_tv : Icons.schedule,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                isMatchLive ? 'LIVE' : matchStatus,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Score Display
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87, // Changed to black
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 1),
            ],
          ),
          margin: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamScoreCard(
                widget.event['team1'],
                team1Goals,
                () => updateScore('team1', true),
                () => updateScore('team1', false),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Changed to white
                  ),
                ),
              ),
              _buildTeamScoreCard(
                widget.event['team2'],
                team2Goals,
                () => updateScore('team2', true),
                () => updateScore('team2', false),
              ),
            ],
          ),
        ),
        // Team Players Section
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: widget.event['team1']),
                    Tab(text: widget.event['team2']),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTeamPlayersList(team1Players),
                      _buildTeamPlayersList(team2Players),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamScoreCard(
    String teamName,
    int goals,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
  ) {
    return Flexible(
      // Wrap in Flexible
      child: Container(
        constraints: BoxConstraints(maxWidth: 160), // Add max width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              teamName,
              textAlign: TextAlign.center, // Center team name
              style: TextStyle(
                fontSize: 16, // Reduce font size
                fontWeight: FontWeight.bold,
                color: Colors.white, // Changed to white
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ), // Reduce padding
              decoration: BoxDecoration(
                color: Colors.black54, // Slightly lighter black for contrast
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24), // Subtle border
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center, // Center controls
                children: [
                  if (isMatchLive && !widget.isReadOnly)
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                        size: 20,
                      ), // Reduce icon size
                      padding: EdgeInsets.zero, // Remove padding
                      constraints: BoxConstraints(), // Remove constraints
                      onPressed: onDecrement,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                    ), // Reduce padding
                    child: Text(
                      '$goals',
                      style: TextStyle(
                        fontSize: 24, // Reduce font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to white
                      ),
                    ),
                  ),
                  if (isMatchLive && !widget.isReadOnly)
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.green,
                        size: 20,
                      ), // Reduce icon size
                      padding: EdgeInsets.zero, // Remove padding
                      constraints: BoxConstraints(), // Remove constraints
                      onPressed: onIncrement,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentaryTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Live Commentary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: commentary.length,
            itemBuilder: (context, index) {
              final comment = commentary[index];
              final commentTime = DateTime.parse(comment['timestamp']);
              // Replace timeago with simple time format
              final formattedTime = DateFormat('HH:mm').format(commentTime);
              final formattedDate = DateFormat('MMM dd').format(commentTime);

              return Dismissible(
                key: Key(comment['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  deleteCommentary(comment['id']);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        final fullDateTime = DateFormat(
                          'EEEE, MMMM d, y\nh:mm a',
                        ).format(commentTime);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(fullDateTime),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['text'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$formattedDate at $formattedTime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (!widget.isReadOnly)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.white70,
                                    ),
                                    onPressed:
                                        () => deleteCommentary(comment['id']),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
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
            },
          ),
        ),
        if (isMatchLive && !widget.isReadOnly)
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentaryController,
                    decoration: InputDecoration(
                      hintText: 'Add match commentary...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_commentaryController.text.trim().isNotEmpty) {
                        addCommentary(_commentaryController.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStandingsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [Tab(text: 'Men\'s Teams'), Tab(text: 'Women\'s Teams')],
            labelColor: Colors.black,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStandingsTable(maleStandings),
                _buildStandingsTable(femaleStandings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsTable(List<Map<String, dynamic>> standings) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.blue.shade100,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Team',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'P',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'W',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'L',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'D',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Pts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              standings.isEmpty
                  ? Center(child: Text('No teams available'))
                  : ListView.builder(
                    itemCount: standings.length,
                    itemBuilder: (context, index) {
                      final team = standings[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                          color:
                              index % 2 == 0
                                  ? Colors.white
                                  : Colors.grey.shade50,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  team['name'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    team['matches']?.toString() ?? '0',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(team['wins']?.toString() ?? '0'),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    team['losses']?.toString() ?? '0',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(team['draws']?.toString() ?? '0'),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    team['points']?.toString() ?? '0',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
