import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leaderboard_entry.dart';

/// Service for leaderboard API calls.
class LeaderboardService {
  final String baseUrl;
  final String Function() getToken;

  LeaderboardService({required this.baseUrl, required this.getToken});

  /// Get global leaderboard.
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/leaderboard?limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return (data['data']['leaderboard'] as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  /// Get current user's rank and stats.
  Future<Map<String, dynamic>> getMyRank() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/leaderboard/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${getToken()}',
      },
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return data['data'];
  }
}
