import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { submitDrawing, uploadMiddleware, getGameDrawings, evaluateSoloDrawing, analyzeDrawingLive } from '../controllers/drawing.controller.js';
import { getAiStatus } from '../services/geminiEvaluator.service.js';

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
router.get('/:gameId', getGameDrawings);

export default router;
