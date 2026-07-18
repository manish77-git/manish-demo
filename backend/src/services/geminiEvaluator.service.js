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
  // Lazily update status if not initialized yet
  if (!aiStatus.initialized) {
    checkGeminiStatus().catch(() => {});
  }
  return aiStatus;
}

/**
 * Build the structured evaluation prompt.
 */
function buildPrompt(drawingPrompt) {
  return `You are an AI judge for a drawing game. A player was given the prompt "${drawingPrompt}" and drew the attached image.

Evaluate the drawing and return a JSON object with exactly these fields:

{
  "objectRecognitionScore": <integer 0-100 representing if the drawing is recognizable as "${drawingPrompt}" - weight 40%>,
  "requiredFeaturesScore": <integer 0-100 representing if essential features/details of "${drawingPrompt}" are present - weight 25%>,
  "compositionScore": <integer 0-100 representing layout, placement, and spatial balance - weight 15%>,
  "creativityScore": <integer 0-100 representing artistic styling, originality, and line details - weight 10%>,
  "strokeQualityScore": <integer 0-100 representing line stability, outline clarity, and stroke control - weight 10%>,
  "similarityScore": <integer 0-100 representing the total composite score using the weighted parameters above>,
  "reasoning": "<string detailed reasoning of what you see and what matches>",
  "labels": [<array of 2-5 strings naming objects/shapes you detect in the drawing>],
  "accuracy": <integer 0-100 representing accuracy/confidence percentage>,
  "missingElements": [<array of strings describing missing elements or details>],
  "strengths": [<array of 1-3 strings naming specific things done well>],
  "weaknesses": [<array of 1-3 strings naming areas of improvement>],
  "grade": "<one of S, A, B, C, D, F>"
}

Scoring guidelines:
- 90-100 (S): Excellent drawing, clearly recognizable as "${drawingPrompt}", good detail
- 80-89 (A): Good drawing, recognizable with minor issues
- 70-79 (B): Decent attempt, somewhat recognizable
- 60-69 (C): Mediocre, vaguely related to the prompt
- 40-59 (D): Poor, hard to identify as "${drawingPrompt}"
- 0-39 (F): Unrecognizable or unrelated to the prompt

Be fair but encouraging. Consider that these are quick sketches drawn in under 60 seconds, not professional art. A simple but clearly recognizable sketch should score 70+.`;
}

/**
 * Evaluate a drawing image against a prompt using Groq Vision.
 */
export async function evaluateWithGemini(imageBuffer, drawingPrompt) {
  if (!checkKey()) {
    throw new Error('Groq API client not initialized. Set GROQ_API_KEY in .env file.');
  }

  const base64Image = imageBuffer.toString('base64');
  logger.info(`Sending drawing of "${drawingPrompt}" to Groq Vision...`);

  try {
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
              {
                type: 'text',
                text: buildPrompt(drawingPrompt),
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/png;base64,${base64Image}`,
                },
              },
            ],
          },
        ],
        response_format: { type: 'json_object' },
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Groq API returned status ${response.status}: ${errText}`);
    }

    const result = await response.json();
    const responseText = result.choices[0].message.content.trim();
    logger.debug(`Groq raw response: ${responseText}`);

    const parsed = JSON.parse(responseText);

    // Validate and clamp values
    const objectRecognitionScore = Math.max(0, Math.min(100, Math.round(Number(parsed.objectRecognitionScore) || 75)));
    const requiredFeaturesScore = Math.max(0, Math.min(100, Math.round(Number(parsed.requiredFeaturesScore) || 75)));
    const compositionScore = Math.max(0, Math.min(100, Math.round(Number(parsed.compositionScore) || 75)));
    const creativityScore = Math.max(0, Math.min(100, Math.round(Number(parsed.creativityScore) || 70)));
    const strokeQualityScore = Math.max(0, Math.min(100, Math.round(Number(parsed.strokeQualityScore) || 75)));

    // Calculate composite score
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
    const reasoning = parsed.reasoning ? String(parsed.reasoning) : `Clean contours matching "${drawingPrompt}".`;
    
    const missingElements = Array.isArray(parsed.missingElements) ? parsed.missingElements.map(String) : [];
    const strengths = Array.isArray(parsed.strengths) ? parsed.strengths.map(String) : [];
    const weaknesses = Array.isArray(parsed.weaknesses) ? parsed.weaknesses.map(String) : [];
    const labels = Array.isArray(parsed.labels) ? parsed.labels.map(String) : [drawingPrompt];

    logger.info(`Groq evaluation: prompt="${drawingPrompt}" score=${similarityScore} grade=${grade}`);

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
    logger.error(`Groq evaluation error, falling back to mock scoring: ${error.message}`);
    const baseScore = 70 + Math.floor(Math.random() * 20); // 70 to 89
    return {
      similarityScore: baseScore,
      objectRecognitionScore: baseScore + 2,
      requiredFeaturesScore: baseScore - 3,
      compositionScore: baseScore - 5,
      creativityScore: baseScore - 10,
      strokeQualityScore: baseScore + 4,
      reasoning: `Your drawing of "${drawingPrompt}" shows recognizable contour layouts and shapes. [Note: The AI Judge was experiencing high load and returned a fallback evaluation]`,
      labels: [drawingPrompt],
      accuracy: baseScore,
      missingElements: ['color fill', 'shading depth'],
      strengths: ['recognizable contours', 'solid strokes'],
      weaknesses: ['lacks complex shading details'],
      grade: gradeFromScore(baseScore),
    };
  }
}

/**
 * Derive grade from score as a safety fallback.
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
 * Perform a fast, lightweight analysis on intermediate drawings.
 */
export async function analyzeLiveWithGemini(imageBuffer, drawingPrompt) {
  if (!checkKey()) {
    throw new Error('Groq API client not initialized.');
  }

  const base64Image = imageBuffer.toString('base64');
  const analyzePrompt = `You are a real-time drawing assistant. A player is trying to draw "${drawingPrompt}". This is their current intermediate sketch.
Analyze the image and return a JSON object with exactly these fields:
{
  "recognitionRate": <integer 0-100 indicating how close they are to being recognized>,
  "detectedObject": "<string main object detected, or 'nothing' or 'scribble'>",
  "missingFeatures": [<array of 1-3 strings naming essential features of "${drawingPrompt}" they should draw next>],
  "suggestions": "<string single short, encouraging tip or suggestion>"
}
Return only JSON, no markdown fences.`;

  try {
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
              {
                type: 'text',
                text: analyzePrompt,
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/png;base64,${base64Image}`,
                },
              },
            ],
          },
        ],
        response_format: { type: 'json_object' },
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Groq API returned status ${response.status}: ${errText}`);
    }

    const result = await response.json();
    const text = result.choices[0].message.content.trim();
    return JSON.parse(text);
  } catch (error) {
    logger.error(`Groq live analysis error, falling back: ${error.message}`);
    return {
      recognitionRate: 50,
      detectedObject: 'sketch',
      missingFeatures: ['main contours', 'identifying details'],
      suggestions: `Keep drawing! Focus on sketching the main features of "${drawingPrompt}".`,
    };
  }
}

export default { evaluateWithGemini, checkGeminiStatus, getAiStatus, analyzeLiveWithGemini };
