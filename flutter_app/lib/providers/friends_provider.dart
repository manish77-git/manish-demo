import 'package:flutter/material.dart';
import '../services/friends_service.dart';
import '../services/api_service.dart';

class FriendsProvider extends ChangeNotifier {
  List<FriendUser> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendUser> _searchResults = [];

  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<FriendUser> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendUser> get searchResults => _searchResults;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  int get pendingCount => _incomingRequests.length;

  Future<void> fetchFriendsAndRequests(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = FriendsService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => token,
      );

      final friendsList = await service.getFriends();
      final reqMap = await service.getPendingRequests();

      _friends = friendsList;
      _incomingRequests = reqMap['incoming'] ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String token, String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final service = FriendsService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => token,
      );
      _searchResults = await service.searchUsers(query);
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<bool> sendRequest(String token, String target) async {
    try {
      final service = FriendsService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => token,
      );
      await service.sendRequest(target);
      await fetchFriendsAndRequests(token);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> acceptRequest(String token, String requesterId) async {
    try {
      final service = FriendsService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => token,
      );
      await service.acceptRequest(requesterId);
      await fetchFriendsAndRequests(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> declineRequest(String token, String requesterId) async {
    try {
      final service = FriendsService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => token,
      );
      await service.declineRequest(requesterId);
      await fetchFriendsAndRequests(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFriend(String token, String friendId) async {
    try {
      final service = FriendsService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => token,
      );
      await service.removeFriend(friendId);
      await fetchFriendsAndRequests(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
