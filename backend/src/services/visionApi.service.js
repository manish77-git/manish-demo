import vision from '@google-cloud/vision';
import env from '../config/env.js';
import logger from '../utils/logger.js';
import { imageToBase64 } from '../utils/imageProcessor.js';

let client = null;

/**
 * Initialize the Google Cloud Vision API client.
 */
function getClient() {
  if (!client) {
    try {
      client = new vision.ImageAnnotatorClient({
        keyFilename: env.firebaseServiceAccountPath, // Reuse Firebase SA if it has Vision API access
      });
    } catch (error) {
      logger.warn('Failed to initialize Vision API client:', error.message);
      return null;
    }
  }
  return client;
}

/**
 * Detect labels in a drawing image using Google Cloud Vision API.
 * @param {Buffer} imageBuffer - Preprocessed PNG image buffer
 * @returns {Promise<Array<{ label: string, score: number }>>}
 */
export async function detectLabels(imageBuffer) {
  const visionClient = getClient();
  if (!visionClient) {
    throw new Error('Vision API client not available');
  }

  try {
    const [result] = await visionClient.labelDetection({
      image: { content: imageToBase64(imageBuffer) },
    });

    const labels = result.labelAnnotations || [];
    return labels.map(label => ({
      label: label.description.toLowerCase(),
      score: Math.round(label.score * 100) / 100,
    }));
  } catch (error) {
    logger.error('Vision API label detection failed:', error.message);
    throw error;
  }
}

/**
 * Detect web entities related to the drawing.
 * @param {Buffer} imageBuffer
 * @returns {Promise<Array<{ entity: string, score: number }>>}
 */
export async function detectWebEntities(imageBuffer) {
  const visionClient = getClient();
  if (!visionClient) {
    throw new Error('Vision API client not available');
  }

  try {
    const [result] = await visionClient.webDetection({
      image: { content: imageToBase64(imageBuffer) },
    });

    const webDetection = result.webDetection || {};
    const entities = webDetection.webEntities || [];
    return entities
      .filter(e => e.description)
      .map(entity => ({
        entity: entity.description.toLowerCase(),
        score: Math.round((entity.score || 0) * 100) / 100,
      }));
  } catch (error) {
    logger.error('Vision API web detection failed:', error.message);
    return [];
  }
}

/**
 * Calculate a similarity score between detected labels and the prompt.
 * @param {string} prompt - The drawing prompt
 * @param {Array<{ label: string, score: number }>} labels - Detected labels
 * @param {Array<{ entity: string, score: number }>} webEntities - Web entities
 * @returns {number} Score 0-100
 */
export function calculateVisionScore(prompt, labels, webEntities = []) {
  const promptWords = prompt.toLowerCase().split(/\s+/);
  let bestScore = 0;

  // Check labels for exact and partial matches
  for (const { label, score: confidence } of labels) {
    const labelWords = label.split(/\s+/);

    // Exact match (prompt found in label or label found in prompt)
    if (promptWords.some(pw => labelWords.includes(pw)) ||
        labelWords.some(lw => promptWords.includes(lw))) {
      const matchScore = 70 + (confidence * 30); // 70-100 range
      bestScore = Math.max(bestScore, matchScore);
    }

    // Partial/related match (check for common semantic relationships)
    const relatedScore = getSemanticSimilarity(prompt, label) * confidence;
    if (relatedScore > 0) {
      bestScore = Math.max(bestScore, 30 + (relatedScore * 40)); // 30-70 range
    }
  }

  // Check web entities for additional signal
  for (const { entity, score: confidence } of webEntities) {
    const entityWords = entity.split(/\s+/);
    if (promptWords.some(pw => entityWords.includes(pw))) {
      const entityScore = 60 + (confidence * 20);
      bestScore = Math.max(bestScore, entityScore);
    }
  }

  return Math.min(100, Math.round(bestScore));
}

/**
 * Basic semantic similarity using category groupings.
 * Returns 0-1 based on how related two terms are.
 */
function getSemanticSimilarity(term1, term2) {
  const categories = {
    animals: ['cat', 'dog', 'fish', 'bird', 'elephant', 'dolphin', 'penguin', 'octopus', 'butterfly', 'jellyfish', 'dragon', 'spider', 'wolf'],
    nature: ['tree', 'flower', 'mountain', 'volcano', 'sun', 'moon', 'star', 'cloud', 'rain', 'rainbow', 'leaf', 'mushroom', 'cactus', 'waterfall', 'palm tree'],
    buildings: ['house', 'castle', 'lighthouse', 'igloo', 'tent', 'bridge', 'windmill'],
    vehicles: ['car', 'bicycle', 'boat', 'airplane', 'train', 'helicopter', 'submarine', 'skateboard', 'pirate ship', 'hot air balloon'],
    food: ['apple', 'banana', 'pizza', 'ice cream', 'cake'],
    objects: ['hat', 'shoe', 'book', 'cup', 'clock', 'key', 'door', 'chair', 'table', 'lamp', 'pencil', 'guitar', 'telescope', 'compass', 'anchor', 'crown', 'diamond', 'treasure chest'],
    people: ['astronaut', 'pirate', 'knight', 'wizard', 'mermaid', 'ninja', 'surfer', 'explorer', 'robot', 'samurai', 'alien'],
  };

  const t1 = term1.toLowerCase();
  const t2 = term2.toLowerCase();

  for (const [, members] of Object.entries(categories)) {
    const t1Match = members.some(m => t1.includes(m) || m.includes(t1));
    const t2Match = members.some(m => t2.includes(m) || m.includes(t2));
    if (t1Match && t2Match) return 0.5; // Same category
  }

  return 0;
}

export default { detectLabels, detectWebEntities, calculateVisionScore };
