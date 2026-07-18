import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/chat_panel.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String _roomCode = '';
  final List<Map<String, dynamic>> _chatMessages = [];

  final List<String> _categories = [
    'all',
    'Animals',
    'Food',
    'Nature',
    'Objects',
    'Vehicles',
    'Sports',
    'Buildings',
    'Fantasy',
    'Space',
    'Technology',
    'Jobs',
    'Holidays',
    'Emotions',
    'Mythology',
    'Abstract Concepts'
  ];

  final List<String> _difficulties = ['all', 'easy', 'medium', 'hard'];
  final List<int> _durations = [30, 60, 80, 120];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _roomCode.isEmpty) {
      _roomCode = args;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketProvider = context.read<SocketProvider>();
      socketProvider.onMatchStarted = (prompt, duration) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/drawing',
            arguments: {
              'prompt': prompt,
              'duration': duration,
              'isMultiplayer': true,
            },
          );
        }
      };

      socketProvider.onChatMessageReceived = (message, senderName) {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'type': 'message',
              'displayName': senderName,
              'message': message,
            });
          });
        }
      };

      socketProvider.onChatReactionReceived = (emoji, userId) {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'type': 'reaction',
              'displayName': 'Reaction',
              'emoji': emoji,
            });
          });
        }
      };
    });
  }

  @override
  void dispose() {
    try {
      final socketProvider = context.read<SocketProvider>();
      socketProvider.onMatchStarted = null;
      socketProvider.onChatMessageReceived = null;
      socketProvider.onChatReactionReceived = null;
    } catch (_) {}
    super.dispose();
  }

  void _handleSendMessage(String msg) {
    final auth = context.read<AuthProvider>();
    context.read<SocketProvider>().emitChatMessage(msg, auth.displayName);
  }

  void _handleSendReaction(String emoji) {
    context.read<SocketProvider>().emitChatReaction(emoji);
  }

  void _startGame() {
    final socketProvider = context.read<SocketProvider>();
    final settings = socketProvider.roomSettings;
    socketProvider.emitStartMatch(
      difficulty: settings['difficulty'] ?? 'all',
      category: settings['category'] ?? 'all',
      duration: settings['duration'] ?? 80,
    );
  }

  void _leaveRoom() {
    context.read<SocketProvider>().leaveRoom();
    Navigator.pop(context);
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    required Color textColor,
    required Color borderColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              dropdownColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1A33)
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final socketProvider = context.watch<SocketProvider>();
    final players = socketProvider.roomPlayers;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final roomCode = socketProvider.roomCode ?? _roomCode;

    final myUid = context.read<AuthProvider>().uid;
    final isHost = players.any((p) => p['uid'] == myUid && p['isHost'] == true);
    final myPlayer = players.firstWhere((p) => p['uid'] == myUid, orElse: () => {});
    final isMyReady = myPlayer['isReady'] == true;
    final isSpectator = myPlayer['isSpectator'] == true;

    final otherPlayers = players.where((p) => p['uid'] != myUid);
    final allReady = otherPlayers.isNotEmpty && otherPlayers.every((p) => p['isReady'] == true || p['isSpectator'] == true);
    final canStart = players.length >= 2 && allReady;

    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: textColor),
          onPressed: _leaveRoom,
        ),
        title: Text('Waiting Arena', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: SketchpadBackgroundPainter(
                gridColor: textColor,
                isDark: isDark,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildMainPanel(
                            roomCode: roomCode,
                            players: players,
                            canStart: canStart,
                            isHost: isHost,
                            isMyReady: isMyReady,
                            isSpectator: isSpectator,
                            allReady: allReady,
                            myUid: myUid,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            primaryColor: primaryColor,
                            textMuted: textMuted,
                            textColor: textColor,
                            isDark: isDark,
                            socketProvider: socketProvider,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space24),
                        Expanded(
                          flex: 1,
                          child: ChatPanel(
                            messages: _chatMessages,
                            onSendMessage: _handleSendMessage,
                            onSendReaction: _handleSendReaction,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMainPanel(
                          roomCode: roomCode,
                          players: players,
                          canStart: canStart,
                          isHost: isHost,
                          isMyReady: isMyReady,
                          isSpectator: isSpectator,
                          allReady: allReady,
                          myUid: myUid,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                          textMuted: textMuted,
                          textColor: textColor,
                          isDark: isDark,
                          socketProvider: socketProvider,
                        ),
                        const SizedBox(height: AppTheme.space24),
                        Expanded(
                          child: ChatPanel(
                            messages: _chatMessages,
                            onSendMessage: _handleSendMessage,
                            onSendReaction: _handleSendReaction,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPanel({
    required String roomCode,
    required List<Map<String, dynamic>> players,
    required bool canStart,
    required bool isHost,
    required bool isMyReady,
    required bool isSpectator,
    required bool allReady,
    required String myUid,
    required Color cardBg,
    required Color borderColor,
    required Color primaryColor,
    required Color textMuted,
    required Color textColor,
    required bool isDark,
    required SocketProvider socketProvider,
  }) {
    final settings = socketProvider.roomSettings;
    final category = settings['category'] ?? 'all';
    final difficulty = settings['difficulty'] ?? 'all';
    final duration = settings['duration'] ?? 80;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Code Panel
          Center(
            child: Column(
              children: [
                Text(
                  'ROOM CODE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room code copied!')),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: AppTheme.gameCardDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderColor: borderColor,
                      shadowColor: borderColor,
                      radius: AppTheme.radiusMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          roomCode,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Icon(LucideIcons.copy, size: 16, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Player list count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Players (${players.length}/8)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Player list wrap box
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: AppTheme.gameCardDecoration(
              color: isDark ? const Color(0xFF0F0C1B) : const Color(0xFFFAF9FC),
              borderColor: borderColor,
              shadowColor: primaryColor.withOpacity(0.2),
              radius: AppTheme.radiusMedium,
            ),
            child: Wrap(
              spacing: AppTheme.space16,
              runSpacing: AppTheme.space16,
              alignment: WrapAlignment.start,
              children: players.map((p) => _buildPlayerItem(p, primaryColor, textMuted)).toList(),
            ),
          ),

          if (players.length <= 1) ...[
            const SizedBox(height: AppTheme.space12),
            Center(
              child: Text(
                'Share the room code with friends to join!',
                style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.space24),

          // Config / Settings Panel
          if (isHost) ...[
            Text(
              'ROOM SETTINGS (HOST ONLY)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            _buildDropdown<String>(
              label: 'Category',
              value: category,
              items: _categories,
              itemLabel: (c) => c == 'all' ? 'Mixed Categories' : c,
              onChanged: (val) {
                if (val != null) {
                  socketProvider.emitUpdateSettings({'category': val});
                }
              },
              textColor: textColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppTheme.space8),
            _buildDropdown<String>(
              label: 'Difficulty',
              value: difficulty,
              items: _difficulties,
              itemLabel: (d) => d == 'all' ? 'Mixed Difficulties' : d.toUpperCase(),
              onChanged: (val) {
                if (val != null) {
                  socketProvider.emitUpdateSettings({'difficulty': val});
                }
              },
              textColor: textColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppTheme.space8),
            _buildDropdown<int>(
              label: 'Time Limit',
              value: duration,
              items: _durations,
              itemLabel: (d) => '$d seconds',
              onChanged: (val) {
                if (val != null) {
                  socketProvider.emitUpdateSettings({'duration': val});
                }
              },
              textColor: textColor,
              borderColor: borderColor,
            ),
          ] else ...[
            // Read-only settings banner for guest players
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GAME CONFIGURATION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Category: ${category == 'all' ? 'Mixed' : category}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Difficulty: ${difficulty == 'all' ? 'Mixed' : difficulty.toUpperCase()}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Time Limit: $duration seconds',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.space24),

          // Action Buttons: Ready toggle for guest, Start Game for host
          if (isHost) ...[
            Container(
              height: 56,
              decoration: AppTheme.gameCardDecoration(
                color: canStart ? primaryColor : primaryColor.withOpacity(0.4),
                borderColor: borderColor,
                shadowColor: borderColor,
                radius: AppTheme.radiusMedium,
              ),
              child: ElevatedButton(
                onPressed: canStart ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  players.length < 2
                      ? 'Need at least 2 players'
                      : (!allReady ? 'Waiting for players to ready up...' : 'Start Game'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ] else if (!isSpectator) ...[
            Container(
              height: 56,
              decoration: AppTheme.gameCardDecoration(
                color: isMyReady ? AppTheme.accentCoral : AppTheme.accentLight,
                borderColor: borderColor,
                shadowColor: borderColor,
                radius: AppTheme.radiusMedium,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  socketProvider.emitToggleReady(uid: myUid);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                icon: Icon(
                  isMyReady ? LucideIcons.x : LucideIcons.check,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  isMyReady ? 'Not Ready' : 'Ready Up',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ] else ...[
            // Spectator waiting panel
            Center(
              child: Text(
                'Spectating Lobby · Game is in progress',
                style: TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerItem(Map<String, dynamic> player, Color primaryColor, Color textMuted) {
    final isHost = player['isHost'] == true;
    final isOnline = player['isOnline'] != false;
    final isSpectator = player['isSpectator'] == true;
    final isReady = player['isReady'] == true;

    String statusText = 'Not Ready';
    Color statusColor = AppTheme.accentCoral;

    if (!isOnline) {
      statusText = 'Offline';
      statusColor = Colors.grey;
    } else if (isSpectator) {
      statusText = 'Spectator';
      statusColor = Colors.blue;
    } else if (isHost) {
      statusText = 'Host';
      statusColor = AppTheme.accentYellow;
    } else if (isReady) {
      statusText = 'Ready';
      statusColor = AppTheme.accentLight;
    }

    return Opacity(
      opacity: isOnline ? 1.0 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              PlayerAvatar(
                size: 46,
                displayName: player['displayName'] ?? 'Player',
              ),
              if (isHost)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.crown, size: 8, color: Colors.white),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            player['displayName'] ?? 'Player',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
