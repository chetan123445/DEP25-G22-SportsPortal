import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'PlayerProfilePage.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Round {
  final int roundNumber;
  final int score;

  Round({required this.roundNumber, required this.score});

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      roundNumber: json['roundNumber'] ?? 0,
      score: json['score'] ?? 0,
    );
  }
}

class SportScore {
  final int runs;
  final int wickets;
  final int overs;
  final int balls;
  final int goals;
  final int currentRound;
  final List<Round> roundHistory;

  SportScore({
    this.runs = 0,
    this.wickets = 0,
    this.overs = 0,
    this.balls = 0,
    this.goals = 0,
    this.currentRound = 1,
    this.roundHistory = const [],
  });

  factory SportScore.fromJson(Map<String, dynamic> json) {
    var historyJson = json['roundHistory'] as List<dynamic>?;
    List<Round> parsedHistory = [];
    if (historyJson != null) {
      parsedHistory =
          historyJson.map((round) => Round.fromJson(round)).toList();
    }

    return SportScore(
      runs: json['runs'] ?? 0,
      wickets: json['wickets'] ?? 0,
      overs: json['overs'] ?? 0,
      balls: json['balls'] ?? 0,
      goals: json['goals'] ?? 0,
      currentRound: json['currentRound'] ?? 1,
      roundHistory: parsedHistory,
    );
  }

  String getFormattedScore(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'cricket':
        return '$runs/$wickets ($overs.$balls)';
      case 'hockey':
      case 'football':
        return '$goals';
      default:
        if (roundHistory.isEmpty) return '$goals';
        return roundHistory.map((r) => r.score.toString()).join(' - ');
    }
  }
}

class IYSCEventDetailsPage extends StatefulWidget {
  final dynamic event;
  final bool isReadOnly;

  IYSCEventDetailsPage({required this.event, this.isReadOnly = false});

  @override
  _IYSCEventDetailsPageState createState() => _IYSCEventDetailsPageState();
}

class _IYSCEventDetailsPageState extends State<IYSCEventDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> team1Players = [];
  List<Map<String, dynamic>> team2Players = [];
  List<Map<String, dynamic>> commentary = [];
  List<Map<String, dynamic>> standings = [];
  SportScore team1Score = SportScore();
  SportScore team2Score = SportScore();
  TextEditingController _commentaryController = TextEditingController();
  bool isMatchLive = false;
  String matchStatus = 'Not Started';
  late IO.Socket socket;
  bool _isBlinking = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize scores from event data
    if (widget.event['team1Score'] != null) {
      team1Score = SportScore.fromJson(widget.event['team1Score']);
    }
    if (widget.event['team2Score'] != null) {
      team2Score = SportScore.fromJson(widget.event['team2Score']);
    }

    fetchEventDetails();
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
          team1Score = SportScore.fromJson(data['team1Score']);
          team2Score = SportScore.fromJson(data['team2Score']);
          widget.event['team1Score'] = data['team1Score'];
          widget.event['team2Score'] = data['team2Score'];
        });
      }
    });

    socket.on('commentary-update', handleCommentaryUpdate);
  }

  void handleCommentaryUpdate(dynamic data) {
    if (data['eventId'] == widget.event['_id'] && mounted) {
      setState(() {
        if (data['type'] == 'add') {
          commentary.insert(0, {
            'id': data['newComment']['id'],
            'text': data['newComment']['text'],
            'timestamp': data['newComment']['timestamp'],
          });
        } else if (data['type'] == 'delete') {
          commentary.removeWhere((c) => c['id'] == data['commentaryId']);
        }
      });
    }
  }

  Future<void> fetchEventDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/iysc/event/${widget.event['_id']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eventData = data['event'];

        if (eventData != null) {
          setState(() {
            team1Players = List<Map<String, dynamic>>.from(
              eventData['team1Players'] ?? [],
            );
            team2Players = List<Map<String, dynamic>>.from(
              eventData['team2Players'] ?? [],
            );
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

            // Sort commentary by timestamp in descending order
            commentary.sort(
              (a, b) => DateTime.parse(
                b['timestamp'],
              ).compareTo(DateTime.parse(a['timestamp'])),
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  Future<void> checkMatchStatus() async {
    final eventDate = DateTime.parse(widget.event['date']);
    final now = DateTime.now();
    setState(() {
      isMatchLive =
          eventDate.year == now.year &&
          eventDate.month == now.month &&
          eventDate.day == now.day;
      matchStatus =
          isMatchLive
              ? 'Live'
              : eventDate.isBefore(now)
              ? 'Completed'
              : 'Not Started Yet';
    });
  }

  Future<void> fetchStandings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/iysc/standings'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          standings = List<Map<String, dynamic>>.from(data['standings'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching standings: $e');
    }
  }

  Future<void> updateScore(
    String team,
    String scoreType,
    bool increment, [
    int? roundIndex,
  ]) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/iysc/update-score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'team': team,
          'scoreType': scoreType,
          'increment': increment,
          if (roundIndex != null) 'roundIndex': roundIndex,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (team == 'team1') {
            team1Score = SportScore.fromJson(data['event']['team1Score']);
            widget.event['team1Score'] = data['event']['team1Score'];
          } else {
            team2Score = SportScore.fromJson(data['event']['team2Score']);
            widget.event['team2Score'] = data['event']['team2Score'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating score: $e')));
    }
  }

  Future<void> addCommentary(String text) async {
    if (text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/iysc/add-commentary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _commentaryController.clear();
        // Let socket event handle the update
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
        Uri.parse('$baseUrl/iysc/delete-commentary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': widget.event['_id'],
          'commentaryId': commentaryId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete commentary');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting commentary: $e')));
    }
  }

  Widget _buildScorecardTab() {
    final sportType = widget.event['type'].toString().toLowerCase();

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
              if (sportType == 'cricket') ...[
                // Cricket Score Display (IRCC Style)
                _buildTeamScoreRow(
                  'team1',
                  widget.event['team1'] ?? 'Team 1',
                  team1Score,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (matchStatus == 'Completed')
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _getWinningText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildTeamScoreRow(
                  'team2',
                  widget.event['team2'] ?? 'Team 2',
                  team2Score,
                ),
              ] else ...[
                // Other Sports Score Display (PHL Style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNonCricketScoreCard(
                      widget.event['team1'],
                      team1Score,
                      () => updateScore('team1', 'goals', true),
                      () => updateScore('team1', 'goals', false),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (matchStatus == 'Completed')
                            Text(
                              _getWinningText(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildNonCricketScoreCard(
                      widget.event['team2'],
                      team2Score,
                      () => updateScore('team2', 'goals', true),
                      () => updateScore('team2', 'goals', false),
                    ),
                  ],
                ),
                if (isMatchLive && !widget.isReadOnly) ...[
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.done_all),
                    label: Text('Complete Round ${team1Score.currentRound}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('Complete Round'),
                              content: Text(
                                'Are you sure you want to complete this round and start the next one?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    updateScore('team1', 'completeRound', true);
                                    Navigator.pop(context);
                                  },
                                  child: Text('Yes'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
                if (team1Score.roundHistory.isNotEmpty)
                  TextButton(
                    onPressed: () => _showRoundHistory(),
                    child: Text(
                      isMatchLive ? 'View Previous Rounds' : 'View All Rounds',
                    ),
                  ),
              ],
            ],
          ),
        ),

        // Rest of the tab content (team players section)
      ],
    );
  }

  Widget _buildTeamScoreRow(String team, String teamName, SportScore score) {
    return Column(
      children: [
        Row(
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
            Text(
              '${score.runs}/${score.wickets}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '(${score.overs}.${score.balls})',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
        if (isMatchLive && !widget.isReadOnly) ...[
          SizedBox(height: 12),
          // Runs Control Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreControl(
                team,
                'Runs',
                () => updateScore(team, 'runs', false),
                () => updateScore(team, 'runs', true),
              ),
              _buildScoreControl(
                team,
                'Wickets',
                () => updateScore(team, 'wickets', false),
                () => updateScore(team, 'wickets', true),
              ),
              _buildScoreControl(
                team,
                'Balls',
                () => updateScore(team, 'balls', false),
                () => updateScore(team, 'balls', true),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Boundaries Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBoundaryButton(
                team,
                '4',
                () => updateScore(team, 'four', true),
              ),
              _buildBoundaryButton(
                team,
                '6',
                () => updateScore(team, 'six', true),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Extras Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExtraButton(
                team,
                'WD',
                () => updateScore(team, 'wd', true),
              ),
              _buildExtraButton(
                team,
                'NB',
                () => updateScore(team, 'nb', true),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScoreControl(
    String team,
    String label,
    VoidCallback onDecrement,
    VoidCallback onIncrement,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red, size: 24),
                onPressed: onDecrement,
                padding: EdgeInsets.all(4),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.green, size: 24),
                onPressed: onIncrement,
                padding: EdgeInsets.all(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoundaryButton(
    String team,
    String value,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '+$value',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraButton(String team, String label, VoidCallback onPressed) {
    final color =
        label == 'WD' ? Colors.purple.shade700 : Colors.orange.shade700;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildNonCricketScoreCard(
    String teamName,
    SportScore score,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
  ) {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(maxWidth: 160),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              teamName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Round ${score.currentRound}',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMatchLive && !widget.isReadOnly)
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: onDecrement,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${score.goals}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isMatchLive && !widget.isReadOnly)
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
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

  void _showRoundHistory() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                isMatchLive ? 'Previous Rounds' : 'Match Rounds',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            content: Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      int i = 0;
                      i < team1Score.roundHistory.length;
                      i++
                    ) ...[
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Round ${i + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        widget.event["team1"],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${team1Score.roundHistory[i].score}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'vs',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        widget.event["team2"],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${team2Score.roundHistory[i].score}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < team1Score.roundHistory.length - 1)
                        Icon(Icons.arrow_downward, color: Colors.grey),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ],
          ),
    );
  }

  String _getWinningText() {
    final sportType = widget.event['type'].toString().toLowerCase();

    if (sportType == 'cricket') {
      if (team1Score.runs == team2Score.runs) {
        return 'Match Drawn';
      }
      bool team1Won = team1Score.runs > team2Score.runs;
      if (team1Won) {
        return '${widget.event['team1']} Won by ${team1Score.runs - team2Score.runs} runs';
      } else {
        return '${widget.event['team2']} Won by ${10 - team2Score.wickets} wickets';
      }
    } else {
      // For round-based sports
      int team1RoundsWon = 0;
      int team2RoundsWon = 0;

      for (int i = 0; i < team1Score.roundHistory.length; i++) {
        if (team1Score.roundHistory[i].score >
            team2Score.roundHistory[i].score) {
          team1RoundsWon++;
        } else if (team2Score.roundHistory[i].score >
            team1Score.roundHistory[i].score) {
          team2RoundsWon++;
        }
      }

      if (team1RoundsWon == team2RoundsWon) {
        return 'Match Drawn';
      }
      return team1RoundsWon > team2RoundsWon
          ? '${widget.event['team1']} Won (${team1RoundsWon}-${team2RoundsWon})'
          : '${widget.event['team2']} Won (${team2RoundsWon}-${team1RoundsWon})';
    }
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
                  onDismissed: (_) => deleteCommentary(comment['id']),
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
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentaryController,
                      decoration: InputDecoration(
                        hintText: 'Add commentary...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (text) => addCommentary(text),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => addCommentary(_commentaryController.text),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    final sportTypes = [
      'Cricket',
      'Hockey',
      'Football',
      'Table Tennis',
      'Tennis',
      'Badminton',
      'Basketball',
      'Volleyball',
    ];

    return DefaultTabController(
      length: sportTypes.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: sportTypes.map((type) => Tab(text: type)).toList(),
            labelColor: Colors.black,
          ),
          Expanded(
            child: TabBarView(
              children:
                  sportTypes
                      .map(
                        (type) => DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                tabs: [
                                  Tab(text: 'Men\'s Teams'),
                                  Tab(text: 'Women\'s Teams'),
                                ],
                                labelColor: Colors.black,
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildSportStandingsTable(type, 'male'),
                                    _buildSportStandingsTable(type, 'female'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportStandingsTable(String sportType, String gender) {
    final filteredStandings =
        standings
            .where(
              (team) =>
                  team['type']?.toString().toLowerCase() ==
                      sportType.toLowerCase() &&
                  team['gender']?.toString().toLowerCase() ==
                      gender.toLowerCase(),
            )
            .toList();

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
              filteredStandings.isEmpty
                  ? Center(child: Text('No teams available'))
                  : ListView.builder(
                    itemCount: filteredStandings.length,
                    itemBuilder: (context, index) {
                      final team = filteredStandings[index];
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
                                  child: Text(team['matches'].toString()),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(team['wins'].toString()),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(team['losses'].toString()),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(team['draws'].toString()),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    team['points'].toString(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IYSC ${widget.event['type']} Match Details'),
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
          tabs: [
            Tab(icon: Icon(Icons.scoreboard), text: 'Scorecard'),
            Tab(icon: Icon(Icons.comment), text: 'Commentary'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Standings'),
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
}
