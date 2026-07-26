import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// AuthProvider — manages authentication state, user profile, and all persistent stats.
/// Replaces the old ProgressionProvider. All user data lives here.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _error;
  String? _idToken;

  // Full user profile from backend
  String _username = '';
  String _avatar = '🎨';
  int _highestScore = 0;
  int _gamesPlayed = 0;
  int _gamesWon = 0;
  int _gamesLost = 0;
  int _winRate = 0;
  int _averageScore = 0;
  int _totalDrawings = 0;
  int _friendsCount = 0;
  String _favouriteGameMode = 'single_player';
  String? _lastOnline;
  List<Map<String, dynamic>> _matchHistory = [];
  Map<String, dynamic> _settings = {
    'soundEnabled': true,
    'volume': 0.8,
    'theme': 'system',
    'notifications': true,
  };

  // ─── Getters ────────────────────────────────────────────
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String get displayName => _user?.displayName ?? 'Player';
  String get username => _username.isNotEmpty ? _username : displayName.toLowerCase();
  String? get photoUrl => _user?.photoURL;
  String get uid => _user?.uid ?? '';
  String get idToken => _idToken ?? '';

  String get avatar => _avatar;
  int get highestScore => _highestScore;
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  int get gamesLost => _gamesLost;
  int get winRate => _winRate;
  int get averageScore => _averageScore;
  int get totalDrawings => _totalDrawings;
  int get friendsCount => _friendsCount;
  String get favouriteGameMode => _favouriteGameMode;
  String? get lastOnline => _lastOnline;
  List<Map<String, dynamic>> get matchHistory => List.unmodifiable(_matchHistory);
  Map<String, dynamic> get settings => Map.unmodifiable(_settings);

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _idToken = await _authService.getIdToken();
        await _syncProfileFromBackend();
      } else {
        _idToken = null;
        _resetProfile();
      }
      notifyListeners();
    });
  }

  void _resetProfile() {
    _username = '';
    _avatar = '🎨';
    _highestScore = 0;
    _gamesPlayed = 0;
    _gamesWon = 0;
    _gamesLost = 0;
    _winRate = 0;
    _averageScore = 0;
    _totalDrawings = 0;
    _friendsCount = 0;
    _matchHistory = [];
  }

  /// Attempt to restore a previously saved session.
  Future<bool> tryRestoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final restored = await _authService.restoreSession();
      if (restored != null) {
        _user = restored;
        _idToken = await _authService.getIdToken();
        await _syncProfileFromBackend();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Session restore failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sync user profile from the backend.
  Future<void> _syncProfileFromBackend() async {
    if (_user == null || _idToken == null) return;

    try {
      final uri = Uri.parse('${ApiConfig.serverUrl}/api/auth/profile');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
        body: jsonEncode({
          'displayName': _user!.displayName,
          'username': _user!.displayName.toLowerCase(),
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data']?['user'] != null) {
        _applyProfileData(data['data']['user']);
      }
    } catch (e) {
      debugPrint('[AuthProvider] Sync profile failed: $e');
    }
  }

  /// Refresh profile from backend (call from profile screen pull-to-refresh).
  Future<void> refreshProfile() async {
    if (_user == null || _idToken == null) return;

    try {
      final uri = Uri.parse('${ApiConfig.serverUrl}/api/auth/profile');
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data']?['user'] != null) {
        _applyProfileData(data['data']['user']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Refresh profile failed: $e');
    }
  }

  void _applyProfileData(Map<String, dynamic> u) {
    _username = u['username'] as String? ?? _user?.displayName.toLowerCase() ?? '';
    _avatar = u['avatar'] as String? ?? '🎨';
    _highestScore = u['highestScore'] as int? ?? 0;
    _gamesPlayed = u['gamesPlayed'] as int? ?? 0;
    _gamesWon = u['gamesWon'] as int? ?? 0;
    _gamesLost = u['gamesLost'] as int? ?? 0;
    _winRate = u['winRate'] as int? ?? 0;
    _averageScore = u['averageScore'] as int? ?? 0;
    _totalDrawings = u['totalDrawings'] as int? ?? 0;
    _friendsCount = (u['friends'] as List?)?.length ?? 0;
    _favouriteGameMode = u['favouriteGameMode'] as String? ?? 'single_player';
    _lastOnline = u['lastOnline'] as String?;

    if (u['matchHistory'] is List) {
      _matchHistory = (u['matchHistory'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    if (u['settings'] is Map) {
      _settings = Map<String, dynamic>.from(u['settings'] as Map);
    }
  }

  // ─── Actions ────────────────────────────────────────────

  Future<bool> signInWithUsername(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithUsername(username);
      _username = username.trim().toLowerCase();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update display name and/or avatar.
  Future<bool> updateProfile({String? displayName, String? avatar}) async {
    if (_idToken == null) return false;
    try {
      final uri = Uri.parse('${ApiConfig.serverUrl}/api/auth/profile');
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (avatar != null) body['avatar'] = avatar;

      final res = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data']?['user'] != null) {
        _applyProfileData(data['data']['user']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Update profile failed: $e');
    }
    return false;
  }

  /// Save single player challenge high score.
  Future<void> saveSinglePlayerScore({
    required int totalScore,
    required int roundsCount,
    required int totalRounds,
    required int averageScore,
  }) async {
    if (_idToken == null) return;
    try {
      final uri = Uri.parse('${ApiConfig.serverUrl}/api/auth/singleplayer-score');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
        body: jsonEncode({
          'score': totalScore,
          'rounds': roundsCount,
          'totalRounds': totalRounds,
          'averageScore': averageScore,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        final d = data['data'];
        _highestScore = d['highestScore'] as int? ?? _highestScore;
        _gamesPlayed = d['gamesPlayed'] as int? ?? _gamesPlayed;
        _gamesWon = d['gamesWon'] as int? ?? _gamesWon;
        _gamesLost = d['gamesLost'] as int? ?? _gamesLost;
        _winRate = d['winRate'] as int? ?? _winRate;
        _averageScore = d['averageScore'] as int? ?? _averageScore;
        _totalDrawings += roundsCount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Save singleplayer score failed: $e');
    }
  }

  /// Record a multiplayer match result.
  Future<void> recordMatchResult({
    required String mode,
    required int totalScore,
    required int averageScore,
    required int roundsCount,
    required int placement,
    required int opponentCount,
  }) async {
    if (_idToken == null) return;
    try {
      final uri = Uri.parse('${ApiConfig.serverUrl}/api/auth/match-result');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_idToken',
        },
        body: jsonEncode({
          'mode': mode,
          'totalScore': totalScore,
          'averageScore': averageScore,
          'roundsCount': roundsCount,
          'placement': placement,
          'opponentCount': opponentCount,
        }),
      ).timeout(const Duration(seconds: 8));

      // Refresh profile to get updated stats
      await refreshProfile();
    } catch (e) {
      debugPrint('[AuthProvider] Record match result failed: $e');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
