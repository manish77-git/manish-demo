import { v4 as uuidv4 } from 'uuid';
import { getFirestore } from '../config/firebase.js';
import { getRandomPrompt } from '../models/prompts.js';
import { recordGameToHistory } from './playerStats.service.js';
import logger from '../utils/logger.js';
import env from '../config/env.js';

/**
 * Game session service — manages game lifecycle.
 * States: waiting → drawing → evaluating → evaluation_failed | completed
 *
 * IMPORTANT: Drawing buffers are stored in-memory (not Firestore) to avoid
 * Buffer serialization corruption. Only metadata is persisted to Firestore.
 */

// ─── In-Memory Drawing Buffer Store ──────────────────────────
// Key: `${gameId}:${userId}` → Buffer
const drawingBufferStore = new Map();

/**
 * Store a drawing buffer in memory for later AI evaluation.
 */
export function storeDrawingBuffer(gameId, userId, buffer) {
  const key = `${gameId}:${userId}`;
  drawingBufferStore.set(key, buffer);
  logger.info(`[BUFFER STORE] Stored drawing buffer for ${key}, size: ${buffer.length} bytes`);
}

/**
 * Retrieve a drawing buffer from memory.
 */
export function getDrawingBuffer(gameId, userId) {
  const key = `${gameId}:${userId}`;
  const buf = drawingBufferStore.get(key);
  if (buf) {
    logger.info(`[BUFFER STORE] Retrieved drawing buffer for ${key}, size: ${buf.length} bytes`);
  } else {
    logger.warn(`[BUFFER STORE] No drawing buffer found for ${key}`);
  }
  return buf || null;
}

/**
 * Get all drawing buffers for a game session.
 */
export function getAllDrawingBuffers(gameId) {
  const buffers = {};
  for (const [key, buf] of drawingBufferStore.entries()) {
    if (key.startsWith(`${gameId}:`)) {
      const userId = key.split(':').slice(1).join(':');
      buffers[userId] = buf;
    }
  }
  return buffers;
}

/**
 * Clean up drawing buffers for a game session (call after results are sent).
 * Uses a delay to ensure results screen can still fetch images.
 */
export function scheduleBufferCleanup(gameId, delayMs = 300000) {
  setTimeout(() => {
    let cleaned = 0;
    for (const key of drawingBufferStore.keys()) {
      if (key.startsWith(`${gameId}:`)) {
        drawingBufferStore.delete(key);
        cleaned++;
      }
    }
    if (cleaned > 0) {
      logger.info(`[BUFFER STORE] Cleaned up ${cleaned} drawing buffer(s) for game ${gameId}`);
    }
  }, delayMs);
}

// ─── Game Session CRUD ───────────────────────────────────────

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
    evaluationError: null,
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
      evaluationError: null,
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
 * Atomically transition game session status to 'evaluating' using a Firestore transaction
 * to prevent duplicate evaluations (race condition between auto-eval timer and submission trigger).
 *
 * Returns true if THIS caller won the transition, false if another caller already did.
 */
export async function transitionToEvaluating(sessionId) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);

    const transitioned = await db.runTransaction(async (transaction) => {
      const sessionDoc = await transaction.get(sessionRef);

      if (!sessionDoc.exists) return false;

      const session = sessionDoc.data();
      // Only transition from 'drawing' status — anything else means someone already did it
      if (session.status !== 'drawing') {
        logger.info(`[TRANSITION] Game ${sessionId} already in status '${session.status}', skipping transition`);
        return false;
      }

      transaction.update(sessionRef, {
        status: 'evaluating',
        evaluatingStartedAt: new Date().toISOString(),
        evaluationError: null,
      });

      return true;
    });

    if (transitioned) {
      logger.info(`[LOG] Match state changed: drawing -> evaluating for game ${sessionId} (atomic transaction)`);
    }
    return transitioned;
  } catch (error) {
    logger.error(`Failed to transition game ${sessionId} to evaluating:`, error);
    return false;
  }
}

/**
 * Mark evaluation as failed in Firestore so both clients can detect it.
 */
export async function markEvaluationFailed(sessionId, errorMessage) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);
    await sessionRef.update({
      status: 'evaluation_failed',
      evaluationError: errorMessage,
      evaluationFailedAt: new Date().toISOString(),
    });
    logger.info(`[EVAL FAILED] Game ${sessionId} marked as evaluation_failed: ${errorMessage}`);
  } catch (error) {
    logger.error(`Failed to mark evaluation as failed for game ${sessionId}:`, error);
  }
}

/**
 * Reset evaluation state so a retry can proceed (transition from evaluation_failed back to evaluating).
 */
export async function resetForRetryEvaluation(sessionId) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);

    const transitioned = await db.runTransaction(async (transaction) => {
      const sessionDoc = await transaction.get(sessionRef);
      if (!sessionDoc.exists) return false;

      const session = sessionDoc.data();
      if (session.status !== 'evaluation_failed') {
        logger.info(`[RETRY] Game ${sessionId} status is '${session.status}', not evaluation_failed — skipping retry`);
        return false;
      }

      transaction.update(sessionRef, {
        status: 'evaluating',
        evaluatingStartedAt: new Date().toISOString(),
        evaluationError: null,
      });

      return true;
    });

    if (transitioned) {
      logger.info(`[RETRY] Game ${sessionId} reset from evaluation_failed -> evaluating for retry`);
    }
    return transitioned;
  } catch (error) {
    logger.error(`Failed to reset evaluation for retry in game ${sessionId}:`, error);
    return false;
  }
}

/**
 * Record a player's drawing submission.
 * Stores the drawing buffer in memory (NOT Firestore) and metadata in Firestore.
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

    if (session.status !== 'drawing' && session.status !== 'evaluating') {
      throw Object.assign(new Error('Game is not in drawing or evaluating phase'), { status: 400 });
    }

    let player = session.players.find(p => p.userId === userId);
    if (player) {
      player.status = 'submitted';
      // Only set displayName if player didn't have one set from room creation
      if (!player.displayName || player.displayName === 'Player') {
        player.displayName = drawingData.displayName || userId;
      }
    } else {
      // If player wasn't in players array, register them now
      player = {
        userId,
        displayName: drawingData.displayName || userId,
        photoUrl: null,
        status: 'submitted',
        joinedAt: new Date().toISOString(),
      };
      session.players.push(player);
    }

    // Store drawing buffer in memory (NOT in Firestore)
    if (drawingData.drawingBuffer) {
      const buf = Buffer.isBuffer(drawingData.drawingBuffer)
        ? drawingData.drawingBuffer
        : Buffer.from(drawingData.drawingBuffer);
      storeDrawingBuffer(sessionId, userId, buf);
      logger.info(`[CANVAS SAVE] Stored canvas buffer in memory for user ${userId} (${player.displayName}), size: ${buf.length} bytes in game ${sessionId}`);
    }

    // Only store metadata in Firestore (no raw buffers)
    const submission = {
      userId,
      displayName: player.displayName,
      hasDrawing: true,
      drawingUrl: drawingData.drawingUrl || null,
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

    // Check if all active players have submitted
    const activePlayers = session.players.filter(p => p.status !== 'spectator');
    const allSubmitted = activePlayers.length > 0 && activePlayers.every(p => p.status === 'submitted');

    logger.info(`[LOG] Player submitted drawing: ${player.displayName} for game ${sessionId} (allSubmitted=${allSubmitted})`);

    return { session: { ...session }, allSubmitted };
  } catch (error) {
    if (!error.status) error.status = 500;
    throw error;
  }
}

/**
 * Update scores after AI evaluation and move to completed state.
 */
export async function finalizeGame(sessionId, scores) {
  try {
    const db = getFirestore();
    const sessionRef = db.collection('gameSessions').doc(sessionId);

    const updates = {
      status: 'completed',
      endedAt: new Date().toISOString(),
      evaluationError: null,
    };

    // Update each player's score
    for (const [userId, scoreData] of Object.entries(scores)) {
      updates[`submissions.${userId}.score`] = scoreData.score;
      updates[`submissions.${userId}.aiLabels`] = scoreData.labels || [];
      updates[`submissions.${userId}.evaluatedAt`] = new Date().toISOString();
    }

    await sessionRef.update(updates);

    // Schedule cleanup of in-memory buffers (5 min delay for image fetching)
    scheduleBufferCleanup(sessionId, 300000);

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
        displayName: scoreData.displayName,
        photoUrl: scoreData.photoUrl,
      }).catch(err => logger.warn(`Failed to record history for ${userId}:`, err.message));
    }

    logger.info(`[LOG] Game ${sessionId} finalized with scores in state: completed`);
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
