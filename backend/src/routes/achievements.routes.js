import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getMyBadges, getAllMyBadges, getUserBadgesPublic } from '../controllers/achievements.controller.js';

const router = Router();

/**
 * Achievements routes.
 *
 * GET  /api/achievements/me      → My unlocked badges (auth)
 * GET  /api/achievements/me/all  → All badges with unlock status (auth)
 * GET  /api/achievements/:userId → Public player badges
 */

router.get('/me', authMiddleware, getMyBadges);
router.get('/me/all', authMiddleware, getAllMyBadges);
router.get('/:userId', getUserBadgesPublic);

export default router;
