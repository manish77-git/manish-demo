import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

/// Configuration for backend API
class ApiConfig {
  // Use 10.0.2.2 for Android Emulator to reach localhost.
  // Or use your tunneling URL if testing on a real device.
  static const String baseUrl = 'http://localhost:3000/api'; 
}

/// Centralized service for communicating with the Node.js backend.
class ApiService {
  final AuthProvider auth;

  ApiService(this.auth);

  /// Helper to get headers including the Auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = auth.idToken;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── PLAYER STATS ──────────────────────────────────────────────────────────

  /// Fetch the current user's stats
  Future<Map<String, dynamic>> getMyStats() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/stats/me'), headers: headers);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']['stats'];
    }
    throw Exception('Failed to load stats');
  }

  // ─── ACHIEVEMENTS ──────────────────────────────────────────────────────────

  /// Fetch the current user's badges (with all catalog unlocked status)
  Future<Map<String, dynamic>> getMyBadges() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/achievements/me/all'), headers: headers);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Failed to load badges');
  }

  // ─── DAILY CHALLENGE ───────────────────────────────────────────────────────

  /// Fetch today's daily challenge
  Future<Map<String, dynamic>> getDailyChallenge() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/daily'));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']['challenge'];
    }
    throw Exception('Failed to load daily challenge');
  }

  /// Submit result for the daily challenge
  Future<Map<String, dynamic>> submitDailyChallenge(int score, List<String> labels) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/daily/submit'),
      headers: headers,
      body: jsonEncode({
        'score': score,
        'aiLabels': labels,
      }),
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Failed to submit daily challenge');
  }

  /// Fetch today's daily leaderboard
  Future<List<dynamic>> getDailyLeaderboard() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/daily/leaderboard'));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']['leaderboard'] as List<dynamic>;
    }
    throw Exception('Failed to load daily leaderboard');
  }

  // ─── MATCHMAKING ───────────────────────────────────────────────────────────

  /// Join the matchmaking queue
  Future<Map<String, dynamic>> joinMatchmaking(String difficulty) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matchmaking/join'),
      headers: headers,
      body: jsonEncode({
        'difficulty': difficulty,
      }),
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Failed to join matchmaking queue');
  }

  /// Leave the matchmaking queue
  Future<void> leaveMatchmaking() async {
    final headers = await _getHeaders();
    await http.post(Uri.parse('${ApiConfig.baseUrl}/matchmaking/leave'), headers: headers);
  }
}
