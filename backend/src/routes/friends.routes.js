import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import * as friendsController from '../controllers/friends.controller.js';

const router = Router();

router.use(authMiddleware);

router.get('/search', friendsController.searchUsers);
router.get('/', friendsController.getFriends);
router.get('/requests', friendsController.getPendingRequests);
router.post('/request', friendsController.sendRequest);
router.post('/accept', friendsController.acceptRequest);
router.post('/decline', friendsController.declineOrCancelRequest);
router.delete('/:friendId', friendsController.removeFriend);

export default router;
