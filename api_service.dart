import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this URL based on your setup:
  // For Android Emulator: 'http://10.0.2.2:3001/api'
  // For iOS Simulator: 'http://127.0.0.1:3001/api'
  // For Physical Device: 'http://YOUR_COMPUTER_IP:3001/api'
  static const String baseUrl = 'http://127.0.0.1:3001/api';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Duration timeoutDuration = Duration(seconds: 30);

  // ==================== CONNECTION TESTING ====================
  
  // Find working server URL
  static Future<String?> findWorkingUrl() async {
    final urls = [
      'http://127.0.0.1:3001/api',
      'http://10.0.2.2:3001/api',
      'http://localhost:3001/api',
      'http://192.168.1.100:3001/api', // Replace with your computer's IP
    ];
    
    for (String url in urls) {
      try {
        print('Testing URL: $url/health');
        final response = await http.get(
          Uri.parse('$url/health'),
          headers: headers,
        ).timeout(Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          print('Working URL found: $url');
          return url;
        }
      } catch (e) {
        print('Failed: $url - $e');
      }
    }
    return null;
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl/health');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(Duration(seconds: 10));
      
      print('Health check status: ${response.statusCode}');
      print('Health check response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Get network status with detailed info
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    final status = <String, dynamic>{
      'baseUrl': baseUrl,
      'connected': false,
      'workingUrl': null,
      'lastError': null,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    try {
      status['connected'] = await testConnection();
      if (!status['connected']) {
        status['workingUrl'] = await findWorkingUrl();
      }
    } catch (e) {
      status['lastError'] = e.toString();
    }
    
    return status;
  }

  // ==================== CORE HTTP METHODS ====================

  // Enhanced GET request
  static Future<List<Map<String, dynamic>>> getData(String endpoint) async {
    try {
      print('GET request to: $baseUrl/$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Data received: ${data.length} items');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error: Status ${response.statusCode}');
        return [];
      }
    } on SocketException catch (e) {
      print('Network error: Cannot connect to server - $e');
      return [];
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      return [];
    } catch (e) {
      print('Exception in getData: $e');
      return [];
    }
  }

  // Enhanced POST request
  static Future<bool> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      print('POST request to: $baseUrl/$endpoint');
      print('Data being sent: $data');
      
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(timeoutDuration);
      
      print('POST Response status: ${response.statusCode}');
      print('POST Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('POST request successful');
        return true;
      } else {
        print('POST failed - Status: ${response.statusCode}');
        print('Error response: ${response.body}');
        return false;
      }
    } on SocketException catch (e) {
      print('Network error: Cannot connect to server - $e');
      return false;
    } on FormatException catch (e) {
      print('JSON format error: $e');
      return false;
    } catch (e) {
      print('Exception in postData: $e');
      return false;
    }
  }

  // Enhanced PUT request
  static Future<bool> putData(String endpoint, int id, Map<String, dynamic> data) async {
    try {
      print('PUT request to: $baseUrl/$endpoint/$id');
      print('Data: $data');
      
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(timeoutDuration);
      
      print('PUT Response status: ${response.statusCode}');
      print('PUT Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('PUT request successful');
        return true;
      } else {
        print('PUT failed - Status: ${response.statusCode}');
        return false;
      }
    } on SocketException catch (e) {
      print('Network error: Cannot connect to server - $e');
      return false;
    } catch (e) {
      print('Exception in putData: $e');
      return false;
    }
  }

  // Enhanced DELETE request
  static Future<bool> deleteData(String endpoint, int id) async {
    try {
      print('DELETE request to: $baseUrl/$endpoint/$id');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      print('DELETE Response status: ${response.statusCode}');
      print('DELETE Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('DELETE request successful');
        return true;
      } else {
        print('DELETE failed - Status: ${response.statusCode}');
        return false;
      }
    } on SocketException catch (e) {
      print('Network error: Cannot connect to server - $e');
      return false;
    } catch (e) {
      print('Exception in deleteData: $e');
      return false;
    }
  }

  // ==================== EVENT TYPES METHODS ====================

  static Future<List<Map<String, dynamic>>> getEventTypes() async {
    print('Fetching event types...');
    return await getData('event-types');
  }

  static Future<bool> addEventType(Map<String, dynamic> eventType) async {
    print('Adding event type: ${eventType['name']}');
    
    // Validate required fields
    if (eventType['name'] == null || eventType['name'].toString().trim().isEmpty) {
      print('Error: Event type name is required');
      return false;
    }
    
    final cleanedData = {
      'name': eventType['name'].toString().trim(),
      'description': eventType['description']?.toString().trim() ?? '',
      'max_participants': eventType['max_participants'] ?? 50,
    };
    
    return await postData('event-types', cleanedData);
  }

  static Future<bool> updateEventType(int id, Map<String, dynamic> eventType) async {
    print('Updating event type ID: $id');
    return await putData('event-types', id, eventType);
  }

  static Future<bool> deleteEventType(int id) async {
    print('Deleting event type ID: $id');
    return await deleteData('event-types', id);
  }

  // ==================== COMPETITION METHODS ====================

  static Future<List<Map<String, dynamic>>> getCompetitions() async {
    print('Fetching competitions...');
    return await getData('competitions');
  }

  static Future<bool> addCompetition(Map<String, dynamic> competition) async {
    print('Adding competition: ${competition['name']}');
    
    // Validate required fields
    if (competition['name'] == null || competition['name'].toString().trim().isEmpty) {
      print('Error: Competition name is required');
      return false;
    }
    
    if (competition['description'] == null || competition['description'].toString().trim().isEmpty) {
      print('Error: Competition description is required');
      return false;
    }
    
    // Clean and prepare data
    final cleanedData = {
      'name': competition['name'].toString().trim(),
      'description': competition['description'].toString().trim(),
      'date': competition['date']?.toString().trim(),
      'event_type': competition['event_type']?.toString().trim(),
    };
    
    return await postData('competitions', cleanedData);
  }

  static Future<bool> updateCompetition(int id, Map<String, dynamic> competition) async {
    print('Updating competition ID: $id');
    return await putData('competitions', id, competition);
  }

  static Future<bool> deleteCompetition(int id) async {
    print('Deleting competition ID: $id');
    return await deleteData('competitions', id);
  }

  // ==================== JUDGE METHODS ====================

  static Future<List<Map<String, dynamic>>> getJudges() async {
    print('Fetching judges...');
    return await getData('judges');
  }

  static Future<bool> addJudge(Map<String, dynamic> judge) async {
    print('Adding judge: ${judge['name']}');
    
    // Validate required fields
    if (judge['name'] == null || judge['name'].toString().trim().isEmpty) {
      print('Error: Judge name is required');
      return false;
    }
    
    if (judge['email'] == null || judge['email'].toString().trim().isEmpty) {
      print('Error: Judge email is required');
      return false;
    }
    
    // Basic email validation
    final email = judge['email'].toString().trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      print('Error: Invalid email format');
      return false;
    }
    
    final cleanedData = {
      'name': judge['name'].toString().trim(),
      'email': email,
      'expertise': judge['expertise']?.toString().trim(),
      'phone': judge['phone']?.toString().trim(),
      'status': judge['status'] ?? 'active',
    };
    
    return await postData('judges', cleanedData);
  }

  static Future<bool> updateJudge(int id, Map<String, dynamic> judge) async {
    print('Updating judge ID: $id');
    return await putData('judges', id, judge);
  }

  static Future<bool> deleteJudge(int id) async {
    print('Deleting judge ID: $id');
    return await deleteData('judges', id);
  }

  // ==================== PARTICIPANT METHODS ====================

  static Future<List<Map<String, dynamic>>> getParticipants() async {
    print('Fetching participants...');
    return await getData('participants');
  }

  static Future<bool> addParticipant(Map<String, dynamic> participant) async {
    print('Adding participant: ${participant['name']}');
    
    // Validate required fields
    if (participant['name'] == null || participant['name'].toString().trim().isEmpty) {
      print('Error: Participant name is required');
      return false;
    }
    
    if (participant['course'] == null || participant['course'].toString().trim().isEmpty) {
      print('Error: Participant course is required');
      return false;
    }
    
    final cleanedData = {
      'name': participant['name'].toString().trim(),
      'course': participant['course'].toString().trim(),
      'category': participant['category']?.toString().trim(),
      'contact': participant['contact']?.toString().trim(),
      'age': participant['age'],
      'year_level': participant['year_level']?.toString().trim(),
      'status': participant['status'] ?? 'active',
    };
    
    return await postData('participants', cleanedData);
  }

  static Future<bool> updateParticipant(int id, Map<String, dynamic> participant) async {
    print('Updating participant ID: $id');
    return await putData('participants', id, participant);
  }

  static Future<bool> deleteParticipant(int id) async {
    print('Deleting participant ID: $id');
    return await deleteData('participants', id);
  }

  // ==================== CRITERIA METHODS ====================

  static Future<List<Map<String, dynamic>>> getCriteria() async {
    print('Fetching criteria...');
    return await getData('criteria');
  }

  static Future<bool> addCriteria(Map<String, dynamic> criteria) async {
    print('Adding criteria: ${criteria['name']}');
    
    // Validate required fields
    if (criteria['name'] == null || criteria['name'].toString().trim().isEmpty) {
      print('Error: Criteria name is required');
      return false;
    }
    
    // Validate max_score
    int maxScore = 100;
    if (criteria['max_score'] != null) {
      if (criteria['max_score'] is String) {
        maxScore = int.tryParse(criteria['max_score']) ?? 100;
      } else {
        maxScore = criteria['max_score'] as int? ?? 100;
      }
    }
    
    if (maxScore <= 0 || maxScore > 100) {
      print('Error: Max score must be between 1 and 100');
      return false;
    }
    
    final cleanedData = {
      'name': criteria['name'].toString().trim(),
      'description': criteria['description']?.toString().trim(),
      'max_score': maxScore,
      'weight': criteria['weight'] ?? 1.00,
      'competition': criteria['competition']?.toString().trim(),
    };
    
    return await postData('criteria', cleanedData);
  }

  static Future<bool> updateCriteria(int id, Map<String, dynamic> criteria) async {
    print('Updating criteria ID: $id');
    return await putData('criteria', id, criteria);
  }

  static Future<bool> deleteCriteria(int id) async {
    print('Deleting criteria ID: $id');
    return await deleteData('criteria', id);
  }

  // ==================== DASHBOARD & STATISTICS ====================

  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      print('Fetching dashboard stats...');
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      print('Dashboard stats status: ${response.statusCode}');
      print('Dashboard stats response: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Exception in getDashboardStats: $e');
      return null;
    }
  }

  // Get competition statistics
  static Future<Map<String, dynamic>?> getCompetitionStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/competitions/stats'),
        headers: headers,
      ).timeout(timeoutDuration);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Exception in getCompetitionStats: $e');
      return null;
    }
  }

  // ==================== UTILITY METHODS ====================

  // Debug method to test all endpoints
  static Future<void> debugAllEndpoints() async {
    print('=== DEBUGGING ALL API ENDPOINTS ===');
    
    // Test connection first
    bool connected = await testConnection();
    print('Connection test: ${connected ? "PASS" : "FAIL"}');
    
    if (!connected) {
      print('Cannot proceed - server not reachable');
      String? workingUrl = await findWorkingUrl();
      if (workingUrl != null) {
        print('Alternative working URL found: $workingUrl');
      } else {
        print('No working URLs found');
      }
      return;
    }
    
    // Test all GET endpoints
    final endpoints = ['event-types', 'competitions', 'judges', 'participants', 'criteria'];
    
    for (String endpoint in endpoints) {
      try {
        final data = await getData(endpoint);
        print('$endpoint: ${data.isNotEmpty ? "PASS (${data.length} items)" : "EMPTY"}');
      } catch (e) {
        print('$endpoint: FAIL - $e');
      }
    }
    
    print('=== DEBUG COMPLETE ===');
  }

  // Test specific endpoint with sample data
  static Future<bool> testEndpoint(String endpoint, Map<String, dynamic> sampleData) async {
    try {
      print('Testing endpoint: $endpoint');
      bool result = await postData(endpoint, sampleData);
      print('Test result for $endpoint: ${result ? "SUCCESS" : "FAILED"}');
      return result;
    } catch (e) {
      print('Test failed for $endpoint: $e');
      return false;
    }
  }

  // Get server URL for debugging
  static String getServerUrl() => baseUrl;

  // Check if server is reachable
  static Future<bool> isServerReachable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get detailed API information
  static Map<String, dynamic> getApiInfo() {
    return {
      'baseUrl': baseUrl,
      'version': '1.0.0',
      'timeout': '${timeoutDuration.inSeconds} seconds',
      'headers': headers,
      'endpoints': {
        'eventTypes': '$baseUrl/event-types',
        'competitions': '$baseUrl/competitions',
        'judges': '$baseUrl/judges',
        'participants': '$baseUrl/participants',
        'criteria': '$baseUrl/criteria',
        'health': '$baseUrl/health',
      },
    };
  }
} 
