import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';

import env from './config/env.js';
import { initializeFirebase, getFirestore } from './config/firebase.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import logger from './utils/logger.js';
import LobbyManager from './services/lobbyManager.js';
import { checkGeminiStatus } from './services/geminiEvaluator.service.js';
import { getRandomPrompt } from './models/prompts.js';
import { evaluateDrawing } from './services/aiEvaluation.service.js';

// Routes
import authRoutes from './routes/auth.routes.js';
import gameRoutes from './routes/game.routes.js';
import drawingRoutes from './routes/drawing.routes.js';
import statsRoutes from './routes/stats.routes.js';
import friendsRoutes from './routes/friends.routes.js';

// ─── Bootstrap ──────────────────────────────────────────────
async function bootstrap() {
  // Validate environment
  env.validate();

  // Initialize Firebase
  initializeFirebase();

  // Check Gemini Status
  checkGeminiStatus().catch(err => logger.error('Error during AI verification:', err.message));

  // ─── Express App ────────────────────────────────────────
  const app = express();
  const httpServer = createServer(app);

  // ─── Socket.IO ──────────────────────────────────────────
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
    pingTimeout: 30000,
    pingInterval: 15000,
  });

  // Store io instance on app for controllers to use
  app.set('io', io);

  // ─── Lobby Manager ──────────────────────────────────────
  const lobbyManager = new LobbyManager();

  // Socket.IO connection handling
  io.on('connection', (socket) => {
    logger.debug(`Socket connected: ${socket.id}`);

    // Track user online status
    socket.on('user:online', async (data) => {
      const { uid } = data || {};
      if (!uid) return;
      socket.userId = uid;
      socket.join(`user:${uid}`);
      try {
        const db = getFirestore();
        await db.collection('users').doc(uid).update({ isOnline: true, lastOnline: new Date().toISOString() });
        io.emit('user:online_status', { uid, isOnline: true });
      } catch (_) {}
    });

    // Send direct game invite to a friend
    socket.on('friend:invite', (data) => {
      const { friendUid, roomCode, hostName } = data || {};
      if (!friendUid || !roomCode) return;
      io.to(`user:${friendUid}`).emit('friend:invite_received', {
        fromUid: socket.userId,
        hostName: hostName || 'Your friend',
        roomCode,
      });
      logger.info(`Friend game invite sent from ${socket.userId} to ${friendUid} for room ${roomCode}`);
    });

    // ─── Room: Create ─────────────────────────────────────
    socket.on('room:create', (data) => {
      const { uid, displayName } = data || {};
      if (!uid || !displayName) return;

      const roomCode = lobbyManager.createRoom(socket.id, uid, displayName);
      socket.join(roomCode);
      socket.roomCode = roomCode;
      socket.userId = uid;

      const room = lobbyManager.rooms.get(roomCode);
      socket.emit('room:created', { roomCode });
      io.to(roomCode).emit('room:update', {
        roomCode,
        players: room.players,
        settings: room.settings
      });

      logger.info(`Room ${roomCode} created by ${displayName} (${socket.id})`);
    });

    // ─── Room: Join ───────────────────────────────────────
    socket.on('room:join', (data) => {
      const { roomCode, uid, displayName } = data || {};
      if (!roomCode || !uid || !displayName) return;

      const room = lobbyManager.joinRoom(roomCode, socket.id, uid, displayName);
      if (!room) {
        socket.emit('room:error', { message: 'Room not found or full.' });
        return;
      }

      socket.join(roomCode);
      socket.roomCode = roomCode;
      socket.userId = uid;

      io.to(roomCode).emit('room:update', {
        roomCode,
        players: room.players,
        settings: room.settings
      });

      // If there are existing strokes, send history to re-connecting player
      const history = lobbyManager.getStrokes(roomCode);
      socket.emit('drawing:history', { history });

      logger.info(`${displayName} joined room ${roomCode} (${socket.id})`);
    });

    // ─── Room: Leave (explicit) ───────────────────────────
    socket.on('room:leave', () => {
      const result = lobbyManager.leaveRoom(socket.id);
      if (result) {
        socket.leave(result.roomCode);
        io.to(result.roomCode).emit('room:update', {
          roomCode: result.roomCode,
          players: result.room ? result.room.players : [],
          settings: result.room ? result.room.settings : null
        });
        logger.info(`Socket ${socket.id} left room ${result.roomCode}`);
      }
    });

    // ─── Room: Toggle Ready ───────────────────────────────
    socket.on('room:toggle_ready', (data) => {
      const { roomCode, uid } = data || {};
      const actualRoomCode = roomCode || socket.roomCode;
      const actualUid = uid || socket.userId;
      if (!actualRoomCode || !actualUid) return;

      const room = lobbyManager.toggleReady(actualRoomCode, actualUid);
      if (room) {
        io.to(actualRoomCode).emit('room:update', {
          roomCode: actualRoomCode,
          players: room.players,
          settings: room.settings
        });
      }
    });

    // ─── Room: Update Settings ───────────────────────────
    socket.on('room:update_settings', (data) => {
      const { roomCode, settings } = data || {};
      const actualRoomCode = roomCode || socket.roomCode;
      if (!actualRoomCode || !settings) return;

      const room = lobbyManager.updateSettings(actualRoomCode, settings);
      if (room) {
        io.to(actualRoomCode).emit('room:update', {
          roomCode: actualRoomCode,
          players: room.players,
          settings: room.settings
        });
      }
    });

    // ─── Real-Time Private Canvas System ─────────────────
    // Stroke synchronization removed to ensure 100% canvas privacy per player.

    // ─── Match Start (Round 1 with 3s Countdown) ──────────
    socket.on('match:start', async (data) => {
      const { roomCode, difficulty, category, duration } = data || {};
      const actualRoomCode = roomCode || socket.roomCode;
      if (!actualRoomCode) return;

      const room = lobbyManager.rooms.get(actualRoomCode);
      if (room) {
        room.status = 'playing';
        if (difficulty) room.settings.difficulty = difficulty;
        if (category) room.settings.category = category;
        if (duration) room.settings.duration = parseInt(duration) || 80;
      }

      const activeSettings = room ? room.settings : { difficulty: 'all', category: 'all', duration: 80, rounds: 3 };

      // Initialize multi-round tracking
      lobbyManager.startMatch(actualRoomCode);

      // Select the prompt from the database based on difficulty and category
      const promptInfo = getRandomPrompt(activeSettings.difficulty, activeSettings.category);
      const selectedPrompt = promptInfo.prompt;

      // Record this round's prompt
      lobbyManager.setRoundPrompt(actualRoomCode, selectedPrompt);

      // Create the game session in the Firestore mock database
      try {
        const db = getFirestore();
        const playersList = room ? room.players : [];
        const hostPlayer = playersList.find(p => p.isHost) || playersList[0];
        
        const session = {
          id: actualRoomCode,
          status: 'drawing',
          prompt: selectedPrompt,
          promptDifficulty: promptInfo.difficulty,
          hostId: hostPlayer ? hostPlayer.uid : '',
          players: playersList.map(p => ({
            userId: p.uid,
            displayName: p.displayName,
            photoUrl: null,
            status: p.isSpectator ? 'spectator' : 'drawing',
            joinedAt: new Date().toISOString(),
          })),
          maxPlayers: activeSettings.maxPlayers || 8,
          drawingTimeSeconds: activeSettings.duration,
          totalRounds: activeSettings.rounds || 3,
          currentRound: 1,
          createdAt: new Date().toISOString(),
          startedAt: new Date().toISOString(),
          endedAt: null,
          submissions: {},
          rounds: [],
        };

        await db.collection('gameSessions').doc(actualRoomCode).set(session);
        logger.info(`Game session initialized for room: ${actualRoomCode} | Round 1 | Prompt: "${selectedPrompt}"`);
      } catch (err) {
        logger.error(`Failed to initialize game session: ${err.message}`);
      }

      // Emit 3-second countdown signal first
      io.to(actualRoomCode).emit('match:countdown', {
        countdownSeconds: 3,
        prompt: selectedPrompt,
        duration: activeSettings.duration,
        currentRound: 1,
        totalRounds: activeSettings.rounds || 3,
      });

      // Emit start_drawing after countdown
      setTimeout(() => {
        io.to(actualRoomCode).emit('match:start', {
          prompt: selectedPrompt,
          duration: activeSettings.duration,
          currentRound: 1,
          totalRounds: activeSettings.rounds || 3,
        });
      }, 3000);
    });

    // ─── Match: Next Round ────────────────────────────────
    socket.on('match:next_round', async (data) => {
      const { roomCode } = data || {};
      const actualRoomCode = roomCode || socket.roomCode;
      if (!actualRoomCode) return;

      const room = lobbyManager.rooms.get(actualRoomCode);
      if (!room) return;

      const roundInfo = lobbyManager.advanceRound(actualRoomCode);
      if (!roundInfo) {
        // No more rounds — finalize
        socket.emit('room:error', { message: 'No more rounds available.' });
        return;
      }

      // Pick a new prompt
      const promptInfo = getRandomPrompt(room.settings.difficulty, room.settings.category);
      lobbyManager.setRoundPrompt(actualRoomCode, promptInfo.prompt);

      // Clear all drawings for the new round
      lobbyManager.drawings.set(actualRoomCode, {});

      // Update DB
      try {
        const db = getFirestore();
        await db.collection('gameSessions').doc(actualRoomCode).update({
          currentRound: roundInfo.currentRound,
          prompt: promptInfo.prompt,
          status: 'drawing',
          startedAt: new Date().toISOString(),
          submissions: {},
        });
      } catch (_) {}

      io.to(actualRoomCode).emit('match:start', {
        prompt: promptInfo.prompt,
        duration: room.settings.duration,
        currentRound: roundInfo.currentRound,
        totalRounds: roundInfo.totalRounds,
      });

      logger.info(`Room ${actualRoomCode} advanced to round ${roundInfo.currentRound}/${roundInfo.totalRounds} | Prompt: "${promptInfo.prompt}"`);
    });

    // ─── Live Match Metrics ───────────────────────────────
    socket.on('match:live_metrics', (data) => {
      const { roomCode, metrics } = data || {};
      const actualRoomCode = roomCode || socket.roomCode;
      if (!actualRoomCode || !socket.userId) return;

      io.to(actualRoomCode).emit('match:live_metrics', {
        userId: socket.userId,
        metrics,
      });
    });

    // ─── Chat ─────────────────────────────────────────────
    const chatRateLimit = new Map();

    socket.on('chat:message', (data) => {
      const { roomCode, message, displayName } = data;
      if (!roomCode || !message || !displayName) return;

      const now = Date.now();
      const userMessages = chatRateLimit.get(socket.id) || [];
      const recentMessages = userMessages.filter(t => now - t < 10000);
      if (recentMessages.length >= 5) {
        socket.emit('chat:error', { message: 'Slow down! Too many messages.' });
        return;
      }
      recentMessages.push(now);
      chatRateLimit.set(socket.id, recentMessages);

      const sanitized = message.replace(/<[^>]*>/g, '').trim().slice(0, 200);
      if (!sanitized) return;

      io.to(roomCode).emit('chat:message', {
        uid: socket.userId || 'anonymous',
        displayName,
        message: sanitized,
        timestamp: new Date().toISOString(),
      });
    });

    socket.on('chat:reaction', (data) => {
      const { roomCode, emoji } = data;
      if (!roomCode || !emoji) return;

      const validEmojis = ['👍', '😂', '🔥', '🎨', '👏', '😮', '❤️', '💀'];
      if (!validEmojis.includes(emoji)) return;

      io.to(roomCode).emit('chat:reaction', {
        uid: socket.userId || 'anonymous',
        emoji,
        timestamp: new Date().toISOString(),
      });
    });

    // ─── Disconnect ───────────────────────────────────────
    socket.on('disconnect', async () => {
      chatRateLimit.delete(socket.id);

      // Mark user offline
      if (socket.userId) {
        try {
          const db = getFirestore();
          await db.collection('users').doc(socket.userId).update({ isOnline: false, lastOnline: new Date().toISOString() });
          io.emit('user:online_status', { uid: socket.userId, isOnline: false });
        } catch (_) {}
      }

      const result = lobbyManager.disconnectPlayer(socket.id, (roomCode, room) => {
        // Broadcast the removal of player after timeout
        io.to(roomCode).emit('room:update', {
          roomCode,
          players: room ? room.players : [],
          settings: room ? room.settings : null
        });
        logger.info(`Offline player removed from room ${roomCode}`);
      });

      if (result) {
        // Broadcast the offline status immediately
        io.to(result.roomCode).emit('room:update', {
          roomCode: result.roomCode,
          players: result.room.players,
          settings: result.room.settings
        });
        logger.info(`Socket ${socket.id} disconnected, marked offline in room ${result.roomCode}`);
      }

      logger.debug(`Socket disconnected: ${socket.id}`);
    });
  });

  // ─── Middleware ─────────────────────────────────────────
  app.use(cors());
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Request logging
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      logger.debug(`${req.method} ${req.path} → ${res.statusCode} (${duration}ms)`);
    });
    next();
  });

  // ─── Routes ─────────────────────────────────────────────
  app.get('/api/health', (req, res) => {
    res.json({
      success: true,
      data: {
        status: 'healthy',
        version: '2.0.0',
        uptime: Math.round(process.uptime()),
        timestamp: new Date().toISOString(),
      },
    });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/games', gameRoutes);
  app.use('/api/drawings', drawingRoutes);
  app.use('/api/stats', statsRoutes);
  app.use('/api/friends', friendsRoutes);

  // ─── Error Handling ─────────────────────────────────────
  app.use(notFoundHandler);
  app.use(errorHandler);

  // ─── Start Server ───────────────────────────────────────
  httpServer.listen(env.port, () => {
    logger.info(`
╔══════════════════════════════════════════════╗
║           🎨 DrawBattle API Server           ║
║──────────────────────────────────────────────║
║  Port:      ${String(env.port).padEnd(33)}║
║  Mode:      ${String(env.nodeEnv).padEnd(33)}║
║  Health:    http://localhost:${env.port}/api/health${' '.repeat(Math.max(0, 8 - String(env.port).length))}║
╚══════════════════════════════════════════════╝
    `);
  });
}

bootstrap().catch((error) => {
  logger.error('Failed to start server:', error);
  process.exit(1);
});
