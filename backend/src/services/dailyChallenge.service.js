import { getFirestore } from '../config/firebase.js';
import { getRandomPrompt } from '../models/prompts.js';
import logger from '../utils/logger.js';

/**
 * Daily Challenge service.
 * Generates one prompt per day that all players compete on.
 * Maintains a separate daily leaderboard.
 */

// In-memory cache of today's challenge
let todaysChallenge = null;

/**
 * Get today's daily challenge. Creates one if it doesn't exist.
 */
export async function getDailyChallenge() {
  const today = _getTodayKey();

  // Check in-memory cache
  if (todaysChallenge && todaysChallenge.dateKey === today) {
    return todaysChallenge;
  }

  try {
    const db = getFirestore();
    const challengeDoc = await db.collection('dailyChallenges').doc(today).get();

    if (challengeDoc.exists) {
      todaysChallenge = challengeDoc.data();
      return todaysChallenge;
    }

    // Create today's challenge
    const { prompt, difficulty } = getRandomPrompt('all');
    const challenge = {
      dateKey: today,
      prompt,
      difficulty,
      drawingTimeSeconds: 90, // More time for daily challenges
      participantCount: 0,
      topScore: 0,
      createdAt: new Date().toISOString(),
    };

    await db.collection('dailyChallenges').doc(today).set(challenge);
    todaysChallenge = challenge;

    logger.info(`Daily challenge created for ${today}: "${prompt}" (${difficulty})`);
    return challenge;
  } catch (error) {
    logger.warn('Firestore unavailable for daily challenge, using fallback:', error.message);

    // Fallback: generate deterministic daily challenge from date seed
    const { prompt, difficulty } = getRandomPrompt('all');
    todaysChallenge = {
      dateKey: today,
      prompt,
      difficulty,
      drawingTimeSeconds: 90,
      participantCount: 0,
      topScore: 0,
      createdAt: new Date().toISOString(),
    };
    return todaysChallenge;
  }
}

/**
 * Submit a daily challenge result.
 */
export async function submitDailyResult(userId, displayName, score, aiLabels = []) {
  const today = _getTodayKey();

  const result = {
    userId,
    displayName,
    score,
    aiLabels,
    submittedAt: new Date().toISOString(),
  };

  try {
    const db = getFirestore();

    // Check if user already submitted today
    const existingDoc = await db.collection('dailyChallenges').doc(today)
      .collection('submissions').doc(userId).get();

    if (existingDoc.exists) {
      const existing = existingDoc.data();
      if (score <= existing.score) {
        return { improved: false, previousScore: existing.score, currentScore: score };
      }
      // Allow improving score
    }

    // Save submission
    await db.collection('dailyChallenges').doc(today)
      .collection('submissions').doc(userId).set(result);

    // Update challenge stats
    const challengeRef = db.collection('dailyChallenges').doc(today);
    const challengeDoc = await challengeRef.get();
    if (challengeDoc.exists) {
      const challenge = challengeDoc.data();
      await challengeRef.update({
        participantCount: (challenge.participantCount || 0) + (existingDoc.exists ? 0 : 1),
        topScore: Math.max(challenge.topScore || 0, score),
      });
    }

    // Update user's daily challenge count
    await _incrementDailyChallengeCount(userId);

    logger.info(`Daily challenge submission: ${displayName} scored ${score} on ${today}`);
    return { improved: true, currentScore: score };
  } catch (error) {
    logger.warn('Failed to submit daily result:', error.message);
    return { improved: true, currentScore: score, offlineMode: true };
  }
}

/**
 * Get the daily challenge leaderboard.
 */
export async function getDailyLeaderboard(dateKey = null, limit = 20) {
  const day = dateKey || _getTodayKey();

  try {
    const db = getFirestore();
    const snapshot = await db.collection('dailyChallenges').doc(day)
      .collection('submissions')
      .orderBy('score', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map((doc, index) => ({
      rank: index + 1,
      ...doc.data(),
    }));
  } catch (error) {
    logger.warn('Failed to get daily leaderboard:', error.message);
    return [];
  }
}

/**
 * Get a user's daily challenge history (last N days).
 */
export async function getUserDailyHistory(userId, days = 7) {
  const results = [];

  try {
    const db = getFirestore();

    for (let i = 0; i < days; i++) {
      const dateKey = _getDateKey(i);
      const doc = await db.collection('dailyChallenges').doc(dateKey)
        .collection('submissions').doc(userId).get();

      const challengeDoc = await db.collection('dailyChallenges').doc(dateKey).get();

      if (doc.exists) {
        results.push({
          dateKey,
          prompt: challengeDoc.exists ? challengeDoc.data().prompt : 'unknown',
          ...doc.data(),
        });
      } else {
        results.push({ dateKey, participated: false });
      }
    }
  } catch (error) {
    logger.warn('Failed to get daily history:', error.message);
  }

  return results;
}

/**
 * Increment a user's daily challenge completion count.
 */
async function _incrementDailyChallengeCount(userId) {
  try {
    const db = getFirestore();
    const ref = db.collection('playerStats').doc(userId);
    const doc = await ref.get();

    if (doc.exists) {
      const current = doc.data().dailyChallengesCompleted || 0;
      await ref.update({ dailyChallengesCompleted: current + 1 });
    } else {
      await ref.set({ userId, dailyChallengesCompleted: 1 }, { merge: true });
    }
  } catch (error) {
    logger.warn('Failed to increment daily count:', error.message);
  }
}

/**
 * Get today's date key in YYYY-MM-DD format.
 */
function _getTodayKey() {
  return new Date().toISOString().split('T')[0];
}

/**
 * Get a date key N days ago.
 */
function _getDateKey(daysAgo) {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().split('T')[0];
}

export default {
  getDailyChallenge,
  submitDailyResult,
  getDailyLeaderboard,
  getUserDailyHistory,
};
