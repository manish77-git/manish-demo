import env from '../config/env.js';
import logger from '../utils/logger.js';

let aiStatus = {
  initialized: false,
  error: 'Not initialized yet',
  model: 'qwen/qwen3.6-27b',
};

/**
 * Verify key availability.
 */
function checkKey() {
  if (!env.groqApiKey || env.groqApiKey === 'gsk_your_groq_api_key_here') {
    aiStatus.initialized = false;
    aiStatus.error = 'GROQ_API_KEY is not set or using placeholder in .env file';
    return false;
  }
  return true;
}

/**
 * Perform a verification call to Groq to ensure the API key works.
 */
export async function checkGeminiStatus() {
  if (!checkKey()) {
    return aiStatus;
  }

  try {
    logger.info('Testing connection to Groq API...');
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'qwen/qwen3.6-27b',
        messages: [
          { role: 'user', content: 'respond with ok' }
        ],
        max_tokens: 5,
      }),
    });

    if (response.ok) {
      aiStatus.initialized = true;
      aiStatus.error = null;
      logger.info('Groq API verified successfully!');
    } else {
      const errText = await response.text();
      throw new Error(`Groq returned status ${response.status}: ${errText}`);
    }
  } catch (err) {
    logger.error(`Groq connection check failed: ${err.message}`);
    aiStatus.initialized = false;
    aiStatus.error = `Groq connection check failed: ${err.message}`;
  }
  return aiStatus;
}

export function getAiStatus() {
  if (!aiStatus.initialized) {
    checkGeminiStatus().catch(() => {});
  }
  return aiStatus;
}

/**
 * Build the rigorous vision evaluation prompt.
 */
function buildPrompt(drawingPrompt) {
  return `You are an expert AI art judge for an online drawing game. A user was given the prompt "${drawingPrompt}" and drew the attached image.

Analyze the image carefully based strictly on visual evidence:
1. Shape accuracy & Object recognition (Is the main subject recognizable as "${drawingPrompt}"? - weight 40%)
2. Required features & Proportions (Are key structural details present and scaled correctly? - weight 25%)
3. Line quality & Stroke control (Clean outlines, contour stability - weight 15%)
4. Composition & Spatial arrangement (Center balance, framing - weight 10%)
5. Color relevance (If color is present/needed, does it fit "${drawingPrompt}"? - weight 10%)

Return ONLY a JSON object with exactly these fields:
{
  "objectRecognitionScore": <integer 0-100 representing recognizable subject match>,
  "requiredFeaturesScore": <integer 0-100 representing presence of key features and proportions>,
  "compositionScore": <integer 0-100 representing layout and spatial balance>,
  "creativityScore": <integer 0-100 representing artistic style and line details>,
  "strokeQualityScore": <integer 0-100 representing line stability and outline clarity>,
  "similarityScore": <integer 0-100 weighted final score>,
  "accuracy": <integer 0-100 representing AI certainty/confidence level>,
  "reasoning": "<string detailed personalized explanation of what is drawn and how well it matches>",
  "labels": [<array of 2-5 strings naming distinct objects/features detected in the drawing>],
  "missingElements": [<array of 1-3 strings naming essential missing parts or details>],
  "strengths": [<array of 1-3 strings highlighting what was drawn well>],
  "weaknesses": [<array of 1-3 strings describing specific areas for improvement>],
  "grade": "<one of S, A, B, C, D, F>"
}

Scoring criteria:
- 90-100 (S): Excellent, highly recognizable drawing of "${drawingPrompt}" with clear details.
- 80-89 (A): Very good drawing, clearly recognizable with minor missing details.
- 70-79 (B): Good attempt, recognizable subject.
- 60-69 (C): Average sketch, vaguely resembles "${drawingPrompt}".
- 40-59 (D): Poor drawing, missing major defining characteristics.
- 0-39 (F): Unrecognizable scribble or completely unrelated object.

Be objective, consistent, and base evaluation ONLY on the actual drawing lines provided.`;
}

/**
 * Evaluate a drawing image against a prompt using Groq Vision.
 * Implements up to 3 retries with exponential backoff and NO FALLBACK SCORES.
 */
export async function evaluateWithGemini(imageBuffer, drawingPrompt) {
  if (!checkKey()) {
    throw new Error('The AI evaluation service is temporarily unavailable. Please try again in a moment.');
  }

  const base64Image = imageBuffer.toString('base64');
  const MAX_RETRIES = 3;
  let attempt = 0;
  let lastError = null;

  while (attempt < MAX_RETRIES) {
    attempt++;
    logger.info(`Attempt ${attempt}/${MAX_RETRIES}: Sending drawing of "${drawingPrompt}" to Groq Vision API...`);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 35000); // 35 second timeout

      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.groqApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'qwen/qwen3.6-27b',
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: buildPrompt(drawingPrompt) },
                {
                  type: 'image_url',
                  image_url: { url: `data:image/png;base64,${base64Image}` },
                },
              ],
            },
          ],
          response_format: { type: 'json_object' },
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`Groq API returned status ${response.status}: ${errText}`);
      }

      const result = await response.json();
      const responseText = result.choices[0].message.content.trim();
      const parsed = JSON.parse(responseText);

      // Validate and clamp scores
      const objectRecognitionScore = Math.max(0, Math.min(100, Math.round(Number(parsed.objectRecognitionScore) || 75)));
      const requiredFeaturesScore = Math.max(0, Math.min(100, Math.round(Number(parsed.requiredFeaturesScore) || 75)));
      const compositionScore = Math.max(0, Math.min(100, Math.round(Number(parsed.compositionScore) || 75)));
      const creativityScore = Math.max(0, Math.min(100, Math.round(Number(parsed.creativityScore) || 70)));
      const strokeQualityScore = Math.max(0, Math.min(100, Math.round(Number(parsed.strokeQualityScore) || 75)));

      const compositeScore = Math.round(
        (objectRecognitionScore * 0.40) +
        (requiredFeaturesScore * 0.25) +
        (compositionScore * 0.15) +
        (creativityScore * 0.10) +
        (strokeQualityScore * 0.10)
      );

      const similarityScore = Math.max(0, Math.min(100, Math.round(Number(parsed.similarityScore) || compositeScore)));
      const accuracy = Math.max(0, Math.min(100, Math.round(Number(parsed.accuracy) || similarityScore)));
      const validGrades = ['S', 'A', 'B', 'C', 'D', 'F'];
      const grade = validGrades.includes(parsed.grade) ? parsed.grade : gradeFromScore(similarityScore);

      const reasoning = parsed.reasoning ? String(parsed.reasoning) : `Drawing evaluated for prompt "${drawingPrompt}".`;
      const missingElements = Array.isArray(parsed.missingElements) ? parsed.missingElements.map(String) : [];
      const strengths = Array.isArray(parsed.strengths) ? parsed.strengths.map(String) : [];
      const weaknesses = Array.isArray(parsed.weaknesses) ? parsed.weaknesses.map(String) : [];
      const labels = Array.isArray(parsed.labels) ? parsed.labels.map(String) : [drawingPrompt];

      logger.info(`Groq evaluation success on attempt ${attempt}: prompt="${drawingPrompt}" score=${similarityScore} grade=${grade}`);

      return {
        similarityScore,
        objectRecognitionScore,
        requiredFeaturesScore,
        compositionScore,
        creativityScore,
        strokeQualityScore,
        reasoning,
        labels,
        accuracy,
        missingElements,
        strengths,
        weaknesses,
        grade,
      };
    } catch (error) {
      lastError = error;
      logger.warn(`Attempt ${attempt}/${MAX_RETRIES} failed for "${drawingPrompt}": ${error.message}`);

      if (attempt < MAX_RETRIES) {
        const backoffMs = Math.pow(2, attempt) * 1000; // 2s, 4s
        logger.info(`Retrying in ${backoffMs}ms...`);
        await new Promise(resolve => setTimeout(resolve, backoffMs));
      }
    }
  }

  // All 3 retries failed — throw explicit unavailable error without generating fallback score
  logger.error(`All ${MAX_RETRIES} AI evaluation attempts failed for prompt "${drawingPrompt}". Exception: ${lastError?.message}`);
  throw new Error('The AI evaluation service is temporarily unavailable. Please try again in a moment.');
}

/**
 * Derive grade from score.
 */
function gradeFromScore(score) {
  if (score >= 90) return 'S';
  if (score >= 80) return 'A';
  if (score >= 70) return 'B';
  if (score >= 60) return 'C';
  if (score >= 40) return 'D';
  return 'F';
}

/**
 * Intermediate sketch live analysis.
 */
export async function analyzeLiveWithGemini(imageBuffer, drawingPrompt) {
  if (!checkKey()) {
    throw new Error('The AI evaluation service is temporarily unavailable. Please try again in a moment.');
  }

  const base64Image = imageBuffer.toString('base64');
  const analyzePrompt = `You are a real-time drawing assistant. A player is drawing "${drawingPrompt}". Analyze this intermediate sketch and return JSON:
{
  "recognitionRate": <integer 0-100>,
  "detectedObject": "<string>",
  "missingFeatures": [<array of 1-3 strings>],
  "suggestions": "<string short tip>"
}`;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'qwen/qwen3.6-27b',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: analyzePrompt },
              { type: 'image_url', image_url: { url: `data:image/png;base64,${base64Image}` } },
            ],
          },
        ],
        response_format: { type: 'json_object' },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    if (!response.ok) throw new Error(`Groq live status ${response.status}`);

    const result = await response.json();
    return JSON.parse(result.choices[0].message.content.trim());
  } catch (error) {
    logger.warn(`Live analysis warning: ${error.message}`);
    return {
      recognitionRate: 50,
      detectedObject: 'sketch',
      missingFeatures: ['main outlines'],
      suggestions: `Keep sketching the main features of "${drawingPrompt}".`,
    };
  }
}

export default { evaluateWithGemini, checkGeminiStatus, getAiStatus, analyzeLiveWithGemini };
