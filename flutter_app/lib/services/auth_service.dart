import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// User model with persistent UID.
class AppUser {
  final String uid;
  final String displayName;
  final String? photoURL;

  AppUser({required this.uid, required this.displayName, this.photoURL});

  Future<String> getIdToken() async => 'token_$uid';
}

/// Persistent Username Authentication Service.
/// Deterministically maps a username to a unique UID so that typing the same
/// nickname always restores the player's saved level, XP, coins, and match history.
class AuthService {
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;
  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<String?> getIdToken() async {
    return await _currentUser?.getIdToken();
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
    return _currentUser!;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
