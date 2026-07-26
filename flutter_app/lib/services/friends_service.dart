import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class FriendUser {
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final int gamesPlayed;
  final int gamesWon;
  final int averageScore;
  final bool isOnline;

  const FriendUser({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.averageScore = 0,
    this.isOnline = false,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      uid: json['uid'] as String? ?? '',
      username: json['username'] as String? ?? json['displayName'] as String? ?? 'user',
      displayName: json['displayName'] as String? ?? 'Player',
      photoUrl: json['photoUrl'] as String?,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromDisplayName;
  final String fromUsername;
  final String createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromDisplayName,
    required this.fromUsername,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String? ?? '',
      fromUid: json['fromUid'] as String? ?? '',
      fromDisplayName: json['fromDisplayName'] as String? ?? 'Player',
      fromUsername: json['fromUsername'] as String? ?? 'user',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class FriendsService {
  final String baseUrl;
  final String Function() getToken;

  FriendsService({required this.baseUrl, required this.getToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${getToken()}',
      };

  Future<List<FriendUser>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/api/friends/search?query=${Uri.encodeComponent(query)}');
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']?['message'] ?? 'Failed to search users');
    final list = data['data']['users'] as List;
    return list.map((u) => FriendUser.fromJson(u)).toList();
  }

  Future<List<FriendUser>> getFriends() async {
    final uri = Uri.parse('$baseUrl/api/friends');
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']?['message'] ?? 'Failed to get friends');
    final list = data['data']['friends'] as List;
    return list.map((u) => FriendUser.fromJson(u)).toList();
  }

  Future<Map<String, List<FriendRequest>>> getPendingRequests() async {
    final uri = Uri.parse('$baseUrl/api/friends/requests');
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']?['message'] ?? 'Failed to get requests');

    final incomingList = data['data']['incoming'] as List? ?? [];
    final incoming = incomingList.map((r) => FriendRequest.fromJson(r)).toList();

    return {'incoming': incoming};
  }

  Future<void> sendRequest(String targetUsernameOrUid) async {
    final uri = Uri.parse('$baseUrl/api/friends/request');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'target': targetUsernameOrUid}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || !data['success']) {
      throw Exception(data['error']?['message'] ?? 'Failed to send request');
    }
  }

  Future<void> acceptRequest(String requesterId) async {
    final uri = Uri.parse('$baseUrl/api/friends/accept');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'requesterId': requesterId}),
    );
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']?['message'] ?? 'Failed to accept request');
  }

  Future<void> declineRequest(String targetUid) async {
    final uri = Uri.parse('$baseUrl/api/friends/decline');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'targetUid': targetUid}),
    );
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']?['message'] ?? 'Failed to decline request');
  }

  Future<void> removeFriend(String friendId) async {
    final uri = Uri.parse('$baseUrl/api/friends/$friendId');
    final response = await http.delete(uri, headers: _headers);
    final data = jsonDecode(response.body);
    if (!data['success']) throw Exception(data['error']?['message'] ?? 'Failed to remove friend');
  }
}
