import multer from 'multer';
import * as gameService from '../services/gameSession.service.js';
import { evaluateDrawing, evaluateAllDrawings } from '../services/aiEvaluation.service.js';
import { rankPlayers } from '../services/scoring.service.js';
import { analyzeLiveWithGemini } from '../services/geminiEvaluator.service.js';
import logger from '../utils/logger.js';

// Configure multer for in-memory file upload
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

export const uploadMiddleware = upload.single('drawing');

/**
 * Triggers match evaluation, evaluates all drawings in parallel, saves scores, calculates winner, and emits results.
 */
export async function triggerMatchEvaluation(gameId, io) {
  const canEvaluate = await gameService.transitionToEvaluating(gameId);
  if (!canEvaluate) {
    logger.info(`[EVAL TRIGGER] Already in progress or completed for game ${gameId}`);
    return;
  }

  logger.info(`[EVAL TRIGGER] Evaluation started for game ${gameId}`);

  // Cancel the server-side auto-eval timer since evaluation is starting now
  try {
    const { default: lobbyManagerModule } = await import('../services/lobbyManager.js');
    const room = lobbyManagerModule.rooms?.get(gameId);
    if (room && room._autoEvalTimer) {
      clearTimeout(room._autoEvalTimer);
      room._autoEvalTimer = null;
      logger.info(`[EVAL TRIGGER] Auto-eval timer cancelled for game ${gameId} (evaluation started early)`);
    }
  } catch (_) {}

  if (io) {
    io.to(gameId).emit('game:status', { status: 'evaluating', gameId });
  }

  const session = await gameService.getGameSession(gameId);
  const submissions = session.submissions || {};

  // Evaluate all drawings in parallel
  const evalResults = await evaluateAllDrawings(
    submissions,
    session.prompt,
    session.drawingTimeSeconds,
    session.startedAt
  );

  const scores = {};
  for (const [userId, evalData] of Object.entries(evalResults)) {
    const player = session.players.find(p => p.userId === userId);
    scores[userId] = {
      ...evalData,
      displayName: player?.displayName || 'Player',
      photoUrl: player?.photoUrl || null,
      prompt: session.prompt,
    };
  }

  // Finalize game with scores in DB
  await gameService.finalizeGame(gameId, scores);
  logger.info(`[LOG] Scores saved to DB for game ${gameId}`);

  // Build drawings map with base64 images for side-by-side comparison
  const drawingsMap = {};
  for (const [userId, scoreData] of Object.entries(scores)) {
    const sub = submissions[userId];
    let base64Img = null;
    if (sub?.drawingBuffer) {
      const buf = Buffer.isBuffer(sub.drawingBuffer)
        ? sub.drawingBuffer
        : (sub.drawingBuffer.type === 'Buffer' ? Buffer.from(sub.drawingBuffer.data) : Buffer.from(sub.drawingBuffer));
      base64Img = `data:image/png;base64,${buf.toString('base64')}`;
    }

    drawingsMap[userId] = {
      userId,
      displayName: scoreData.displayName || 'Player',
      score: scoreData.score,
      grade: scoreData.grade,
      breakdown: scoreData.breakdown,
      explanation: scoreData.explanation,
      strengths: scoreData.strengths || [],
      weaknesses: scoreData.weaknesses || [],
      imageData: base64Img,
    };
  }

  // Calculate winner
  const rankings = rankPlayers(scores);
  const sortedDrawings = Object.values(drawingsMap).sort((a, b) => b.score - a.score);
  const isTie = sortedDrawings.length >= 2 && sortedDrawings[0].score === sortedDrawings[1].score;
  const winnerId = isTie ? 'tie' : (sortedDrawings[0]?.userId || null);
  logger.info(`[LOG] Winner calculated for game ${gameId}: ${winnerId}`);

  // Emit results to all players immediately
  if (io) {
    io.to(gameId).emit('game:results', {
      gameId,
      prompt: session.prompt,
      rankings,
      drawings: drawingsMap,
      winnerId,
    });
    logger.info(`[LOG] Results screen opened / emitted via socket for game ${gameId}`);
  }

  return { rankings, drawingsMap, winnerId };
}

/**
 * POST /api/drawings/submit — Submit a drawing for evaluation.
 */
export async function submitDrawing(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No drawing image provided' },
      });
    }

    const { gameId } = req.body;
    if (!gameId) {
      return res.status(400).json({
        success: false,
        error: { message: 'Game ID is required' },
      });
    }

    // Get game session to verify state
    const session = await gameService.getGameSession(gameId);

    if (session.status !== 'drawing' && session.status !== 'evaluating') {
      return res.status(400).json({
        success: false,
        error: { message: 'Game is not in drawing phase' },
      });
    }

    // Record submission
    const { allSubmitted } = await gameService.submitDrawing(gameId, req.user.uid, {
      drawingBuffer: req.file.buffer,
      drawingUrl: null,
    });

    logger.info(`[LOG] Player submitted: ${req.user.uid} (${req.user.displayName})`);

    const io = req.app.get('io');
    if (io) {
      io.to(gameId).emit('drawing:submitted', {
        userId: req.user.uid,
        displayName: req.user.displayName,
      });
      logger.info(`[LOG] Opponent submitted notification sent for ${req.user.uid}`);
    }

    // If all players submitted, immediately trigger parallel evaluation
    if (allSubmitted) {
      logger.info(`[SUBMIT] All players submitted for game ${gameId}, starting AI evaluation...`);
      triggerMatchEvaluation(gameId, io).catch(err => {
        logger.error(`[SUBMIT] Error in match evaluation for game ${gameId}: ${err.message}`);
      });
    } else {
      logger.info(`[SUBMIT] Waiting for more submissions in game ${gameId}`);
    }

    res.json({
      success: true,
      data: {
        message: 'Drawing submitted successfully',
        allSubmitted,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/drawings/:gameId — Get all drawings for a game.
 */
export async function getGameDrawings(req, res, next) {
  try {
    const session = await gameService.getGameSession(req.params.gameId);

    if (session.status !== 'completed' && session.status !== 'results') {
      return res.status(400).json({
        success: false,
        error: { message: 'Game results not yet available' },
      });
    }

    // Remove raw buffers, return only metadata and scores
    const drawings = {};
    for (const [userId, submission] of Object.entries(session.submissions || {})) {
      drawings[userId] = {
        score: submission.score,
        displayName: submission.displayName || 'Player',
        photoUrl: submission.photoUrl,
        grade: submission.grade,
        explanation: submission.explanation,
        objectRecognitionScore: submission.objectRecognitionScore,
        requiredFeaturesScore: submission.requiredFeaturesScore,
        compositionScore: submission.compositionScore,
        creativityScore: submission.creativityScore,
        strokeQualityScore: submission.strokeQualityScore,
        strengths: submission.strengths,
        weaknesses: submission.weaknesses,
        aiLabels: submission.aiLabels,
        submittedAt: submission.submittedAt,
        drawingUrl: submission.drawingUrl,
      };
    }

    const rankings = rankPlayers(
      Object.fromEntries(
        Object.entries(drawings).map(([uid, d]) => [uid, { score: d.score }])
      )
    );

    res.json({
      success: true,
      data: { drawings, rankings, prompt: session.prompt },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/drawings/:gameId/image/:userId — Get raw drawing image as PNG stream.
 */
export async function getGameDrawingImage(req, res, next) {
  try {
    const { gameId, userId } = req.params;
    const session = await gameService.getGameSession(gameId);

    const submission = session.submissions?.[userId];
    if (!submission || !submission.drawingBuffer) {
      return res.status(404).json({
        success: false,
        error: { message: 'Drawing not found for this user' },
      });
    }

    let buffer;
    if (Buffer.isBuffer(submission.drawingBuffer)) {
      buffer = submission.drawingBuffer;
    } else if (submission.drawingBuffer && submission.drawingBuffer.type === 'Buffer') {
      buffer = Buffer.from(submission.drawingBuffer.data);
    } else {
      buffer = Buffer.from(submission.drawingBuffer);
    }

    res.type('image/png').send(buffer);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/drawings/evaluate-solo — Evaluate drawing for practice/solo mode.
 */
export async function evaluateSoloDrawing(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No drawing image provided' },
      });
    }

    const { prompt } = req.body;
    if (!prompt) {
      return res.status(400).json({
        success: false,
        error: { message: 'Prompt is required' },
      });
    }

    logger.info(`Evaluating solo drawing for prompt: "${prompt}"`);

    const evaluation = await evaluateDrawing(req.file.buffer, prompt, {
      drawingTimeSeconds: 60,
      timeTakenSeconds: 30,
    });

    res.json({
      success: true,
      data: {
        score: evaluation.score,
        grade: evaluation.grade,
        confidence: evaluation.confidence,
        explanation: evaluation.explanation,
        labels: evaluation.labels,
        objectRecognitionScore: evaluation.objectRecognitionScore,
        requiredFeaturesScore: evaluation.requiredFeaturesScore,
        compositionScore: evaluation.compositionScore,
        creativityScore: evaluation.creativityScore,
        strokeQualityScore: evaluation.strokeQualityScore,
        strengths: evaluation.strengths,
        weaknesses: evaluation.weaknesses,
        breakdown: evaluation.breakdown,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/drawings/analyze — Perform lightweight live analysis of intermediate sketch strokes.
 */
export async function analyzeDrawingLive(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No drawing image provided' },
      });
    }

    const { prompt } = req.body;
    if (!prompt) {
      return res.status(400).json({
        success: false,
        error: { message: 'Prompt is required' },
      });
    }

    const analysis = await analyzeLiveWithGemini(req.file.buffer, prompt);
    res.json({
      success: true,
      data: analysis,
    });
  } catch (error) {
    next(error);
  }
}
