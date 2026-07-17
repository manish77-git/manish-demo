import logger from '../utils/logger.js';

/**
 * Scoring service — computes the final composite score for a drawing submission.
 */

/**
 * Calculate composite score from AI evaluation results.
 *
 * Scoring breakdown:
 * - AI Similarity Score (primary): 80% weight
 * - Speed Bonus: up to 10% bonus
 * - Drawing Quality Bonus: up to 10% bonus
 *
 * @param {Object} params
 * @param {number} params.aiScore - Raw AI similarity score (0-100)
 * @param {number} params.drawingTimeSeconds - Max allowed drawing time
 * @param {number} params.timeTakenSeconds - Actual time taken to submit
 * @param {Object} params.imageFeatures - Image feature analysis results
 * @param {number} params.streak - Current win streak (consecutive wins)
 * @returns {{ score: number, breakdown: Object }}
 */
export function calculateCompositeScore({
  aiScore = 0,
  drawingTimeSeconds = 60,
  timeTakenSeconds = 60,
  imageFeatures = {},
  streak = 0,
}) {
  // 1. AI Score (80% weight)
  const weightedAiScore = aiScore * 0.8;

  // 2. Speed bonus (up to 10 points)
  // Faster submissions get more points, but only if they have decent AI score
  let speedBonus = 0;
  if (aiScore > 20 && timeTakenSeconds < drawingTimeSeconds) {
    const timeRatio = 1 - (timeTakenSeconds / drawingTimeSeconds);
    speedBonus = Math.round(timeRatio * 10);
  }

  // 3. Quality bonus (up to 10 points)
  // Based on drawing complexity and coverage
  let qualityBonus = 0;
  if (imageFeatures.hasContent) {
    const coverageBonus = Math.min(5, imageFeatures.coverage * 10);
    const detailBonus = Math.min(5, imageFeatures.edgeDensity * 15);
    qualityBonus = Math.round(coverageBonus + detailBonus);
  }

  // 4. Streak bonus (small multiplier)
  const streakMultiplier = 1 + Math.min(streak * 0.02, 0.1); // Max 10% boost

  // Calculate final score
  const rawScore = (weightedAiScore + speedBonus + qualityBonus) * streakMultiplier;
  const finalScore = Math.min(100, Math.max(0, Math.round(rawScore)));

  const breakdown = {
    aiScore,
    weightedAiScore: Math.round(weightedAiScore),
    speedBonus,
    qualityBonus,
    streakMultiplier: Math.round(streakMultiplier * 100) / 100,
    rawScore: Math.round(rawScore),
    finalScore,
  };

  logger.debug('Score breakdown:', breakdown);
  return { score: finalScore, breakdown };
}

/**
 * Rank players by score, handling ties.
 * @param {Object} playerScores - { userId: { score, ... } }
 * @returns {Array<{ userId: string, rank: number, score: number }>}
 */
export function rankPlayers(playerScores) {
  const sorted = Object.entries(playerScores)
    .map(([userId, data]) => ({ userId, score: data.score, ...data }))
    .sort((a, b) => b.score - a.score);

  let currentRank = 1;
  return sorted.map((player, index) => {
    if (index > 0 && player.score < sorted[index - 1].score) {
      currentRank = index + 1;
    }
    return { ...player, rank: currentRank };
  });
}

export default { calculateCompositeScore, rankPlayers };
