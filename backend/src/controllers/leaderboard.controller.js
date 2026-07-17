import { getFirestore } from '../config/firebase.js';
import logger from '../utils/logger.js';

/**
 * Leaderboard controller — global rankings.
 */

/**
 * GET /api/leaderboard — Get top players.
 */
export async function getLeaderboard(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 100);
    const db = getFirestore();

    let entries = [];
    try {
      const snapshot = await db.collection('leaderboard')
        .orderBy('averageScore', 'desc')
        .limit(limit)
        .get();

      entries = snapshot.docs.map((doc, index) => ({
        rank: index + 1,
        ...doc.data(),
      }));
    } catch (dbError) {
      logger.warn('Firestore unavailable for leaderboard, returning empty:', dbError.message);
    }

    res.json({
      success: true,
      data: { leaderboard: entries, total: entries.length },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/leaderboard/me — Get current user's rank and stats.
 */
export async function getMyRank(req, res, next) {
  try {
    const db = getFirestore();
    const myDoc = await db.collection('leaderboard').doc(req.user.uid).get();

    if (!myDoc.exists) {
      return res.json({
        success: true,
        data: {
          rank: null,
          stats: {
            totalScore: 0,
            gamesPlayed: 0,
            gamesWon: 0,
            averageScore: 0,
          },
          message: 'Play a game to appear on the leaderboard!',
        },
      });
    }

    const myData = myDoc.data();

    // Calculate rank by counting how many players have a higher average score
    const higherScoreCount = await db.collection('leaderboard')
      .where('averageScore', '>', myData.averageScore)
      .count()
      .get();

    const rank = higherScoreCount.data().count + 1;

    res.json({
      success: true,
      data: {
        rank,
        stats: {
          totalScore: myData.totalScore,
          gamesPlayed: myData.gamesPlayed,
          gamesWon: myData.gamesWon,
          averageScore: myData.averageScore,
          lastPlayedAt: myData.lastPlayedAt,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}
