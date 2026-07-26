import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/socket_provider.dart';
import '../../widgets/doodle_painter.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/mascot_painter.dart';
import '../../widgets/player_avatar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addUsernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.idToken.isNotEmpty) {
        context.read<FriendsProvider>().fetchFriendsAndRequests(auth.idToken);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _addUsernameController.dispose();
    super.dispose();
  }

  void _sendFriendRequest(String target) async {
    if (target.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final friendsProvider = context.read<FriendsProvider>();

    final success = await friendsProvider.sendRequest(auth.idToken, target.trim());
    if (mounted) {
      if (success) {
        _addUsernameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!'), backgroundColor: AppColors.mint),
        );
      } else if (friendsProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendsProvider.error!), backgroundColor: AppColors.coral),
        );
      }
    }
  }

  void _inviteFriend(String friendUid) {
    final socket = context.read<SocketProvider>();
    final auth = context.read<AuthProvider>();
    final roomCode = socket.roomCode ?? 'ROOM123';

    socket.inviteFriendToRoom(
      friendUid: friendUid,
      hostName: auth.displayName,
      roomCode: roomCode,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game invite sent to friend!'), backgroundColor: AppColors.mint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final auth = context.watch<AuthProvider>();
    final friendsProvider = context.watch<FriendsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Social'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: textMuted,
          tabs: [
            Tab(text: 'Friends (${friendsProvider.friends.length})'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  if (friendsProvider.pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${friendsProvider.pendingCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Find Players'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedDoodleBackground()),
          TabBarView(
            controller: _tabController,
            children: [
              // ─── TAB 1: FRIENDS LIST ────────────────────────────────────────
              _buildFriendsListTab(auth, friendsProvider, cardBg, borderColor, textColor, textMuted, primaryColor),

              // ─── TAB 2: PENDING REQUESTS ────────────────────────────────────
              _buildRequestsTab(auth, friendsProvider, cardBg, borderColor, textColor, textMuted, primaryColor),

              // ─── TAB 3: USER SEARCH ─────────────────────────────────────────
              _buildSearchTab(auth, friendsProvider, cardBg, borderColor, textColor, textMuted, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsListTab(
    AuthProvider auth,
    FriendsProvider friendsProvider,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
  ) {
    if (friendsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendsProvider.friends.isEmpty) {
      return const EmptyStateWidget(
        title: 'No friends yet',
        message: 'Search for players by username in the Find Players tab\nto build your friends list!',
        showMascot: true,
        mascotExpression: InkyExpression.waving,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space16),
      itemCount: friendsProvider.friends.length,
      itemBuilder: (context, index) {
        final friend = friendsProvider.friends[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.space12),
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: AppTheme.gameCard(context),
          child: Row(
            children: [
              Stack(
                children: [
                  PlayerAvatar(displayName: friend.displayName, photoUrl: friend.photoUrl, size: 46),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: friend.isOnline ? AppColors.mint : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '@${friend.username}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () => _inviteFriend(friend.uid),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                tooltip: 'Invite to Room',
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  foregroundColor: primaryColor,
                ),
              ),

              IconButton(
                onPressed: () => friendsProvider.removeFriend(auth.idToken, friend.uid),
                icon: const Icon(LucideIcons.userMinus, size: 18),
                tooltip: 'Remove Friend',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.coral.withValues(alpha: 0.1),
                  foregroundColor: AppColors.coral,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(
    AuthProvider auth,
    FriendsProvider friendsProvider,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
  ) {
    if (friendsProvider.incomingRequests.isEmpty) {
      return const EmptyStateWidget(
        title: 'No pending requests',
        message: 'When someone sends you a friend request,\nit will show up right here!',
        showMascot: true,
        mascotExpression: InkyExpression.happy,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.space16),
      itemCount: friendsProvider.incomingRequests.length,
      itemBuilder: (context, index) {
        final req = friendsProvider.incomingRequests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.space12),
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: AppTheme.gameCard(context),
          child: Row(
            children: [
              PlayerAvatar(displayName: req.fromDisplayName, size: 44),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.fromDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('@${req.fromUsername}', style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => friendsProvider.acceptRequest(auth.idToken, req.fromUid),
                icon: const Icon(LucideIcons.check, size: 18),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => friendsProvider.declineRequest(auth.idToken, req.fromUid),
                icon: const Icon(LucideIcons.x, size: 18),
                style: IconButton.styleFrom(backgroundColor: AppColors.coral.withValues(alpha: 0.15), foregroundColor: AppColors.coral),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchTab(
    AuthProvider auth,
    FriendsProvider friendsProvider,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: AppTheme.gameCard(context),
            child: Row(
              children: [
                Icon(LucideIcons.search, color: textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search username or display name...',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => friendsProvider.search(auth.idToken, val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          Expanded(
            child: friendsProvider.isSearching
                ? const Center(child: CircularProgressIndicator())
                : friendsProvider.searchResults.isEmpty
                    ? const EmptyStateWidget(
                        title: 'Search DrawBattle Players',
                        message: 'Type a username above to find other artists.',
                        showMascot: true,
                        mascotExpression: InkyExpression.thinking,
                      )
                    : ListView.builder(
                        itemCount: friendsProvider.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = friendsProvider.searchResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppTheme.space12),
                            padding: const EdgeInsets.all(AppTheme.space12),
                            decoration: AppTheme.gameCard(context),
                            child: Row(
                              children: [
                                PlayerAvatar(displayName: user.displayName, photoUrl: user.photoUrl, size: 44),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('@${user.username}', style: TextStyle(fontSize: 12, color: textMuted)),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _sendFriendRequest(user.username),
                                  icon: const Icon(LucideIcons.userPlus, size: 14),
                                  label: const Text('Add Friend', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
