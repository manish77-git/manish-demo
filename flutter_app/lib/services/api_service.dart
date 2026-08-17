import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'retry_helper.dart';

/// Configuration for backend API
class ApiConfig {
  static String? _customUrl;

  static void setCustomUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _customUrl = url.trim();
    } else {
      _customUrl = null;
    }
  }

  static String get serverUrl {
    if (_customUrl != null && _customUrl!.isNotEmpty) {
      return _customUrl!;
    }
    if (kIsWeb && !Uri.base.toString().contains('localhost')) {
      return 'https://draw-battle-backend.onrender.com';
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

  // ─── PLAYER STATS & PROFILE ──────────────────────────────────────────────

  /// Fetch the current user's full stats & profile
  Future<Map<String, dynamic>> getMyStats() async {
    try {
      return await RetryHelper.retryAsync(() async {
        final headers = await _getHeaders();
        final response = await http
            .get(Uri.parse('${ApiConfig.baseUrl}/auth/profile'), headers: headers)
            .timeout(const Duration(seconds: 6));
        
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['data']['user'] as Map<String, dynamic>;
        }
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }, taskName: 'getMyStats');
    } catch (e) {
      debugPrint('[ApiService] getMyStats fallback due to error: $e');
      return {
        'totalScore': auth.highestScore,
        'gamesPlayed': auth.gamesPlayed,
        'gamesWon': auth.gamesWon,
        'averageScore': auth.averageScore,
      };
    }
  }

  /// Get public profile of another player by userId
  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    try {
      return await RetryHelper.retryAsync(() async {
        final response = await http
            .get(Uri.parse('${ApiConfig.baseUrl}/auth/profile/$userId'))
            .timeout(const Duration(seconds: 6));
        
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['data']['user'] as Map<String, dynamic>;
        }
        return null;
      }, taskName: 'getPublicProfile');
    } catch (e) {
      debugPrint('[ApiService] getPublicProfile error: $e');
      return null;
    }
  }

  /// Update own display name or avatar
  Future<bool> updateProfile({String? displayName, String? avatar}) async {
    try {
      return await RetryHelper.retryAsync(() async {
        final headers = await _getHeaders();
        final body = <String, dynamic>{};
        if (displayName != null) body['displayName'] = displayName;
        if (avatar != null) body['avatar'] = avatar;

        final response = await http
            .patch(
              Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 6));
        
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['success'] == true;
        }
        return false;
      }, taskName: 'updateProfile');
    } catch (e) {
      debugPrint('[ApiService] updateProfile error: $e');
      return false;
    }
  }

  /// Record multiplayer match result
  Future<bool> recordMatchResult({
    required String mode,
    required int totalScore,
    required int averageScore,
    required int roundsCount,
    required int placement,
    required int opponentCount,
  }) async {
    try {
      return await RetryHelper.retryAsync(() async {
        final headers = await _getHeaders();
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/auth/match-result'),
              headers: headers,
              body: jsonEncode({
                'mode': mode,
                'totalScore': totalScore,
                'averageScore': averageScore,
                'roundsCount': roundsCount,
                'placement': placement,
                'opponentCount': opponentCount,
              }),
            )
            .timeout(const Duration(seconds: 6));
        
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['success'] == true;
        }
        return false;
      }, taskName: 'recordMatchResult');
    } catch (e) {
      debugPrint('[ApiService] recordMatchResult error: $e');
      return false;
    }
  }
}
