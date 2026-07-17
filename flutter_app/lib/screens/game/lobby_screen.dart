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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _roomCode.isEmpty) {
      _roomCode = args;
    }
  }

  void _handleSendMessage(String msg) {
    final auth = context.read<AuthProvider>();
    setState(() {
      _chatMessages.add({
        'type': 'message',
        'displayName': auth.displayName,
        'message': msg,
      });
    });
  }

  void _handleSendReaction(String emoji) {
    final auth = context.read<AuthProvider>();
    setState(() {
      _chatMessages.add({
        'type': 'reaction',
        'displayName': auth.displayName,
        'emoji': emoji,
      });
    });
  }

  void _startGame() {
    Navigator.pushReplacementNamed(context, '/drawing');
  }

  void _leaveRoom() {
    context.read<SocketProvider>().leaveRoom();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final socketProvider = context.watch<SocketProvider>();
    final players = socketProvider.roomPlayers;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final roomCode = socketProvider.roomCode ?? _roomCode;
    final canStart = players.length >= 2;

    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft),
          onPressed: _leaveRoom,
        ),
        title: const Text('Waiting Room'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildMainPanel(roomCode, players, canStart, cardBg, borderColor, primaryColor, textMuted),
                    ),
                    const SizedBox(width: 24),
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
                    _buildMainPanel(roomCode, players, canStart, cardBg, borderColor, primaryColor, textMuted),
                    const SizedBox(height: 24),
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
    );
  }

  Widget _buildMainPanel(
    String roomCode,
    List<Map<String, dynamic>> players,
    bool canStart,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Code copy block
          Center(
            child: Column(
              children: [
                Text(
                  'ROOM CODE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room code copied to clipboard!')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          roomCode,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.copy, size: 18, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Player list count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Players (${players.length}/8)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Player avatars grid list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: players.map((p) => _buildPlayerItem(p, primaryColor, textMuted)).toList(),
            ),
          ),

          if (players.length <= 1) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Share room code with friends to start drawing!',
                style: TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Game Rules Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Game Settings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '60 Seconds • Normal Difficulty • Gemini AI Judging',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start Button
          ElevatedButton.icon(
            onPressed: canStart ? _startGame : null,
            icon: Icon(LucideIcons.play, color: Colors.white, size: 20),
            label: Text(canStart ? 'Start Game' : 'Waiting for Players...'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: primaryColor,
              disabledBackgroundColor: primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(Map<String, dynamic> player, Color primaryColor, Color textMuted) {
    final isHost = player['isHost'] == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            PlayerAvatar(
              size: 52,
              displayName: player['displayName'] ?? 'Player',
            ),
            if (isHost)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.crown, size: 10, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          player['displayName'] ?? 'Player',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          isHost ? 'Host' : 'Ready',
          style: TextStyle(fontSize: 11, color: isHost ? Colors.orangeAccent : textMuted),
        ),
      ],
    );
  }
}
