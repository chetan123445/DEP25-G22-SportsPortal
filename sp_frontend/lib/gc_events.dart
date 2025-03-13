import 'package:flutter/material.dart';

class GCEventsPage extends StatelessWidget {
  final List<dynamic> events;

  GCEventsPage({required this.events});

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
            events.isEmpty
                ? Center(child: Text('No events available'))
                : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(
                      context,
                      event['MainType'] ?? 'Main Type',
                      event['type'] ?? 'Type',
                      event['date']?.split('T')[0] ?? 'No Date',
                      event['time'] ?? 'No Time',
                      event['venue'] ?? 'No Venue',
                      event['description'] ?? 'No Description',
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
  ) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
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
            // Main Type and Type row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MainType,
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  type,
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}