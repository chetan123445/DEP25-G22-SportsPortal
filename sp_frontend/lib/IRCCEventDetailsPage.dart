import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'PlayerProfilePage.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CricketScore {
  final int runs;
  final int wickets;
  final int overs;
  final int balls;

  CricketScore({
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
  });

  factory CricketScore.fromJson(Map<String, dynamic> json) {
    return CricketScore(
      runs: json['runs'] ?? 0,
      wickets: json['wickets'] ?? 0,
      overs: json['overs'] ?? 0,
      balls: json['balls'] ?? 0,
    );
  }

  String get scoreString => '$runs/$wickets';
  String get oversString => '$overs.${balls}';
}

class IRCCEventDetailsPage extends StatefulWidget {
  final dynamic event;
  final bool isReadOnly;

  IRCCEventDetailsPage({required this.event, this.isReadOnly = false});

  @override
  _IRCCEventDetailsPageState createState() => _IRCCEventDetailsPageState();
}

class _IRCCEventDetailsPageState extends State<IRCCEventDetailsPage>
    with SingleTickerProviderStateMixin {
  // Add state variables for score, commentary, standings
  late TabController _tabController;
  List<Map<String, dynamic>> team1Players = [];
  List<Map<String, dynamic>> team2Players = [];
  List<Map<String, dynamic>> commentary = [];
  List<Map<String, dynamic>> maleStandings = [];
  List<Map<String, dynamic>> femaleStandings = [];
  CricketScore team1Score = CricketScore(
    runs: 0,
    wickets: 0,
    overs: 0,
    balls: 0,
  );
  CricketScore team2Score = CricketScore(
    runs: 0,
    wickets: 0,
    overs: 0,
    balls: 0,
  );
  TextEditingController _commentaryController = TextEditingController();
  bool isMatchLive = false;
  String matchStatus = 'Not Started';
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize scores from event data first
    if (widget.event['team1Score'] != null) {
      team1Score = CricketScore.fromJson(widget.event['team1Score']);
    }
    if (widget.event['team2Score'] != null) {
      team2Score = CricketScore.fromJson(widget.event['team2Score']);
    }
    if (widget.event['commentary'] != null) {
      commentary = List<Map<String, dynamic>>.from(
        widget.event['commentary'].map(
          (c) => {
            'id': c['_id'],
            'text': c['text'],
            'timestamp': c['timestamp'],
          },
        ),
      );
    }

    // Add fetchEventDetails() here to load players
    fetchEventDetails();
    // Call other init methods
    checkMatchStatus();
    fetchStandings();
    connectToSocket();
  }

  void connectToSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.emit('join-event', widget.event['_id']);

    socket.on('score-update', (data) {
      if (data['eventId'] == widget.event['_id'] && mounted) {
        setState(() {
          team1Score = CricketScore.fromJson(data['team1Score']);
          team2Score = CricketScore.fromJson(data['team2Score']);
          // Update the event data for persistence
          widget.event['team1Score'] = data['team1Score'];
          widget.event['team2Score'] = data['team2Score'];
        });
      }
    });

    socket.on('commentary-update', (data) {
      if (data['eventId'] == widget.event['_id'] && mounted) {
        setState(() {
          commentary = List<Map<String, dynamic>>.from(data['commentary']);
          widget.event['commentary'] = data['commentary'];
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
      print('Fetching event details...'); // Debug print
      final response = await http.get(
        Uri.parse('$baseUrl/ircc/event/${widget.event['_id']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Received event data: $data'); // Debug print
        final eventData = data['event'];

        if (eventData != null) {
          setState(() {
            // Only update team players and commentary, not scores
            team1Players = List<Map<String, dynamic>>.from(
              eventData['team1Players'] ?? [],
            );
            team2Players = List<Map<String, dynamic>>.from(
              eventData['team2Players'] ?? [],
            );
            print('Team 1 Players: $team1Players'); // Debug print
            print('Team 2 Players: $team2Players'); // Debug print

            // Update commentary if needed
            commentary = List<Map<String, dynamic>>.from(
              (eventData['commentary'] ?? []).map(
                (c) => {
                  'id': c['_id'] ?? '',
                  'text': c['text'] ?? '',
                  'timestamp':
                      c['timestamp'] ?? DateTime.now().toIso8601String(),
                },
              ),
            );

            // Store players in event data
            widget.event['team1Players'] = eventData['team1Players'];
            widget.event['team2Players'] = eventData['team2Players'];
            widget.event['commentary'] = eventData['commentary'];
          });
        }
      }
    } catch (e) {
      print('Error fetching event details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading event details: $e')),
        );
      }
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
        // Update winner if not already set
        if (widget.event['winner'] == null) {
          updateWinner();
        }
      } else {
        matchStatus = 'Not Started Yet';
      }
    });
  }

  Future<void> updateWinner() async {
    String winner;
    if (team1Score.runs > team2Score.runs) {
      winner = widget.event['team1'];
    } else if (team2Score.runs > team1Score.runs) {
      winner = widget.event['team2'];
    } else {
      winner = 'draw';
    }

    try {
      // First update the winner in event
      final response = await http.post(
        Uri.parse('$baseUrl/ircc/update-winner'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'winner': winner,
          'team1': widget.event['team1'],
          'team2': widget.event['team2'],
          'status': 'completed',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          widget.event['winner'] = data['event']['winner'];
          widget.event['status'] = 'completed';
        });

        // After updating winner, refresh standings to reflect changes
        await fetchStandings();
      }
    } catch (e) {
      print('Error updating winner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating match winner: $e')),
      );
    }
  }

  Future<void> fetchStandings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ircc/standings'));

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

  Future<void> updateScore(
    String team,
    String scoreType,
    bool increment,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ircc/update-score'), // Remove email query param
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'team': team,
          'scoreType': scoreType,
          'increment': increment,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Update both local state and event data
            team1Score = CricketScore.fromJson(data['event']['team1Score']);
            team2Score = CricketScore.fromJson(data['event']['team2Score']);
            widget.event['team1Score'] = data['event']['team1Score'];
            widget.event['team2Score'] = data['event']['team2Score'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating score: $e')));
      }
    }
  }

  Future<void> addCommentary(String text) async {
    if (text.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ircc/add-commentary'),
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

  Future<void> deleteCommentary(String commentaryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ircc/delete-commentary'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IRCC Cricket Match Details'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScorecardTab(),
          _buildCommentaryTab(),
          _buildStandingsTab(),
        ],
      ),
    );
  }

  // Add widget building methods
  Widget _buildScorecardTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Match Status
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
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 1),
            ],
          ),
          child: Column(
            children: [
              _buildTeamScoreRow(
                'team1',
                widget.event['team1'] ?? 'Team 1',
                team1Score,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildTeamScoreRow(
                'team2',
                widget.event['team2'] ?? 'Team 2',
                team2Score,
              ),
            ],
          ),
        ),

        // Team Players Section
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.black87,
                  tabs: [
                    Tab(text: widget.event['team1'] ?? 'Team 1'),
                    Tab(text: widget.event['team2'] ?? 'Team 2'),
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

  Widget _buildTeamScoreRow(String team, String teamName, CricketScore score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (isMatchLive && !widget.isReadOnly) ...[
          IconButton(
            icon: Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => updateScore(team, 'runs', false),
          ),
        ],
        Text(
          score.scoreString,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          '(${score.oversString})',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        if (isMatchLive && !widget.isReadOnly) ...[
          IconButton(
            icon: Icon(Icons.add_circle, color: Colors.green),
            onPressed: () => updateScore(team, 'runs', true),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: InkWell(
              onTap: () => updateScore(team, 'ball', true),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'B',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: InkWell(
              onTap: () => updateScore(team, 'wickets', true),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentaryTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
      ),
      child: Column(
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: commentary.length,
              itemBuilder: (context, index) {
                final comment = commentary[index];
                final commentTime = DateTime.parse(comment['timestamp']);
                final formattedTime = DateFormat('HH:mm').format(commentTime);
                final formattedDate = DateFormat('MMM dd').format(commentTime);
                final isCurrentDate = commentTime.day == DateTime.now().day;

                return Dismissible(
                  key: Key(comment['id']),
                  direction:
                      !widget.isReadOnly
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    deleteCommentary(comment['id']);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black87,
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
                              backgroundColor: Colors.black,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color:
                                  isCurrentDate
                                      ? Colors.blue.shade400
                                      : Colors.grey.shade600,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isCurrentDate
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$formattedDate at $formattedTime',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (!widget.isReadOnly)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red.shade300,
                                      ),
                                      onPressed:
                                          () => deleteCommentary(comment['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                comment['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.3,
                                  letterSpacing: 0.3,
                                ),
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
              padding: EdgeInsets.all(12),
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
                        hintText: 'Add live commentary...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.sports_cricket,
                          color: Colors.blue.shade300,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_commentaryController.text.trim().isNotEmpty) {
                            addCommentary(_commentaryController.text);
                          }
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
                      var matchesPlayed = int.parse(
                        team['matches']?.toString() ?? '0',
                      );
                      var points = int.parse(team['points']?.toString() ?? '0');
                      var wins = int.parse(team['wins']?.toString() ?? '0');
                      var losses = int.parse(team['losses']?.toString() ?? '0');
                      var draws = int.parse(team['draws']?.toString() ?? '0');

                      // For current match teams logic remains same
                      if (widget.event['team1'] == team['name'] ||
                          widget.event['team2'] == team['name']) {
                        final eventDate = DateTime.parse(widget.event['date']);
                        final now = DateTime.now();
                        final isToday =
                            eventDate.year == now.year &&
                            eventDate.month == now.month &&
                            eventDate.day == now.day;
                        final isPast = eventDate.isBefore(
                          DateTime(now.year, now.month, now.day),
                        );

                        if (isToday) {
                          matchesPlayed += 1;
                        } else if (isPast && widget.event['winner'] != null) {
                          matchesPlayed += 1;
                          if (widget.event['winner'] == 'draw') {
                            draws += 1;
                            points += 1;
                          } else if (widget.event['winner'] == team['name']) {
                            wins += 1;
                            points += 2;
                          } else {
                            losses += 1;
                          }
                        }
                      }

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
                                  child: Text(matchesPlayed.toString()),
                                ),
                              ),
                              Expanded(
                                child: Center(child: Text(wins.toString())),
                              ),
                              Expanded(
                                child: Center(child: Text(losses.toString())),
                              ),
                              Expanded(
                                child: Center(child: Text(draws.toString())),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    points.toString(),
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

  Widget _buildTeamPlayersList(List<Map<String, dynamic>> players) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          'No players available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: Colors.black87,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
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
        );
      },
    );
  }
}
