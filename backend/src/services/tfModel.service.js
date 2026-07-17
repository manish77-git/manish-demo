import * as tf from '@tensorflow/tfjs';
import * as mobilenet from '@tensorflow-models/mobilenet';
import logger from '../utils/logger.js';

let model = null;
let modelLoading = null;

/**
 * Initialize and load the MobileNet model.
 */
export async function initModel() {
  if (model) return true;
  if (modelLoading) return modelLoading;

  modelLoading = (async () => {
    try {
      logger.info('Loading MobileNet model from TensorFlow Hub...');
      model = await mobilenet.load();
      logger.info('MobileNet model loaded successfully!');
      return true;
    } catch (error) {
      logger.error('Failed to load MobileNet model:', error);
      modelLoading = null;
      return false;
    }
  })();

  return modelLoading;
}

/**
 * Classify a drawing image buffer using MobileNet.
 * Converts raw buffer to a 3D tensor and runs classification.
 *
 * @param {Buffer} rawBuffer - Image buffer (must be raw pixels: 3 channels, 224x224)
 * @returns {Promise<Array<{ className: string, probability: number }>>}
 */
export async function classifyDrawing(rawBuffer) {
  try {
    // Make sure model is loaded
    await initModel();
    if (!model) {
      throw new Error('MobileNet model is not initialized');
    }

    // Convert raw pixel buffer to a 3D Tensor [224, 224, 3]
    const tensor = tf.tensor3d(new Uint8Array(rawBuffer), [224, 224, 3]);

    // Classify the image tensor
    const predictions = await model.classify(tensor);

    // Clean up tensor to prevent memory leaks
    tensor.dispose();

    logger.debug(`MobileNet classification complete: ${JSON.stringify(predictions)}`);
    return predictions;
  } catch (error) {
    logger.error('MobileNet classification failed:', error);
    return [];
  }
}

/**
 * Check if the predicted class is semantically related to the prompt.
 */
export function isSemanticMatch(prompt, className) {
  const p = prompt.toLowerCase().trim();
  const tags = className.toLowerCase().split(',').map(t => t.trim());

  // 1. Direct string match
  if (tags.some(t => t === p || t.includes(p) || p.includes(t))) {
    return true;
  }

  // 2. Synonyms and related categories mapping
  const synonyms = {
    'cat': ['cat', 'tabby', 'egyptian cat', 'persian cat', 'siamese', 'cougar', 'panther', 'leopard', 'lion', 'tiger', 'feline'],
    'dog': ['dog', 'retriever', 'shepherd', 'terrier', 'pug', 'poodle', 'bulldog', 'dalmatian', 'canine', 'puppy'],
    'house': ['house', 'home', 'building', 'shack', 'structure', 'igloo', 'yurt', 'castle', 'palace'],
    'tree': ['tree', 'forest', 'wood', 'pine', 'fir', 'oak', 'maple', 'palm'],
    'sun': ['sun', 'star', 'light', 'sky', 'sunlight'],
    'moon': ['moon', 'crescent', 'satellite', 'sky'],
    'star': ['star', 'sun', 'moon', 'sky'],
    'car': ['car', 'cab', 'taxi', 'limousine', 'limo', 'minivan', 'vehicle', 'automobile'],
    'fish': ['fish', 'goldfish', 'shark', 'salmon', 'trout', 'bass'],
    'flower': ['flower', 'rose', 'daisy', 'tulip', 'sunflower', 'petal', 'plant'],
    'apple': ['apple', 'fruit', 'food'],
    'banana': ['banana', 'fruit', 'food'],
    'hat': ['hat', 'cap', 'bonnet', 'sombrero', 'helmet'],
    'shoe': ['shoe', 'boot', 'sandal', 'sneaker', 'clog'],
    'book': ['book', 'notebook', 'novel', 'paper'],
    'cup': ['cup', 'mug', 'glass', 'goblet', 'beaker'],
    'clock': ['clock', 'watch', 'timer', 'dial'],
    'heart': ['heart', 'love', 'red'],
    'cloud': ['cloud', 'fog', 'mist', 'sky'],
    'rain': ['rain', 'water', 'drop', 'shower'],
    'ball': ['ball', 'sphere', 'soccer', 'basketball', 'tennis'],
    'key': ['key', 'lock', 'metal'],
    'door': ['door', 'gate', 'entrance'],
    'chair': ['chair', 'seat', 'stool'],
    'table': ['table', 'desk', 'counter'],
    'lamp': ['lamp', 'light', 'lantern'],
    'pencil': ['pencil', 'pen', 'crayon', 'marker'],
    'eye': ['eye', 'vision', 'pupil'],
    'hand': ['hand', 'palm', 'finger', 'glove'],
    'smile': ['smile', 'face', 'happy'],
    'boat': ['boat', 'ship', 'canoe', 'yacht', 'vessel'],
    'flag': ['flag', 'banner', 'standard'],
    'bell': ['bell', 'chime', 'gong'],
    'bird': ['bird', 'canary', 'robin', 'sparrow', 'finch', 'eagle', 'hawk', 'owl', 'ostrich', 'penguin'],
    'egg': ['egg', 'shell', 'nest'],
    'leaf': ['leaf', 'foliage', 'petal', 'plant'],
    'mushroom': ['mushroom', 'fungus', 'toadstool'],
    'pizza': ['pizza', 'food', 'pie'],
    'ice cream': ['ice cream', 'icecream', 'dessert', 'cone'],
    'cake': ['cake', 'dessert', 'pastry'],
    'bicycle': ['bicycle', 'bike', 'cycle', 'wheel'],
    'guitar': ['guitar', 'banjo', 'ukulele', 'lute', 'stringed instrument'],
    'lighthouse': ['lighthouse', 'tower', 'beacon'],
    'dragon': ['dragon', 'lizard', 'dinosaur', 'reptile', 'monster'],
    'robot': ['robot', 'cyborg', 'android', 'machine'],
    'castle': ['castle', 'fort', 'fortress', 'palace', 'monastery', 'tower', 'wall'],
    'airplane': ['airplane', 'plane', 'aircraft', 'jet'],
    'elephant': ['elephant', 'tusker'],
    'butterfly': ['butterfly', 'moth', 'insect'],
    'dolphin': ['dolphin', 'whale', 'mammal', 'fish'],
    'mountain': ['mountain', 'hill', 'peak', 'alp'],
    'volcano': ['volcano', 'lava', 'mountain'],
    'pirate ship': ['ship', 'boat', 'vessel', 'pirate'],
    'crown': ['crown', 'coronet', 'diadem', 'tiara'],
    'diamond': ['diamond', 'gem', 'jewel', 'crystal'],
    'skateboard': ['skateboard', 'board', 'deck'],
    'telescope': ['telescope', 'spyglass', 'binocular'],
    'compass': ['compass', 'dial', 'navigation'],
    'anchor': ['anchor', 'hook', 'metal'],
    'tornado': ['tornado', 'whirlwind', 'cyclone', 'storm'],
    'palm tree': ['palm', 'tree', 'coconut'],
    'igloo': ['igloo', 'ice', 'dome', 'shelter'],
    'snowman': ['snowman', 'snow', 'figure'],
    'penguin': ['penguin', 'bird'],
    'octopus': ['octopus', 'squid', 'cuttlefish'],
    'jellyfish': ['jellyfish', 'cnidarian', 'medusa'],
    'spider web': ['web', 'spiderweb', 'net'],
    'treasure chest': ['chest', 'box', 'trunk', 'coffer'],
    'hot air balloon': ['balloon', 'aircraft'],
    'roller coaster': ['coaster', 'train', 'ride'],
    'windmill': ['windmill', 'mill', 'wheel'],
    'train': ['train', 'locomotive', 'engine'],
    'helicopter': ['helicopter', 'chopper', 'copter'],
    'submarine': ['submarine', 'sub', 'vessel'],
    'cactus': ['cactus', 'plant', 'desert'],
    'rainbow': ['rainbow', 'arc', 'color'],
    'campfire': ['campfire', 'fire', 'flame'],
    'tent': ['tent', 'canopy', 'shelter'],
    'bridge': ['bridge', 'overpass', 'span'],
    'waterfall': ['waterfall', 'cascade', 'fall'],
  };

  const pSyns = synonyms[p] || [];
  return pSyns.some(syn => tags.some(t => t === syn || t.includes(syn) || syn.includes(t)));
}

/**
 * Compute the semantic score for predictions.
 */
export function getTfScore(prompt, predictions, imageFeatures = {}) {
  if (imageFeatures.isBlank) {
    return 0;
  }

  // 1. Direct/Semantic matches
  let bestProb = 0;
  let isMatched = false;

  for (const pred of predictions) {
    if (isSemanticMatch(prompt, pred.className)) {
      bestProb = Math.max(bestProb, pred.probability);
      isMatched = true;
    }
  }

  if (isMatched) {
    // Map probability to score (e.g. 5% match is a solid sketch!)
    // If probability >= 0.1, we give a nearly perfect score
    const score = Math.round(75 + Math.min(1.0, bestProb * 8) * 20);
    return Math.min(98, score);
  }

  // 2. Fallback: drawing quality / lines drawn
  const { coverage = 0.3, edgeDensity = 0.2 } = imageFeatures;

  // Good drawings typically have moderate coverage (0.05 - 0.4) and higher edge density
  const coverageScore = coverage > 0.05 && coverage < 0.5
    ? 1.0 - Math.abs(coverage - 0.2) * 2
    : 0.3;

  const detailScore = Math.min(1.0, edgeDensity * 4);
  const qualityEstimate = (coverageScore * 0.4 + detailScore * 0.6);

  // Score range: 30 to 65 for drawings that don't match MobileNet classes directly
  return Math.round(30 + qualityEstimate * 35);
}

export default { initModel, classifyDrawing, getTfScore, isSemanticMatch };
