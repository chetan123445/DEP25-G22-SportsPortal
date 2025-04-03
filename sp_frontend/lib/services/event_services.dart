import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/event.dart';

class EventServices {
  static Future<bool> addEvent({
    required String gender,
    required String eventType,
    String? mainType,
    required String type,
    required DateTime date,
    required String time,
    required String venue,
    String? description,
    String? winner,
    required String team1,
    required String team2,
    Team? team1Details,
    Team? team2Details,
    List<EventManager>? eventManagers,
  }) async {
    // Create event data map
    Map<String, dynamic> eventData = {
      'gender': gender,
      'eventType': eventType,
      'mainType': mainType,
      'type': type,
      'date': date.toIso8601String(),
      'time': time,
      'venue': venue,
      'description': description,
      'winner': winner,
      'team1': team1,
      'team2': team2,
      'team1Details':
          team1Details != null
              ? {
                'teamName': team1Details.teamName,
                'members':
                    team1Details.members
                        .map((m) => {'name': m.name, 'email': m.email})
                        .toList(),
              }
              : null,
      'team2Details':
          team2Details != null
              ? {
                'teamName': team2Details.teamName,
                'members':
                    team2Details.members
                        .map((m) => {'name': m.name, 'email': m.email})
                        .toList(),
              }
              : null,
      'eventManagers':
          eventManagers != null
              ? eventManagers
                  .map((m) => {'name': m.name, 'email': m.email})
                  .toList()
              : [],
    };

    print(
      "Sending event data: ${jsonEncode(eventData)}",
    ); // Add this debug line

    // Select endpoint based on eventType
    String endpoint;
    switch (eventType) {
      case 'IYSC':
        endpoint = '/add-IYSCevent';
        break;
      case 'GC':
        endpoint = '/add-GCevent';
        break;
      case 'IRCC':
        endpoint = '/add-IRCCevent';
        break;
      case 'PHL':
        endpoint = '/add-PHLevent';
        break;
      case 'Basket Brawl':
        endpoint = '/add-BasketBrawlevent';
        break;
      default:
        throw Exception('Invalid event type');
    }

    final response = await http.post(
      Uri.parse('${Config.apiUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(eventData),
    );

    print("Response status: ${response.statusCode}"); // Add this debug line
    print("Response body: ${response.body}"); // Add this debug line

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to add event: ${response.body}');
    }
  }
}
