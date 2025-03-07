import 'package:flutter/material.dart';

class IYSCEventsPage extends StatelessWidget {
  final List<dynamic> events;

  IYSCEventsPage({required this.events});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IYSC Events'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: events.isEmpty
            ? Center(child: Text('No events available'))
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(
                    context,
                    event['type'] ?? 'No Type',
                    event['date']?.split('T')[0] ?? 'No Date', // Trim the date part
                    event['time'] ?? 'No Time',
                    event['venue'] ?? 'No Venue',
                    event['description'] ?? 'No Description',
                    event['winner'],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    String type,
    String date,
    String time,
    String venue,
    String description,
    String? winner,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle event tap
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Type:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(type),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(date),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Time:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(time),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Venue:',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text(venue),
                  ],
                ),
                SizedBox(height: 8.0),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14.0),
                  maxLines: null,
                ),
                if (winner != null) ...[
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text(
                        'Winner:',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text(winner),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
