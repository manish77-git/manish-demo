import multer from 'multer';
import * as gameService from '../services/gameSession.service.js';
import { evaluateDrawing } from '../services/aiEvaluation.service.js';
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

    // Get game session to verify state and get prompt
    const session = await gameService.getGameSession(gameId);

    if (session.status !== 'drawing') {
      return res.status(400).json({
        success: false,
        error: { message: 'Game is not in drawing phase' },
      });
    }

    // Record submission
    const { allSubmitted } = await gameService.submitDrawing(gameId, req.user.uid, {
      drawingBuffer: req.file.buffer,
      drawingUrl: null, // Would upload to Firebase Storage in production
    });

    // Evaluate this drawing immediately
    const startTime = new Date(session.startedAt).getTime();
    const timeTaken = Math.round((Date.now() - startTime) / 1000);

    const evaluation = await evaluateDrawing(req.file.buffer, session.prompt, {
      drawingTimeSeconds: session.drawingTimeSeconds,
      timeTakenSeconds: Math.min(timeTaken, session.drawingTimeSeconds),
    });

    // Emit score to the player
    const io = req.app.get('io');
    if (io) {
      io.to(gameId).emit('drawing:submitted', {
        userId: req.user.uid,
        displayName: req.user.displayName,
      });
    }

    // If all players submitted, finalize the game
    if (allSubmitted) {
      logger.info(`All drawings submitted for game ${gameId}, finalizing...`);

      // Get all submissions and evaluate
      const updatedSession = await gameService.getGameSession(gameId);
      const scores = {};

      for (const [userId, submission] of Object.entries(updatedSession.submissions)) {
        if (userId === req.user.uid) {
          scores[userId] = {
            score: evaluation.score,
            labels: evaluation.labels,
            displayName: req.user.displayName,
          };
        } else if (submission.drawingBuffer) {
          const otherEval = await evaluateDrawing(
            Buffer.from(submission.drawingBuffer),
            session.prompt,
            { drawingTimeSeconds: session.drawingTimeSeconds }
          );
          const player = session.players.find(p => p.userId === userId);
          scores[userId] = {
            score: otherEval.score,
            labels: otherEval.labels,
            displayName: player?.displayName || 'Unknown',
          };
        }
      }

      // Finalize game with scores
      await gameService.finalizeGame(gameId, scores);

      // Emit results
      const rankings = rankPlayers(scores);
      if (io) {
        io.to(gameId).emit('game:results', { rankings, prompt: session.prompt });
      }
    }

    res.json({
      success: true,
      data: {
        score: evaluation.score,
        grade: evaluation.grade,
        confidence: evaluation.confidence,
        explanation: evaluation.explanation,
        labels: evaluation.labels,
        breakdown: evaluation.breakdown,
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

    if (session.status !== 'results') {
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
