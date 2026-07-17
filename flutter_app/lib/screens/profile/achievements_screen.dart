import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<dynamic> _badges = [];
  bool _isLoading = true;
  int _unlockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService(auth);
      final data = await api.getMyBadges();
      
      setState(() {
        _badges = data['badges'];
        _unlockedCount = data['unlocked'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Achievements'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_unlockedCount / ${_badges.length} Unlocked',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    LinearProgressIndicator(
                      value: _badges.isEmpty ? 0 : _unlockedCount / _badges.length,
                      backgroundColor: Colors.white12,
                      color: AppTheme.accentGold,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (context, index) {
                    final badge = _badges[index];
                    final bool isUnlocked = badge['unlocked'];
                    
                    return _buildBadgeCard(badge, isUnlocked);
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, bool isUnlocked) {
    // Determine color by tier
    Color tierColor = Colors.grey;
    if (isUnlocked) {
      switch (badge['tier']) {
        case 'bronze': tierColor = Colors.orangeAccent.shade400; break;
        case 'silver': tierColor = Colors.grey.shade300; break;
        case 'gold': tierColor = AppTheme.accentGold; break;
        case 'platinum': tierColor = Colors.cyanAccent; break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? tierColor.withOpacity(0.5) : Colors.white12,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnlocked ? Icons.stars_rounded : Icons.lock_rounded,
            size: 40,
            color: isUnlocked ? tierColor : Colors.white24,
          ),
          const SizedBox(height: 8),
          Text(
            badge['name'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.white : Colors.white54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge['description'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Colors.white38),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
