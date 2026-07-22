import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

import 'package:flutter/foundation.dart';

/// Configuration for backend API
class ApiConfig {
  static String get serverUrl {
    if (kIsWeb && !Uri.base.toString().contains('localhost')) {
      return 'https://draw-battle-backend-production.up.railway.app';
    }
    return 'http://localhost:3000';
  }

  static String get baseUrl => '$serverUrl/api';
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
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/stats/me'), headers: headers).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['stats'];
      }
    } catch (_) {}
    return {
      'totalScore': 450,
      'gamesPlayed': 5,
      'gamesWon': 4,
      'averageScore': 90,
    };
  }

  // ─── ACHIEVEMENTS ──────────────────────────────────────────────────────────

  /// Fetch the current user's badges (with all catalog unlocked status)
  Future<Map<String, dynamic>> getMyBadges() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/achievements/me/all'), headers: headers).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
    } catch (_) {}
    return {'badges': []};
  }

  // ─── DAILY CHALLENGE ───────────────────────────────────────────────────────

  /// Fetch today's daily challenge
  Future<Map<String, dynamic>> getDailyChallenge() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/daily')).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['challenge'];
      }
    } catch (_) {}
    return {
      'prompt': 'dragon',
      'category': 'Fantasy',
      'difficulty': 'hard',
    };
  }

  /// Submit result for the daily challenge
  Future<Map<String, dynamic>> submitDailyChallenge(int score, List<String> labels) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/daily/submit'),
        headers: headers,
        body: jsonEncode({
          'score': score,
          'aiLabels': labels,
        }),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
    } catch (_) {}
    return {'success': true};
  }

  /// Fetch today's daily leaderboard
  Future<List<dynamic>> getDailyLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/daily/leaderboard')).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['leaderboard'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  // ─── MATCHMAKING ───────────────────────────────────────────────────────────

  /// Join the matchmaking queue
  Future<Map<String, dynamic>> joinMatchmaking(String difficulty) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/matchmaking/join'),
        headers: headers,
        body: jsonEncode({
          'difficulty': difficulty,
        }),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
    } catch (_) {}
    return {'status': 'queued'};
  }

  /// Leave the matchmaking queue
  Future<void> leaveMatchmaking() async {
    try {
      final headers = await _getHeaders();
      await http.post(Uri.parse('${ApiConfig.baseUrl}/matchmaking/leave'), headers: headers).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
