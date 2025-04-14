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
  @override
  void initState() {
    super.initState();
    // Remove _markNotificationsAsRead call - we don't want to automatically mark as read
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-single-read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'notificationId': notificationId,
        }),
      );

      if (response.statusCode == 200) {
        // Show a brief success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
            return Center(child: Text('No new notifications'));
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
                  if (!notification['read']) {
                    // Only show unread notifications
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      color: Colors.black.withOpacity(0.8),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              notification['message'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
                            leading: Icon(
                              Icons.event,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delete this notification?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed:
                                          () => _deleteNotification(
                                            notification['_id'],
                                          ),
                                      child: Text(
                                        'Yes',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Do nothing for "No"
                                      },
                                      child: Text(
                                        'No',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink(); // Skip read notifications
                },
              ),
            );
          }
        },
      ),
    );
  }
}
