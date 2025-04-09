import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';

class NotificationsPage extends StatefulWidget {
  final String email;

  NotificationsPage({required this.email});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Future<List<dynamic>> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?email=${widget.email}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications available'));
          } else {
            final notifications = snapshot.data!;
            return Container(
              decoration: BoxDecoration(
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
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    color: Colors.black.withOpacity(0.7),
                    child: ListTile(
                      title: Text(
                        notification['message'],
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'Event Type: ${notification['eventType'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Venue: ${notification['venue'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            DateTime.parse(
                              notification['timestamp'],
                            ).toString(),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      leading: Icon(Icons.event, color: Colors.blue, size: 32),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
