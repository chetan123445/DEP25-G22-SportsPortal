import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class FavoriteService {
  static Future<bool> addFavorite(String eventType, String eventId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-favourite-event'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'eventType': eventType,
          'eventId': eventId,
          'userId': userId,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  static Future<bool> removeFavorite(String eventType, String eventId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/remove-favourite-event'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'eventType': eventType,
          'eventId': eventId,
          'userId': userId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  static Future<bool> verifyFavorite(String eventType, String eventId, String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/verify-favourite-event?eventType=$eventType&eventId=$eventId&userId=$userId');
      print('Verifying favorite - URI: $uri'); // Debug log
      
      final response = await http.get(uri);
      print('Verify response status: ${response.statusCode}'); // Debug log
      print('Verify response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error verifying favorite: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getFavorites(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-favourite-events?userId=$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['favorites'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }
}
