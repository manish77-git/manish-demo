import env from '../config/env.js';
import logger from '../utils/logger.js';

let aiStatus = {
  initialized: true,
  error: null,
  model: 'gemini-2.0-flash',
};

export function getAiStatus() {
  return aiStatus;
}

export async function checkGeminiStatus() {
  if (!env.geminiApiKey && !env.groqApiKey) {
    aiStatus.initialized = false;
    aiStatus.error = 'No AI API Key configured (neither GEMINI_API_KEY nor GROQ_API_KEY).';
    logger.error('[AI STATUS] No AI API keys configured. AI evaluation will fail.');
    return aiStatus;
  }
  aiStatus.initialized = true;
  aiStatus.error = null;
  const providers = [];
  if (env.geminiApiKey) providers.push('Gemini');
  if (env.groqApiKey) providers.push('Groq');
  logger.info(`[AI STATUS] AI providers available: ${providers.join(', ')}`);
  return aiStatus;
}

/**
 * Build structured vision prompt for AI evaluation.
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
 * Parse and validate AI response JSON, returning sanitized scores.
 */
function parseAndValidateResponse(parsed, drawingPrompt) {
  const objRec = Number(parsed.objectRecognitionScore);
  const reqFeat = Number(parsed.requiredFeaturesScore);
  const comp = Number(parsed.compositionScore);
  const creat = Number(parsed.creativityScore);
  const strokeQ = Number(parsed.strokeQualityScore);

  if (isNaN(objRec) || isNaN(reqFeat) || isNaN(comp) || isNaN(creat) || isNaN(strokeQ)) {
    throw new Error('AI response missing numeric score fields');
  }

  const objectRecognitionScore = Math.max(0, Math.min(100, Math.round(objRec)));
  const requiredFeaturesScore = Math.max(0, Math.min(100, Math.round(reqFeat)));
  const compositionScore = Math.max(0, Math.min(100, Math.round(comp)));
  const creativityScore = Math.max(0, Math.min(100, Math.round(creat)));
  const strokeQualityScore = Math.max(0, Math.min(100, Math.round(strokeQ)));

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
}

// ─── Gemini API Provider ─────────────────────────────────────────

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
    logger.info(`[AI REQUEST] Gemini API call: model=${modelName}, prompt="${drawingPrompt}"`);
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
      const err = new Error(`Gemini API [${modelName}] returned status ${res.status}: ${errText.substring(0, 300)}`);
      if (res.status === 429) err.isRateLimit = true;
      throw err;
    }

    const data = await res.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    if (!text) throw new Error('Gemini API returned empty response body');

    logger.info(`[AI RESPONSE] Gemini raw response received (${text.length} chars)`);
    return JSON.parse(text);
  } finally {
    clearTimeout(timeoutId);
  }
}

// ─── Groq Vision API Provider (Secondary Fallback) ───────────────

/**
 * Call Groq Vision API as secondary AI provider.
 * Uses llama-4-scout-17b-16e-instruct which supports image understanding.
 */
async function callGroqApi(imageBuffer, drawingPrompt) {
  const apiKey = env.groqApiKey;
  if (!apiKey) throw new Error('GROQ_API_KEY is not configured');

  const base64Image = imageBuffer.toString('base64');
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 45000);

  try {
    logger.info(`[AI REQUEST] Groq Vision API call: model=llama-3.2-11b-vision-instruct, prompt="${drawingPrompt}"`);
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'llama-3.2-11b-vision-instruct',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: buildPrompt(drawingPrompt) },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/png;base64,${base64Image}`,
                },
              },
            ],
          },
        ],
        temperature: 0.3,
        max_tokens: 1024,
        response_format: { type: 'json_object' },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Groq API returned status ${res.status}: ${errText.substring(0, 300)}`);
    }

    const data = await res.json();
    const text = data.choices?.[0]?.message?.content?.trim();
    if (!text) throw new Error('Groq API returned empty response body');

    logger.info(`[AI RESPONSE] Groq raw response received (${text.length} chars)`);
    return JSON.parse(text);
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Sleep with exponential backoff and jitter.
 */
function backoffSleep(attempt) {
  const baseMs = Math.pow(2, attempt) * 1000;
  const jitter = Math.random() * 1000;
  return new Promise(resolve => setTimeout(resolve, baseMs + jitter));
}

// ─── Main Evaluation Entry Point ─────────────────────────────────

/**
 * Evaluate drawing image using AI Vision with multi-provider fallback.
 *
 * Strategy:
 * 1. Try Gemini (primary) with multiple models, 3 retries each with exponential backoff + jitter
 * 2. If all Gemini attempts fail, try Groq Vision (secondary) with 3 retries
 * 3. If BOTH providers fail completely, THROW an error — never return placeholder scores
 */
export async function evaluateWithGemini(imageBuffer, drawingPrompt) {
  const MAX_RETRIES = 2;
  // Models supported by v1beta API endpoint
  const geminiModels = ['gemini-2.0-flash', 'gemini-2.0-flash-lite'];

  let lastError = null;

  // ─── Phase 1: Try Gemini Models ───────────────────────────
  if (env.geminiApiKey) {
    for (const model of geminiModels) {
      let attempt = 0;
      while (attempt < MAX_RETRIES) {
        attempt++;
        logger.info(`[AI EVAL] Gemini attempt ${attempt}/${MAX_RETRIES} with model [${model}] for prompt "${drawingPrompt}"`);

        try {
          const parsed = await callGeminiApi(imageBuffer, drawingPrompt, model);
          const result = parseAndValidateResponse(parsed, drawingPrompt);

          logger.info(`[AI EVAL SUCCESS] Gemini [${model}]: prompt="${drawingPrompt}" score=${result.similarityScore} grade=${result.grade}`);
          return result;
        } catch (error) {
          lastError = error;
          logger.warn(`[AI EVAL FAIL] Gemini attempt ${attempt}/${MAX_RETRIES} with [${model}]: ${error.message}`);

          if (error.isRateLimit) {
            logger.warn(`[AI EVAL RATE LIMIT] Model [${model}] quota exceeded (429). Switching to next model immediately.`);
            break; // Break inner loop to try next model quota bucket right away
          }

          if (attempt < MAX_RETRIES) {
            await backoffSleep(attempt);
          }
        }
      }
    }
    logger.warn(`[AI EVAL] All Gemini attempts exhausted for prompt "${drawingPrompt}". Falling back to Groq Vision.`);
  } else {
    logger.warn('[AI EVAL] No GEMINI_API_KEY configured. Skipping Gemini, trying Groq.');
  }

  // ─── Phase 2: Try Groq Vision (Secondary Provider) ────────
  if (env.groqApiKey) {
    let attempt = 0;
    while (attempt < MAX_RETRIES) {
      attempt++;
      logger.info(`[AI EVAL] Groq attempt ${attempt}/${MAX_RETRIES} for prompt "${drawingPrompt}"`);

      try {
        const parsed = await callGroqApi(imageBuffer, drawingPrompt);
        const result = parseAndValidateResponse(parsed, drawingPrompt);

        logger.info(`[AI EVAL SUCCESS] Groq Vision: prompt="${drawingPrompt}" score=${result.similarityScore} grade=${result.grade}`);
        return result;
      } catch (error) {
        lastError = error;
        logger.warn(`[AI EVAL FAIL] Groq attempt ${attempt}/${MAX_RETRIES}: ${error.message}`);

        if (attempt < MAX_RETRIES) {
          await backoffSleep(attempt);
        }
      }
    }
    logger.warn(`[AI EVAL] All Groq attempts exhausted for prompt "${drawingPrompt}".`);
  } else {
    logger.warn('[AI EVAL] No GROQ_API_KEY configured. No secondary provider available.');
  }

  // ─── Phase 3: Total Failure — THROW, never return placeholder ──
  const errorMsg = `All AI evaluation providers failed for prompt "${drawingPrompt}" after exhausting all retries. Last error: ${lastError?.message}`;
  logger.error(`[AI EVAL FATAL] ${errorMsg}`);
  throw new Error(errorMsg);
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
  // Live analysis is best-effort — use Gemini if available, Groq as fallback, graceful default on failure
  const apiKey = env.geminiApiKey;
  const groqKey = env.groqApiKey;

  try {
    if (apiKey) {
      const base64Image = imageBuffer.toString('base64');
      const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`, {
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

      if (res.ok) {
        const data = await res.json();
        return JSON.parse(data.candidates[0].content.parts[0].text);
      }
    }

    // Fallback to Groq for live analysis
    if (groqKey) {
      const base64Image = imageBuffer.toString('base64');
      const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${groqKey}`,
        },
        body: JSON.stringify({
          model: 'llama-4-scout-17b-16e-instruct',
          messages: [{
            role: 'user',
            content: [
              { type: 'text', text: `Analyze intermediate sketch for prompt "${drawingPrompt}" and return JSON: {"recognitionRate": 70, "detectedObject": "cat", "missingFeatures": ["ears"], "suggestions": "Add ears"}` },
              { type: 'image_url', image_url: { url: `data:image/png;base64,${base64Image}` } }
            ]
          }],
          temperature: 0.3,
          max_tokens: 256,
          response_format: { type: 'json_object' },
        }),
      });

      if (res.ok) {
        const data = await res.json();
        return JSON.parse(data.choices[0].message.content);
      }
    }
  } catch (_) {
    // Live analysis is non-critical — fall through to default
  }

  return {
    recognitionRate: 50,
    detectedObject: 'sketch',
    missingFeatures: ['main outlines'],
    suggestions: `Keep sketching the main features of "${drawingPrompt}".`,
  };
}

export default { evaluateWithGemini, checkGeminiStatus, getAiStatus, analyzeLiveWithGemini };
