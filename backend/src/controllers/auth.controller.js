import { getFirestore } from '../config/firebase.js';
import logger from '../utils/logger.js';

/**
 * Auth controller — handles user profile creation, update, username check,
 * stats persistence, and match history.
 */

// ─── Default User Schema ─────────────────────────────────────────

function buildDefaultUser(uid, email, displayName, username, photoUrl) {
  return {
    uid,
    email: email || `${uid}@drawbattle.app`,
    username: (username || displayName || `user_${uid.substring(0, 6)}`).toLowerCase(),
    displayName: displayName || 'Artist',
    avatar: '🎨', // default emoji avatar
    photoUrl: photoUrl || null,

    // Stats
    totalScore: 0,
    gamesPlayed: 0,
    gamesWon: 0,
    gamesLost: 0,
    winRate: 0,
    averageScore: 0,
    highestScore: 0,
    totalDrawings: 0,
    favouriteGameMode: 'single_player',

    // Social
    friends: [],
    friendRequests: {
      incoming: [],
      outgoing: [],
    },

    // History
    matchHistory: [],

    // Settings
    settings: {
      soundEnabled: true,
      volume: 0.8,
      theme: 'system', // 'light' | 'dark' | 'system'
      notifications: true,
    },

    // Meta
    isOnline: false,
    createdAt: new Date().toISOString(),
    lastOnline: new Date().toISOString(),
  };
}

// ─── Check Username Availability ──────────────────────────────────

export async function checkUsername(req, res, next) {
  try {
    const { username } = req.query;
    if (!username || username.trim().length < 3) {
      return res.json({ success: true, data: { available: false, reason: 'Username must be at least 3 characters' } });
    }

    const db = getFirestore();
    const cleanUsername = username.trim().toLowerCase();
    const snapshot = await db.collection('users').get();

    let taken = false;
    snapshot.docs.forEach((doc) => {
      const u = doc.data();
      if (u.username && u.username.toLowerCase() === cleanUsername && u.uid !== req.user?.uid) {
        taken = true;
      }
    });

    res.json({
      success: true,
      data: { available: !taken },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Create or Update Profile on Login ────────────────────────────

export async function createProfile(req, res, next) {
  try {
    const { uid, email, displayName, photoUrl } = req.user;
    const { displayName: customName, username, settings, avatar } = req.body;

    const db = getFirestore();
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    const nameToUse = customName || displayName || (username ? `@${username}` : 'Artist');

    if (userDoc.exists) {
      const existing = userDoc.data();
      const updates = {
        displayName: nameToUse,
        lastOnline: new Date().toISOString(),
        isOnline: true,
      };
      if (username) updates.username = username.toLowerCase();
      if (photoUrl) updates.photoUrl = photoUrl;
      if (avatar) updates.avatar = avatar;
      if (settings) updates.settings = { ...(existing.settings || {}), ...settings };

      await userRef.update(updates);
      const updated = (await userRef.get()).data();

      return res.json({
        success: true,
        data: { user: updated, isNew: false },
      });
    }

    const newUser = buildDefaultUser(uid, email, nameToUse, username, photoUrl);
    if (avatar) newUser.avatar = avatar;
    if (settings) newUser.settings = { ...newUser.settings, ...settings };

    await userRef.set(newUser);
    logger.info(`New user profile created: @${newUser.username} (${newUser.displayName})`);

    res.status(201).json({
      success: true,
      data: { user: newUser, isNew: true },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Get Own Profile ──────────────────────────────────────────────

export async function getProfile(req, res, next) {
  try {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'User profile not found. Please create one first.' },
      });
    }

    res.json({
      success: true,
      data: { user: userDoc.data() },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Update Profile (PATCH) ───────────────────────────────────────

export async function updateProfile(req, res, next) {
  try {
    const { displayName, avatar, settings } = req.body;
    const db = getFirestore();
    const userRef = db.collection('users').doc(req.user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'User not found' },
      });
    }

    const updates = {};
    if (displayName && displayName.trim().length >= 2) {
      updates.displayName = displayName.trim();
    }
    if (avatar) {
      updates.avatar = avatar;
    }
    if (settings) {
      const existing = userDoc.data();
      updates.settings = { ...(existing.settings || {}), ...settings };
    }

    if (Object.keys(updates).length === 0) {
      return res.json({
        success: true,
        data: { user: userDoc.data() },
      });
    }

    await userRef.update(updates);
    const updated = (await userRef.get()).data();

    res.json({
      success: true,
      data: { user: updated },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Get Public Profile ───────────────────────────────────────────

export async function getPublicProfile(req, res, next) {
  try {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(req.params.userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'User not found' },
      });
    }

    const data = userDoc.data();
    res.json({
      success: true,
      data: {
        user: {
          uid: data.uid,
          username: data.username,
          displayName: data.displayName,
          avatar: data.avatar || '🎨',
          photoUrl: data.photoUrl,
          totalScore: data.totalScore,
          gamesPlayed: data.gamesPlayed,
          gamesWon: data.gamesWon,
          gamesLost: data.gamesLost || 0,
          winRate: data.winRate || 0,
          averageScore: data.averageScore,
          highestScore: data.highestScore || 0,
          totalDrawings: data.totalDrawings || 0,
          friendsCount: (data.friends || []).length,
          isOnline: data.isOnline || false,
          lastOnline: data.lastOnline,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Save Single Player High Score ────────────────────────────────

export async function saveSinglePlayerHighScore(req, res, next) {
  try {
    const { score, rounds, totalRounds, averageScore } = req.body;
    const db = getFirestore();
    const userRef = db.collection('users').doc(req.user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) return res.status(404).json({ success: false, error: { message: 'User not found' } });

    const u = userDoc.data();
    const currentHigh = u.highestScore || 0;
    const isNewHigh = score > currentHigh;
    const newHigh = Math.max(currentHigh, score);

    const newGamesPlayed = (u.gamesPlayed || 0) + 1;
    const isWin = averageScore >= 70;
    const newGamesWon = (u.gamesWon || 0) + (isWin ? 1 : 0);
    const newGamesLost = (u.gamesLost || 0) + (isWin ? 0 : 1);
    const newTotalScore = (u.totalScore || 0) + (score || 0);
    const newAvgScore = Math.round(newTotalScore / newGamesPlayed);
    const newWinRate = newGamesPlayed > 0 ? Math.round((newGamesWon / newGamesPlayed) * 100) : 0;

    const historyEntry = {
      date: new Date().toISOString(),
      mode: 'single_player',
      totalScore: score,
      roundsCount: rounds,
      totalRounds: totalRounds,
      averageScore: averageScore,
    };

    const matchHistory = [historyEntry, ...(u.matchHistory || [])].slice(0, 50);

    const updates = {
      highestScore: newHigh,
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      gamesLost: newGamesLost,
      winRate: newWinRate,
      totalScore: newTotalScore,
      averageScore: newAvgScore,
      matchHistory,
      totalDrawings: (u.totalDrawings || 0) + (rounds || 1),
    };

    await userRef.update(updates);

    res.json({
      success: true,
      data: {
        isNewHigh,
        highestScore: newHigh,
        gamesPlayed: newGamesPlayed,
        gamesWon: newGamesWon,
        gamesLost: newGamesLost,
        winRate: newWinRate,
        averageScore: newAvgScore,
      },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Record Multiplayer Match Result ──────────────────────────────

export async function recordMatchResult(req, res, next) {
  try {
    const { mode, totalScore, averageScore, roundsCount, placement, opponentCount } = req.body;
    const db = getFirestore();
    const userRef = db.collection('users').doc(req.user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) return res.status(404).json({ success: false, error: { message: 'User not found' } });

    const u = userDoc.data();
    const isWin = placement === 1;
    const newGamesPlayed = (u.gamesPlayed || 0) + 1;
    const newGamesWon = (u.gamesWon || 0) + (isWin ? 1 : 0);
    const newGamesLost = (u.gamesLost || 0) + (isWin ? 0 : 1);
    const newTotalScore = (u.totalScore || 0) + (totalScore || 0);
    const newAvgScore = Math.round(newTotalScore / newGamesPlayed);
    const newWinRate = newGamesPlayed > 0 ? Math.round((newGamesWon / newGamesPlayed) * 100) : 0;
    const newHighestScore = Math.max(u.highestScore || 0, totalScore || 0);

    const historyEntry = {
      date: new Date().toISOString(),
      mode: mode || 'multiplayer',
      totalScore: totalScore || 0,
      averageScore: averageScore || 0,
      roundsCount: roundsCount || 1,
      placement: placement || 0,
      opponentCount: opponentCount || 1,
    };

    const matchHistory = [historyEntry, ...(u.matchHistory || [])].slice(0, 50);

    // Track favourite game mode
    const modes = matchHistory.map(m => m.mode);
    const modeCounts = {};
    modes.forEach(m => { modeCounts[m] = (modeCounts[m] || 0) + 1; });
    const favouriteGameMode = Object.entries(modeCounts).sort((a, b) => b[1] - a[1])[0]?.[0] || 'single_player';

    const updates = {
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      gamesLost: newGamesLost,
      winRate: newWinRate,
      totalScore: newTotalScore,
      averageScore: newAvgScore,
      highestScore: newHighestScore,
      matchHistory,
      totalDrawings: (u.totalDrawings || 0) + (roundsCount || 1),
      favouriteGameMode,
    };

    await userRef.update(updates);

    res.json({
      success: true,
      data: {
        gamesPlayed: newGamesPlayed,
        gamesWon: newGamesWon,
        winRate: newWinRate,
        averageScore: newAvgScore,
      },
    });
  } catch (error) {
    next(error);
  }
}
