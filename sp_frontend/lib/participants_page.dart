import 'package:flutter/material.dart';

class ParticipantsPage extends StatelessWidget {
  final String eventId;

  ParticipantsPage({required this.eventId});

  @override
  Widget build(BuildContext context) {
    // Dummy data for participants (replace with actual API call)
    final participants = [
      {'name': 'John Doe', 'email': 'john.doe@example.com'},
      {'name': 'Jane Smith', 'email': 'jane.smith@example.com'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Participants')),
      body: Container(
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
        child: ListView.separated(
          itemCount: participants.length,
          separatorBuilder: (context, index) => Divider(color: Colors.black),
          itemBuilder: (context, index) {
            final participant = participants[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Text(
                    '${index + 1}.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16),
                  Expanded(child: Text(participant['name'] ?? 'No Name')),
                  Expanded(child: Text(participant['email'] ?? 'No Email')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
