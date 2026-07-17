import { getPlayerStats, getGameHistory } from '../services/playerStats.service.js';
import logger from '../utils/logger.js';

/**
 * Player stats controller — player analytics and game history.
 */

/**
 * GET /api/stats/me — Get my detailed stats.
 */
export async function getMyStats(req, res, next) {
  try {
    const stats = await getPlayerStats(req.user.uid);

    res.json({
      success: true,
      data: { stats },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/stats/:userId — Get another player's stats (public view).
 */
export async function getUserStats(req, res, next) {
  try {
    const { userId } = req.params;
    const stats = await getPlayerStats(userId);

    // Remove sensitive fields for public view
    const publicStats = {
      totalGames: stats.totalGames,
      totalWins: stats.totalWins,
      averageScore: stats.averageScore,
      bestScore: stats.bestScore,
      longestWinStreak: stats.longestWinStreak,
      winRate: stats.winRate,
    };

    res.json({
      success: true,
      data: { stats: publicStats },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/stats/me/history — Get my game history.
 */
export async function getMyHistory(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit || '20', 10), 50);
    const offset = Math.max(parseInt(req.query.offset || '0', 10), 0);

    const history = await getGameHistory(req.user.uid, { limit, offset });

    res.json({
      success: true,
      data: {
        history,
        count: history.length,
        limit,
        offset,
      },
    });
  } catch (error) {
    next(error);
  }
}
