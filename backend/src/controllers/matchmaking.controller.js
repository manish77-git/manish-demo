import {
  joinQueue,
  leaveQueue,
  getQueueStatus,
  getQueueStats,
} from '../services/matchmaking.service.js';
import logger from '../utils/logger.js';

/**
 * Matchmaking controller — queue management for automatic game pairing.
 */

/**
 * POST /api/matchmaking/join — Join the matchmaking queue.
 */
export async function joinMatchmakingQueue(req, res, next) {
  try {
    const { difficulty = 'all' } = req.body;

    const validDifficulties = ['all', 'easy', 'medium', 'hard'];
    if (!validDifficulties.includes(difficulty)) {
      return res.status(400).json({
        success: false,
        error: { message: `Invalid difficulty. Must be one of: ${validDifficulties.join(', ')}` },
      });
    }

    const result = joinQueue(req.user, { difficulty });

    res.json({
      success: true,
      data: {
        message: 'Joined matchmaking queue',
        ...result,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/matchmaking/leave — Leave the matchmaking queue.
 */
export async function leaveMatchmakingQueue(req, res, next) {
  try {
    const removed = leaveQueue(req.user.uid);

    res.json({
      success: true,
      data: {
        message: removed ? 'Left matchmaking queue' : 'Not in queue',
        wasInQueue: removed,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/matchmaking/status — Get my queue status.
 */
export async function getMyQueueStatus(req, res, next) {
  try {
    const status = getQueueStatus(req.user.uid);

    res.json({
      success: true,
      data: status,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/matchmaking/stats — Get global queue statistics.
 */
export async function getMatchmakingStats(req, res, next) {
  try {
    const stats = getQueueStats();

    res.json({
      success: true,
      data: { queues: stats },
    });
  } catch (error) {
    next(error);
  }
}
