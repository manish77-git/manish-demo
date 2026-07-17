import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getLeaderboard, getMyRank } from '../controllers/leaderboard.controller.js';

const router = Router();

router.get('/', getLeaderboard); // Public
router.get('/me', authMiddleware, getMyRank);

export default router;
