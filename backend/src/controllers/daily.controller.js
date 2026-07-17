import {
  getDailyChallenge,
  submitDailyResult,
  getDailyLeaderboard,
  getUserDailyHistory,
} from '../services/dailyChallenge.service.js';
import logger from '../utils/logger.js';

/**
 * Daily challenge controller.
 */

/**
 * GET /api/daily — Get today's daily challenge.
 */
export async function getTodaysChallenge(req, res, next) {
  try {
    const challenge = await getDailyChallenge();

    res.json({
      success: true,
      data: { challenge },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/daily/submit — Submit daily challenge result.
 */
export async function submitDaily(req, res, next) {
  try {
    const { score, aiLabels } = req.body;

    if (typeof score !== 'number' || score < 0 || score > 100) {
      return res.status(400).json({
        success: false,
        error: { message: 'Score must be a number between 0 and 100' },
      });
    }

    const result = await submitDailyResult(
      req.user.uid,
      req.user.displayName,
      score,
      aiLabels || [],
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/daily/leaderboard — Get today's daily leaderboard.
 */
export async function getDailyBoard(req, res, next) {
  try {
    const dateKey = req.query.date || null; // Optional: ?date=2026-07-09
    const limit = Math.min(parseInt(req.query.limit || '20', 10), 50);

    const leaderboard = await getDailyLeaderboard(dateKey, limit);

    res.json({
      success: true,
      data: {
        leaderboard,
        total: leaderboard.length,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/daily/me/history — My daily challenge history.
 */
export async function getMyDailyHistory(req, res, next) {
  try {
    const days = Math.min(parseInt(req.query.days || '7', 10), 30);
    const history = await getUserDailyHistory(req.user.uid, days);

    res.json({
      success: true,
      data: { history, days },
    });
  } catch (error) {
    next(error);
  }
}
