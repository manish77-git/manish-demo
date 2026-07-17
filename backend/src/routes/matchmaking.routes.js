import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import {
  joinMatchmakingQueue,
  leaveMatchmakingQueue,
  getMyQueueStatus,
  getMatchmakingStats,
} from '../controllers/matchmaking.controller.js';

const router = Router();

/**
 * Matchmaking routes.
 *
 * POST /api/matchmaking/join   → Join queue (auth required)
 * POST /api/matchmaking/leave  → Leave queue (auth required)
 * GET  /api/matchmaking/status → My queue status (auth required)
 * GET  /api/matchmaking/stats  → Global queue stats (public)
 */

router.post('/join', authMiddleware, joinMatchmakingQueue);
router.post('/leave', authMiddleware, leaveMatchmakingQueue);
router.get('/status', authMiddleware, getMyQueueStatus);
router.get('/stats', getMatchmakingStats);

export default router;
