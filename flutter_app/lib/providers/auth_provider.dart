import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Auth state management provider — username only.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _error;
  String? _idToken;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String get displayName => _user?.displayName ?? 'Player';
  String? get photoUrl => _user?.photoURL;
  String get uid => _user?.uid ?? '';
  String get idToken => _idToken ?? '';

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _idToken = await _authService.getIdToken();
      } else {
        _idToken = null;
      }
      notifyListeners();
    });
  }

  /// Sign in with just a username.
  Future<bool> signInWithUsername(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithUsername(username);
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

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
