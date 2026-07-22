import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final int cost;
  final String iconName;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.cost,
    required this.iconName,
  });
}

/// State Provider for Player Progression, XP, Level, Titles & Match Rewards.
/// Persists data by Username in SharedPreferences so returning users keep their stats!
class ProgressionProvider extends ChangeNotifier {
  final AudioService _audio = AudioService();

  String _currentUsername = 'Player';
  int _level = 1;
  int _xp = 0;
  int _coins = 250;
  int _wins = 0;
  int _gamesPlayed = 0;
  bool _dailyRewardClaimed = false;

  final List<String> _unlockedBrushes = [
    'pencil', 'marker', 'watercolor', 'oilBrush', 'spray', 'chalk', 'calligraphy', 'crayon', 'pen', 'airbrush'
  ];

  static const List<ShopItem> shopCatalog = [
    ShopItem(id: 'oilBrush', name: 'Oil Brush', description: 'Impasto paint strokes', category: 'brush', cost: 150, iconName: 'brush'),
    ShopItem(id: 'chalk', name: 'Chalk', description: 'Dusty grain texture', category: 'brush', cost: 200, iconName: 'brush'),
  ];

  // Getters
  String get currentUsername => _currentUsername;
  int get level => _level;
  int get xp => _xp;
  int get coins => _coins;
  int get wins => _wins;
  int get gamesPlayed => _gamesPlayed;
  bool get dailyRewardClaimed => _dailyRewardClaimed;
  List<String> get unlockedBrushes => List.unmodifiable(_unlockedBrushes);

  int get xpForNextLevel => _level * 250;
  double get levelProgress => (_xp % 250) / 250.0;

  String get playerTitle {
    if (_level >= 10) return '👑 Canvas Legend';
    if (_level >= 7) return '🧙 Color Wizard';
    if (_level >= 5) return '🎨 Master Painter';
    if (_level >= 3) return '⚡ Doodle Pro';
    return '✏️ Sketch Rookie';
  }

  /// Load user data when username is set or logged in
  Future<void> loadProfileForUsername(String username) async {
    if (username.trim().isEmpty) return;
    _currentUsername = username.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keyPrefix = 'user_profile_${_currentUsername.toLowerCase()}';
      _level = prefs.getInt('${keyPrefix}_level') ?? 1;
      _xp = prefs.getInt('${keyPrefix}_xp') ?? 0;
      _coins = prefs.getInt('${keyPrefix}_coins') ?? 250;
      _wins = prefs.getInt('${keyPrefix}_wins') ?? 0;
      _gamesPlayed = prefs.getInt('${keyPrefix}_games') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[ProgressionProvider] Error loading profile: $e');
    }
  }

  /// Save user profile to persistent storage
  Future<void> _saveProfile() async {
    if (_currentUsername.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyPrefix = 'user_profile_${_currentUsername.toLowerCase()}';
      await prefs.setInt('${keyPrefix}_level', _level);
      await prefs.setInt('${keyPrefix}_xp', _xp);
      await prefs.setInt('${keyPrefix}_coins', _coins);
      await prefs.setInt('${keyPrefix}_wins', _wins);
      await prefs.setInt('${keyPrefix}_games', _gamesPlayed);
    } catch (e) {
      debugPrint('[ProgressionProvider] Error saving profile: $e');
    }
  }

  bool claimDailyReward() {
    if (_dailyRewardClaimed) return false;
    _dailyRewardClaimed = true;
    addCoins(100);
    addXp(150);
    return true;
  }

  bool isUnlocked(String itemId) => true;

  bool purchaseItem(ShopItem item) {
    if (_coins < item.cost) return false;
    _coins -= item.cost;
    notifyListeners();
    _saveProfile();
    return true;
  }

  /// Award XP & Coins after a match
  void awardMatchRewards({required int score, required bool isWin}) {
    _gamesPlayed++;
    if (isWin) _wins++;

    final xpEarned = score * 2 + (isWin ? 100 : 30);
    final coinsEarned = (score / 2).round() + (isWin ? 50 : 15);

    addXp(xpEarned);
    addCoins(coinsEarned);
    _saveProfile();
  }

  void addXp(int amount) {
    _xp += amount;
    final newLevel = (_xp / 250).floor() + 1;
    if (newLevel > _level) {
      _level = newLevel;
      _audio.playVictory();
    }
    notifyListeners();
    _saveProfile();
  }

  void addCoins(int amount) {
    _coins += amount;
    _audio.playReward();
    notifyListeners();
    _saveProfile();
  }
}
