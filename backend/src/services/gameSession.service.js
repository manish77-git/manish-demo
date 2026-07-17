import { v4 as uuidv4 } from 'uuid';
import { getFirestore } from '../config/firebase.js';
import { getRandomPrompt } from '../models/prompts.js';
import { recordGameToHistory } from './playerStats.service.js';
import logger from '../utils/logger.js';
import env from '../config/env.js';

/**
 * Game session service — manages game lifecycle.
 * States: waiting → drawing → evaluating → results
 */

/**
 * Create a new game session.
 */
export async function createGameSession(hostUser, options = {}) {
  const sessionId = uuidv4();
  const { difficulty = 'all', maxPlayers = env.maxPlayersPerGame, drawingTime = env.defaultDrawingTime } = options;

  const session = {
    id: sessionId,
    status: 'waiting',
    prompt: null,
    promptDifficulty: difficulty,
    hostId: hostUser.uid,
    players: [
      {
        userId: hostUser.uid,
        displayName: hostUser.displayName,
        photoUrl: hostUser.photoUrl || null,
        status: 'waiting',  // waiting | ready | drawing | submitted
        joinedAt: new Date().toISOString(),
      },
    ],
    maxPlayers,
    drawingTimeSeconds: drawingTime,
    createdAt: new Date().toISOString(),
    startedAt: null,
    endedAt: null,
    submissions: {},
  };

  try {
    const db = getFirestore();
    await db.collection('gameSessions').doc(sessionId).set(session);
    logger.info(`Game session created: ${sessionId} by ${hostUser.displayName}`);
    return session;
  } catch (error) {
    logger.error('Failed to create game session:', error);
    throw error;
  }
}

/**
 * Join an existing game session.
 */
export async function joinGameSession(sessionId, user) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      throw Object.assign(new Error('Game session not found'), { status: 404 });
    }

    const session = sessionDoc.data();

    if (session.status !== 'waiting') {
      throw Object.assign(new Error('Game has already started'), { status: 400 });
    }

    if (session.players.length >= session.maxPlayers) {
      throw Object.assign(new Error('Game is full'), { status: 400 });
    }

    if (session.players.some(p => p.userId === user.uid)) {
      throw Object.assign(new Error('Already in this game'), { status: 400 });
    }

    const newPlayer = {
      userId: user.uid,
      displayName: user.displayName,
      photoUrl: user.photoUrl || null,
      status: 'waiting',
      joinedAt: new Date().toISOString(),
    };

    session.players.push(newPlayer);
    await sessionRef.update({ players: session.players });

    logger.info(`${user.displayName} joined game ${sessionId}`);
    return session;
  } catch (error) {
    if (!error.status) error.status = 500;
    throw error;
  }
}

/**
 * Mark a player as ready.
 */
export async function setPlayerReady(sessionId, userId) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      throw Object.assign(new Error('Game session not found'), { status: 404 });
    }

    const session = sessionDoc.data();
    const player = session.players.find(p => p.userId === userId);

    if (!player) {
      throw Object.assign(new Error('Player not in this game'), { status: 400 });
    }

    player.status = 'ready';
    await sessionRef.update({ players: session.players });

    // Check if all players are ready
    const allReady = session.players.every(p => p.status === 'ready');
    return { session, allReady };
  } catch (error) {
    if (!error.status) error.status = 500;
    throw error;
  }
}

/**
 * Start the game — transition from waiting to drawing.
 */
export async function startGame(sessionId, userId) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      throw Object.assign(new Error('Game session not found'), { status: 404 });
    }

    const session = sessionDoc.data();

    if (session.hostId !== userId) {
      throw Object.assign(new Error('Only the host can start the game'), { status: 403 });
    }

    if (session.status !== 'waiting') {
      throw Object.assign(new Error('Game is not in waiting state'), { status: 400 });
    }

    if (session.players.length < 1) {
      throw Object.assign(new Error('Need at least 1 player to start'), { status: 400 });
    }

    // Select prompt
    const { prompt, difficulty } = getRandomPrompt(session.promptDifficulty);

    // Update all players to drawing state
    session.players.forEach(p => { p.status = 'drawing'; });

    const updates = {
      status: 'drawing',
      prompt,
      promptDifficulty: difficulty,
      startedAt: new Date().toISOString(),
      players: session.players,
    };

    await sessionRef.update(updates);

    logger.info(`Game ${sessionId} started! Prompt: "${prompt}" (${difficulty})`);
    return { ...session, ...updates };
  } catch (error) {
    if (!error.status) error.status = 500;
    throw error;
  }
}

/**
 * Record a player's drawing submission.
 */
export async function submitDrawing(sessionId, userId, drawingData) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      throw Object.assign(new Error('Game session not found'), { status: 404 });
    }

    const session = sessionDoc.data();

    if (session.status !== 'drawing') {
      throw Object.assign(new Error('Game is not in drawing phase'), { status: 400 });
    }

    const player = session.players.find(p => p.userId === userId);
    if (!player) {
      throw Object.assign(new Error('Player not in this game'), { status: 400 });
    }

    player.status = 'submitted';

    const submission = {
      drawingUrl: drawingData.drawingUrl || null,
      drawingBuffer: drawingData.drawingBuffer || null, // For AI evaluation
      score: null,
      aiLabels: [],
      submittedAt: new Date().toISOString(),
      evaluatedAt: null,
    };

    session.submissions = session.submissions || {};
    session.submissions[userId] = submission;

    await sessionRef.update({
      players: session.players,
      [`submissions.${userId}`]: submission,
    });

    // Check if all players have submitted
    const allSubmitted = session.players.every(p => p.status === 'submitted');

    logger.info(`${player.displayName} submitted drawing for game ${sessionId}`);
    return { session: { ...session }, allSubmitted };
  } catch (error) {
    if (!error.status) error.status = 500;
    throw error;
  }
}

/**
 * Update scores after AI evaluation and move to results state.
 */
export async function finalizeGame(sessionId, scores) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);

    const updates = {
      status: 'results',
      endedAt: new Date().toISOString(),
    };

    // Update each player's score
    for (const [userId, scoreData] of Object.entries(scores)) {
      updates[`submissions.${userId}.score`] = scoreData.score;
      updates[`submissions.${userId}.aiLabels`] = scoreData.labels || [];
      updates[`submissions.${userId}.evaluatedAt`] = new Date().toISOString();
    }

    await sessionRef.update(updates);

    // Update leaderboard
    await updateLeaderboard(scores);

    // Record game history for each player
    const sortedScores = Object.entries(scores)
      .sort(([, a], [, b]) => b.score - a.score);

    for (let i = 0; i < sortedScores.length; i++) {
      const [userId, scoreData] = sortedScores[i];
      recordGameToHistory(userId, {
        gameId: sessionId,
        prompt: scoreData.prompt || 'unknown',
        difficulty: scoreData.difficulty,
        score: scoreData.score,
        rank: i + 1,
        totalPlayers: sortedScores.length,
        labels: scoreData.labels,
      }).catch(err => logger.warn(`Failed to record history for ${userId}:`, err.message));
    }

    logger.info(`Game ${sessionId} finalized with scores`);
    return updates;
  } catch (error) {
    logger.error('Failed to finalize game:', error);
    throw error;
  }
}

/**
 * Get a game session by ID.
 */
export async function getGameSession(sessionId) {
  try {
    const db = getFirestore();
    const sessionDoc = await db.collection('gameSessions').doc(sessionId).get();

    if (!sessionDoc.exists) {
      throw Object.assign(new Error('Game session not found'), { status: 404 });
    }

    return sessionDoc.data();
  } catch (error) {
    if (!error.status) error.status = 500;
    throw error;
  }
}

/**
 * List available game sessions (waiting status).
 */
export async function listAvailableGames() {
  try {
    const db = getFirestore();
    const snapshot = await db.collection('gameSessions')
      .where('status', '==', 'waiting')
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();

    return snapshot.docs.map(doc => doc.data());
  } catch (error) {
    logger.error('Failed to list games:', error);
    return [];
  }
}

/**
 * Update leaderboard after game results.
 */
async function updateLeaderboard(scores) {
  try {
    const db = getFirestore();
    const batch = db.batch();

    // Find winner
    let maxScore = -1;
    let winnerId = null;
    for (const [userId, scoreData] of Object.entries(scores)) {
      if (scoreData.score > maxScore) {
        maxScore = scoreData.score;
        winnerId = userId;
      }
    }

    for (const [userId, scoreData] of Object.entries(scores)) {
      const leaderboardRef = db.collection('leaderboard').doc(userId);
      const doc = await leaderboardRef.get();

      const isWinner = userId === winnerId;

      if (doc.exists) {
        const data = doc.data();
        const newGamesPlayed = (data.gamesPlayed || 0) + 1;
        const newTotalScore = (data.totalScore || 0) + scoreData.score;
        const newGamesWon = (data.gamesWon || 0) + (isWinner ? 1 : 0);

        batch.update(leaderboardRef, {
          totalScore: newTotalScore,
          gamesPlayed: newGamesPlayed,
          gamesWon: newGamesWon,
          averageScore: Math.round(newTotalScore / newGamesPlayed),
          lastPlayedAt: new Date().toISOString(),
        });
      } else {
        batch.set(leaderboardRef, {
          userId,
          displayName: scoreData.displayName || 'Unknown',
          photoUrl: scoreData.photoUrl || null,
          totalScore: scoreData.score,
          gamesPlayed: 1,
          gamesWon: isWinner ? 1 : 0,
          averageScore: scoreData.score,
          lastPlayedAt: new Date().toISOString(),
        });
      }
    }

    await batch.commit();
    logger.debug('Leaderboard updated');
  } catch (error) {
    logger.error('Failed to update leaderboard:', error);
  }
}
