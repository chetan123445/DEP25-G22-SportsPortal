import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/favorite_service.dart';
import 'dart:async'; // Add this import for blinking animation

class GCEventsPage extends StatefulWidget {
  final List<dynamic> events;
  GCEventsPage({required this.events});

  @override
  _GCEventsPageState createState() => _GCEventsPageState();
}

class _GCEventsPageState extends State<GCEventsPage> {
  Map<String, bool> favoriteStatus = {};
  String? userId;
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
      print('Retrieved userId from SharedPreferences: $storedUserId');

      if (storedUserId != null && storedUserId.isNotEmpty) {
        setState(() {
          userId = storedUserId;
        });
        await _loadFavoriteStatus();
      } else {
        print('No valid user ID found in SharedPreferences');
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
          'GC',
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
      success = await FavoriteService.removeFavorite('GC', eventId, userId!);
    } else {
      success = await FavoriteService.addFavorite('GC', eventId, userId!);
    }

    if (success && mounted) {
      setState(() {
        favoriteStatus[eventId] = !currentStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'GC Events',
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            widget.events.isEmpty
                ? Center(child: Text('No events available'))
                : ListView.builder(
                  itemCount: widget.events.length,
                  itemBuilder: (context, index) {
                    final event = widget.events[index];
                    return _buildEventCard(
                      context,
                      event['MainType'] ?? 'Main Type',
                      event['type'] ?? 'Type',
                      event['date']?.split('T')[0] ?? 'No Date',
                      event['time'] ?? 'No Time',
                      event['venue'] ?? 'No Venue',
                      event['description'] ?? 'No Description',
                      event['_id'], // Add event ID parameter
                      event['eventType'] ??
                          'Event Type', // Add eventType parameter
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    String MainType,
    String type,
    String date,
    String time,
    String venue,
    String description,
    String eventId, // Add event ID parameter
    String eventType, // Add eventType parameter
  ) {
    bool isFavorite = favoriteStatus[eventId] ?? false;
    bool isLive =
        date ==
        DateTime.now().toIso8601String().split(
          'T',
        )[0]; // Check if the event is live

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
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: Column(
              children: [
                // Event Type at the top center
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
                SizedBox(height: 4.0), // Add spacing below eventType
                // Main Type and Type row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      MainType,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),

                // Date and Time centered below
                Column(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

                // Description
                Text(
                  description,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),

                // Add Favorite Button as last child in Column
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
          if (isLive) // Add red blinking circle for live events
            Positioned(
              bottom: 8.0,
              left: 8.0, // Change from right to left
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
