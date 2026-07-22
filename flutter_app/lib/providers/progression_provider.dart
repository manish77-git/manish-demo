import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';

/// Item in the Shop
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String category; // 'brush', 'theme', 'avatar'
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

/// Daily Mission Model
class DailyMission {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final int rewardXp;
  final int targetCount;
  int currentCount;
  bool isClaimed;

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.rewardXp,
    required this.targetCount,
    this.currentCount = 0,
    this.isClaimed = false,
  });

  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
  bool get isCompleted => currentCount >= targetCount;
}

/// State Provider for Player Progression, XP, Coins, Missions & Shop Unlocks.
class ProgressionProvider extends ChangeNotifier {
  final AudioService _audio = AudioService();

  int _level = 1;
  int _xp = 0;
  int _coins = 250;
  bool _dailyRewardClaimed = false;

  final List<String> _unlockedBrushes = ['pencil', 'paintbrush', 'marker', 'eraser'];
  final List<String> _unlockedThemes = ['classic', 'sketchpad'];
  final List<String> _unlockedAvatars = ['mascot_1', 'mascot_2'];

  // Missions
  final List<DailyMission> _missions = [
    DailyMission(
      id: 'm1',
      title: 'Quick Draw',
      description: 'Complete 2 drawing duels',
      rewardCoins: 50,
      rewardXp: 100,
      targetCount: 2,
    ),
    DailyMission(
      id: 'm2',
      title: 'High Scorer',
      description: 'Score over 80 points in any match',
      rewardCoins: 80,
      rewardXp: 150,
      targetCount: 1,
    ),
    DailyMission(
      id: 'm3',
      title: 'Daily Master',
      description: 'Participate in the Daily Challenge',
      rewardCoins: 100,
      rewardXp: 200,
      targetCount: 1,
    ),
  ];

  // Shop Catalog
  static const List<ShopItem> shopCatalog = [
    ShopItem(
      id: 'airbrush',
      name: 'Airbrush',
      description: 'Soft radial spray wash brush effect',
      category: 'brush',
      cost: 150,
      iconName: 'spray',
    ),
    ShopItem(
      id: 'pixel',
      name: 'Pixel Brush',
      description: 'Retro 8-bit grid aligned block brush',
      category: 'brush',
      cost: 200,
      iconName: 'grid',
    ),
    ShopItem(
      id: 'watercolor',
      name: 'Watercolor',
      description: 'Layered translucent wet bleed wash',
      category: 'brush',
      cost: 250,
      iconName: 'droplet',
    ),
    ShopItem(
      id: 'calligraphy',
      name: 'Calligraphy Nib',
      description: '45-degree angled stroke nib',
      category: 'brush',
      cost: 300,
      iconName: 'pen-tool',
    ),
    ShopItem(
      id: 'neon',
      name: 'Neon Glow',
      description: 'Vibrant intense glowing outer shadow line',
      category: 'brush',
      cost: 400,
      iconName: 'sparkles',
    ),
    ShopItem(
      id: 'theme_cyber',
      name: 'Cyberpunk Theme',
      description: 'Futuristic neon dark aesthetic',
      category: 'theme',
      cost: 350,
      iconName: 'palette',
    ),
    ShopItem(
      id: 'theme_retro',
      name: 'Retro Arcade Theme',
      description: 'Vintage 80s arcade vibe',
      category: 'theme',
      cost: 350,
      iconName: 'gamepad-2',
    ),
  ];

  // Getters
  int get level => _level;
  int get xp => _xp;
  int get coins => _coins;
  bool get dailyRewardClaimed => _dailyRewardClaimed;
  List<String> get unlockedBrushes => List.unmodifiable(_unlockedBrushes);
  List<String> get unlockedThemes => List.unmodifiable(_unlockedThemes);
  List<String> get unlockedAvatars => List.unmodifiable(_unlockedAvatars);
  List<DailyMission> get missions => List.unmodifiable(_missions);

  int get xpForNextLevel => _level * 250;
  double get levelProgress => (_xp % 250) / 250.0;

  /// Award XP & Coins after a match
  void awardMatchRewards({required int score, required bool isWin}) {
    final xpEarned = score * 2 + (isWin ? 100 : 30);
    final coinsEarned = (score / 2).round() + (isWin ? 50 : 15);

    addXp(xpEarned);
    addCoins(coinsEarned);

    // Update mission counts
    updateMissionProgress('m1', 1);
    if (score >= 80) {
      updateMissionProgress('m2', 1);
    }
  }

  void addXp(int amount) {
    _xp += amount;
    final newLevel = (_xp / 250).floor() + 1;
    if (newLevel > _level) {
      _level = newLevel;
      _audio.playVictory();
    }
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins += amount;
    _audio.playReward();
    notifyListeners();
  }

  /// Claim Daily Login Reward
  bool claimDailyReward() {
    if (_dailyRewardClaimed) return false;

    _dailyRewardClaimed = true;
    addCoins(100);
    addXp(150);
    return true;
  }

  /// Update Mission Progress
  void updateMissionProgress(String missionId, int delta) {
    final index = _missions.indexWhere((m) => m.id == missionId);
    if (index != -1) {
      _missions[index].currentCount += delta;
      notifyListeners();
    }
  }

  /// Claim Completed Mission Reward
  bool claimMissionReward(String missionId) {
    final index = _missions.indexWhere((m) => m.id == missionId);
    if (index != -1) {
      final mission = _missions[index];
      if (mission.isCompleted && !mission.isClaimed) {
        mission.isClaimed = true;
        addCoins(mission.rewardCoins);
        addXp(mission.rewardXp);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Purchase an Item from the Shop
  bool purchaseItem(ShopItem item) {
    if (_coins < item.cost) return false;

    if (item.category == 'brush' && _unlockedBrushes.contains(item.id)) return false;
    if (item.category == 'theme' && _unlockedThemes.contains(item.id)) return false;

    _coins -= item.cost;
    if (item.category == 'brush') {
      _unlockedBrushes.add(item.id);
    } else if (item.category == 'theme') {
      _unlockedThemes.add(item.id);
    }

    _audio.playReward();
    notifyListeners();
    return true;
  }

  bool isUnlocked(String itemId) {
    return _unlockedBrushes.contains(itemId) ||
        _unlockedThemes.contains(itemId) ||
        _unlockedAvatars.contains(itemId);
  }
}
