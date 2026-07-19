import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { submitDrawing, uploadMiddleware, getGameDrawings, evaluateSoloDrawing, analyzeDrawingLive, getGameDrawingImage } from '../controllers/drawing.controller.js';
import { getAiStatus } from '../services/geminiEvaluator.service.js';

import { getRandomPrompt } from '../models/prompts.js';

const router = Router();

router.get('/ai-status', (req, res) => {
  res.json({
    success: true,
    data: getAiStatus(),
  });
});

router.post('/submit', authMiddleware, uploadMiddleware, submitDrawing);
router.post('/evaluate-solo', uploadMiddleware, evaluateSoloDrawing);
router.post('/analyze', uploadMiddleware, analyzeDrawingLive);
router.get('/random-prompt', (req, res) => {
  const { difficulty, category } = req.query;
  const promptObj = getRandomPrompt(difficulty || 'all', category || 'all');
  res.json({
    success: true,
    data: promptObj,
  });
});
router.get('/:gameId/image/:userId', getGameDrawingImage);
router.get('/:gameId', getGameDrawings);

export default router;
