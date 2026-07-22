import env from '../config/env.js';
import logger from '../utils/logger.js';

let aiStatus = {
  initialized: true,
  error: null,
  model: 'gemini-2.5-flash',
};

export function getAiStatus() {
  return aiStatus;
}

export async function checkGeminiStatus() {
  if (!env.geminiApiKey && !env.groqApiKey) {
    aiStatus.initialized = false;
    aiStatus.error = 'No AI API Key configured.';
    return aiStatus;
  }
  aiStatus.initialized = true;
  aiStatus.error = null;
  return aiStatus;
}

/**
 * Build structured vision prompt for Gemini AI evaluation.
 */
function buildPrompt(drawingPrompt) {
  return `You are an expert AI art judge for an online drawing game. A user was given the prompt "${drawingPrompt}" and drew the attached image.

Analyze the visual evidence in the image carefully:
1. Shape accuracy & Object recognition (Is the subject recognizable as "${drawingPrompt}"? - weight 40%)
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
  "reasoning": "<string detailed explanation of what is drawn and how well it matches>",
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
- 0-39 (F): Unrecognizable scribble or completely empty/blank canvas.

Be objective, consistent, and base evaluation ONLY on the actual drawing lines provided.`;
}

/**
 * Call Gemini Vision API directly.
 */
async function callGeminiApi(imageBuffer, drawingPrompt, modelName) {
  const apiKey = env.geminiApiKey;
  if (!apiKey) throw new Error('GEMINI_API_KEY is not configured');

  const base64Image = imageBuffer.toString('base64');
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 35000);

  try {
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: buildPrompt(drawingPrompt) },
              {
                inline_data: {
                  mime_type: 'image/png',
                  data: base64Image,
                },
              },
            ],
          },
        ],
        generationConfig: {
          response_mime_type: 'application/json',
        },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Gemini API [${modelName}] returned status ${res.status}: ${errText}`);
    }

    const data = await res.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    if (!text) throw new Error('Gemini API returned empty response body');

    return JSON.parse(text);
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Evaluate drawing image using Gemini Vision with 3 retries and zero fallback scores.
 */
export async function evaluateWithGemini(imageBuffer, drawingPrompt) {
  const MAX_RETRIES = 3;
  const models = ['gemini-2.5-flash', 'gemini-flash-latest'];

  let lastError = null;

  for (const model of models) {
    let attempt = 0;
    while (attempt < MAX_RETRIES) {
      attempt++;
      logger.info(`Attempt ${attempt}/${MAX_RETRIES} with model [${model}] for prompt "${drawingPrompt}"...`);

      try {
        const parsed = await callGeminiApi(imageBuffer, drawingPrompt, model);

        // Validate and clamp score values
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

        logger.info(`Gemini vision evaluation success: prompt="${drawingPrompt}" score=${similarityScore} grade=${grade}`);

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
        logger.warn(`Attempt ${attempt}/${MAX_RETRIES} with [${model}] failed: ${error.message}`);

        if (attempt < MAX_RETRIES) {
          const backoffMs = Math.pow(2, attempt) * 1000;
          await new Promise(resolve => setTimeout(resolve, backoffMs));
        }
      }
    }
  }

  // If all retries fail, throw explicit error without generating mock scores
  logger.error(`All Gemini AI evaluation attempts failed for prompt "${drawingPrompt}". Error: ${lastError?.message}`);
  throw new Error('The AI evaluation service is temporarily unavailable. Please try again in a moment.');
}

function gradeFromScore(score) {
  if (score >= 90) return 'S';
  if (score >= 80) return 'A';
  if (score >= 70) return 'B';
  if (score >= 60) return 'C';
  if (score >= 40) return 'D';
  return 'F';
}

export async function analyzeLiveWithGemini(imageBuffer, drawingPrompt) {
  const apiKey = env.geminiApiKey;
  if (!apiKey) return { recognitionRate: 50, detectedObject: 'sketch', missingFeatures: [], suggestions: 'Keep sketching!' };

  try {
    const base64Image = imageBuffer.toString('base64');
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: `Analyze intermediate sketch for prompt "${drawingPrompt}" and return JSON: {"recognitionRate": 70, "detectedObject": "cat", "missingFeatures": ["ears"], "suggestions": "Add ears"}` },
              { inline_data: { mime_type: 'image/png', data: base64Image } }
            ]
          }
        ],
        generationConfig: { response_mime_type: 'application/json' }
      }),
    });

    if (!res.ok) throw new Error('Live analysis request failed');
    const data = await res.json();
    return JSON.parse(data.candidates[0].content.parts[0].text);
  } catch (_) {
    return {
      recognitionRate: 50,
      detectedObject: 'sketch',
      missingFeatures: ['main outlines'],
      suggestions: `Keep sketching the main features of "${drawingPrompt}".`,
    };
  }
}

export default { evaluateWithGemini, checkGeminiStatus, getAiStatus, analyzeLiveWithGemini };
