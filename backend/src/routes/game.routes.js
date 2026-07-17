import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import {
  createGame,
  listGames,
  getGame,
  joinGame,
  readyUp,
  startGame,
} from '../controllers/game.controller.js';

const router = Router();

router.post('/', authMiddleware, createGame);
router.get('/', listGames); // Public listing
router.get('/:id', getGame);
router.post('/:id/join', authMiddleware, joinGame);
router.post('/:id/ready', authMiddleware, readyUp);
router.post('/:id/start', authMiddleware, startGame);

export default router;
