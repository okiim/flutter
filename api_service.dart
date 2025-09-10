import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // Generic GET request
  static Future<List<Map<String, dynamic>>> getData(String endpoint) async {
    try {
      print('GET request to: $baseUrl/$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Data received: ${data.length} items');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error: Status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in getData: $e');
      return [];
    }
  }

  // Generic POST request
  static Future<bool> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      print('POST request to: $baseUrl/$endpoint');
      print('Data: $data');
      
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      print('POST Response status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Exception in postData: $e');
      return false;
    }
  }

  // Generic PUT request
  static Future<bool> putData(String endpoint, int id, Map<String, dynamic> data) async {
    try {
      print('PUT request to: $baseUrl/$endpoint/$id');
      print('Data: $data');
      
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      print('PUT Response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Exception in putData: $e');
      return false;
    }
  }

  // Generic DELETE request
  static Future<bool> deleteData(String endpoint, int id) async {
    try {
      print('DELETE request to: $baseUrl/$endpoint/$id');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: headers,
      );
      
      print('DELETE Response status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception in deleteData: $e');
      return false;
    }
  }

  // Competition methods
  static Future<List<Map<String, dynamic>>> getCompetitions() => getData('competitions');
  static Future<bool> addCompetition(Map<String, dynamic> competition) => postData('competitions', competition);
  static Future<bool> updateCompetition(int id, Map<String, dynamic> competition) => putData('competitions', id, competition);
  static Future<bool> deleteCompetition(int id) => deleteData('competitions', id);

  // Judge methods
  static Future<List<Map<String, dynamic>>> getJudges() => getData('judges');
  static Future<bool> addJudge(Map<String, dynamic> judge) => postData('judges', judge);
  static Future<bool> updateJudge(int id, Map<String, dynamic> judge) => putData('judges', id, judge);
  static Future<bool> deleteJudge(int id) => deleteData('judges', id);

  // Participant methods
  static Future<List<Map<String, dynamic>>> getParticipants() => getData('participants');
  static Future<bool> addParticipant(Map<String, dynamic> participant) => postData('participants', participant);
  static Future<bool> updateParticipant(int id, Map<String, dynamic> participant) => putData('participants', id, participant);
  static Future<bool> deleteParticipant(int id) => deleteData('participants', id);
}