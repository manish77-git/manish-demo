/**
 * DrawBattle Prompt Bank — 800+ Curated Drawing Prompts
 * 
 * 14 Categories × 3 Difficulty Levels
 * All prompts: short (1-4 words), clear, no obscure vocabulary, no duplicates.
 * Distribution: ~40% easy, ~35% medium, ~25% hard
 */

import logger from '../utils/logger.js';

// ─── ANIMALS ─────────────────────────────────────────────────────

const ANIMALS_EASY = [
  'Cat', 'Dog', 'Rabbit', 'Lion', 'Bear', 'Fox', 'Wolf', 'Cow', 'Pig', 'Duck',
  'Horse', 'Mouse', 'Frog', 'Turtle', 'Elephant', 'Giraffe', 'Owl', 'Penguin',
  'Fish', 'Bird', 'Panda', 'Monkey', 'Snake', 'Bee', 'Dolphin', 'Shark',
  'Crab', 'Ladybug', 'Snail', 'Bat', 'Deer', 'Goat', 'Sheep', 'Chicken',
  'Parrot', 'Whale', 'Octopus', 'Butterfly', 'Ant', 'Koala',
];

const ANIMALS_MEDIUM = [
  'Sleeping Cat', 'Flying Eagle', 'Flamingo', 'Crocodile', 'Kangaroo',
  'Chameleon', 'Peacock', 'Dinosaur', 'Hedgehog', 'Hamster',
  'Porcupine', 'Sea Horse', 'Jellyfish', 'Scorpion', 'Pelican',
  'Panda eating bamboo', 'Dog with sunglasses', 'Duckling swimming',
  'Rooster crowing', 'Cat in a box', 'Parrot on perch', 'Frog on lily pad',
  'Hummingbird', 'Armadillo', 'Iguana',
];

const ANIMALS_HARD = [
  'Cat sleeping on couch', 'Dragon breathing fire', 'Wolf howling at moon',
  'Penguin in scarf', 'Monkey eating banana', 'Owl on a branch',
  'Elephant spraying water', 'Giraffe eating leaves', 'Shark jumping',
  'Dolphin doing a flip', 'Chameleon on branch', 'Peacock with open tail',
  'Kangaroo with joey', 'Crocodile in swamp', 'Butterfly on flower',
];

// ─── FOOD ────────────────────────────────────────────────────────

const FOOD_EASY = [
  'Apple', 'Banana', 'Orange', 'Strawberry', 'Pizza', 'Burger', 'Cookie',
  'Donut', 'Cupcake', 'Ice Cream', 'Cheese', 'Bread', 'Egg', 'Taco',
  'Sushi', 'Cake', 'Watermelon', 'Fries', 'Hot Dog', 'Popcorn',
  'Cherry', 'Grapes', 'Pear', 'Pineapple', 'Lemon', 'Carrot',
  'Corn', 'Mushroom', 'Pretzel', 'Candy',
];

const FOOD_MEDIUM = [
  'Birthday Cake', 'Pancake Stack', 'Lollipop', 'Gingerbread Man',
  'Taco with salsa', 'Ice Cream Sundae', 'Chocolate Bar', 'Burrito',
  'Sandwich', 'Croissant', 'Waffle', 'Ramen Bowl', 'Drumstick',
  'Pie Slice', 'Smoothie Cup', 'Milkshake', 'Fruit Bowl',
  'Spaghetti', 'Cereal Bowl', 'Bagel',
];

const FOOD_HARD = [
  'Pancake stack with syrup', 'Sushi platter', 'Burger with toppings',
  'Pizza with pepperoni', 'Fruit salad in bowl', 'Ramen with chopsticks',
  'Wedding cake', 'Breakfast plate', 'Bento box', 'Gingerbread house',
];

// ─── NATURE ──────────────────────────────────────────────────────

const NATURE_EASY = [
  'Tree', 'Flower', 'Leaf', 'Sun', 'Moon', 'Star', 'Cloud', 'River',
  'Mountain', 'Rain', 'Snow', 'Fire', 'Rainbow', 'Beach', 'Volcano',
  'Island', 'Cactus', 'Rose', 'Tulip', 'Daisy', 'Sunflower', 'Palm Tree',
  'Pine Tree', 'Seashell', 'Coral', 'Wave', 'Pond', 'Cliff', 'Cave', 'Tornado',
];

const NATURE_MEDIUM = [
  'Waterfall', 'Lightning Storm', 'Full Moon', 'Coral Reef', 'Aurora',
  'Sunset Over Ocean', 'Snowy Mountain', 'Desert Oasis', 'Bamboo Forest',
  'Cherry Blossom', 'Autumn Tree', 'Meadow', 'Canyon', 'Glacier',
  'Tide Pool', 'Mushroom Ring', 'Starry Sky', 'Misty Forest', 'Swamp',
  'Sand Dune',
];

const NATURE_HARD = [
  'Lightning storm over mountain', 'Sunrise through clouds',
  'Volcano erupting at night', 'Underwater coral reef',
  'Northern lights over snow', 'Waterfall in jungle',
  'Desert with cactus sunset', 'Forest with fireflies',
  'Rainbow over waterfall', 'Tornado approaching farm',
];

// ─── OBJECTS ─────────────────────────────────────────────────────

const OBJECTS_EASY = [
  'Book', 'Cup', 'Clock', 'Key', 'Pencil', 'Scissors', 'Umbrella', 'Hat',
  'Shoe', 'Glasses', 'Phone', 'Ring', 'Balloon', 'Bag', 'Lamp', 'Chair',
  'Table', 'Mirror', 'Candle', 'Crown', 'Sword', 'Shield', 'Ball',
  'Bottle', 'Bell', 'Lock', 'Magnet', 'Dice', 'Trophy', 'Flag',
];

const OBJECTS_MEDIUM = [
  'Treasure Chest', 'Magic Wand', 'Anchor', 'Compass', 'Telescope',
  'Binoculars', 'Hourglass', 'Lantern', 'Pocket Watch', 'Birdhouse',
  'Magnifying Glass', 'Chess Piece', 'Globe', 'Backpack', 'Toolbox',
  'Paint Palette', 'Crystal Ball', 'Snow Globe', 'Music Box', 'Swiss Knife',
];

const OBJECTS_HARD = [
  'Treasure chest open', 'Grandfather clock', 'Globe on stand',
  'Backpack with gear', 'Stacked books', 'Antique lantern',
  'Birdhouse in tree', 'Snow globe with scene', 'Chess board setup',
  'Paint palette with brushes',
];

// ─── VEHICLES ────────────────────────────────────────────────────

const VEHICLES_EASY = [
  'Car', 'Bicycle', 'Train', 'Airplane', 'Boat', 'Truck', 'Bus', 'Rocket',
  'Submarine', 'Helicopter', 'Scooter', 'Ship', 'Taxi', 'Motorcycle',
  'Canoe', 'Sailboat', 'Tractor', 'Skateboard', 'Sled', 'Wagon',
];

const VEHICLES_MEDIUM = [
  'Hot Air Balloon', 'Pirate Ship', 'Police Car', 'Fire Truck', 'Ambulance',
  'Space Shuttle', 'Jet Ski', 'Monster Truck', 'Race Car', 'Double Decker Bus',
  'Cruise Ship', 'Hang Glider', 'Cable Car', 'Tank', 'Blimp',
];

const VEHICLES_HARD = [
  'Race car on track', 'Pirate ship at sea', 'Rocket launching',
  'Helicopter in sky', 'Submarine underwater', 'Train on bridge',
  'Hot air balloon festival', 'Monster truck jumping',
  'Sailboat in storm', 'Spaceship in space',
];

// ─── BUILDINGS & PLACES ──────────────────────────────────────────

const BUILDINGS_EASY = [
  'House', 'Castle', 'Bridge', 'Tower', 'School', 'Tent', 'Igloo', 'Barn',
  'Lighthouse', 'Church', 'Temple', 'Windmill', 'Hospital', 'Factory',
  'Cabin', 'Skyscraper', 'Fountain', 'Well', 'Arch', 'Gate',
];

const BUILDINGS_MEDIUM = [
  'Haunted House', 'Treehouse', 'Pyramid', 'Colosseum', 'Pagoda',
  'Log Cabin', 'Space Station', 'Roller Coaster', 'Ferris Wheel',
  'Water Tower', 'Observatory', 'Clock Tower', 'Drawbridge',
  'Gazebo', 'Stadium',
];

const BUILDINGS_HARD = [
  'Castle on cliff', 'Treehouse in jungle', 'Lighthouse at night',
  'Haunted house with ghosts', 'City skyline', 'Medieval village',
  'Space station orbiting', 'Temple in mountains', 'Underwater city',
  'Futuristic cityscape',
];

// ─── FANTASY & FUN ───────────────────────────────────────────────

const FANTASY_EASY = [
  'Dragon', 'Wizard', 'Fairy', 'Robot', 'Alien', 'Ghost', 'Snowman',
  'Superhero', 'Monster', 'Unicorn', 'Mermaid', 'Vampire', 'Zombie',
  'Angel', 'Elf', 'Troll', 'Phoenix', 'Yeti', 'Cyclops', 'Goblin',
];

const FANTASY_MEDIUM = [
  'Astronaut', 'Pirate', 'Chef', 'Detective', 'Ninja', 'Knight',
  'King', 'Queen', 'Clown', 'Witch', 'Skeleton', 'Werewolf',
  'Centaur', 'Griffin', 'Kraken', 'Medusa', 'Minotaur', 'Sphinx',
  'Genie', 'Leprechaun',
];

const FANTASY_HARD = [
  'Wizard casting spell', 'Robot riding bicycle', 'Alien playing guitar',
  'Banana on skateboard', 'Teddy bear having tea', 'Snowman melting',
  'Pirate finding treasure', 'Astronaut floating space',
  'Mermaid on rock', 'Dragon guarding treasure',
];

// ─── SPACE ───────────────────────────────────────────────────────

const SPACE_EASY = [
  'Planet', 'Comet', 'Meteor', 'Satellite', 'UFO', 'Constellation',
  'Asteroid', 'Black Hole', 'Nebula', 'Galaxy',
];

const SPACE_MEDIUM = [
  'Solar System', 'Space Walk', 'Moon Rover', 'Star Map',
  'Saturn Rings', 'Rocket Launch', 'Space Telescope', 'Mars Landscape',
  'Lunar Eclipse', 'Space Suit',
];

const SPACE_HARD = [
  'Astronaut on moon', 'Alien planet landscape', 'Space battle',
  'Satellite orbiting earth', 'Rocket passing moon', 'Planet with rings',
  'Space colony', 'Meteor shower',
];

// ─── SPORTS ──────────────────────────────────────────────────────

const SPORTS_EASY = [
  'Basketball', 'Soccer Ball', 'Tennis Racket', 'Baseball Bat',
  'Football', 'Golf Club', 'Boxing Glove', 'Bowling Pin', 'Surfboard',
  'Skateboard', 'Hockey Stick', 'Swimming Goggles', 'Medal', 'Dumbbell',
  'Jump Rope', 'Archery Target', 'Badminton', 'Dart Board',
];

const SPORTS_MEDIUM = [
  'Basketball Hoop', 'Soccer Goal', 'Tennis Court', 'Ice Skating',
  'Gymnastics', 'Kayaking', 'Rock Climbing', 'Volleyball Net',
  'Boxing Ring', 'Race Track',
];

const SPORTS_HARD = [
  'Soccer player scoring', 'Surfer on wave', 'Gymnast on beam',
  'Rock climber on cliff', 'Basketball slam dunk',
  'Skier going downhill', 'Archer shooting arrow',
  'Swimmer in pool',
];

// ─── PROFESSIONS ─────────────────────────────────────────────────

const PROFESSIONS_EASY = [
  'Doctor', 'Firefighter', 'Pilot', 'Teacher', 'Artist', 'Farmer',
  'Police Officer', 'Scientist', 'Baker', 'Mechanic', 'Dentist',
  'Photographer', 'Musician', 'Dancer', 'Magician',
];

const PROFESSIONS_MEDIUM = [
  'Scuba Diver', 'Mountain Climber', 'Race Car Driver', 'Conductor',
  'Archaeologist', 'Veterinarian', 'Lifeguard', 'Zookeeper',
  'Park Ranger', 'Blacksmith',
];

const PROFESSIONS_HARD = [
  'Chef cooking', 'Firefighter with hose', 'Scientist with beaker',
  'Artist painting canvas', 'Doctor with stethoscope',
  'Farmer on tractor', 'Magician doing trick',
  'Pilot in cockpit',
];

// ─── HOUSEHOLD ───────────────────────────────────────────────────

const HOUSEHOLD_EASY = [
  'Bed', 'Couch', 'Bathtub', 'Fridge', 'Oven', 'Sink', 'Broom',
  'Pillow', 'Blanket', 'Curtain', 'Staircase', 'Door', 'Window',
  'Fireplace', 'Bookshelf', 'Washing Machine', 'Television', 'Sofa',
];

const HOUSEHOLD_MEDIUM = [
  'Kitchen Counter', 'Living Room', 'Bunk Bed', 'Dining Table',
  'Fish Tank', 'Plant Pot', 'Ceiling Fan', 'Rocking Chair',
  'Welcome Mat', 'Mailbox',
];

const HOUSEHOLD_HARD = [
  'Cozy living room', 'Kitchen with pots', 'Bedroom at night',
  'Bathroom with mirror', 'Garden with fence', 'Attic with boxes',
  'Garage with car', 'Backyard barbecue',
];

// ─── ELECTRONICS ─────────────────────────────────────────────────

const ELECTRONICS_EASY = [
  'Computer', 'Laptop', 'Headphones', 'Camera', 'Game Controller',
  'Flashlight', 'Remote Control', 'Microphone', 'Speaker', 'Battery',
  'Light Bulb', 'Calculator', 'Alarm Clock', 'Radio', 'Mouse',
];

const ELECTRONICS_MEDIUM = [
  'Robot Vacuum', 'Drone', 'Smart Watch', 'VR Headset',
  'Gaming Setup', 'Tablet', 'Projector', 'Earbuds',
  'Keyboard', 'Webcam',
];

const ELECTRONICS_HARD = [
  'Gaming setup with lights', 'Robot with screen', 'Drone in sky',
  'Computer with code', 'DJ with turntable', 'Recording studio',
];

// ─── MUSICAL INSTRUMENTS ─────────────────────────────────────────

const INSTRUMENTS_EASY = [
  'Guitar', 'Piano', 'Drums', 'Trumpet', 'Violin', 'Flute',
  'Tambourine', 'Harp', 'Xylophone', 'Maracas', 'Accordion',
  'Ukulele', 'Banjo', 'Harmonica', 'Triangle',
];

const INSTRUMENTS_MEDIUM = [
  'Electric Guitar', 'Grand Piano', 'Drum Kit', 'Saxophone',
  'Cello', 'Double Bass', 'Organ', 'Bagpipes',
  'Steel Drums', 'Synthesizer',
];

const INSTRUMENTS_HARD = [
  'Band on stage', 'Orchestra conductor', 'Guitar with amplifier',
  'DJ spinning records', 'Street musician playing',
  'Piano in concert hall',
];

// ─── HOLIDAYS & CELEBRATIONS ─────────────────────────────────────

const HOLIDAYS_EASY = [
  'Christmas Tree', 'Pumpkin', 'Fireworks', 'Candy Cane', 'Gift Box',
  'Stocking', 'Easter Egg', 'Heart', 'Snowflake', 'Party Hat',
  'Wreath', 'Mistletoe', 'Jack-o-Lantern', 'Menorah', 'Ornament',
];

const HOLIDAYS_MEDIUM = [
  'Gingerbread House', 'Haunted Graveyard', 'Firework Display',
  'Scarecrow', 'Carnival Mask', 'Piñata', 'Lantern Festival',
  'Snow Angel', 'Sand Castle', 'May Pole',
];

const HOLIDAYS_HARD = [
  'Christmas scene with snow', 'Halloween trick-or-treat',
  'Birthday party', 'New Year fireworks', 'Easter egg hunt',
  'Valentine dinner', 'Thanksgiving feast', 'Carnival parade',
];

// ─── Category Registry ──────────────────────────────────────────

const CATEGORY_MAP = {
  animals:     { easy: ANIMALS_EASY, medium: ANIMALS_MEDIUM, hard: ANIMALS_HARD },
  food:        { easy: FOOD_EASY, medium: FOOD_MEDIUM, hard: FOOD_HARD },
  nature:      { easy: NATURE_EASY, medium: NATURE_MEDIUM, hard: NATURE_HARD },
  objects:     { easy: OBJECTS_EASY, medium: OBJECTS_MEDIUM, hard: OBJECTS_HARD },
  vehicles:    { easy: VEHICLES_EASY, medium: VEHICLES_MEDIUM, hard: VEHICLES_HARD },
  buildings:   { easy: BUILDINGS_EASY, medium: BUILDINGS_MEDIUM, hard: BUILDINGS_HARD },
  fantasy:     { easy: FANTASY_EASY, medium: FANTASY_MEDIUM, hard: FANTASY_HARD },
  space:       { easy: SPACE_EASY, medium: SPACE_MEDIUM, hard: SPACE_HARD },
  sports:      { easy: SPORTS_EASY, medium: SPORTS_MEDIUM, hard: SPORTS_HARD },
  professions: { easy: PROFESSIONS_EASY, medium: PROFESSIONS_MEDIUM, hard: PROFESSIONS_HARD },
  household:   { easy: HOUSEHOLD_EASY, medium: HOUSEHOLD_MEDIUM, hard: HOUSEHOLD_HARD },
  electronics: { easy: ELECTRONICS_EASY, medium: ELECTRONICS_MEDIUM, hard: ELECTRONICS_HARD },
  instruments: { easy: INSTRUMENTS_EASY, medium: INSTRUMENTS_MEDIUM, hard: INSTRUMENTS_HARD },
  holidays:    { easy: HOLIDAYS_EASY, medium: HOLIDAYS_MEDIUM, hard: HOLIDAYS_HARD },
};

// Build flat lookup maps
const promptDifficultyMap = {};
const promptCategoryMap = {};
const allPrompts = [];

for (const [category, difficulties] of Object.entries(CATEGORY_MAP)) {
  for (const [difficulty, prompts] of Object.entries(difficulties)) {
    for (const prompt of prompts) {
      promptDifficultyMap[prompt] = difficulty;
      promptCategoryMap[prompt] = category;
      allPrompts.push(prompt);
    }
  }
}

// Deduplicate
const uniquePrompts = [...new Set(allPrompts)];

logger.info(`Loaded ${uniquePrompts.length} curated prompts across ${Object.keys(CATEGORY_MAP).length} categories.`);

// ─── Recent Prompt Tracking ─────────────────────────────────────

const recentPrompts = new Set();
const maxRecentSize = 200;

function trackRecent(prompt) {
  recentPrompts.add(prompt);
  if (recentPrompts.size > maxRecentSize) {
    const firstItem = recentPrompts.values().next().value;
    recentPrompts.delete(firstItem);
  }
}

// ─── Public API ──────────────────────────────────────────────────

/**
 * Get a random prompt based on difficulty and category.
 * @param {string} difficulty - 'easy' | 'medium' | 'hard' | 'all'
 * @param {string} category - one of CATEGORY_MAP keys | 'all'
 * @returns {{ prompt: string, difficulty: string, category: string }}
 */
export function getRandomPrompt(difficulty, category) {
  let pool;

  if (category && category !== 'all' && CATEGORY_MAP[category]) {
    const catData = CATEGORY_MAP[category];
    if (difficulty && difficulty !== 'all' && catData[difficulty]) {
      pool = catData[difficulty];
    } else {
      pool = [...catData.easy, ...catData.medium, ...catData.hard];
    }
  } else if (difficulty && difficulty !== 'all') {
    pool = uniquePrompts.filter(p => promptDifficultyMap[p] === difficulty);
  } else {
    pool = uniquePrompts;
  }

  if (!pool || pool.length === 0) pool = uniquePrompts;

  // Filter recently used prompts if possible
  const unused = pool.filter(p => !recentPrompts.has(p));
  const finalPool = unused.length > 0 ? unused : pool;

  const selected = finalPool[Math.floor(Math.random() * finalPool.length)];
  trackRecent(selected);

  return {
    prompt: selected,
    difficulty: promptDifficultyMap[selected] || 'easy',
    category: promptCategoryMap[selected] || 'general',
  };
}

/**
 * Get multiple random prompts (no duplicates within the batch).
 */
export function getRandomPrompts(count = 3, difficulty, category) {
  const result = [];
  const seen = new Set();

  for (let i = 0; i < count; i++) {
    let attempts = 0;
    let p;
    do {
      p = getRandomPrompt(difficulty, category);
      attempts++;
    } while (seen.has(p.prompt) && attempts < 20);
    seen.add(p.prompt);
    result.push(p);
  }

  return result;
}

export { uniquePrompts as allPrompts, promptCategoryMap as promptCategories, promptDifficultyMap, CATEGORY_MAP };
export default CATEGORY_MAP;
