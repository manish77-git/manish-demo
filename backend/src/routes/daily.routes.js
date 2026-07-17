import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import {
  getTodaysChallenge,
  submitDaily,
  getDailyBoard,
  getMyDailyHistory,
} from '../controllers/daily.controller.js';

const router = Router();

/**
 * Daily challenge routes.
 *
 * GET  /api/daily               → Today's challenge (public)
 * POST /api/daily/submit        → Submit result (auth)
 * GET  /api/daily/leaderboard   → Today's daily leaderboard (public)
 * GET  /api/daily/me/history    → My daily history (auth)
 */

router.get('/', getTodaysChallenge);
router.post('/submit', authMiddleware, submitDaily);
router.get('/leaderboard', getDailyBoard);
router.get('/me/history', authMiddleware, getMyDailyHistory);

export default router;
