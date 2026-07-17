import { getFirestore } from '../config/firebase.js';
import logger from '../utils/logger.js';

/**
 * Achievements & Badges system.
 * Automatically awards badges based on player milestones.
 */

// Badge definitions
export const BADGES = {
  // Game milestones
  FIRST_GAME:     { id: 'first_game',     name: 'Rookie Artist',       emoji: '🎨', description: 'Play your first game', tier: 'bronze' },
  TEN_GAMES:      { id: 'ten_games',      name: 'Regular',             emoji: '🖌️', description: 'Play 10 games', tier: 'silver' },
  FIFTY_GAMES:    { id: 'fifty_games',     name: 'Dedicated Artist',    emoji: '🎭', description: 'Play 50 games', tier: 'gold' },
  HUNDRED_GAMES:  { id: 'hundred_games',   name: 'Drawing Legend',      emoji: '👑', description: 'Play 100 games', tier: 'platinum' },

  // Win milestones
  FIRST_WIN:      { id: 'first_win',       name: 'First Victory',       emoji: '🏆', description: 'Win your first game', tier: 'bronze' },
  TEN_WINS:       { id: 'ten_wins',        name: 'Champion',            emoji: '⭐', description: 'Win 10 games', tier: 'silver' },
  FIFTY_WINS:     { id: 'fifty_wins',      name: 'Grand Master',        emoji: '💫', description: 'Win 50 games', tier: 'gold' },

  // Score milestones
  SCORE_80:       { id: 'score_80',        name: 'Sharp Eye',           emoji: '👁️', description: 'Score 80+ in a game', tier: 'bronze' },
  SCORE_90:       { id: 'score_90',        name: 'Precision Artist',    emoji: '🎯', description: 'Score 90+ in a game', tier: 'silver' },
  SCORE_95:       { id: 'score_95',        name: 'Near Perfect',        emoji: '💎', description: 'Score 95+ in a game', tier: 'gold' },
  PERFECT_100:    { id: 'perfect_100',     name: 'Perfection',          emoji: '🌟', description: 'Score a perfect 100', tier: 'platinum' },

  // Streak milestones
  STREAK_3:       { id: 'streak_3',        name: 'Hat Trick',           emoji: '🔥', description: 'Win 3 games in a row', tier: 'bronze' },
  STREAK_5:       { id: 'streak_5',        name: 'On Fire',             emoji: '🔥', description: 'Win 5 games in a row', tier: 'silver' },
  STREAK_10:      { id: 'streak_10',       name: 'Unstoppable',         emoji: '⚡', description: 'Win 10 games in a row', tier: 'gold' },

  // Special
  SPEED_DEMON:    { id: 'speed_demon',     name: 'Speed Demon',         emoji: '⏱️', description: 'Submit in under 15 seconds', tier: 'silver' },
  NIGHT_OWL:      { id: 'night_owl',       name: 'Night Owl',           emoji: '🦉', description: 'Play a game between midnight and 5 AM', tier: 'bronze' },
  DAILY_WARRIOR:  { id: 'daily_warrior',   name: 'Daily Warrior',       emoji: '📅', description: 'Complete 7 daily challenges', tier: 'silver' },
  DAILY_MASTER:   { id: 'daily_master',    name: 'Daily Master',        emoji: '🗓️', description: 'Complete 30 daily challenges', tier: 'gold' },
};

/**
 * Check and award badges after a game.
 * @param {string} userId
 * @param {Object} gameResult - { score, rank, isWin, submittedInSeconds }
 * @param {Object} playerStats - Current aggregate player stats
 * @returns {Array<Object>} Newly awarded badges
 */
export async function checkAndAwardBadges(userId, gameResult, playerStats) {
  const newBadges = [];

  try {
    const existingBadges = await getUserBadges(userId);
    const existingIds = new Set(existingBadges.map(b => b.badgeId));

    // Check each potential badge
    const checks = [
      // Game milestones
      { badge: BADGES.FIRST_GAME,    condition: playerStats.totalGames >= 1 },
      { badge: BADGES.TEN_GAMES,     condition: playerStats.totalGames >= 10 },
      { badge: BADGES.FIFTY_GAMES,   condition: playerStats.totalGames >= 50 },
      { badge: BADGES.HUNDRED_GAMES, condition: playerStats.totalGames >= 100 },

      // Win milestones
      { badge: BADGES.FIRST_WIN,     condition: playerStats.totalWins >= 1 },
      { badge: BADGES.TEN_WINS,      condition: playerStats.totalWins >= 10 },
      { badge: BADGES.FIFTY_WINS,    condition: playerStats.totalWins >= 50 },

      // Score milestones (from this game)
      { badge: BADGES.SCORE_80,      condition: gameResult.score >= 80 },
      { badge: BADGES.SCORE_90,      condition: gameResult.score >= 90 },
      { badge: BADGES.SCORE_95,      condition: gameResult.score >= 95 },
      { badge: BADGES.PERFECT_100,   condition: gameResult.score >= 100 },

      // Streak milestones
      { badge: BADGES.STREAK_3,      condition: playerStats.currentWinStreak >= 3 },
      { badge: BADGES.STREAK_5,      condition: playerStats.currentWinStreak >= 5 },
      { badge: BADGES.STREAK_10,     condition: playerStats.currentWinStreak >= 10 },

      // Special
      { badge: BADGES.SPEED_DEMON,   condition: gameResult.submittedInSeconds && gameResult.submittedInSeconds < 15 },
      { badge: BADGES.NIGHT_OWL,     condition: _isNightOwlHour() },
    ];

    for (const { badge, condition } of checks) {
      if (condition && !existingIds.has(badge.id)) {
        newBadges.push(badge);
      }
    }

    // Save new badges
    if (newBadges.length > 0) {
      await saveBadges(userId, newBadges);
      logger.info(`Awarded ${newBadges.length} badge(s) to ${userId}: ${newBadges.map(b => b.name).join(', ')}`);
    }
  } catch (error) {
    logger.warn('Failed to check badges:', error.message);
  }

  return newBadges;
}

/**
 * Check and award daily challenge badges.
 */
export async function checkDailyBadges(userId, dailyChallengesCompleted) {
  const newBadges = [];

  try {
    const existingBadges = await getUserBadges(userId);
    const existingIds = new Set(existingBadges.map(b => b.badgeId));

    if (dailyChallengesCompleted >= 7 && !existingIds.has(BADGES.DAILY_WARRIOR.id)) {
      newBadges.push(BADGES.DAILY_WARRIOR);
    }
    if (dailyChallengesCompleted >= 30 && !existingIds.has(BADGES.DAILY_MASTER.id)) {
      newBadges.push(BADGES.DAILY_MASTER);
    }

    if (newBadges.length > 0) {
      await saveBadges(userId, newBadges);
    }
  } catch (error) {
    logger.warn('Failed to check daily badges:', error.message);
  }

  return newBadges;
}

/**
 * Get all badges for a user.
 */
export async function getUserBadges(userId) {
  try {
    const db = getFirestore();
    const snapshot = await db.collection('users').doc(userId)
      .collection('badges')
      .orderBy('awardedAt', 'desc')
      .get();

    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    logger.warn('Failed to get user badges:', error.message);
    return [];
  }
}

/**
 * Save new badges to Firestore.
 */
async function saveBadges(userId, badges) {
  try {
    const db = getFirestore();
    const batch = db.batch();

    for (const badge of badges) {
      const ref = db.collection('users').doc(userId)
        .collection('badges').doc(badge.id);
      batch.set(ref, {
        badgeId: badge.id,
        name: badge.name,
        emoji: badge.emoji,
        description: badge.description,
        tier: badge.tier,
        awardedAt: new Date().toISOString(),
      });
    }

    await batch.commit();
  } catch (error) {
    logger.warn('Failed to save badges:', error.message);
  }
}

/**
 * Get all available badges with unlock status for a user.
 */
export async function getAllBadgesWithStatus(userId) {
  const userBadges = await getUserBadges(userId);
  const unlockedIds = new Set(userBadges.map(b => b.badgeId));

  return Object.values(BADGES).map(badge => ({
    ...badge,
    unlocked: unlockedIds.has(badge.id),
    awardedAt: userBadges.find(b => b.badgeId === badge.id)?.awardedAt || null,
  }));
}

function _isNightOwlHour() {
  const hour = new Date().getHours();
  return hour >= 0 && hour < 5;
}

export default {
  BADGES,
  checkAndAwardBadges,
  checkDailyBadges,
  getUserBadges,
  getAllBadgesWithStatus,
};
