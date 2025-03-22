import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/favorite_service.dart';
import 'dart:async'; // Add this import for blinking animation
import 'team_details_page.dart'; // Import TeamDetailsPage
// Add any authentication imports here

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
          return (event['gender']?.toLowerCase() ==
                  query) || // Exact match for gender
              (event['date'] ?? '').toLowerCase().contains(query) ||
              (event['time'] ?? '').toLowerCase().contains(query) ||
              (event['team1'] ?? '').toLowerCase().contains(query) ||
              (event['team2'] ?? '').toLowerCase().contains(query) ||
              (event['venue'] ?? '').toLowerCase().contains(query) ||
              (event['type'] ?? '').toLowerCase().contains(query);
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
    String type = event['type'] ?? 'No Type';
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
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      eventType,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (event['team1Details'] == null) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Team Details Not Available'),
                                      content: Text(
                                        'Team member details for "${event['team1'] ?? 'Team 1'}" have not been added yet.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TeamDetailsPage(
                                        teamId: event['team1Details'],
                                      ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            team1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'v/s',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (event['team2Details'] == null) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Team Details Not Available'),
                                      content: Text(
                                        'Team member details for "${event['team2'] ?? 'Team 2'}" have not been added yet.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TeamDetailsPage(
                                        teamId: event['team2Details'],
                                      ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            team2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Column(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      gender,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.yellow : null,
                      size: 18,
                    ),
                    onPressed: () => _toggleFavorite(eventId, isFavorite),
                  ),
                ),
              ],
            ),
          ),
          if (isLive)
            Positioned(
              bottom: 8.0,
              left: 8.0,
              child: AnimatedOpacity(
                opacity: _isBlinking ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
