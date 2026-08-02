/**
 * LobbyManager — In-memory room, player, multi-round match, and settings tracking.
 *
 * Supports host settings updates, player ready-up states,
 * multi-round game flow, and player disconnection grace periods (reconnection support).
 */

class LobbyManager {
  constructor() {
    /** @type {Map<string, {roomCode: string, players: Array<any>, settings: any, status: string, matchState: any}>} */
    this.rooms = new Map();

    /** @type {Map<string, string>} socketId -> roomCode */
    this.socketToRoom = new Map();

    /** @type {Map<string, { [uid]: Array<any> }>} roomCode -> { [uid]: strokes } */
    this.drawings = new Map();

    /** @type {Map<string, NodeJS.Timeout>} roomCode:uid -> timeoutId */
    this.reconnectTimeouts = new Map();
  }

  /**
   * Create a new room with default settings.
   */
  createRoom(socketId, uid, displayName) {
    const roomCode = this._generateCode();
    const room = {
      roomCode,
      players: [
        {
          socketId,
          uid,
          displayName,
          isHost: true,
          isReady: true,
          isOnline: true,
          isSpectator: false
        }
      ],
      settings: {
        category: 'all',
        difficulty: 'all',
        duration: 80,
        maxPlayers: 10,
        rounds: 3,
        isPrivate: false,
      },
      status: 'lobby', // 'lobby' | 'playing' | 'results'
      matchState: null, // populated on match start
    };

    this.rooms.set(roomCode, room);
    this.socketToRoom.set(socketId, roomCode);
    this.drawings.set(roomCode, {});
    return roomCode;
  }

  /**
   * Join an existing room by code, supporting reconnection and spectator mode.
   */
  joinRoom(roomCode, socketId, uid, displayName) {
    const room = this.rooms.get(roomCode);
    if (!room) return null;

    // Check for reconnection
    const existingPlayer = room.players.find(p => p.uid === uid);
    if (existingPlayer) {
      // Cancel disconnect timeout
      const timeoutKey = `${roomCode}:${uid}`;
      if (this.reconnectTimeouts.has(timeoutKey)) {
        clearTimeout(this.reconnectTimeouts.get(timeoutKey));
        this.reconnectTimeouts.delete(timeoutKey);
      }
      
      // Update socket connection
      this.socketToRoom.delete(existingPlayer.socketId);
      existingPlayer.socketId = socketId;
      existingPlayer.isOnline = true;
      this.socketToRoom.set(socketId, roomCode);
      return room;
    }

    // Prevent duplicate joins — if uid is already in room (not a reconnect), reject
    const duplicateCheck = room.players.find(p => p.uid === uid);
    if (duplicateCheck) {
      // Already handled above as reconnection, this shouldn't happen, but guard anyway
      console.warn(`[LOBBY] Duplicate join attempt blocked: uid=${uid} already in room ${roomCode}`);
      return room;
    }

    // Join as spectator if game is in progress or room is full
    const isSpectator = room.status === 'playing' || room.players.length >= room.settings.maxPlayers;

    room.players.push({
      socketId,
      uid,
      displayName,
      isHost: false,
      isReady: isSpectator, // Spectators are ready by default
      isOnline: true,
      isSpectator
    });

    this.socketToRoom.set(socketId, roomCode);

    if (!this.drawings.has(roomCode)) {
      this.drawings.set(roomCode, {});
    }

    console.log(`[LOBBY] Player joined: uid=${uid}, room=${roomCode}, isSpectator=${isSpectator}, totalPlayers=${room.players.length}`);
    return room;
  }

  /**
   * Toggle a player's ready state.
   */
  toggleReady(roomCode, uid) {
    const room = this.rooms.get(roomCode);
    if (!room) return null;

    const player = room.players.find(p => p.uid === uid);
    if (player && !player.isHost && !player.isSpectator) {
      player.isReady = !player.isReady;
    }
    return room;
  }

  /**
   * Update the room configuration settings.
   */
  updateSettings(roomCode, newSettings) {
    const room = this.rooms.get(roomCode);
    if (!room) return null;

    room.settings = {
      ...room.settings,
      ...newSettings
    };
    return room;
  }

  // ─── Multi-Round Match State ────────────────────────────

  /**
   * Initialize match state for a new game.
   */
  startMatch(roomCode) {
    const room = this.rooms.get(roomCode);
    if (!room) return null;

    room.status = 'playing';
    room.matchState = {
      currentRound: 1,
      totalRounds: room.settings.rounds || 3,
      rounds: [], // { round, prompt, scores: { [uid]: number } }
      playerTotals: {}, // { [uid]: totalScore }
    };

    // Initialize player totals
    room.players.filter(p => !p.isSpectator).forEach(p => {
      room.matchState.playerTotals[p.uid] = 0;
    });

    return room.matchState;
  }

  /**
   * Set the prompt for the current round.
   */
  setRoundPrompt(roomCode, prompt) {
    const room = this.rooms.get(roomCode);
    if (!room || !room.matchState) return;

    const currentRound = room.matchState.currentRound;
    // Ensure the rounds array has an entry for this round
    if (room.matchState.rounds.length < currentRound) {
      room.matchState.rounds.push({
        round: currentRound,
        prompt,
        scores: {},
      });
    } else {
      room.matchState.rounds[currentRound - 1].prompt = prompt;
    }
  }

  /**
   * Record a player's score for the current round.
   */
  recordRoundScore(roomCode, uid, score) {
    const room = this.rooms.get(roomCode);
    if (!room || !room.matchState) return null;

    const roundIndex = room.matchState.currentRound - 1;
    if (roundIndex >= 0 && roundIndex < room.matchState.rounds.length) {
      room.matchState.rounds[roundIndex].scores[uid] = score;
      room.matchState.playerTotals[uid] = (room.matchState.playerTotals[uid] || 0) + score;
    }

    return room.matchState;
  }

  /**
   * Advance to the next round.
   * Returns null if all rounds are complete.
   */
  advanceRound(roomCode) {
    const room = this.rooms.get(roomCode);
    if (!room || !room.matchState) return null;

    const { currentRound, totalRounds } = room.matchState;
    if (currentRound >= totalRounds) return null;

    room.matchState.currentRound = currentRound + 1;
    return {
      currentRound: room.matchState.currentRound,
      totalRounds: room.matchState.totalRounds,
    };
  }

  /**
   * Get the final match results.
   */
  getFinalResults(roomCode) {
    const room = this.rooms.get(roomCode);
    if (!room || !room.matchState) return null;

    const { playerTotals, rounds, totalRounds } = room.matchState;

    // Build sorted rankings
    const rankings = Object.entries(playerTotals)
      .map(([uid, totalScore]) => {
        const player = room.players.find(p => p.uid === uid);
        return {
          uid,
          displayName: player ? player.displayName : 'Unknown',
          totalScore,
          averageScore: Math.round(totalScore / Math.max(rounds.length, 1)),
        };
      })
      .sort((a, b) => b.totalScore - a.totalScore);

    return {
      rankings,
      rounds,
      totalRounds,
    };
  }

  /**
   * Reset a room for a rematch without creating a new room.
   * Preserves room code, player list, and settings.
   * Clears match state, drawings, and resets player ready status.
   */
  resetForRematch(roomCode) {
    const room = this.rooms.get(roomCode);
    if (!room) return null;

    // Reset room status
    room.status = 'lobby';
    room.matchState = null;

    // Reset all players to not-ready (host stays ready)
    room.players.forEach(p => {
      p.isReady = p.isHost;
      p.isSpectator = false;
    });

    // Clear drawings
    this.drawings.set(roomCode, {});

    console.log(`[LOBBY] Room ${roomCode} reset for rematch. Players: ${room.players.map(p => p.displayName).join(', ')}`);
    return room;
  }

  // ─── Drawing / Strokes ──────────────────────────────────

  /**
   * Set or update strokes for a player.
   */
  saveStrokes(roomCode, uid, strokes) {
    if (!this.drawings.has(roomCode)) {
      this.drawings.set(roomCode, {});
    }
    this.drawings.get(roomCode)[uid] = strokes;
  }

  /**
   * Get strokes in a room.
   */
  getStrokes(roomCode) {
    return this.drawings.get(roomCode) || {};
  }

  // ─── Disconnect / Reconnect ─────────────────────────────

  /**
   * Mark a player as offline on disconnect, starting the reconnect grace period.
   */
  disconnectPlayer(socketId, onTimeout) {
    const roomCode = this.socketToRoom.get(socketId);
    if (!roomCode) return null;

    const room = this.rooms.get(roomCode);
    if (!room) return null;

    const player = room.players.find(p => p.socketId === socketId);
    if (!player) return null;

    // Mark as offline and not ready
    player.isOnline = false;
    player.isReady = false;

    // Start a 30-second grace period for reconnection
    const timeoutKey = `${roomCode}:${player.uid}`;
    if (this.reconnectTimeouts.has(timeoutKey)) {
      clearTimeout(this.reconnectTimeouts.get(timeoutKey));
    }

    const timeout = setTimeout(() => {
      this.reconnectTimeouts.delete(timeoutKey);
      
      // Perform actual removal of player
      const result = this.leaveRoom(socketId);
      if (result && onTimeout) {
        onTimeout(roomCode, result.room);
      }
    }, 30000); // 30 seconds (increased from 15s)

    this.reconnectTimeouts.set(timeoutKey, timeout);
    return { roomCode, room };
  }

  /**
   * Remove a player explicitly from the room.
   */
  leaveRoom(socketId) {
    const roomCode = this.socketToRoom.get(socketId);
    if (!roomCode) return null;

    this.socketToRoom.delete(socketId);
    const room = this.rooms.get(roomCode);
    if (!room) return null;

    const idx = room.players.findIndex(p => p.socketId === socketId);
    if (idx === -1) return null;

    const player = room.players[idx];
    const wasHost = player.isHost;
    room.players.splice(idx, 1);

    // Clean up timeouts
    const timeoutKey = `${roomCode}:${player.uid}`;
    if (this.reconnectTimeouts.has(timeoutKey)) {
      clearTimeout(this.reconnectTimeouts.get(timeoutKey));
      this.reconnectTimeouts.delete(timeoutKey);
    }

    // Destroy room if empty
    if (room.players.length === 0) {
      this.rooms.delete(roomCode);
      this.drawings.delete(roomCode);
      return { roomCode, room: null };
    }

    // Promote new host if host left
    if (wasHost && room.players.length > 0) {
      const nextHost = room.players.find(p => p.isOnline) || room.players[0];
      nextHost.isHost = true;
      nextHost.isReady = true;
    }

    return { roomCode, room };
  }

  /**
   * Get the current player list for a room.
   */
  getPlayers(roomCode) {
    const room = this.rooms.get(roomCode);
    return room ? room.players : [];
  }

  /**
   * Generate a 4-digit numeric room code.
   */
  _generateCode() {
    let code;
    do {
      code = String(Math.floor(1000 + Math.random() * 9000));
    } while (this.rooms.has(code));
    return code;
  }
}

export default LobbyManager;
