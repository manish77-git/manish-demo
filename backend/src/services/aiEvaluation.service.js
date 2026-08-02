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
 * Evaluate a single drawing against a prompt using AI Vision.
 *
 * Pipeline:
 * 1. Extract image features (blank detection)
 * 2. If blank → return 0/F immediately
 * 3. Call AI Vision API (Gemini primary, Groq fallback) for semantic evaluation
 * 4. On total AI failure → THROW (never return placeholder scores)
 *
 * @param {Buffer} imageBuffer - Raw PNG image from user
 * @param {string} prompt - The drawing prompt
 * @param {Object} options
 * @returns {Promise<Object>}
 */
export async function evaluateDrawing(imageBuffer, prompt, options = {}) {
  const { drawingTimeSeconds = 60, timeTakenSeconds = 60, streak = 0 } = options;

  logger.info(`[EVAL] Starting evaluation for prompt: "${prompt}"`);

  // 1. Preprocess and extract features
  let processedImage, imageFeatures;
  try {
    const result = await preprocessImage(imageBuffer, { width: 256, height: 256 });
    processedImage = result.buffer;
    imageFeatures = await extractImageFeatures(processedImage);
    logger.info(`[EVAL] Image features: coverage=${imageFeatures.coverage}, edgeDensity=${imageFeatures.edgeDensity}, isBlank=${imageFeatures.isBlank}`);
  } catch (err) {
    logger.warn(`[EVAL] Image preprocessing failed: ${err.message}. Using raw buffer with default features.`);
    imageFeatures = { isBlank: false, coverage: 0.5, edgeDensity: 0.5, hasContent: true };
  }

  // 2. Blank drawing check
  if (imageFeatures.isBlank) {
    logger.warn('[EVAL] Blank drawing submitted — returning 0/F');
    return {
      score: 0,
      grade: 'F',
      confidence: 0,
      explanation: ['Blank drawing submitted.', 'Please draw on the canvas.'],
      labels: [],
      creativityScore: 0,
      objectRecognitionScore: 0,
      requiredFeaturesScore: 0,
      compositionScore: 0,
      strokeQualityScore: 0,
      reasoning: 'Blank canvas detected.',
      missingElements: ['All elements missing.'],
      strengths: [],
      weaknesses: ['Nothing was drawn'],
      breakdown: { aiScore: 0, reason: 'Blank drawing detected' },
    };
  }

  // 3. Call AI Vision evaluation (Gemini primary → Groq fallback)
  // This will THROW if all providers fail — no placeholder scores
  const aiResult = await evaluateWithGemini(imageBuffer, prompt);

  // 4. Calculate composite score using AI score as base
  const { score, breakdown } = calculateCompositeScore({
    aiScore: aiResult.similarityScore,
    drawingTimeSeconds,
    timeTakenSeconds,
    imageFeatures,
    streak,
  });

  const grade = getGrade(score);

  // Build explanation array for the UI
  const explanation = [
    aiResult.reasoning,
    ...(aiResult.missingElements || []).map(element => `Missing: ${element}`),
    ...(aiResult.strengths || []).map(strength => `Strength: ${strength}`),
  ];

  logger.info(`[EVAL COMPLETE] prompt="${prompt}", score=${score}, grade=${grade}, aiRawScore=${aiResult.similarityScore}`);

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
      aiRawScore: aiResult.similarityScore,
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
 * Evaluate a single drawing with timeout and automatic retries with exponential backoff.
 * 3 attempts total (initial + 2 retries).
 */
export async function evaluateDrawingWithRetry(imageBuffer, prompt, options = {}) {
  const timeoutMs = options.timeoutMs || 45000; // 45s timeout per attempt
  const maxAttempts = 3;

  logger.info(`[EVAL RETRY] Starting evaluation with up to ${maxAttempts} attempts for prompt "${prompt}"`);

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      logger.info(`[EVAL RETRY] Attempt ${attempt}/${maxAttempts} — sending AI request`);

      let timeoutId;
      const timeoutPromise = new Promise((_, reject) => {
        timeoutId = setTimeout(() => reject(new Error(`AI evaluation timed out after ${timeoutMs / 1000}s`)), timeoutMs);
      });

      const evalPromise = evaluateDrawing(imageBuffer, prompt, options);
      const result = await Promise.race([evalPromise, timeoutPromise]);
      clearTimeout(timeoutId);

      logger.info(`[EVAL RETRY] AI response received on attempt ${attempt}: score=${result.score}`);
      return result;
    } catch (err) {
      logger.warn(`[EVAL RETRY] Attempt ${attempt}/${maxAttempts} failed: ${err.message}`);
      if (attempt === maxAttempts) {
        logger.error(`[EVAL RETRY FATAL] All ${maxAttempts} evaluation attempts failed for prompt "${prompt}"`);
        throw err;
      }
      // Exponential backoff between retries
      const backoffMs = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
      logger.info(`[EVAL RETRY] Backing off ${Math.round(backoffMs)}ms before attempt ${attempt + 1}...`);
      await new Promise(resolve => setTimeout(resolve, backoffMs));
    }
  }
}

/**
 * Evaluate all drawings for a game session in parallel.
 *
 * IMPORTANT: Every drawing MUST be evaluated by AI. If AI fails for a player,
 * the error is thrown — never assign placeholder/random scores.
 */
export async function evaluateAllDrawings(submissions, prompt, drawingTimeSeconds, gameStartTime) {
  const results = {};
  const startTime = gameStartTime ? new Date(gameStartTime).getTime() : Date.now();
  const playerIds = Object.keys(submissions || {});

  logger.info(`[EVAL ALL] Starting parallel evaluation for ${playerIds.length} submission(s), prompt="${prompt}"`);

  const evaluationPromises = Object.entries(submissions || {}).map(async ([userId, submission]) => {
    const submittedAt = submission.submittedAt ? new Date(submission.submittedAt).getTime() : Date.now();
    const timeTakenSeconds = Math.round((submittedAt - startTime) / 1000);

    let drawingBuffer = null;
    if (submission.drawingBuffer) {
      if (Buffer.isBuffer(submission.drawingBuffer)) {
        drawingBuffer = submission.drawingBuffer;
      } else if (submission.drawingBuffer.type === 'Buffer') {
        drawingBuffer = Buffer.from(submission.drawingBuffer.data);
      } else {
        drawingBuffer = Buffer.from(submission.drawingBuffer);
      }
    }

    if (!drawingBuffer || drawingBuffer.length === 0) {
      logger.warn(`[EVAL ALL] No valid drawing buffer for user ${userId} — scoring as blank (0/F)`);
      results[userId] = {
        score: 0,
        grade: 'F',
        confidence: 0,
        explanation: ['No drawing submitted.'],
        labels: [],
        objectRecognitionScore: 0,
        requiredFeaturesScore: 0,
        compositionScore: 0,
        creativityScore: 0,
        strokeQualityScore: 0,
        reasoning: 'No drawing submitted.',
        missingElements: ['All elements missing.'],
        strengths: [],
        weaknesses: ['No submission'],
        breakdown: { aiScore: 0 },
      };
      return;
    }

    // This will THROW if AI evaluation completely fails — no placeholders
    logger.info(`[EVAL ALL] Evaluating drawing for user ${userId} (${drawingBuffer.length} bytes)`);
    const result = await evaluateDrawingWithRetry(drawingBuffer, prompt, {
      drawingTimeSeconds: drawingTimeSeconds || 60,
      timeTakenSeconds: Math.min(Math.max(0, timeTakenSeconds), drawingTimeSeconds || 60),
      streak: 0,
    });

    logger.info(`[EVAL ALL] User ${userId} scored: ${result.score} (${result.grade})`);
    results[userId] = result;
  });

  await Promise.all(evaluationPromises);

  logger.info(`[EVAL ALL] All ${playerIds.length} evaluations complete`);
  return results;
}

export default { evaluateDrawing, evaluateDrawingWithRetry, evaluateAllDrawings };
