/**
 * LobbyManager — In-memory room, player, and settings tracking.
 *
 * Supports host settings updates, player ready-up states,
 * and player disconnection grace periods (reconnection support).
 */

class LobbyManager {
  constructor() {
    /** @type {Map<string, {roomCode: string, players: Array<any>, settings: any, status: string}>} */
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
        maxPlayers: 8
      },
      status: 'lobby' // 'lobby' | 'playing'
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

    // Start a 15-second grace period for reconnection
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
    }, 15000); // 15 seconds

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
