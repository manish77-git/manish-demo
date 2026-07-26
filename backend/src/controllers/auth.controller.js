import { getFirestore } from '../config/firebase.js';
import logger from '../utils/logger.js';

// ─── Core Achievement Definitions ────────────────────────────────

export const ALL_ACHIEVEMENTS = [
  { id: 'first_draw', title: 'First Canvas', description: 'Complete your first drawing challenge', emoji: '🎨', target: 1, metric: 'totalDrawings' },
  { id: 'first_win', title: 'First Victory', description: 'Win your first match or high score challenge', emoji: '🏆', target: 1, metric: 'gamesWon' },
  { id: 'sharp_eye', title: 'Sharp Artist', description: 'Score 85+ points on a drawing challenge', emoji: '🎯', target: 85, metric: 'highestScore' },
  { id: 'century_club', title: 'High Scorer', description: 'Score 200+ total points in a single challenge', emoji: '💯', target: 200, metric: 'highestScore' },
  { id: 'artist_5', title: '5 Games Played', description: 'Complete 5 drawing challenges', emoji: '🖌️', target: 5, metric: 'gamesPlayed' },
  { id: 'artist_25', title: 'Drawing Veteran', description: 'Complete 25 drawing challenges', emoji: '⭐', target: 25, metric: 'gamesPlayed' },
  { id: 'artist_100', title: 'Drawing Master', description: 'Complete 100 drawing challenges', emoji: '💎', target: 100, metric: 'gamesPlayed' },
  { id: 'wins_5', title: '5 Wins', description: 'Win 5 matches or challenges', emoji: '🔥', target: 5, metric: 'gamesWon' },
  { id: 'wins_25', title: '25 Wins', description: 'Win 25 matches or challenges', emoji: '👑', target: 25, metric: 'gamesWon' },
  { id: 'social_butterfly', title: 'Social Butterfly', description: 'Add at least 1 friend to your list', emoji: '👥', target: 1, metric: 'friendsCount' },
  { id: 'speed_demon', title: 'Doodle Speedster', description: 'Create 20 total drawings', emoji: '⚡', target: 20, metric: 'totalDrawings' },
  { id: 'perfectionist', title: 'Perfectionist', description: 'Maintain an average score of 75+', emoji: '🌟', target: 75, metric: 'averageScore' },
];

/**
 * Evaluate and calculate achievement progress for a user object.
 */
export function evaluateAchievements(user) {
  const existingMap = {};
  if (Array.isArray(user.achievements)) {
    user.achievements.forEach((a) => {
      if (a && a.id) existingMap[a.id] = a;
    });
  }

  const friendsCount = (user.friends || []).length;

  return ALL_ACHIEVEMENTS.map((ach) => {
    let current = 0;
    if (ach.metric === 'friendsCount') {
      current = friendsCount;
    } else {
      current = user[ach.metric] || 0;
    }

    const wasUnlocked = existingMap[ach.id]?.unlocked === true;
    const isUnlocked = wasUnlocked || current >= ach.target;
    const unlockedAt = wasUnlocked
      ? existingMap[ach.id].unlockedAt
      : isUnlocked
      ? new Date().toISOString()
      : null;

    return {
      id: ach.id,
      title: ach.title,
      description: ach.description,
      emoji: ach.emoji,
      target: ach.target,
      current: Math.min(current, ach.target),
      unlocked: isUnlocked,
      unlockedAt,
    };
  });
}

// ─── Default User Schema ─────────────────────────────────────────

function buildDefaultUser(uid, email, displayName, username, photoUrl) {
  const user = {
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

    // Achievements
    achievements: [],

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

  user.achievements = evaluateAchievements(user);
  return user;
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

      // Re-evaluate achievements
      const mergedUser = { ...existing, ...updates };
      updates.achievements = evaluateAchievements(mergedUser);

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
    newUser.achievements = evaluateAchievements(newUser);

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
    const userRef = db.collection('users').doc(req.user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'User profile not found. Please create one first.' },
      });
    }

    const data = userDoc.data();

    // Ensure achievements are fresh
    const updatedAchievements = evaluateAchievements(data);
    if (JSON.stringify(updatedAchievements) !== JSON.stringify(data.achievements)) {
      await userRef.update({ achievements: updatedAchievements });
      data.achievements = updatedAchievements;
    }

    res.json({
      success: true,
      data: { user: data },
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

    const existing = userDoc.data();
    const updates = {};
    if (displayName && displayName.trim().length >= 2) {
      updates.displayName = displayName.trim();
    }
    if (avatar) {
      updates.avatar = avatar;
    }
    if (settings) {
      updates.settings = { ...(existing.settings || {}), ...settings };
    }

    const mergedUser = { ...existing, ...updates };
    updates.achievements = evaluateAchievements(mergedUser);

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
          achievements: data.achievements || [],
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

    const mergedUser = {
      ...u,
      highestScore: newHigh,
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      gamesLost: newGamesLost,
      winRate: newWinRate,
      totalScore: newTotalScore,
      averageScore: newAvgScore,
      totalDrawings: (u.totalDrawings || 0) + (rounds || 1),
    };

    const updatedAchievements = evaluateAchievements(mergedUser);

    const updates = {
      highestScore: newHigh,
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      gamesLost: newGamesLost,
      winRate: newWinRate,
      totalScore: newTotalScore,
      averageScore: newAvgScore,
      matchHistory,
      totalDrawings: mergedUser.totalDrawings,
      achievements: updatedAchievements,
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
        achievements: updatedAchievements,
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
    const modes = matchHistory.map((m) => m.mode);
    const modeCounts = {};
    modes.forEach((m) => {
      modeCounts[m] = (modeCounts[m] || 0) + 1;
    });
    const favouriteGameMode = Object.entries(modeCounts).sort((a, b) => b[1] - a[1])[0]?.[0] || 'single_player';

    const mergedUser = {
      ...u,
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      gamesLost: newGamesLost,
      winRate: newWinRate,
      totalScore: newTotalScore,
      averageScore: newAvgScore,
      highestScore: newHighestScore,
      totalDrawings: (u.totalDrawings || 0) + (roundsCount || 1),
    };

    const updatedAchievements = evaluateAchievements(mergedUser);

    const updates = {
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      gamesLost: newGamesLost,
      winRate: newWinRate,
      totalScore: newTotalScore,
      averageScore: newAvgScore,
      highestScore: newHighestScore,
      matchHistory,
      totalDrawings: mergedUser.totalDrawings,
      favouriteGameMode,
      achievements: updatedAchievements,
    };

    await userRef.update(updates);

    res.json({
      success: true,
      data: {
        gamesPlayed: newGamesPlayed,
        gamesWon: newGamesWon,
        winRate: newWinRate,
        averageScore: newAvgScore,
        achievements: updatedAchievements,
      },
    });
  } catch (error) {
    next(error);
  }
}
