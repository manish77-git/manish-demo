import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';

import env from './config/env.js';
import { initializeFirebase } from './config/firebase.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import logger from './utils/logger.js';
import LobbyManager from './services/lobbyManager.js';
import { checkGeminiStatus } from './services/geminiEvaluator.service.js';

// Routes
import authRoutes from './routes/auth.routes.js';
import gameRoutes from './routes/game.routes.js';
import drawingRoutes from './routes/drawing.routes.js';
import leaderboardRoutes from './routes/leaderboard.routes.js';
import statsRoutes from './routes/stats.routes.js';
import matchmakingRoutes from './routes/matchmaking.routes.js';
import achievementsRoutes from './routes/achievements.routes.js';
import dailyRoutes from './routes/daily.routes.js';

// Services
import { initMatchmaking } from './services/matchmaking.service.js';

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
  });

  // Store io instance on app for controllers to use
  app.set('io', io);

  // Initialize matchmaking system
  initMatchmaking(io);

  // ─── Lobby Manager ──────────────────────────────────────
  const lobbyManager = new LobbyManager();

  // Socket.IO connection handling
  io.on('connection', (socket) => {
    logger.debug(`Socket connected: ${socket.id}`);

    // ─── Room: Create ─────────────────────────────────────
    socket.on('room:create', (data) => {
      const { uid, displayName } = data || {};
      if (!uid || !displayName) return;

      const roomCode = lobbyManager.createRoom(socket.id, uid, displayName);
      socket.join(roomCode);

      const players = lobbyManager.getPlayers(roomCode);
      socket.emit('room:created', { roomCode });
      io.to(roomCode).emit('room:update', { roomCode, players });

      logger.info(`Room ${roomCode} created by ${displayName} (${socket.id})`);
    });

    // ─── Room: Join ───────────────────────────────────────
    socket.on('room:join', (data) => {
      const { roomCode, uid, displayName } = data || {};
      if (!roomCode || !uid || !displayName) return;

      const players = lobbyManager.joinRoom(roomCode, socket.id, uid, displayName);
      if (!players) {
        socket.emit('room:error', { message: 'Room not found or full.' });
        return;
      }

      socket.join(roomCode);
      io.to(roomCode).emit('room:update', { roomCode, players });

      logger.info(`${displayName} joined room ${roomCode} (${socket.id})`);
    });

    // ─── Room: Leave (explicit) ───────────────────────────
    socket.on('room:leave', () => {
      const result = lobbyManager.leaveRoom(socket.id);
      if (result) {
        socket.leave(result.roomCode);
        io.to(result.roomCode).emit('room:update', {
          roomCode: result.roomCode,
          players: result.players,
        });
        logger.info(`Socket ${socket.id} left room ${result.roomCode}`);
      }
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
    socket.on('disconnect', () => {
      chatRateLimit.delete(socket.id);

      const result = lobbyManager.leaveRoom(socket.id);
      if (result && result.players.length > 0) {
        io.to(result.roomCode).emit('room:update', {
          roomCode: result.roomCode,
          players: result.players,
        });
        logger.info(`Socket ${socket.id} disconnected from room ${result.roomCode}`);
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
        version: '1.0.0',
        uptime: Math.round(process.uptime()),
        timestamp: new Date().toISOString(),
      },
    });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/games', gameRoutes);
  app.use('/api/drawings', drawingRoutes);
  app.use('/api/leaderboard', leaderboardRoutes);
  app.use('/api/stats', statsRoutes);
  app.use('/api/matchmaking', matchmakingRoutes);
  app.use('/api/achievements', achievementsRoutes);
  app.use('/api/daily', dailyRoutes);

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
║  AI Model:  ${String(env.aiModelMode).padEnd(33)}║
║  Health:    http://localhost:${env.port}/api/health${' '.repeat(Math.max(0, 8 - String(env.port).length))}║
╚══════════════════════════════════════════════╝
    `);
  });
}

bootstrap().catch((error) => {
  logger.error('Failed to start server:', error);
  process.exit(1);
});
