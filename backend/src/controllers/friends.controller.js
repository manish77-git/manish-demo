import friendsService from '../services/friends.service.js';

export async function searchUsers(req, res, next) {
  try {
    const { query } = req.query;
    const users = await friendsService.searchUsers(query, req.user.uid);
    res.json({ success: true, data: { users } });
  } catch (err) {
    next(err);
  }
}

export async function sendRequest(req, res, next) {
  try {
    const { target } = req.body;
    const request = await friendsService.sendFriendRequest(req.user.uid, target);
    res.json({ success: true, data: { request } });
  } catch (err) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
}

export async function acceptRequest(req, res, next) {
  try {
    const { requesterId } = req.body;
    const result = await friendsService.acceptFriendRequest(req.user.uid, requesterId);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

export async function declineOrCancelRequest(req, res, next) {
  try {
    const { targetUid } = req.body;
    const result = await friendsService.cancelOrDeclineRequest(req.user.uid, targetUid);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

export async function removeFriend(req, res, next) {
  try {
    const { friendId } = req.params;
    const result = await friendsService.removeFriend(req.user.uid, friendId);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

export async function getFriends(req, res, next) {
  try {
    const friends = await friendsService.getFriends(req.user.uid);
    res.json({ success: true, data: { friends } });
  } catch (err) {
    next(err);
  }
}

export async function getPendingRequests(req, res, next) {
  try {
    const requests = await friendsService.getPendingRequests(req.user.uid);
    res.json({ success: true, data: requests });
  } catch (err) {
    next(err);
  }
}
