import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User model with persistent UID.
class AppUser {
  final String uid;
  final String displayName;
  final String? photoURL;

  AppUser({required this.uid, required this.displayName, this.photoURL});

  Future<String> getIdToken() async => 'token_$uid';

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'photoURL': photoURL,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String,
    displayName: json['displayName'] as String,
    photoURL: json['photoURL'] as String?,
  );
}

/// Persistent Username Authentication Service.
/// Deterministically maps a username to a unique UID so that typing the same
/// nickname always restores the player's saved level, XP, coins, and match history.
/// Persists session across app restarts via SharedPreferences.
class AuthService {
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  static const String _sessionKey = 'drawbattle_session';

  Stream<AppUser?> get authStateChanges => _authStateController.stream;
  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<String?> getIdToken() async {
    return await _currentUser?.getIdToken();
  }

  /// Try to restore a previously saved session.
  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      if (sessionJson != null) {
        final json = jsonDecode(sessionJson) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(json);
        _authStateController.add(_currentUser);
        return _currentUser;
      }
    } catch (_) {}
    return null;
  }

  /// Sign in with username — generates consistent deterministic UID from username hash.
  Future<AppUser> signInWithUsername(String username) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final normalized = username.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    final uid = 'usr_${digest.toString().substring(0, 12)}';

    _currentUser = AppUser(uid: uid, displayName: username.trim());
    _authStateController.add(_currentUser);

    // Persist session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(_currentUser!.toJson()));
    } catch (_) {}

    return _currentUser!;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);

    // Clear persisted session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }
}
