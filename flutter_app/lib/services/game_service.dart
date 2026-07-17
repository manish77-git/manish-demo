import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_session.dart';

/// Service for game session API calls.
class GameService {
  final String baseUrl;
  final String Function() getToken;

  GameService({required this.baseUrl, required this.getToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${getToken()}',
  };

  /// Create a new game session.
  Future<GameSession> createGame({
    String difficulty = 'all',
    int maxPlayers = 6,
    int drawingTime = 60,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/games'),
      headers: _headers,
      body: jsonEncode({
        'difficulty': difficulty,
        'maxPlayers': maxPlayers,
        'drawingTime': drawingTime,
      }),
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return GameSession.fromJson(data['data']['session']);
  }

  /// List available games.
  Future<List<GameSession>> listGames() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/games'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return (data['data']['games'] as List)
        .map((g) => GameSession.fromJson(g))
        .toList();
  }

  /// Get a specific game.
  Future<GameSession> getGame(String gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/$gameId'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return GameSession.fromJson(data['data']['session']);
  }

  /// Join a game.
  Future<GameSession> joinGame(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/games/$gameId/join'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return GameSession.fromJson(data['data']['session']);
  }

  /// Mark as ready.
  Future<Map<String, dynamic>> readyUp(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/games/$gameId/ready'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return data['data'];
  }

  /// Start the game (host only).
  Future<GameSession> startGame(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/games/$gameId/start'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']['message']);
    return GameSession.fromJson(data['data']['session']);
  }
}
