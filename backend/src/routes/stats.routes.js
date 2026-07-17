import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getMyStats, getUserStats, getMyHistory } from '../controllers/stats.controller.js';

const router = Router();

/**
 * Player stats routes.
 *
 * GET  /api/stats/me          → My detailed stats (auth required)
 * GET  /api/stats/me/history  → My game history (auth required)
 * GET  /api/stats/:userId     → Public player stats
 */

router.get('/me', authMiddleware, getMyStats);
router.get('/me/history', authMiddleware, getMyHistory);
router.get('/:userId', getUserStats);

export default router;
