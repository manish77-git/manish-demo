import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/api_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

/// SocketProvider — manages the Socket.IO connection, room state, and game sync.
class SocketProvider extends ChangeNotifier {
  static String get _serverUrl => ApiConfig.serverUrl;

  io.Socket? _socket;
  String? _roomCode;
  List<Map<String, dynamic>> _roomPlayers = [];
  Map<String, dynamic> _roomSettings = {
    'category': 'all',
    'difficulty': 'all',
    'duration': 80,
    'maxPlayers': 8,
    'rounds': 3,
    'isPrivate': false,
  };
  String? _errorMessage;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  // ─── Callback Subscriptions ─────────────────────────────
  void Function(int countdownSeconds, String prompt, int duration, int currentRound, int totalRounds)? onMatchCountdown;
  void Function(String prompt, int duration, int currentRound, int totalRounds)? onMatchStarted;
  void Function(String userId, String displayName)? onPlayerFinished;
  void Function(Map<String, dynamic> resultsData)? onGameResults;
  void Function(String gameId, String error)? onEvaluationFailed;
  void Function(String status, String gameId)? onGameStatus;
  void Function(String roomCode)? onRematchReady;
  void Function(Map<String, dynamic> history)? onDrawingHistory;
  void Function(String userId, List<dynamic> strokes)? onDrawingStroke;
  void Function(String userId)? onDrawingClear;
  void Function(String userId, double x, double y)? onDrawingCursor;
  void Function(String userId, Map<String, dynamic> metrics)? onLiveMetrics;
  void Function(String msg, String displayName)? onChatMessageReceived;
  void Function(String emoji, String userId)? onChatReactionReceived;
  void Function(String fromUid, String hostName, String roomCode)? onFriendInviteReceived;

  // Getters
  String? get roomCode => _roomCode;
  List<Map<String, dynamic>> get roomPlayers => _roomPlayers;
  Map<String, dynamic> get roomSettings => _roomSettings;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  ConnectionStatus get connectionStatus => _connectionStatus;
  int get playerCount => _roomPlayers.length;

  // ─── Update Server URL & Reconnect ──────────────────────
  void updateServerUrl(String? newUrl) {
    ApiConfig.setCustomUrl(newUrl);
    disconnect();
    connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  // ─── Connect with Auto-Reconnection ─────────────────────────
  void connect() {
    if (_socket != null) return; // Already initialized

    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _connectionStatus = ConnectionStatus.connected;
      _errorMessage = null;
      notifyListeners();
      debugPrint('[SocketProvider] Connected to server');
    });

    _socket!.onDisconnect((_) {
      _connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
      debugPrint('[SocketProvider] Disconnected');
    });

    _socket!.onReconnecting((_) {
      _connectionStatus = ConnectionStatus.reconnecting;
      notifyListeners();
      debugPrint('[SocketProvider] Reconnecting...');
    });

    _socket!.onConnectError((err) {
      _connectionStatus = ConnectionStatus.disconnected;
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
      final settingsRaw = data['settings'] as Map<dynamic, dynamic>?;
      if (settingsRaw != null) {
        _roomSettings = Map<String, dynamic>.from(settingsRaw);
      }
      notifyListeners();
      debugPrint('[SocketProvider] Room updated: ${_roomPlayers.length} players');
    });

    _socket!.on('room:error', (data) {
      _errorMessage = data['message'] as String? ?? 'Unknown error';
      notifyListeners();
      debugPrint('[SocketProvider] Room error: $_errorMessage');
    });

    // ─── Multiplayer Match Events ───────────────────────
    _socket!.on('match:countdown', (data) {
      debugPrint('[SocketProvider] Match countdown: $data');
      if (onMatchCountdown != null) {
        final countdown = data['countdownSeconds'] as int? ?? 3;
        final prompt = data['prompt'] as String? ?? 'cat';
        final duration = data['duration'] as int? ?? 80;
        final currentRound = data['currentRound'] as int? ?? 1;
        final totalRounds = data['totalRounds'] as int? ?? 3;
        onMatchCountdown!(countdown, prompt, duration, currentRound, totalRounds);
      }
    });

    _socket!.on('match:start', (data) {
      debugPrint('[SocketProvider] Match start: $data');
      if (onMatchStarted != null) {
        final prompt = data['prompt'] as String? ?? 'cat';
        final duration = data['duration'] as int? ?? 80;
        final currentRound = data['currentRound'] as int? ?? 1;
        final totalRounds = data['totalRounds'] as int? ?? 3;
        onMatchStarted!(prompt, duration, currentRound, totalRounds);
      }
    });

    _socket!.on('drawing:submitted', (data) {
      debugPrint('[SocketProvider] Drawing submitted by player: $data');
      if (onPlayerFinished != null) {
        final userId = data['userId'] as String? ?? '';
        final displayName = data['displayName'] as String? ?? 'Player';
        onPlayerFinished!(userId, displayName);
      }
    });

    _socket!.on('game:results', (data) {
      debugPrint('[SocketProvider] Game results received: $data');
      if (onGameResults != null) {
        final map = Map<String, dynamic>.from(data as Map);
        onGameResults!(map);
      }
    });

    _socket!.on('game:evaluation_failed', (data) {
      debugPrint('[SocketProvider] AI evaluation failed: $data');
      if (onEvaluationFailed != null) {
        final gameId = data['gameId'] as String? ?? '';
        final error = data['error'] as String? ?? 'AI evaluation failed.';
        onEvaluationFailed!(gameId, error);
      }
    });

    _socket!.on('drawing:history', (data) {
      debugPrint('[SocketProvider] Drawing history received');
      if (onDrawingHistory != null) {
        final history = data['history'] as Map<String, dynamic>? ?? {};
        onDrawingHistory!(history);
      }
    });

    _socket!.on('drawing:stroke', (data) {
      if (onDrawingStroke != null) {
        final userId = data['userId'] as String;
        final strokes = data['strokes'] as List<dynamic>;
        onDrawingStroke!(userId, strokes);
      }
    });

    _socket!.on('drawing:clear', (data) {
      if (onDrawingClear != null) {
        final userId = data['userId'] as String;
        onDrawingClear!(userId);
      }
    });

    _socket!.on('drawing:cursor', (data) {
      if (onDrawingCursor != null) {
        final userId = data['userId'] as String;
        final x = (data['x'] as num).toDouble();
        final y = (data['y'] as num).toDouble();
        onDrawingCursor!(userId, x, y);
      }
    });

    _socket!.on('match:live_metrics', (data) {
      if (onLiveMetrics != null) {
        final userId = data['userId'] as String;
        final metrics = Map<String, dynamic>.from(data['metrics'] as Map);
        onLiveMetrics!(userId, metrics);
      }
    });

    _socket!.on('chat:message', (data) {
      if (onChatMessageReceived != null) {
        final msg = data['message'] as String;
        final senderName = data['displayName'] as String;
        onChatMessageReceived!(msg, senderName);
      }
    });

    _socket!.on('chat:reaction', (data) {
      if (onChatReactionReceived != null) {
        final emoji = data['emoji'] as String;
        final userId = data['uid'] as String? ?? '';
        onChatReactionReceived!(emoji, userId);
      }
    });

    _socket!.on('friend:invite_received', (data) {
      if (onFriendInviteReceived != null) {
        final fromUid = data['fromUid'] as String? ?? '';
        final hostName = data['hostName'] as String? ?? 'A friend';
        final code = data['roomCode'] as String? ?? '';
        onFriendInviteReceived!(fromUid, hostName, code);
      }
    });

    _socket!.on('game:status', (data) {
      debugPrint('[SocketProvider] Game status: $data');
      if (onGameStatus != null) {
        final status = data['status'] as String? ?? '';
        final gameId = data['gameId'] as String? ?? '';
        onGameStatus!(status, gameId);
      }
    });

    _socket!.on('room:rematch_ready', (data) {
      debugPrint('[SocketProvider] Rematch ready: $data');
      if (onRematchReady != null) {
        final roomCode = data['roomCode'] as String? ?? '';
        onRematchReady!(roomCode);
      }
    });

    _socket!.connect();
  }

  // ─── Actions ────────────────────────────────────────────
  void createRoom({required String uid, required String displayName}) {
    _errorMessage = null;
    _roomPlayers = [];
    if (_socket != null && _socket!.connected) {
      _socket!.emit('room:create', {
        'uid': uid,
        'displayName': displayName,
      });
    } else {
      _errorMessage = 'Not connected to server. Please check your connection and try again.';
      notifyListeners();
    }
  }

  void joinRoom({
    required String roomCode,
    required String uid,
    required String displayName,
  }) {
    _errorMessage = null;
    _roomPlayers = [];
    _roomCode = roomCode;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('room:join', {
        'roomCode': roomCode,
        'uid': uid,
        'displayName': displayName,
      });
    } else {
      _errorMessage = 'Not connected to server. Please check your connection and try again.';
      notifyListeners();
    }
  }

  void leaveRoom() {
    _socket?.emit('room:leave');
    _roomCode = null;
    _roomPlayers = [];
    notifyListeners();
  }

  void emitStartMatch({
    required String difficulty,
    required String category,
    required int duration,
    int rounds = 3,
  }) {
    _socket?.emit('match:start', {
      'roomCode': _roomCode,
      'difficulty': difficulty,
      'category': category,
      'duration': duration,
      'rounds': rounds,
    });
  }

  void emitNextRound() {
    _socket?.emit('match:next_round', {
      'roomCode': _roomCode,
    });
  }

  void emitRematch() {
    _socket?.emit('room:rematch', {
      'roomCode': _roomCode,
    });
    debugPrint('[SocketProvider] Rematch requested for room $_roomCode');
  }

  void emitStroke(List<Map<String, dynamic>> strokesJson) {
    // Canvas is private to each player; no stroke emission over network
  }

  void emitClear() {
    // Canvas is private to each player; no clear emission over network
  }

  void emitCursor(double x, double y) {
    // Canvas is private to each player; no cursor emission over network
  }

  void emitLiveMetrics(Map<String, dynamic> metrics) {
    _socket?.emit('match:live_metrics', {
      'roomCode': _roomCode,
      'metrics': metrics,
    });
  }

  void emitChatMessage(String message, String displayName) {
    _socket?.emit('chat:message', {
      'roomCode': _roomCode,
      'message': message,
      'displayName': displayName,
    });
  }

  void emitToggleReady({required String uid}) {
    _socket?.emit('room:toggle_ready', {
      'roomCode': _roomCode,
      'uid': uid,
    });
  }

  void emitUpdateSettings(Map<String, dynamic> settings) {
    _socket?.emit('room:update_settings', {
      'roomCode': _roomCode,
      'settings': settings,
    });
  }

  void emitChatReaction(String emoji) {
    _socket?.emit('chat:reaction', {
      'roomCode': _roomCode,
      'emoji': emoji,
    });
  }

  void registerUserOnline(String uid) {
    _socket?.emit('user:online', {'uid': uid});
  }

  void inviteFriendToRoom({required String friendUid, required String hostName, required String roomCode}) {
    _socket?.emit('friend:invite', {
      'friendUid': friendUid,
      'hostName': hostName,
      'roomCode': roomCode,
    });
  }

  // Dispose
  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
