import * as gameService from '../services/gameSession.service.js';
import logger from '../utils/logger.js';

/**
 * Game controller — handles game session CRUD and lifecycle.
 */

/**
 * POST /api/games — Create a new game session.
 */
export async function createGame(req, res, next) {
  try {
    const { difficulty, maxPlayers, drawingTime } = req.body;

    const session = await gameService.createGameSession(req.user, {
      difficulty,
      maxPlayers,
      drawingTime,
    });

    res.status(201).json({
      success: true,
      data: { session },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/games — List available game sessions.
 */
export async function listGames(req, res, next) {
  try {
    const games = await gameService.listAvailableGames();

    res.json({
      success: true,
      data: { games, count: games.length },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/games/:id — Get a specific game session.
 */
export async function getGame(req, res, next) {
  try {
    const session = await gameService.getGameSession(req.params.id);

    // Remove drawing buffers from response (too large)
    if (session.submissions) {
      for (const sub of Object.values(session.submissions)) {
        delete sub.drawingBuffer;
      }
    }

    res.json({
      success: true,
      data: { 
        session,
        serverTime: new Date().toISOString()
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/games/:id/join — Join a game session.
 */
export async function joinGame(req, res, next) {
  try {
    const session = await gameService.joinGameSession(req.params.id, req.user);

    res.json({
      success: true,
      data: { session },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/games/:id/ready — Mark player as ready.
 */
export async function readyUp(req, res, next) {
  try {
    const { session, allReady } = await gameService.setPlayerReady(
      req.params.id,
      req.user.uid
    );

    res.json({
      success: true,
      data: { session, allReady },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/games/:id/start — Start the game (host only).
 */
export async function startGame(req, res, next) {
  try {
    const session = await gameService.startGame(req.params.id, req.user.uid);

    // Emit real-time event
    const io = req.app.get('io');
    if (io) {
      io.to(req.params.id).emit('game:started', {
        prompt: session.prompt,
        drawingTimeSeconds: session.drawingTimeSeconds,
        startedAt: session.startedAt,
      });
    }

    res.json({
      success: true,
      data: { session },
    });
  } catch (error) {
    next(error);
  }
}
