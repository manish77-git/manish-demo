import { getUserBadges, getAllBadgesWithStatus, BADGES } from '../services/achievements.service.js';
import logger from '../utils/logger.js';

/**
 * Achievements controller.
 */

/**
 * GET /api/achievements/me — Get my unlocked badges.
 */
export async function getMyBadges(req, res, next) {
  try {
    const badges = await getUserBadges(req.user.uid);

    res.json({
      success: true,
      data: {
        badges,
        totalUnlocked: badges.length,
        totalAvailable: Object.keys(BADGES).length,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/achievements/me/all — Get all badges with unlock status.
 */
export async function getAllMyBadges(req, res, next) {
  try {
    const badges = await getAllBadgesWithStatus(req.user.uid);

    res.json({
      success: true,
      data: {
        badges,
        unlocked: badges.filter(b => b.unlocked).length,
        total: badges.length,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/achievements/:userId — Get a player's badges (public).
 */
export async function getUserBadgesPublic(req, res, next) {
  try {
    const badges = await getUserBadges(req.params.userId);

    res.json({
      success: true,
      data: {
        badges,
        totalUnlocked: badges.length,
      },
    });
  } catch (error) {
    next(error);
  }
}
