import { v4 as uuidv4 } from 'uuid';
import { getFirestore } from '../config/firebase.js';
import { getRandomPrompt } from '../models/prompts.js';
import logger from '../utils/logger.js';
import env from '../config/env.js';

/**
 * Matchmaking service — automatic player pairing and queue management.
 *
 * Flow:
 * 1. Player enters queue with preferences (difficulty, max wait time)
 * 2. System tries to match with other queued players
 * 3. When enough players found (or timeout), creates a game session
 * 4. All matched players are notified via Socket.IO
 */

// In-memory matchmaking queue (in production, use Redis)
const matchmakingQueue = new Map(); // Map<difficulty, Array<QueueEntry>>
const playerQueueMap = new Map();   // Map<userId, queueId> — quick lookup

const QUEUE_CHECK_INTERVAL = 3000; // Check queue every 3 seconds
const MIN_PLAYERS_TO_START = 2;
const MAX_WAIT_SECONDS = 30;

let queueIntervalId = null;

/**
 * Initialize the matchmaking queue processor.
 * @param {import('socket.io').Server} io
 */
export function initMatchmaking(io) {
  if (queueIntervalId) return;

  // Initialize difficulty queues
  for (const diff of ['all', 'easy', 'medium', 'hard']) {
    matchmakingQueue.set(diff, []);
  }

  queueIntervalId = setInterval(() => processQueues(io), QUEUE_CHECK_INTERVAL);
  logger.info('Matchmaking system initialized');
}

/**
 * Add a player to the matchmaking queue.
 * @returns {{ queueId: string, position: number, estimatedWait: number }}
 */
export function joinQueue(user, options = {}) {
  const { difficulty = 'all' } = options;

  // Remove from any existing queue first
  leaveQueue(user.uid);

  const queueId = uuidv4();
  const entry = {
    queueId,
    userId: user.uid,
    displayName: user.displayName,
    photoUrl: user.photoUrl || null,
    difficulty,
    joinedAt: Date.now(),
    maxWaitSeconds: MAX_WAIT_SECONDS,
  };

  const queue = matchmakingQueue.get(difficulty) || [];
  queue.push(entry);
  matchmakingQueue.set(difficulty, queue);
  playerQueueMap.set(user.uid, { queueId, difficulty });

  const position = queue.length;
  const estimatedWait = Math.max(5, MAX_WAIT_SECONDS - (position * 3));

  logger.info(`${user.displayName} joined matchmaking queue (${difficulty}), position: ${position}`);

  return { queueId, position, estimatedWait, difficulty };
}

/**
 * Remove a player from the matchmaking queue.
 */
export function leaveQueue(userId) {
  const queueInfo = playerQueueMap.get(userId);
  if (!queueInfo) return false;

  const queue = matchmakingQueue.get(queueInfo.difficulty) || [];
  const index = queue.findIndex(e => e.userId === userId);
  if (index !== -1) {
    queue.splice(index, 1);
    matchmakingQueue.set(queueInfo.difficulty, queue);
  }

  playerQueueMap.delete(userId);
  logger.debug(`Player ${userId} left matchmaking queue`);
  return true;
}

/**
 * Get the current queue status for a player.
 */
export function getQueueStatus(userId) {
  const queueInfo = playerQueueMap.get(userId);
  if (!queueInfo) {
    return { inQueue: false };
  }

  const queue = matchmakingQueue.get(queueInfo.difficulty) || [];
  const position = queue.findIndex(e => e.userId === userId) + 1;
  const entry = queue.find(e => e.userId === userId);
  const waitTime = entry ? Math.round((Date.now() - entry.joinedAt) / 1000) : 0;

  return {
    inQueue: true,
    queueId: queueInfo.queueId,
    difficulty: queueInfo.difficulty,
    position,
    totalInQueue: queue.length,
    waitTimeSeconds: waitTime,
  };
}

/**
 * Get global queue statistics.
 */
export function getQueueStats() {
  const stats = {};
  for (const [difficulty, queue] of matchmakingQueue.entries()) {
    stats[difficulty] = {
      playersWaiting: queue.length,
      oldestWaitSeconds: queue.length > 0
        ? Math.round((Date.now() - queue[0].joinedAt) / 1000)
        : 0,
    };
  }
  return stats;
}

/**
 * Process all queues — try to form matches.
 * Called periodically by the interval timer.
 */
async function processQueues(io) {
  for (const [difficulty, queue] of matchmakingQueue.entries()) {
    if (queue.length < MIN_PLAYERS_TO_START) continue;

    // Check if we have enough players or if oldest player has waited long enough
    const now = Date.now();
    const oldestWait = queue.length > 0
      ? (now - queue[0].joinedAt) / 1000
      : 0;

    const shouldStart =
      queue.length >= env.maxPlayersPerGame || // Full lobby
      (queue.length >= MIN_PLAYERS_TO_START && oldestWait >= MAX_WAIT_SECONDS); // Enough + timeout

    if (shouldStart) {
      const matchSize = Math.min(queue.length, env.maxPlayersPerGame);
      const matchedPlayers = queue.splice(0, matchSize);
      matchmakingQueue.set(difficulty, queue);

      // Remove matched players from the player map
      for (const player of matchedPlayers) {
        playerQueueMap.delete(player.userId);
      }

      // Create a game session
      try {
        await createMatchedGame(matchedPlayers, difficulty, io);
      } catch (error) {
        logger.error('Failed to create matched game:', error);
        // Re-queue the players
        for (const player of matchedPlayers) {
          queue.unshift(player);
          playerQueueMap.set(player.userId, {
            queueId: player.queueId,
            difficulty,
          });
        }
        matchmakingQueue.set(difficulty, queue);
      }
    }
  }
}

/**
 * Create a game session from matched players.
 */
async function createMatchedGame(players, difficulty, io) {
  const sessionId = uuidv4();
  const host = players[0];
  const { prompt, difficulty: promptDifficulty } = getRandomPrompt(difficulty);

  const session = {
    id: sessionId,
    status: 'drawing', // Skip lobby, start immediately
    prompt,
    promptDifficulty,
    hostId: host.userId,
    players: players.map(p => ({
      userId: p.userId,
      displayName: p.displayName,
      photoUrl: p.photoUrl,
      status: 'drawing',
      joinedAt: new Date(p.joinedAt).toISOString(),
    })),
    maxPlayers: players.length,
    drawingTimeSeconds: env.defaultDrawingTime,
    createdAt: new Date().toISOString(),
    startedAt: new Date().toISOString(),
    endedAt: null,
    submissions: {},
    matchmade: true, // Flag that this was auto-matched
  };

  try {
    const db = getFirestore();
    await db.collection('gameSessions').doc(sessionId).set(session);
  } catch (error) {
    logger.warn('Firestore unavailable for matchmaking, using in-memory:', error.message);
  }

  // Notify all matched players via Socket.IO
  for (const player of players) {
    if (io) {
      io.to(`user:${player.userId}`).emit('matchmaking:matched', {
        sessionId,
        prompt,
        drawingTimeSeconds: env.defaultDrawingTime,
        players: session.players,
      });
    }
  }

  logger.info(
    `Matchmaking: Created game ${sessionId} with ${players.length} players. ` +
    `Prompt: "${prompt}" (${promptDifficulty})`
  );

  return session;
}

/**
 * Shutdown the matchmaking system.
 */
export function shutdownMatchmaking() {
  if (queueIntervalId) {
    clearInterval(queueIntervalId);
    queueIntervalId = null;
  }
  matchmakingQueue.clear();
  playerQueueMap.clear();
  logger.info('Matchmaking system shut down');
}

export default {
  initMatchmaking,
  joinQueue,
  leaveQueue,
  getQueueStatus,
  getQueueStats,
  shutdownMatchmaking,
};
