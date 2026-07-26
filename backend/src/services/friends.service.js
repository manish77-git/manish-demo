import { getFirestore } from '../config/firebase.js';
import logger from '../utils/logger.js';

/**
 * Friends Service — handles user search, friend requests, and friend list management.
 */
class FriendsService {
  /**
   * Search users by username or display name (case insensitive).
   */
  async searchUsers(query, currentUserId) {
    if (!query || query.trim().length === 0) return [];

    const db = getFirestore();
    const cleanQuery = query.trim().toLowerCase();

    const snapshot = await db.collection('users').get();
    const users = [];

    snapshot.docs.forEach((doc) => {
      const u = doc.data();
      if (u.uid === currentUserId) return;

      const username = (u.username || '').toLowerCase();
      const displayName = (u.displayName || '').toLowerCase();

      if (username.includes(cleanQuery) || displayName.includes(cleanQuery)) {
        users.push({
          uid: u.uid,
          username: u.username || u.displayName,
          displayName: u.displayName || 'Player',
          photoUrl: u.photoUrl || null,
          gamesPlayed: u.gamesPlayed || 0,
          gamesWon: u.gamesWon || 0,
          averageScore: u.averageScore || 0,
        });
      }
    });

    return users.slice(0, 20);
  }

  /**
   * Send a friend request to a target user (by UID or Username).
   */
  async sendFriendRequest(fromUserId, targetQuery) {
    const db = getFirestore();
    const fromDoc = await db.collection('users').doc(fromUserId).get();
    if (!fromDoc.exists) throw new Error('User not found');
    const fromUser = fromDoc.data();

    // Find target user
    let targetUser = null;
    const allUsersSnap = await db.collection('users').get();
    const targetClean = targetQuery.trim().toLowerCase();

    for (const doc of allUsersSnap.docs) {
      const u = doc.data();
      if (u.uid === targetQuery || (u.username && u.username.toLowerCase() === targetClean) || (u.displayName && u.displayName.toLowerCase() === targetClean)) {
        targetUser = u;
        break;
      }
    }

    if (!targetUser) {
      throw new Error(`Player "${targetQuery}" not found.`);
    }

    if (targetUser.uid === fromUserId) {
      throw new Error('You cannot send a friend request to yourself.');
    }

    // Check if already friends
    const fromFriends = fromUser.friends || [];
    if (fromFriends.includes(targetUser.uid)) {
      throw new Error(`You are already friends with ${targetUser.displayName}.`);
    }

    // Check if request already exists
    const requestId = `${fromUserId}_${targetUser.uid}`;
    const reverseRequestId = `${targetUser.uid}_${fromUserId}`;

    const existingReq = await db.collection('friend_requests').doc(requestId).get();
    if (existingReq.exists) {
      throw new Error('Friend request already sent.');
    }

    const reverseReq = await db.collection('friend_requests').doc(reverseRequestId).get();
    if (reverseReq.exists) {
      // Auto-accept if they already sent us a request!
      return this.acceptFriendRequest(fromUserId, targetUser.uid);
    }

    const newRequest = {
      id: requestId,
      fromUid: fromUserId,
      fromDisplayName: fromUser.displayName || 'Player',
      fromUsername: fromUser.username || fromUser.displayName,
      toUid: targetUser.uid,
      toDisplayName: targetUser.displayName || 'Player',
      toUsername: targetUser.username || targetUser.displayName,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    await db.collection('friend_requests').doc(requestId).set(newRequest);
    logger.info(`Friend request sent: ${fromUser.displayName} -> ${targetUser.displayName}`);

    return newRequest;
  }

  /**
   * Accept a friend request.
   */
  async acceptFriendRequest(currentUserId, requesterId) {
    const db = getFirestore();
    const requestId = `${requesterId}_${currentUserId}`;

    const reqDoc = await db.collection('friend_requests').doc(requestId).get();
    if (reqDoc.exists) {
      await db.collection('friend_requests').doc(requestId).set({ status: 'accepted' });
    }

    // Update user 1 friends list
    const user1Ref = db.collection('users').doc(currentUserId);
    const user1Doc = await user1Ref.get();
    if (user1Doc.exists) {
      const u1Data = user1Doc.data();
      const friends = new Set(u1Data.friends || []);
      friends.add(requesterId);
      await user1Ref.update({ friends: Array.from(friends) });
    }

    // Update user 2 friends list
    const user2Ref = db.collection('users').doc(requesterId);
    const user2Doc = await user2Ref.get();
    if (user2Doc.exists) {
      const u2Data = user2Doc.data();
      const friends = new Set(u2Data.friends || []);
      friends.add(currentUserId);
      await user2Ref.update({ friends: Array.from(friends) });
    }

    logger.info(`Friend request accepted between ${currentUserId} and ${requesterId}`);
    return { success: true };
  }

  /**
   * Decline or cancel a friend request.
   */
  async cancelOrDeclineRequest(fromUid, toUid) {
    const db = getFirestore();
    const req1 = `${fromUid}_${toUid}`;
    const req2 = `${toUid}_${fromUid}`;

    await db.collection('friend_requests').doc(req1).set({ status: 'declined' });
    await db.collection('friend_requests').doc(req2).set({ status: 'declined' });

    return { success: true };
  }

  /**
   * Remove a friend.
   */
  async removeFriend(currentUserId, friendId) {
    const db = getFirestore();

    const u1Ref = db.collection('users').doc(currentUserId);
    const u1Doc = await u1Ref.get();
    if (u1Doc.exists) {
      const friends = (u1Doc.data().friends || []).filter((id) => id !== friendId);
      await u1Ref.update({ friends });
    }

    const u2Ref = db.collection('users').doc(friendId);
    const u2Doc = await u2Ref.get();
    if (u2Doc.exists) {
      const friends = (u2Doc.data().friends || []).filter((id) => id !== currentUserId);
      await u2Ref.update({ friends });
    }

    return { success: true };
  }

  /**
   * Get current user's friends details.
   */
  async getFriends(userId) {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    const friendIds = userDoc.data().friends || [];
    if (friendIds.length === 0) return [];

    const friends = [];
    for (const fId of friendIds) {
      const fDoc = await db.collection('users').doc(fId).get();
      if (fDoc.exists) {
        const u = fDoc.data();
        friends.push({
          uid: u.uid,
          username: u.username || u.displayName,
          displayName: u.displayName || 'Player',
          photoUrl: u.photoUrl || null,
          gamesPlayed: u.gamesPlayed || 0,
          gamesWon: u.gamesWon || 0,
          averageScore: u.averageScore || 0,
          isOnline: u.isOnline || false,
        });
      }
    }

    return friends;
  }

  /**
   * Get pending friend requests (incoming & outgoing).
   */
  async getPendingRequests(userId) {
    const db = getFirestore();
    const reqSnap = await db.collection('friend_requests').get();

    const incoming = [];
    const outgoing = [];

    reqSnap.docs.forEach((doc) => {
      const r = doc.data();
      if (r.status !== 'pending') return;

      if (r.toUid === userId) {
        incoming.push({
          id: r.id,
          fromUid: r.fromUid,
          fromDisplayName: r.fromDisplayName,
          fromUsername: r.fromUsername,
          createdAt: r.createdAt,
        });
      } else if (r.fromUid === userId) {
        outgoing.push({
          id: r.id,
          toUid: r.toUid,
          toDisplayName: r.toDisplayName,
          toUsername: r.toUsername,
          createdAt: r.createdAt,
        });
      }
    });

    return { incoming, outgoing };
  }
}

export default new FriendsService();
