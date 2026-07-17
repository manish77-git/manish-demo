import 'package:flutter/material.dart';
import '../models/game_session.dart';

/// Game state management provider.
class GameProvider extends ChangeNotifier {
  GameSession? _currentSession;
  List<GameSession> _availableGames = [];
  bool _isLoading = false;
  String? _error;

  GameSession? get currentSession => _currentSession;
  List<GameSession> get availableGames => _availableGames;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInGame => _currentSession != null;

  void setCurrentSession(GameSession? session) {
    _currentSession = session;
    notifyListeners();
  }

  void setAvailableGames(List<GameSession> games) {
    _availableGames = games;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearSession() {
    _currentSession = null;
    notifyListeners();
  }
}
