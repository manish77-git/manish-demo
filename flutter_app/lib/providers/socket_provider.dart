import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// SocketProvider — manages the Socket.IO connection and room state.
///
/// This is the single source of truth for:
///  - Whether we are connected to the backend
///  - The current room code
///  - The live list of real players in the room
///
/// No fake, bot, or placeholder players are ever created.
class SocketProvider extends ChangeNotifier {
  static const String _serverUrl = 'http://localhost:3000';

  io.Socket? _socket;
  String? _roomCode;
  List<Map<String, dynamic>> _roomPlayers = [];
  String? _errorMessage;
  bool _isConnected = false;

  // ─── Getters ────────────────────────────────────────────
  String? get roomCode => _roomCode;
  List<Map<String, dynamic>> get roomPlayers => _roomPlayers;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  int get playerCount => _roomPlayers.length;

  // ─── Connect ────────────────────────────────────────────
  void connect() {
    if (_socket != null) return; // Already connected

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _errorMessage = null;
      notifyListeners();
      debugPrint('[SocketProvider] Connected to server');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      debugPrint('[SocketProvider] Disconnected');
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      _errorMessage = 'Could not connect to server.';
      notifyListeners();
      debugPrint('[SocketProvider] Connection error: $err');
    });

    // ─── Room Events ────────────────────────────────────
    _socket!.on('room:created', (data) {
      _roomCode = data['roomCode'] as String?;
      notifyListeners();
      debugPrint('[SocketProvider] Room created: $_roomCode');
    });

    _socket!.on('room:update', (data) {
      final playersRaw = data['players'] as List<dynamic>?;
      if (playersRaw != null) {
        _roomPlayers = playersRaw
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
      }
      notifyListeners();
      debugPrint('[SocketProvider] Room updated: ${_roomPlayers.length} players');
    });

    _socket!.on('room:error', (data) {
      _errorMessage = data['message'] as String? ?? 'Unknown error';
      notifyListeners();
      debugPrint('[SocketProvider] Room error: $_errorMessage');
    });

    _socket!.connect();
  }

  // ─── Create Room ────────────────────────────────────────
  void createRoom({required String uid, required String displayName}) {
    _errorMessage = null;
    _roomPlayers = [];
    _socket?.emit('room:create', {
      'uid': uid,
      'displayName': displayName,
    });
  }

  // ─── Join Room ──────────────────────────────────────────
  void joinRoom({
    required String roomCode,
    required String uid,
    required String displayName,
  }) {
    _errorMessage = null;
    _roomPlayers = [];
    _roomCode = roomCode;
    _socket?.emit('room:join', {
      'roomCode': roomCode,
      'uid': uid,
      'displayName': displayName,
    });
  }

  // ─── Leave Room ─────────────────────────────────────────
  void leaveRoom() {
    _socket?.emit('room:leave');
    _roomCode = null;
    _roomPlayers = [];
    notifyListeners();
  }

  // ─── Dispose ────────────────────────────────────────────
  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
