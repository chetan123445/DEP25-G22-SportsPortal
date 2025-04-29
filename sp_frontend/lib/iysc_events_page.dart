import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/favorite_service.dart';
import 'dart:async'; // Add this import for blinking animation
import 'team_details_page.dart'; // Import TeamDetailsPage
import 'PlayerProfilePage.dart'; // Import PlayerProfilePage
import 'IYSCEventDetailsPage.dart'; // Add this import at the top with other imports Import IYSCEventDetailsPage

class IYSCEventsPage extends StatefulWidget {
  final List<dynamic> events;

  IYSCEventsPage({required this.events});

  @override
  _IYSCEventsPageState createState() => _IYSCEventsPageState();
}

class _IYSCEventsPageState extends State<IYSCEventsPage> {
  Map<String, bool> favoriteStatus = {};
  String? userId;
  String _searchQuery = ''; // Add search query state
  bool _isBlinking = true; // Add blinking state

  @override
  void initState() {
    super.initState();
    _startBlinking(); // Start blinking animation
    _getUserIdAndLoadFavorites();
  }

  void _startBlinking() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
      } else {
        setState(() {
          _isBlinking = !_isBlinking;
        });
      }
    });
  }

  Future<void> _getUserIdAndLoadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      print(
        'Retrieved userId from SharedPreferences: $storedUserId',
      ); // Debug log

      if (storedUserId != null && storedUserId.isNotEmpty) {
        setState(() {
          userId = storedUserId;
        });
        await _loadFavoriteStatus(); // Wait for favorite status to load
      } else {
        print('No valid user ID found in SharedPreferences');
        // Don't navigate away, just show a message if needed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please login to manage favorites')),
          );
        }
      }
    } catch (e) {
      print('Error getting userId: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (userId == null || userId!.isEmpty) {
      print('Cannot load favorites: No valid userId');
      return;
    }

    print('Starting to load favorites for user: $userId');
    try {
      for (var event in widget.events) {
        String eventId = event['_id'];
        print('Verifying favorite for event: $eventId');

        bool isFavorite = await FavoriteService.verifyFavorite(
          'IYSC',
          eventId,
          userId!,
        );
        print('Received favorite status for $eventId: $isFavorite');

        if (mounted) {
          setState(() {
            favoriteStatus[eventId] = isFavorite;
          });
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(String eventId, bool currentStatus) async {
    if (userId == null) return;

    bool success;
    if (currentStatus) {
      success = await FavoriteService.removeFavorite('IYSC', eventId, userId!);
    } else {
      success = await FavoriteService.addFavorite('IYSC', eventId, userId!);
    }

    if (success && mounted) {
      setState(() {
        favoriteStatus[eventId] = !currentStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents =
        widget.events.where((event) {
          final query = _searchQuery.toLowerCase();
          final eventType = (event['type'] ?? '').toLowerCase();

          // Normalize common sport type variations
          bool matchesType = false;
          if (eventType.contains('cricket') || query.contains('cricket')) {
            matchesType =
                'cricket'.contains(query) || query.contains('cricket');
          } else if (eventType.contains('football') ||
              query.contains('football')) {
            matchesType =
                'football'.contains(query) || query.contains('football');
          } else if (eventType.contains('hockey') || query.contains('hockey')) {
            matchesType = 'hockey'.contains(query) || query.contains('hockey');
          } else {
            matchesType = eventType.contains(query);
          }

          return matchesType ||
              (event['gender']?.toString().toLowerCase() ==
                  query) || // Exact match for gender
              (event['date'] ?? '').toLowerCase().contains(query) ||
              (event['time'] ?? '').toLowerCase().contains(query) ||
              (event['team1'] ?? '').toLowerCase().contains(query) ||
              (event['team2'] ?? '').toLowerCase().contains(query) ||
              (event['venue'] ?? '').toLowerCase().contains(query);
        }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 79, 188, 247),
                Color.fromARGB(255, 142, 117, 205),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'IYSC Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by gender, date, time, teams and Venue...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  filteredEvents.isEmpty
                      ? Center(child: Text('No events match your search'))
                      : ListView.builder(
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return _buildEventCard(context, event);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    String team1 = event['team1'] ?? 'Team 1';
    String team2 = event['team2'] ?? 'Team 2';
    String date = event['date']?.split('T')[0] ?? 'No Date';
    String time = event['time'] ?? 'No Time';
    String type = (event['type'] ?? 'No Type').toLowerCase();
    // Normalize sport type display
    type =
        type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'No Type';
    String gender = event['gender'] ?? 'Unknown';
    String venue = event['venue'] ?? 'No Venue';
    String eventId = event['_id'] ?? '';
    String eventType = event['eventType'] ?? 'No Type';
    bool isFavorite = favoriteStatus[eventId] ?? false;
    bool isLive = date == DateTime.now().toIso8601String().split('T')[0];

    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (isLive)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildLiveIndicator(),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isPoolEvent(event['type']?.toString() ?? ''))
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Tooltip(
                          message: 'Players have been divided into two pools',
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.blue[800],
                            size: 20,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        event['team1']?.toString() ?? 'TBA',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    if (!_isPoolEvent(event['type']?.toString() ?? ''))
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "vs",
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        event['team2']?.toString() ?? 'TBA',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(date, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(type), Text(gender)],
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Venue: $venue',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 4.0),
                if (event['description'] != null &&
                    event['description'].isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      event['description'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                SizedBox(height: 12.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Event Managers',
                      () => _showEventManagers(context, event),
                    ),
                    // Only show Event Details button if not field athletics
                    if (![
                      'field athletics',
                      'powerlifting',
                      'weightlifting',
                    ].contains(event['type']?.toString().toLowerCase()))
                      _buildActionButton('Event Details', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => IYSCEventDetailsPage(
                                  event: event,
                                  isReadOnly: true,
                                ),
                          ),
                        );
                      }),
                    _buildActionButton(
                      'View Result',
                      () => _showMatchResult(context, event, date),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.yellow : null,
                    ),
                    onPressed: () => _toggleFavorite(eventId, isFavorite),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamButton(
    BuildContext context,
    Map<String, dynamic> event,
    String teamName,
    bool isTeam1,
  ) {
    return TextButton(
      onPressed:
          () => _showTeamDetails(
            context,
            event,
            isTeam1 ? 'team1Details' : 'team2Details',
            teamName,
          ),
      child: Text(
        teamName,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade200,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(label, style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedOpacity(
      opacity: _isBlinking ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: Container(
        width: 12.0,
        height: 12.0,
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }

  void _showEventManagers(BuildContext context, Map<String, dynamic> event) {
    if (event['eventManagers'] == null ||
        (event['eventManagers'] as List).isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('No Event Managers'),
              content: Text(
                'No event managers have been assigned to this event.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...event['eventManagers']
                      .map<Widget>(
                        (manager) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(manager['name'] ?? 'Unknown'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PlayerProfilePage(
                                      playerName: manager['name'],
                                      playerEmail: manager['email'],
                                    ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showMatchResult(
    BuildContext context,
    Map<String, dynamic> event,
    String date,
  ) {
    String message = '';
    DateTime eventDate = DateTime.parse(date);
    DateTime now = DateTime.now();

    if (eventDate.isAfter(now)) {
      message = 'Match has not started yet';
    } else if (eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day) {
      message = 'Match is live, results will be updated soon';
    } else {
      if (event['winner'] == null || event['winner'].isEmpty) {
        message = 'No results available';
      } else if (event['winner'] == 'Draw') {
        message = 'Match ended in a draw';
      } else {
        // Handle different types of games
        if (event['type']?.toLowerCase() == 'cricket') {
          message = _getCricketMatchResult(
            event['team1'],
            event['team2'],
            event['team1Score'],
            event['team2Score'],
            event['winner'],
          );
        } else if (event['team1Score']?['roundHistory'] != null) {
          // For round-based games
          message = _getRoundBasedResult(
            event['team1'],
            event['team2'],
            event['team1Score'],
            event['team2Score'],
            event['winner'],
          );
        } else {
          message = '${event['winner']} won this match!';
        }
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Match Status'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getCricketMatchResult(
    String team1,
    String team2,
    Map<String, dynamic> team1Score,
    Map<String, dynamic> team2Score,
    String winner,
  ) {
    final team1Runs = team1Score['runs'] ?? 0;
    final team2Runs = team2Score['runs'] ?? 0;
    final team2Wickets = team2Score['wickets'] ?? 0;

    if (team1Runs == team2Runs) {
      return 'Match ended in a draw';
    }

    if (team2Runs > team1Runs) {
      return '$team2 won by ${10 - team2Wickets} wickets';
    } else if (team1Runs > team2Runs) {
      return '$team1 won by ${team1Runs - team2Runs} runs';
    }

    return '$winner won this match!';
  }

  String _getRoundBasedResult(
    String team1,
    String team2,
    Map<String, dynamic> team1Score,
    Map<String, dynamic> team2Score,
    String winner,
  ) {
    final team1Rounds = (team1Score['roundHistory'] as List<dynamic>?) ?? [];
    final team2Rounds = (team2Score['roundHistory'] as List<dynamic>?) ?? [];

    int team1RoundsWon = 0;
    int team2RoundsWon = 0;

    for (int i = 0; i < team1Rounds.length; i++) {
      final team1RoundScore = team1Rounds[i]['score'] ?? 0;
      final team2RoundScore = team2Rounds[i]['score'] ?? 0;

      if (team1RoundScore > team2RoundScore) {
        team1RoundsWon++;
      } else if (team2RoundScore > team1RoundScore) {
        team2RoundsWon++;
      }
    }

    if (team1RoundsWon == team2RoundsWon) {
      return 'Match ended in a draw';
    }

    return team1RoundsWon > team2RoundsWon
        ? '$team1 won by winning $team1RoundsWon rounds to $team2RoundsWon'
        : '$team2 won by winning $team2RoundsWon rounds to $team1RoundsWon';
  }

  void _showTeamDetails(
    BuildContext context,
    Map<String, dynamic> event,
    String teamKey,
    String teamName,
  ) {
    if (event[teamKey] == null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Team Details Not Available'),
              content: Text(
                'Team member details for "$teamName" have not been added yet.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamDetailsPage(teamId: event[teamKey]),
        ),
      );
    }
  }

  // Add this helper method at the start of the _IYSCEventsPageState class
  bool _isPoolEvent(String type) {
    return [
      'field athletics',
      'powerlifting',
      'weightlifting',
    ].contains(type.toLowerCase());
  }
}
