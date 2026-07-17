import 'dart:async';
import 'package:uuid/uuid.dart';

/// Simple user model — only needs a display name.
class AppUser {
  final String uid;
  final String displayName;
  final String? photoURL;

  AppUser({required this.uid, required this.displayName, this.photoURL});

  Future<String> getIdToken() async => 'mock_token_$uid';
}

/// Username-only authentication service.
/// No email/password required — just pick a name and play.
class AuthService {
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  /// Current user stream.
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  /// Current user.
  AppUser? get currentUser => _currentUser;

  /// Whether the user is signed in.
  bool get isSignedIn => _currentUser != null;

  /// Get the current user's ID token for API calls.
  Future<String?> getIdToken() async {
    return await _currentUser?.getIdToken();
  }

  /// Sign in with just a username.
  Future<AppUser> signInWithUsername(String username) async {
    // Small delay to feel natural
    await Future.delayed(const Duration(milliseconds: 400));

    final uid = const Uuid().v4().substring(0, 12);
    _currentUser = AppUser(uid: uid, displayName: username);
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  /// Sign out.
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
