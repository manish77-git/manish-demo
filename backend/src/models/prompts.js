/**
 * DrawBattle Prompt Bank
 * 100+ curated drawing prompts organized by difficulty tier.
 */

const prompts = {
  easy: [
    'cat', 'dog', 'house', 'tree', 'sun', 'moon', 'star', 'car', 'fish', 'flower',
    'apple', 'banana', 'hat', 'shoe', 'book', 'cup', 'clock', 'heart', 'cloud', 'rain',
    'ball', 'key', 'door', 'chair', 'table', 'lamp', 'pencil', 'eye', 'hand', 'smile',
    'boat', 'flag', 'bell', 'bird', 'egg', 'leaf', 'mushroom', 'pizza', 'ice cream', 'cake',
  ],
  medium: [
    'bicycle', 'guitar', 'lighthouse', 'dragon', 'robot', 'castle', 'airplane', 'elephant',
    'butterfly', 'dolphin', 'mountain', 'volcano', 'pirate ship', 'crown', 'diamond',
    'skateboard', 'telescope', 'compass', 'anchor', 'tornado', 'palm tree', 'igloo',
    'snowman', 'penguin', 'octopus', 'jellyfish', 'spider web', 'treasure chest',
    'hot air balloon', 'roller coaster', 'windmill', 'train', 'helicopter', 'submarine',
    'cactus', 'rainbow', 'campfire', 'tent', 'bridge', 'waterfall',
  ],
  hard: [
    'astronaut on the moon', 'city skyline at night', 'underwater coral reef',
    'dragon flying over castle', 'robot cooking dinner', 'cat playing piano',
    'pirate finding treasure', 'alien spaceship landing', 'haunted house at midnight',
    'knight fighting dragon', 'wizard casting spell', 'mermaid in ocean',
    'phoenix rising from flames', 'samurai in bamboo forest', 'steampunk airship',
    'explorer in ancient ruins', 'time traveler with clock', 'giant octopus attacking ship',
    'arctic expedition with sled dogs', 'enchanted forest with fairies',
    'mad scientist in lab', 'ninja on rooftop', 'surfer riding giant wave',
    'deep sea diver finding sunken treasure', 'moonlit wolf howling',
  ],
};

// Flatten for quick random selection
const allPrompts = [...prompts.easy, ...prompts.medium, ...prompts.hard];

/**
 * Get a random prompt from a specific difficulty or all prompts.
 * @param {'easy'|'medium'|'hard'|'all'} difficulty
 * @returns {{ prompt: string, difficulty: string }}
 */
export function getRandomPrompt(difficulty = 'all') {
  let pool;
  let tier;

  if (difficulty === 'all') {
    // Weighted random: 40% easy, 40% medium, 20% hard
    const roll = Math.random();
    if (roll < 0.4) {
      pool = prompts.easy;
      tier = 'easy';
    } else if (roll < 0.8) {
      pool = prompts.medium;
      tier = 'medium';
    } else {
      pool = prompts.hard;
      tier = 'hard';
    }
  } else {
    pool = prompts[difficulty] || allPrompts;
    tier = difficulty;
  }

  const prompt = pool[Math.floor(Math.random() * pool.length)];
  return { prompt, difficulty: tier };
}

/**
 * Get multiple unique random prompts.
 * @param {number} count
 * @param {'easy'|'medium'|'hard'|'all'} difficulty
 * @returns {Array<{ prompt: string, difficulty: string }>}
 */
export function getRandomPrompts(count = 5, difficulty = 'all') {
  const pool = difficulty === 'all' ? allPrompts : (prompts[difficulty] || allPrompts);
  const shuffled = [...pool].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(count, shuffled.length)).map(prompt => ({
    prompt,
    difficulty: Object.entries(prompts).find(([, arr]) => arr.includes(prompt))?.[0] || 'unknown',
  }));
}

export { prompts, allPrompts };
export default prompts;
