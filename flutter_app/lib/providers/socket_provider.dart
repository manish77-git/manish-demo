import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// SocketProvider — manages the Socket.IO connection and room state.
class SocketProvider extends ChangeNotifier {
  static String get _serverUrl => kIsWeb && !Uri.base.toString().contains('localhost')
      ? 'https://draw-battle-backend-production.up.railway.app'
      : 'http://localhost:3000';

  io.Socket? _socket;
  String? _roomCode;
  List<Map<String, dynamic>> _roomPlayers = [];
  Map<String, dynamic> _roomSettings = {
    'category': 'all',
    'difficulty': 'all',
    'duration': 80,
    'maxPlayers': 8,
  };
  String? _errorMessage;
  bool _isConnected = false;

  // ─── Callback Subscriptions ─────────────────────────────
  void Function(String prompt, int duration)? onMatchStarted;
  void Function(Map<String, dynamic> history)? onDrawingHistory;
  void Function(String userId, List<dynamic> strokes)? onDrawingStroke;
  void Function(String userId)? onDrawingClear;
  void Function(String userId, double x, double y)? onDrawingCursor;
  void Function(String userId, Map<String, dynamic> metrics)? onLiveMetrics;
  void Function(String msg, String displayName)? onChatMessageReceived;
  void Function(String emoji, String userId)? onChatReactionReceived;

  // Getters
  String? get roomCode => _roomCode;
  List<Map<String, dynamic>> get roomPlayers => _roomPlayers;
  Map<String, dynamic> get roomSettings => _roomSettings;
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
    _socket!.on('match:start', (data) {
      debugPrint('[SocketProvider] Match start: $data');
      if (onMatchStarted != null) {
        final prompt = data['prompt'] as String? ?? 'cat';
        final duration = data['duration'] as int? ?? 80;
        onMatchStarted!(prompt, duration);
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

    _socket!.connect();
  }

  // ─── Actions ────────────────────────────────────────────
  void createRoom({required String uid, required String displayName}) {
    _errorMessage = null;
    _roomPlayers = [];
    _socket?.emit('room:create', {
      'uid': uid,
      'displayName': displayName,
    });
  }

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
  }) {
    _socket?.emit('match:start', {
      'roomCode': _roomCode,
      'difficulty': difficulty,
      'category': category,
      'duration': duration,
    });
  }

  void emitStroke(List<Map<String, dynamic>> strokesJson) {
    _socket?.emit('drawing:stroke', {
      'roomCode': _roomCode,
      'strokes': strokesJson,
    });
  }

  void emitClear() {
    _socket?.emit('drawing:clear', {
      'roomCode': _roomCode,
    });
  }

  void emitCursor(double x, double y) {
    _socket?.emit('drawing:cursor', {
      'roomCode': _roomCode,
      'x': x,
      'y': y,
    });
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

  // Dispose
  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
