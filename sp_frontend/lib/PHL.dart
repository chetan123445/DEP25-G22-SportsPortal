import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'constants.dart';
import 'services/favorite_service.dart';

class PHLPage extends StatefulWidget {
  @override
  _PHLPageState createState() => _PHLPageState();
}

class _PHLPageState extends State<PHLPage> {
  List<dynamic> events = [];
  bool isLoading = true;
  Map<String, bool> favoriteStatus = {};
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserId();
    await _fetchPHLEvents();
    await _loadFavoriteStatus();
  }

  Future<void> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      print('Retrieved userId from SharedPreferences: $storedUserId');

      if (storedUserId != null && storedUserId.isNotEmpty) {
        setState(() {
          userId = storedUserId;
        });
      } else {
        print('No valid user ID found in SharedPreferences');
      }
    } catch (e) {
      print('Error getting userId: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (userId == null || userId!.isEmpty || events.isEmpty) {
      print(
        'Cannot load favorites: userId=$userId, events.length=${events.length}',
      );
      return;
    }

    print('Loading favorites for user: $userId');
    try {
      for (var event in events) {
        if (event['_id'] == null) continue;

        String eventId = event['_id'];
        print('Checking favorite for event: $eventId');

        bool isFavorite = await FavoriteService.verifyFavorite(
          'PHL',
          eventId,
          userId!,
        );
        print('Favorite status for $eventId: $isFavorite');

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
      success = await FavoriteService.removeFavorite('PHL', eventId, userId!);
    } else {
      success = await FavoriteService.addFavorite('PHL', eventId, userId!);
    }

    if (success && mounted) {
      setState(() {
        favoriteStatus[eventId] = !currentStatus;
      });
    }
  }

  Future<void> _fetchPHLEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get-phl-events?type=Hockey'),
    );
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final fetchedEvents = responseBody['data'];
      if (fetchedEvents is List) {
        setState(() {
          events = fetchedEvents;
          isLoading = false;
        });
      } else {
        print('Unexpected response format');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('Failed to load events');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
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
              'Hockey Matches',
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    events.isEmpty
                        ? Center(child: Text('No hockey matches available'))
                        : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return _buildEventCard(
                              context,
                              event['team1'] ?? 'Team 1',
                              event['team2'] ?? 'Team 2',
                              event['date']?.split('T')[0] ?? 'No Date',
                              event['time'] ?? 'No Time',
                              event['type'] ?? 'No Type',
                              event['gender'] ?? 'Unknown',
                              event['venue'] ?? 'No Venue',
                              event['_id'], // Pass the event ID
                              event['eventType'] ??
                                  'No Type', // Pass the eventType
                            );
                          },
                        ),
              ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    String team1,
    String team2,
    String date,
    String time,
    String type,
    String gender,
    String venue,
    String eventId,
    String eventType, // Add eventType parameter
  ) {
    bool isFavorite = favoriteStatus[eventId] ?? false;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2.0),
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
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 8.0,
            ), // Reduced padding
            child: Column(
              children: [
                // Teams Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        team1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
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
                      child: Text(
                        team2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0), // Reduced spacing
                // Date and Time
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

                // Type and Gender
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

                // Venue Box
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

                // Favorite Button
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
          Positioned(
            top: 8.0,
            right: 8.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
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
        ],
      ),
    );
  }
}
