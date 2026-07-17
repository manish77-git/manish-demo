import { preprocessImage, extractImageFeatures } from '../utils/imageProcessor.js';
import { evaluateWithGemini } from './geminiEvaluator.service.js';
import { calculateCompositeScore } from './scoring.service.js';
import logger from '../utils/logger.js';

/**
 * Helper to determine letter grade from score.
 */
function getGrade(score) {
  if (score >= 90) return 'S';
  if (score >= 80) return 'A';
  if (score >= 70) return 'B';
  if (score >= 60) return 'C';
  if (score >= 40) return 'D';
  return 'F';
}

/**
 * Generate a quality-based fallback evaluation when Gemini is unavailable.
 * Uses image feature analysis to provide a best-effort score.
 */
/**
 * Evaluate a single drawing against a prompt using Gemini.
 *
 * Pipeline:
 * 1. Extract image features (blank detection)
 * 2. If blank → return 0/F immediately
 * 3. Call Gemini Vision API for semantic evaluation
 * 4. Propagates any API or rate limit errors directly to the route handler.
 *
 * @param {Buffer} imageBuffer - Raw PNG image from user
 * @param {string} prompt - The drawing prompt
 * @param {Object} options
 * @param {number} options.drawingTimeSeconds - Max allowed time
 * @param {number} options.timeTakenSeconds - Actual time taken
 * @param {number} options.streak - Player's win streak
 * @returns {Promise<{ score: number, grade: string, confidence: number, explanation: string[], labels: string[], creativityScore: number, reasoning: string, missingElements: string[], breakdown: Object }>}
 */
export async function evaluateDrawing(imageBuffer, prompt, options = {}) {
  const { drawingTimeSeconds = 60, timeTakenSeconds = 60, streak = 0 } = options;

  logger.info(`Evaluating drawing for prompt: "${prompt}"`);

  // 1. Preprocess and extract features
  const { buffer: processedImage } = await preprocessImage(imageBuffer, {
    width: 256,
    height: 256,
  });
  const imageFeatures = await extractImageFeatures(processedImage);

  // 2. Blank drawing check
  if (imageFeatures.isBlank) {
    logger.warn('Blank drawing submitted');
    return {
      score: 0,
      grade: 'F',
      confidence: 0,
      explanation: ['Blank drawing submitted.', 'Please draw on the canvas.'],
      labels: [],
      creativityScore: 0,
      reasoning: 'Blank canvas detected.',
      missingElements: ['All elements missing.'],
      breakdown: { aiScore: 0, reason: 'Blank drawing detected' },
    };
  }

  // 3. Call Gemini Vision evaluation (propagates errors)
  const aiResult = await evaluateWithGemini(imageBuffer, prompt);

  // 4. Calculate composite score using Gemini score as base
  const { score, breakdown } = calculateCompositeScore({
    aiScore: aiResult.similarityScore,
    drawingTimeSeconds,
    timeTakenSeconds,
    imageFeatures,
    streak,
  });

  const grade = getGrade(score);

  // Build beautiful explanation array for the UI
  const explanation = [
    aiResult.reasoning,
    ...aiResult.missingElements.map(element => `Missing: ${element}`),
    ...aiResult.strengths.map(strength => `Strength: ${strength}`),
  ];

  logger.info(`Drawing evaluated: prompt="${prompt}", score=${score}, grade=${grade}`);

  return {
    score,
    grade,
    confidence: aiResult.accuracy,
    explanation,
    labels: aiResult.labels,
    objectRecognitionScore: aiResult.objectRecognitionScore,
    requiredFeaturesScore: aiResult.requiredFeaturesScore,
    compositionScore: aiResult.compositionScore,
    creativityScore: aiResult.creativityScore,
    strokeQualityScore: aiResult.strokeQualityScore,
    reasoning: aiResult.reasoning,
    missingElements: aiResult.missingElements,
    strengths: aiResult.strengths,
    weaknesses: aiResult.weaknesses,
    breakdown: {
      ...breakdown,
      geminiRawScore: aiResult.similarityScore,
      objectRecognitionScore: aiResult.objectRecognitionScore,
      requiredFeaturesScore: aiResult.requiredFeaturesScore,
      compositionScore: aiResult.compositionScore,
      creativityScore: aiResult.creativityScore,
      strokeQualityScore: aiResult.strokeQualityScore,
      accuracy: aiResult.accuracy,
      imageFeatures: {
        coverage: imageFeatures.coverage,
        edgeDensity: imageFeatures.edgeDensity,
      },
    },
  };
}

/**
 * Evaluate all drawings for a game session.
 */
export async function evaluateAllDrawings(submissions, prompt, drawingTimeSeconds, gameStartTime) {
  const results = {};
  const startTime = new Date(gameStartTime).getTime();

  const evaluationPromises = Object.entries(submissions).map(async ([userId, submission]) => {
    const submittedAt = new Date(submission.submittedAt).getTime();
    const timeTakenSeconds = Math.round((submittedAt - startTime) / 1000);

    const result = await evaluateDrawing(
      submission.drawingBuffer,
      prompt,
      {
        drawingTimeSeconds,
        timeTakenSeconds: Math.min(timeTakenSeconds, drawingTimeSeconds),
        streak: 0,
      }
    );

    results[userId] = result;
  });

  await Promise.all(evaluationPromises);
  return results;
}

export default { evaluateDrawing, evaluateAllDrawings };
