import { getFirestore } from '../config/firebase.js';
import { checkAndAwardBadges } from './achievements.service.js';
import logger from '../utils/logger.js';

/**
 * Player stats service — detailed analytics and history for players.
 */

/**
 * Record a completed game to a player's history.
 */
export async function recordGameToHistory(userId, gameData) {
  try {
    const db = getFirestore();
    const historyRef = db.collection('users').doc(userId)
      .collection('gameHistory');

    const record = {
      gameId: gameData.gameId,
      prompt: gameData.prompt,
      promptDifficulty: gameData.difficulty || 'unknown',
      score: gameData.score,
      rank: gameData.rank,
      totalPlayers: gameData.totalPlayers,
      aiLabels: gameData.labels || [],
      isWin: gameData.rank === 1,
      playedAt: new Date().toISOString(),
    };

    await historyRef.add(record);
    logger.debug(`Recorded game history for user ${userId}: score=${record.score}`);

    // Update aggregate stats
    await updatePlayerStats(userId, record);

    return record;
  } catch (error) {
    logger.warn('Failed to record game history:', error.message);
  }
}

/**
 * Update aggregate player stats after a game.
 */
async function updatePlayerStats(userId, gameRecord) {
  try {
    const db = getFirestore();
    const statsRef = db.collection('playerStats').doc(userId);
    const statsDoc = await statsRef.get();

    if (statsDoc.exists) {
      const stats = statsDoc.data();
      const newGames = (stats.totalGames || 0) + 1;
      const newWins = (stats.totalWins || 0) + (gameRecord.isWin ? 1 : 0);
      const newTotalScore = (stats.totalScore || 0) + gameRecord.score;
      const currentStreak = gameRecord.isWin ? (stats.currentWinStreak || 0) + 1 : 0;

      await statsRef.update({
        totalGames: newGames,
        totalWins: newWins,
        totalScore: newTotalScore,
        averageScore: Math.round(newTotalScore / newGames),
        bestScore: Math.max(stats.bestScore || 0, gameRecord.score),
        worstScore: Math.min(stats.worstScore || 100, gameRecord.score),
        currentWinStreak: currentStreak,
        longestWinStreak: Math.max(stats.longestWinStreak || 0, currentStreak),
        winRate: Math.round((newWins / newGames) * 100),
        lastPlayedAt: gameRecord.playedAt,
        // Track per-difficulty stats
        [`difficultyStats.${gameRecord.promptDifficulty}.games`]:
          (stats.difficultyStats?.[gameRecord.promptDifficulty]?.games || 0) + 1,
        [`difficultyStats.${gameRecord.promptDifficulty}.totalScore`]:
          (stats.difficultyStats?.[gameRecord.promptDifficulty]?.totalScore || 0) + gameRecord.score,
        [`difficultyStats.${gameRecord.promptDifficulty}.wins`]:
          (stats.difficultyStats?.[gameRecord.promptDifficulty]?.wins || 0) + (gameRecord.isWin ? 1 : 0),
        // Track score distribution
        [`scoreDistribution.${_getScoreBucket(gameRecord.score)}`]:
          (stats.scoreDistribution?.[_getScoreBucket(gameRecord.score)] || 0) + 1,
      });
      // Trigger achievement check
      await checkAndAwardBadges(userId, {
        score: gameRecord.score,
        rank: gameRecord.rank,
        isWin: gameRecord.isWin,
      }, {
        totalGames: newGames,
        totalWins: newWins,
        currentWinStreak: currentStreak,
      });
    } else {
      // First game — initialize stats
      const firstStats = {
        userId,
        totalGames: 1,
        totalWins: gameRecord.isWin ? 1 : 0,
        totalScore: gameRecord.score,
        averageScore: gameRecord.score,
        bestScore: gameRecord.score,
        worstScore: gameRecord.score,
        currentWinStreak: gameRecord.isWin ? 1 : 0,
        longestWinStreak: gameRecord.isWin ? 1 : 0,
        winRate: gameRecord.isWin ? 100 : 0,
        favoriteDifficulty: gameRecord.promptDifficulty,
        lastPlayedAt: gameRecord.playedAt,
        joinedAt: gameRecord.playedAt,
        difficultyStats: {
          [gameRecord.promptDifficulty]: {
            games: 1,
            totalScore: gameRecord.score,
            wins: gameRecord.isWin ? 1 : 0,
          },
        },
        scoreDistribution: {
          [_getScoreBucket(gameRecord.score)]: 1,
        },
      };

      await statsRef.set(firstStats);

      // Trigger achievement check
      await checkAndAwardBadges(userId, {
        score: gameRecord.score,
        rank: gameRecord.rank,
        isWin: gameRecord.isWin,
      }, {
        totalGames: 1,
        totalWins: gameRecord.isWin ? 1 : 0,
        currentWinStreak: gameRecord.isWin ? 1 : 0,
      });
    }
  } catch (error) {
    logger.warn('Failed to update player stats:', error.message);
  }
}

/**
 * Get detailed player stats.
 */
export async function getPlayerStats(userId) {
  try {
    const db = getFirestore();
    const statsDoc = await db.collection('playerStats').doc(userId).get();

    if (!statsDoc.exists) {
      return {
        totalGames: 0,
        totalWins: 0,
        averageScore: 0,
        bestScore: 0,
        currentWinStreak: 0,
        longestWinStreak: 0,
        winRate: 0,
        difficultyStats: {},
        scoreDistribution: {},
      };
    }

    return statsDoc.data();
  } catch (error) {
    logger.warn('Failed to get player stats:', error.message);
    return {
      totalGames: 0,
      totalWins: 0,
      averageScore: 0,
      bestScore: 0,
      currentWinStreak: 0,
      longestWinStreak: 0,
      winRate: 0,
      difficultyStats: {},
      scoreDistribution: {},
    };
  }
}

/**
 * Get a player's game history.
 */
export async function getGameHistory(userId, options = {}) {
  const { limit = 20, offset = 0 } = options;

  try {
    const db = getFirestore();
    const snapshot = await db.collection('users').doc(userId)
      .collection('gameHistory')
      .orderBy('playedAt', 'desc')
      .limit(limit)
      .offset(offset)
      .get();

    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    logger.warn('Failed to get game history:', error.message);
    return [];
  }
}

/**
 * Bucket a score into a distribution category.
 */
function _getScoreBucket(score) {
  if (score >= 90) return '90-100';
  if (score >= 80) return '80-89';
  if (score >= 70) return '70-79';
  if (score >= 60) return '60-69';
  if (score >= 40) return '40-59';
  if (score >= 20) return '20-39';
  return '0-19';
}

export default { recordGameToHistory, getPlayerStats, getGameHistory };
