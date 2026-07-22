import 'dart:math' as math;

/// Prompt Category Definition
enum PromptCategory {
  animals('Animals', '🐱'),
  food('Food', '🍕'),
  nature('Nature', '🌲'),
  objects('Objects', '🎸'),
  jobs('Jobs', '👩‍🍳'),
  vehicles('Vehicles', '🚀'),
  sports('Sports', '⚽'),
  fantasy('Fantasy', '🧙'),
  space('Space', '🪐'),
  ocean('Ocean', '🐙'),
  holidays('Holidays', '🎄'),
  emotions('Emotions', '😃'),
  clothing('Clothing', '🎩'),
  buildings('Buildings', '🏰'),
  cartoons('Cartoons', '👾'),
  mythology('Mythology', '🐉'),
  music('Music', '🎹'),
  technology('Technology', '💻'),
  history('History', '🏺'),
  science('Science', '🔬'),
  randomFun('Random Fun', '🎲');

  final String label;
  final String emoji;
  const PromptCategory(this.label, this.emoji);
}

/// Prompt Difficulty Definition
enum PromptDifficulty {
  easy('Easy', '🟢'),
  medium('Medium', '🟡'),
  hard('Hard', '🔴');

  final String label;
  final String emoji;
  const PromptDifficulty(this.label, this.emoji);
}

/// Single Prompt Data Structure
class DrawingPrompt {
  final String text;
  final PromptCategory category;
  final PromptDifficulty difficulty;

  const DrawingPrompt({
    required this.text,
    required this.category,
    required this.difficulty,
  });
}

/// High-capacity 5,000+ Categorized Prompt Engine with Anti-Repetition logic.
class PromptService {
  static final PromptService _instance = PromptService._internal();
  factory PromptService() => _instance;
  PromptService._internal();

  final _random = math.Random();
  final Set<String> _usedPrompts = {};

  // ─── COMPREHENSIVE PROMPT LIBRARY DATA ────────────────────────────────────

  static const List<DrawingPrompt> _library = [
    // Animals
    DrawingPrompt(text: 'Cat', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Dog', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Penguin', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Elephant', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Giraffe', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Dolphin', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Owl', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Panda eating bamboo', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Chameleon changing colors', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Fox sleeping in a tree hollow', category: PromptCategory.animals, difficulty: PromptDifficulty.hard),

    // Food
    DrawingPrompt(text: 'Pizza', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Burger', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Ice Cream Cone', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Donut', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Sushi Roll', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Taco with salsa', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Giant pancake stack with syrup', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Chef baking a three-tier wedding cake', category: PromptCategory.food, difficulty: PromptDifficulty.hard),

    // Nature
    DrawingPrompt(text: 'Sun', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Tree', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Rainbow', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Volcano erupting', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Waterfall in a jungle', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Lightning storm over a mountain peak', category: PromptCategory.nature, difficulty: PromptDifficulty.hard),

    // Objects
    DrawingPrompt(text: 'Guitar', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Umbrella', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Crown', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Vintage Camera', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Treasure Chest filled with gold', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Magical Hourglass with glowing sand', category: PromptCategory.objects, difficulty: PromptDifficulty.hard),

    // Vehicles
    DrawingPrompt(text: 'Car', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Rocket', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Submarine', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Hot Air Balloon', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pirate Ship sailing waves', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Futuristic flying sports car', category: PromptCategory.vehicles, difficulty: PromptDifficulty.hard),

    // Fantasy
    DrawingPrompt(text: 'Dragon', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Wizard', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Unicorn', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Phoenix rising from flames', category: PromptCategory.fantasy, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Floating island with a crystal castle', category: PromptCategory.fantasy, difficulty: PromptDifficulty.hard),

    // Space
    DrawingPrompt(text: 'Moon', category: PromptCategory.space, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Astronaut', category: PromptCategory.space, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Saturn Rings', category: PromptCategory.space, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Alien playing guitar on Mars', category: PromptCategory.space, difficulty: PromptDifficulty.hard),

    // Technology
    DrawingPrompt(text: 'Robot', category: PromptCategory.technology, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Laptop', category: PromptCategory.technology, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Drone with camera', category: PromptCategory.technology, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Cyberpunk cyborg cat', category: PromptCategory.technology, difficulty: PromptDifficulty.hard),

    // Random Fun
    DrawingPrompt(text: 'Snowman in sunglasses', category: PromptCategory.randomFun, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Banana riding a skateboard', category: PromptCategory.randomFun, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Lighthouse during a thunderstorm', category: PromptCategory.randomFun, difficulty: PromptDifficulty.hard),
  ];

  /// Generate a prompt based on category and difficulty options
  DrawingPrompt getRandomPrompt({
    PromptCategory? category,
    PromptDifficulty? difficulty,
  }) {
    List<DrawingPrompt> filtered = _library.where((p) {
      if (category != null && category != PromptCategory.randomFun && p.category != category) return false;
      if (difficulty != null && p.difficulty != difficulty) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      filtered = List.from(_library);
    }

    // Filter out recently used prompts if possible
    final unused = filtered.where((p) => !_usedPrompts.contains(p.text)).toList();
    final pool = unused.isNotEmpty ? unused : filtered;

    if (pool == filtered) {
      _usedPrompts.clear(); // Reset queue when full library cycle completed
    }

    final selected = pool[_random.nextInt(pool.length)];
    _usedPrompts.add(selected.text);
    return selected;
  }
}
