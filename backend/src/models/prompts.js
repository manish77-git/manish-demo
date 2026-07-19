/**
 * DrawBattle Prompt Bank
 * 5,000+ unique single-word/compound-word prompts organized by 15 categories and 3 difficulty tiers.
 */

import logger from '../utils/logger.js';

// Base word configs for 15 categories to generate simple compound words
const categoryConfigs = {
  'Animals': {
    easyWords: ['cat', 'dog', 'rabbit', 'lion', 'bear', 'fox', 'wolf', 'deer', 'cow', 'pig', 'sheep', 'chicken', 'duck', 'horse', 'mouse', 'frog', 'turtle', 'elephant', 'giraffe', 'zebra', 'hippo', 'rhino', 'owl', 'penguin'],
    prefixes: ['wild', 'sea', 'river', 'lake', 'wood', 'snow', 'ice', 'sand', 'rock', 'night', 'sky', 'fire', 'water', 'gold', 'silver', 'bush', 'swamp', 'cave', 'mountain', 'forest'],
    suffixes: ['cat', 'dog', 'bird', 'fish', 'bear', 'wolf', 'fox', 'deer', 'rabbit', 'mouse', 'owl', 'frog', 'turtle', 'snake', 'crab', 'bee', 'ant', 'wasp', 'duck', 'goose']
  },
  'Food': {
    easyWords: ['apple', 'banana', 'orange', 'strawberry', 'grape', 'carrot', 'potato', 'tomato', 'pizza', 'burger', 'cookie', 'donut', 'cupcake', 'icecream', 'cheese', 'bread', 'egg', 'taco', 'sushi', 'cake'],
    prefixes: ['sweet', 'sour', 'spicy', 'salty', 'hot', 'cold', 'ice', 'fire', 'honey', 'sugar', 'milk', 'cream', 'butter', 'cheese', 'berry', 'cherry', 'lemon', 'coco', 'choco', 'nut'],
    suffixes: ['cake', 'pie', 'tart', 'bun', 'roll', 'bread', 'cookie', 'donut', 'waffle', 'pancake', 'toast', 'soup', 'stew', 'sauce', 'dip', 'salad', 'juice', 'shake', 'syrup', 'candy']
  },
  'Nature': {
    easyWords: ['tree', 'flower', 'leaf', 'grass', 'rock', 'cloud', 'sun', 'moon', 'star', 'river', 'lake', 'mountain', 'hill', 'rain', 'snow', 'wind', 'fire', 'sea', 'shell', 'mushroom'],
    prefixes: ['thunder', 'lightning', 'rain', 'snow', 'frost', 'dew', 'fog', 'mist', 'cloud', 'wind', 'storm', 'dust', 'sand', 'mud', 'dirt', 'clay', 'rock', 'stone', 'lava', 'magma'],
    suffixes: ['storm', 'cloud', 'wind', 'shower', 'drift', 'fall', 'rise', 'flow', 'wave', 'tide', 'pool', 'lake', 'pond', 'river', 'stream', 'brook', 'spring', 'well', 'cave', 'peak']
  },
  'Objects': {
    easyWords: ['book', 'cup', 'clock', 'key', 'pencil', 'scissors', 'umbrella', 'hat', 'shoe', 'glasses', 'phone', 'ring', 'balloon', 'bag', 'lamp', 'chair', 'table', 'mirror', 'candle', 'key'],
    prefixes: ['key', 'lock', 'ring', 'chain', 'box', 'case', 'bag', 'sack', 'pack', 'cup', 'mug', 'bowl', 'plate', 'dish', 'pot', 'pan', 'book', 'page', 'pen', 'pencil'],
    suffixes: ['holder', 'keeper', 'box', 'case', 'bag', 'pack', 'ring', 'chain', 'stand', 'rack', 'shelf', 'tray', 'plate', 'bowl', 'cup', 'pot', 'pan', 'hook', 'clip', 'pin']
  },
  'Vehicles': {
    easyWords: ['car', 'bicycle', 'train', 'airplane', 'boat', 'truck', 'bus', 'rocket', 'subway', 'tractor', 'helicopter', 'scooter', 'van', 'taxi', 'ship'],
    prefixes: ['steam', 'speed', 'race', 'flight', 'sail', 'sub', 'space', 'sky', 'sea', 'land', 'air', 'wind', 'fire', 'auto', 'motor', 'jet', 'cargo', 'road', 'rail', 'track'],
    suffixes: ['car', 'boat', 'ship', 'train', 'plane', 'bike', 'cycle', 'truck', 'bus', 'copter', 'craft', 'rover', 'glider', 'runner', 'flyer', 'cruiser', 'tank', 'wagon', 'cab', 'carrier']
  },
  'Sports': {
    easyWords: ['ball', 'hoop', 'bat', 'racket', 'shoe', 'skateboard', 'helmet', 'glove', 'net', 'whistle', 'jersey'],
    prefixes: ['base', 'basket', 'foot', 'volley', 'hand', 'snow', 'ice', 'water', 'surf', 'skate', 'track', 'field', 'golf', 'tennis', 'hockey', 'match', 'game', 'court', 'pool', 'team'],
    suffixes: ['ball', 'bat', 'net', 'hoop', 'racket', 'board', 'shoe', 'boot', 'glove', 'mask', 'cap', 'ring', 'goal', 'track', 'stick', 'puck', 'club', 'cup', 'medal', 'trophy']
  },
  'Buildings': {
    easyWords: ['house', 'barn', 'tower', 'bridge', 'castle', 'cabin', 'school', 'shop', 'church', 'mill', 'wall', 'tent', 'gate', 'hotel', 'home'],
    prefixes: ['log', 'stone', 'wood', 'brick', 'mud', 'sand', 'snow', 'ice', 'light', 'wind', 'water', 'mill', 'farm', 'guard', 'watch', 'gate', 'town', 'city', 'sky', 'sea'],
    suffixes: ['house', 'cabin', 'cottage', 'home', 'tower', 'bridge', 'gate', 'wall', 'barn', 'shed', 'shack', 'hall', 'room', 'vault', 'dome', 'roof', 'arch', 'port', 'dock', 'yard']
  },
  'Fantasy': {
    easyWords: ['wand', 'hat', 'potion', 'fairy', 'dragon', 'sword', 'shield', 'crown', 'ring', 'crystal', 'spell', 'key', 'cape', 'map', 'book'],
    prefixes: ['magic', 'spell', 'rune', 'myth', 'lore', 'elf', 'dwarf', 'orc', 'troll', 'witch', 'mage', 'pixie', 'sprite', 'ghost', 'fiend', 'star', 'sun', 'moon', 'dream', 'spirit'],
    suffixes: ['wand', 'potion', 'spell', 'rune', 'sword', 'blade', 'shield', 'crown', 'ring', 'key', 'cloak', 'amulet', 'gem', 'stone', 'dust', 'powder', 'fire', 'breath', 'wing', 'horn']
  },
  'Space': {
    easyWords: ['rocket', 'alien', 'planet', 'star', 'moon', 'rover', 'comet', 'sun', 'meteor', 'satellite', 'galaxy', 'capsule', 'telescope', 'ship', 'crater'],
    prefixes: ['space', 'star', 'moon', 'sun', 'sky', 'cosmic', 'solar', 'lunar', 'astro', 'stellar', 'galaxy', 'nebula', 'orbit', 'meteor', 'comet', 'warp', 'hyper', 'dark', 'light', 'void'],
    suffixes: ['ship', 'craft', 'probe', 'lander', 'rover', 'suit', 'port', 'dock', 'base', 'dome', 'station', 'flare', 'spot', 'beam', 'dust', 'rock', 'ring', 'core', 'sail', 'pod']
  },
  'Technology': {
    easyWords: ['computer', 'robot', 'mouse', 'keyboard', 'screen', 'phone', 'printer', 'cable', 'battery', 'chip', 'gear', 'button', 'disk', 'camera', 'plug'],
    prefixes: ['micro', 'macro', 'nano', 'cyber', 'robo', 'tele', 'auto', 'smart', 'super', 'hyper', 'digital', 'quantum', 'laser', 'solar', 'power', 'data', 'web', 'net', 'wire', 'holo'],
    suffixes: ['chip', 'board', 'card', 'drive', 'disk', 'link', 'core', 'cell', 'pack', 'phone', 'bot', 'drone', 'arm', 'hand', 'eye', 'screen', 'plug', 'cord', 'gear', 'grid']
  },
  'Jobs': {
    easyWords: ['doctor', 'nurse', 'teacher', 'chef', 'artist', 'driver', 'pilot', 'police', 'farmer', 'builder', 'singer', 'writer', 'dentist', 'baker', 'actor'],
    prefixes: ['head', 'chief', 'master', 'lead', 'co', 'sub', 'assistant', 'under', 'over', 'fore', 'sea', 'sky', 'land', 'air', 'fire', 'water', 'city', 'town', 'farm', 'shop'],
    suffixes: ['doctor', 'nurse', 'teacher', 'chef', 'artist', 'driver', 'pilot', 'guard', 'farmer', 'builder', 'singer', 'writer', 'baker', 'maker', 'worker', 'agent', 'officer', 'guide', 'runner', 'scout']
  },
  'Holidays': {
    easyWords: ['gift', 'card', 'tree', 'egg', 'mask', 'star', 'flag', 'cake', 'bell', 'hat', 'rose', 'heart', 'sweets', 'lights', 'toy'],
    prefixes: ['merry', 'jolly', 'happy', 'festive', 'spooky', 'scary', 'holy', 'sacred', 'winter', 'spring', 'summer', 'autumn', 'birthday', 'wedding', 'party', 'feast', 'carnival', 'parade'],
    suffixes: ['tree', 'gift', 'card', 'wreath', 'stocking', 'bell', 'candle', 'lantern', 'mask', 'hat', 'cake', 'egg', 'basket', 'flag', 'banner', 'star', 'heart', 'rose', 'toy', 'bonfire']
  },
  'Emotions': {
    easyWords: ['smile', 'tear', 'heart', 'cloud', 'sun', 'frown', 'hand', 'face', 'shout', 'hug', 'gift', 'star', 'flower', 'key', 'cross'],
    prefixes: ['happy', 'sad', 'angry', 'scared', 'joy', 'grief', 'fear', 'dread', 'hope', 'peace', 'love', 'hate', 'shame', 'pride', 'trust', 'gloom', 'cheer', 'rage', 'calm', 'warm'],
    suffixes: ['face', 'smile', 'frown', 'tear', 'look', 'sigh', 'shout', 'scream', 'groan', 'gasp', 'hug', 'touch', 'grip', 'path', 'gate', 'wall', 'cloud', 'storm', 'spark', 'glow']
  },
  'Mythology': {
    easyWords: ['crown', 'sword', 'shield', 'bolt', 'hammer', 'wing', 'horn', 'ring', 'mask', 'altar', 'temple', 'hero', 'statue', 'bow', 'spear'],
    prefixes: ['myth', 'ancient', 'sacred', 'divine', 'god', 'hero', 'titan', 'dragon', 'phoenix', 'sphinx', 'chimera', 'griffin', 'kraken', 'hydra', 'gorgon', 'celt', 'norse', 'greek', 'roman', 'egypt'],
    suffixes: ['temple', 'altar', 'statue', 'shrine', 'tomb', 'mask', 'crown', 'throne', 'sword', 'shield', 'spear', 'bow', 'bolt', 'hammer', 'horn', 'wing', 'talisman', 'scroll', 'urn', 'pillar']
  },
  'Abstract Concepts': {
    easyWords: ['spiral', 'grid', 'circle', 'square', 'triangle', 'arrow', 'cross', 'loop', 'star', 'wave', 'line', 'dot', 'cube', 'prism', 'sphere'],
    prefixes: ['geo', 'meta', 'hyper', 'infra', 'ultra', 'micro', 'macro', 'uni', 'bi', 'tri', 'poly', 'multi', 'omni', 'time', 'space', 'mind', 'soul', 'life', 'force', 'light'],
    suffixes: ['grid', 'loop', 'wave', 'line', 'node', 'link', 'path', 'gate', 'door', 'maze', 'spiral', 'sphere', 'cube', 'prism', 'cone', 'pyramid', 'ring', 'core', 'void', 'realm']
  }
};

// Generate prompt databases
const prompts = {
  easy: [],
  medium: [],
  hard: []
};

const promptCategories = {}; // maps prompt text -> category name
const promptDifficultyMap = {}; // maps prompt text -> difficulty

// Helper to shuffle array
function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

logger.info('Initializing DrawBattle Prompt Database...');

const categories = Object.keys(categoryConfigs);

// Generate prompts for each category
for (const cat of categories) {
  const config = categoryConfigs[cat];

  // 1. EASY PROMPTS: Easy base words + simple combined words (Goal: 125 prompts per category)
  const easyTemp = [...config.easyWords];
  
  // Combine prefix [0-14] with suffix [0-14] (up to 225 combinations)
  const easyCombo = [];
  for (let i = 0; i < Math.min(15, config.prefixes.length); i++) {
    for (let j = 0; j < Math.min(15, config.suffixes.length); j++) {
      const word = `${config.prefixes[i]}${config.suffixes[j]}`;
      if (!easyTemp.includes(word)) {
        easyCombo.push(word);
      }
    }
  }
  shuffle(easyCombo);
  
  // Fill easy list up to exactly 125
  const neededEasy = 125 - easyTemp.length;
  const easySlice = easyCombo.slice(0, neededEasy);
  const finalEasy = [...easyTemp, ...easySlice];
  
  for (const p of finalEasy) {
    prompts.easy.push(p);
    promptCategories[p] = cat;
    promptDifficultyMap[p] = 'easy';
  }

  // 2. MEDIUM PROMPTS: Intermediate combined words (Goal: 125 prompts per category)
  const medCombo = [];
  // Combine all prefixes and suffixes
  for (let i = 0; i < config.prefixes.length; i++) {
    for (let j = 0; j < config.suffixes.length; j++) {
      const word = `${config.prefixes[i]}${config.suffixes[j]}`;
      // Prevent duplicates from easy
      if (!promptDifficultyMap[word]) {
        medCombo.push(word);
      }
    }
  }
  shuffle(medCombo);
  const medSlice = medCombo.slice(0, 125);
  for (const p of medSlice) {
    prompts.medium.push(p);
    promptCategories[p] = cat;
    promptDifficultyMap[p] = 'medium';
  }

  // 3. HARD PROMPTS: Complex combined words (Goal: 125 prompts per category)
  const hardCombo = [];
  // Combine all prefixes and suffixes
  for (let i = 0; i < config.prefixes.length; i++) {
    for (let j = 0; j < config.suffixes.length; j++) {
      const word = `${config.prefixes[i]}${config.suffixes[j]}`;
      // Prevent duplicates from easy/medium
      if (!promptDifficultyMap[word]) {
        hardCombo.push(word);
      }
    }
  }
  shuffle(hardCombo);
  const hardSlice = hardCombo.slice(0, 125);
  for (const p of hardSlice) {
    prompts.hard.push(p);
    promptCategories[p] = cat;
    promptDifficultyMap[p] = 'hard';
  }
}

// Flatten for quick random selection
const allPrompts = [...prompts.easy, ...prompts.medium, ...prompts.hard];

logger.info(`Prompt Database Initialized successfully!`);
logger.info(`Total Easy Prompts: ${prompts.easy.length}`);
logger.info(`Total Medium Prompts: ${prompts.medium.length}`);
logger.info(`Total Hard Prompts: ${prompts.hard.length}`);
logger.info(`Total Prompts: ${allPrompts.length} (Target: >5,000)`);

// Recent prompts tracking queue to prevent repetition
const recentPrompts = new Set();
const maxRecentSize = 1200; // Track up to 1200 prompts to avoid repeats

function trackRecent(prompt) {
  recentPrompts.add(prompt);
  if (recentPrompts.size > maxRecentSize) {
    const first = recentPrompts.values().next().value;
    recentPrompts.delete(first);
  }
}

/**
 * Get a random prompt based on difficulty and category.
 * @param {'easy'|'medium'|'hard'|'mixed'|'all'} difficulty
 * @param {string} category - 'all' or one of the 15 categories
 * @returns {{ prompt: string, difficulty: 'easy'|'medium'|'hard', category: string }}
 */
export function getRandomPrompt(difficulty = 'all', category = 'all') {
  let tier = difficulty === 'mixed' || difficulty === 'all' ? 'all' : difficulty;
  let cat = category === 'all' ? 'all' : category;

  let pool = allPrompts;

  // Filter pool by difficulty first
  if (tier !== 'all') {
    pool = prompts[tier] || allPrompts;
  }

  // Filter pool by category
  if (cat !== 'all') {
    pool = pool.filter(p => promptCategories[p] === cat);
  }

  // Fallback if empty pool
  if (pool.length === 0) {
    pool = allPrompts;
  }

  // Try to select a prompt that hasn't been used recently (up to 30 attempts)
  let attempts = 0;
  let selected = pool[Math.floor(Math.random() * pool.length)];

  while (recentPrompts.has(selected) && attempts < 30) {
    selected = pool[Math.floor(Math.random() * pool.length)];
    attempts++;
  }

  trackRecent(selected);

  return {
    prompt: selected,
    difficulty: promptDifficultyMap[selected] || 'easy',
    category: promptCategories[selected] || 'Animals'
  };
}

/**
 * Get multiple unique random prompts.
 * @param {number} count
 * @param {'easy'|'medium'|'hard'|'mixed'|'all'} difficulty
 * @param {string} category
 * @returns {Array<{ prompt: string, difficulty: string, category: string }>}
 */
export function getRandomPrompts(count = 5, difficulty = 'all', category = 'all') {
  const result = [];
  for (let i = 0; i < count; i++) {
    result.push(getRandomPrompt(difficulty, category));
  }
  return result;
}

export { prompts, allPrompts, promptCategories, promptDifficultyMap };
export default prompts;
