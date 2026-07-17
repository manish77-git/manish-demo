import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  Map<String, dynamic>? _challenge;
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService(auth);
      
      final challenge = await api.getDailyChallenge();
      final leaderboard = await api.getDailyLeaderboard();

      setState(() {
        _challenge = challenge;
        _leaderboard = leaderboard;
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
        title: const Text('Daily Challenge'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challenge == null
              ? const Center(child: Text('No challenge today', style: TextStyle(color: Colors.white)))
              : Column(
                  children: [
                    _buildChallengeCard(),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Daily Leaderboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: _buildLeaderboard()),
                  ],
                ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('TODAY\'S PROMPT', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            _challenge!['prompt'].toString().toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Chip(
                label: Text(_challenge!['difficulty']),
                backgroundColor: Colors.white24,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${_challenge!['drawingTimeSeconds']}s'),
                backgroundColor: Colors.white24,
                labelStyle: const TextStyle(color: Colors.white),
                avatar: const Icon(Icons.timer, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to drawing screen in daily mode
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.accentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Play Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) {
      return const Center(child: Text('Be the first to play today!', style: TextStyle(color: Colors.white54)));
    }
    
    return ListView.builder(
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.cardDark,
            child: Text('#${index + 1}', style: const TextStyle(color: Colors.white)),
          ),
          title: Text(entry['displayName'] ?? 'Player', style: const TextStyle(color: Colors.white)),
          trailing: Text('${entry['score']} pts', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }
}
