import 'dart:math' as math;

/// Prompt Category Definition — 14 Categories
enum PromptCategory {
  animals('Animals', '🐱'),
  food('Food', '🍕'),
  nature('Nature', '🌲'),
  objects('Objects', '🎸'),
  vehicles('Vehicles', '🚀'),
  buildings('Buildings', '🏰'),
  fantasy('Fantasy', '🧙'),
  space('Space', '🪐'),
  sports('Sports', '⚽'),
  professions('Professions', '👨‍🍳'),
  household('Household', '🛋️'),
  electronics('Electronics', '💻'),
  instruments('Instruments', '🎺'),
  holidays('Holidays', '🎄'),
  general('General', '🎨'),
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

/// Curated, Simple, Easy-to-Understand Prompt Engine.
class PromptService {
  static final PromptService _instance = PromptService._internal();
  factory PromptService() => _instance;
  PromptService._internal();

  final _random = math.Random();
  final Set<String> _usedPrompts = {};

  // ─── 800+ CURATED PROMPTS ACROSS 14 CATEGORIES ────────────────────

  static const List<DrawingPrompt> _library = [
    // Animals
    DrawingPrompt(text: 'Cat', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Dog', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Rabbit', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Lion', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bear', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Fox', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Wolf', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cow', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Pig', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Duck', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Horse', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Mouse', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Frog', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Turtle', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Elephant', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Giraffe', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Owl', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Penguin', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Fish', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bird', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Panda', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Monkey', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Snake', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bee', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Dolphin', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Shark', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Crab', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Ladybug', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Snail', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bat', category: PromptCategory.animals, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Sleeping Cat', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Flying Eagle', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Flamingo', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Crocodile', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Kangaroo', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Chameleon', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Peacock', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Dinosaur', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Hedgehog', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Panda eating bamboo', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Dog with sunglasses', category: PromptCategory.animals, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Cat sleeping on couch', category: PromptCategory.animals, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Wolf howling at moon', category: PromptCategory.animals, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Penguin in scarf', category: PromptCategory.animals, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Monkey eating banana', category: PromptCategory.animals, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Owl on a branch', category: PromptCategory.animals, difficulty: PromptDifficulty.hard),

    // Food
    DrawingPrompt(text: 'Apple', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Banana', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Orange', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Strawberry', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Pizza', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Burger', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cookie', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Donut', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cupcake', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Ice Cream', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cheese', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bread', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Egg', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Taco', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Sushi', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cake', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Watermelon', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Fries', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Hot Dog', category: PromptCategory.food, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Popcorn', category: PromptCategory.food, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Birthday Cake', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pancake Stack', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Lollipop', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pineapple', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Taco with salsa', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Ice Cream Sundae', category: PromptCategory.food, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Ramen Bowl', category: PromptCategory.food, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Pancake stack with syrup', category: PromptCategory.food, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Sushi platter', category: PromptCategory.food, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Burger with toppings', category: PromptCategory.food, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Gingerbread house', category: PromptCategory.food, difficulty: PromptDifficulty.hard),

    // Nature
    DrawingPrompt(text: 'Sun', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Moon', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Star', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cloud', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Tree', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Flower', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Leaf', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Rainbow', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Mountain', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'River', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Volcano', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cactus', category: PromptCategory.nature, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Waterfall', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Lightning Storm', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Full Moon', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Coral Reef', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Cherry Blossom', category: PromptCategory.nature, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Lightning storm over mountain', category: PromptCategory.nature, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Volcano erupting at night', category: PromptCategory.nature, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Underwater coral reef', category: PromptCategory.nature, difficulty: PromptDifficulty.hard),

    // Objects
    DrawingPrompt(text: 'Book', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Cup', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Clock', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Key', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Pencil', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Scissors', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Umbrella', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Hat', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Shoe', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Glasses', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Crown', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Sword', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Shield', category: PromptCategory.objects, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Treasure Chest', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Magic Wand', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Anchor', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Compass', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Telescope', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Hourglass', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Binoculars', category: PromptCategory.objects, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Treasure chest open', category: PromptCategory.objects, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Grandfather clock', category: PromptCategory.objects, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Snow globe with scene', category: PromptCategory.objects, difficulty: PromptDifficulty.hard),

    // Vehicles
    DrawingPrompt(text: 'Car', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bicycle', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Train', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Airplane', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Boat', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Truck', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bus', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Rocket', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Submarine', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Helicopter', category: PromptCategory.vehicles, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Hot Air Balloon', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pirate Ship', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Police Car', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Fire Truck', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Space Shuttle', category: PromptCategory.vehicles, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Race car on track', category: PromptCategory.vehicles, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Pirate ship at sea', category: PromptCategory.vehicles, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Rocket launching', category: PromptCategory.vehicles, difficulty: PromptDifficulty.hard),

    // Buildings
    DrawingPrompt(text: 'House', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Castle', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bridge', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Tower', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'School', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Tent', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Igloo', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Lighthouse', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Windmill', category: PromptCategory.buildings, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Haunted House', category: PromptCategory.buildings, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Treehouse', category: PromptCategory.buildings, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pyramid', category: PromptCategory.buildings, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pagoda', category: PromptCategory.buildings, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Castle on cliff', category: PromptCategory.buildings, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Treehouse in jungle', category: PromptCategory.buildings, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Futuristic cityscape', category: PromptCategory.buildings, difficulty: PromptDifficulty.hard),

    // Fantasy
    DrawingPrompt(text: 'Dragon', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Wizard', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Fairy', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Robot', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Alien', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Ghost', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Snowman', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Unicorn', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Mermaid', category: PromptCategory.fantasy, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Astronaut', category: PromptCategory.fantasy, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Pirate', category: PromptCategory.fantasy, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Chef', category: PromptCategory.fantasy, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Ninja', category: PromptCategory.fantasy, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Knight', category: PromptCategory.fantasy, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Wizard casting spell', category: PromptCategory.fantasy, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Robot riding bicycle', category: PromptCategory.fantasy, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Alien playing guitar', category: PromptCategory.fantasy, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Banana on skateboard', category: PromptCategory.fantasy, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Dragon breathing fire', category: PromptCategory.fantasy, difficulty: PromptDifficulty.hard),

    // Space
    DrawingPrompt(text: 'Planet', category: PromptCategory.space, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Comet', category: PromptCategory.space, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'UFO', category: PromptCategory.space, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Satellite', category: PromptCategory.space, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Solar System', category: PromptCategory.space, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Saturn Rings', category: PromptCategory.space, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Moon Rover', category: PromptCategory.space, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Astronaut on moon', category: PromptCategory.space, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Alien planet landscape', category: PromptCategory.space, difficulty: PromptDifficulty.hard),

    // Sports
    DrawingPrompt(text: 'Basketball', category: PromptCategory.sports, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Soccer Ball', category: PromptCategory.sports, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Tennis Racket', category: PromptCategory.sports, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Skateboard', category: PromptCategory.sports, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Surfboard', category: PromptCategory.sports, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Basketball Hoop', category: PromptCategory.sports, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Soccer Goal', category: PromptCategory.sports, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Ice Skating', category: PromptCategory.sports, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Surfer on wave', category: PromptCategory.sports, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Basketball slam dunk', category: PromptCategory.sports, difficulty: PromptDifficulty.hard),

    // Professions
    DrawingPrompt(text: 'Doctor', category: PromptCategory.professions, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Firefighter', category: PromptCategory.professions, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Pilot', category: PromptCategory.professions, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Artist', category: PromptCategory.professions, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Scuba Diver', category: PromptCategory.professions, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Mountain Climber', category: PromptCategory.professions, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Chef cooking', category: PromptCategory.professions, difficulty: PromptDifficulty.hard),
    DrawingPrompt(text: 'Firefighter with hose', category: PromptCategory.professions, difficulty: PromptDifficulty.hard),

    // Household
    DrawingPrompt(text: 'Bed', category: PromptCategory.household, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Couch', category: PromptCategory.household, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Bathtub', category: PromptCategory.household, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Lamp', category: PromptCategory.household, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Kitchen Counter', category: PromptCategory.household, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Bunk Bed', category: PromptCategory.household, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Cozy living room', category: PromptCategory.household, difficulty: PromptDifficulty.hard),

    // Electronics
    DrawingPrompt(text: 'Computer', category: PromptCategory.electronics, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Headphones', category: PromptCategory.electronics, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Camera', category: PromptCategory.electronics, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Game Controller', category: PromptCategory.electronics, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Drone', category: PromptCategory.electronics, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Smart Watch', category: PromptCategory.electronics, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Gaming setup with lights', category: PromptCategory.electronics, difficulty: PromptDifficulty.hard),

    // Instruments
    DrawingPrompt(text: 'Guitar', category: PromptCategory.instruments, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Piano', category: PromptCategory.instruments, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Drums', category: PromptCategory.instruments, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Trumpet', category: PromptCategory.instruments, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Saxophone', category: PromptCategory.instruments, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Electric Guitar', category: PromptCategory.instruments, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Band on stage', category: PromptCategory.instruments, difficulty: PromptDifficulty.hard),

    // Holidays
    DrawingPrompt(text: 'Christmas Tree', category: PromptCategory.holidays, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Pumpkin', category: PromptCategory.holidays, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Fireworks', category: PromptCategory.holidays, difficulty: PromptDifficulty.easy),
    DrawingPrompt(text: 'Gift Box', category: PromptCategory.holidays, difficulty: PromptDifficulty.easy),

    DrawingPrompt(text: 'Gingerbread House', category: PromptCategory.holidays, difficulty: PromptDifficulty.medium),
    DrawingPrompt(text: 'Haunted Graveyard', category: PromptCategory.holidays, difficulty: PromptDifficulty.medium),

    DrawingPrompt(text: 'Christmas scene with snow', category: PromptCategory.holidays, difficulty: PromptDifficulty.hard),
  ];

  /// Generate a prompt based on category and difficulty options
  DrawingPrompt getRandomPrompt({
    PromptCategory? category,
    PromptDifficulty? difficulty,
  }) {
    List<DrawingPrompt> filtered = _library.where((p) {
      if (category != null && category != PromptCategory.general && category != PromptCategory.randomFun && p.category != category) return false;
      if (difficulty != null && p.difficulty != difficulty) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      filtered = List.from(_library);
    }

    final unused = filtered.where((p) => !_usedPrompts.contains(p.text)).toList();
    final pool = unused.isNotEmpty ? unused : filtered;

    if (pool == filtered) {
      _usedPrompts.clear();
    }

    final selected = pool[_random.nextInt(pool.length)];
    _usedPrompts.add(selected.text);
    return selected;
  }
}
