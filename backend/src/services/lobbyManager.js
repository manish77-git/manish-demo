/**
 * LobbyManager — In-memory room and player tracking.
 *
 * Each room is keyed by its room code (e.g. "1875") and stores
 * an array of connected players. No fake/bot/placeholder players
 * are ever created. The player list is populated exclusively
 * from real socket connections.
 */

class LobbyManager {
  constructor() {
    /** @type {Map<string, Array<{socketId: string, uid: string, displayName: string, isHost: boolean}>>} */
    this.rooms = new Map();

    /** @type {Map<string, string>} socketId -> roomCode (reverse lookup for disconnect) */
    this.socketToRoom = new Map();
  }

  /**
   * Create a new room. The creator becomes the host.
   * Returns the generated room code.
   */
  createRoom(socketId, uid, displayName) {
    const roomCode = this._generateCode();
    this.rooms.set(roomCode, [
      { socketId, uid, displayName, isHost: true },
    ]);
    this.socketToRoom.set(socketId, roomCode);
    return roomCode;
  }

  /**
   * Join an existing room by code.
   * Returns the updated player list, or null if room doesn't exist / is full.
   */
  joinRoom(roomCode, socketId, uid, displayName) {
    const players = this.rooms.get(roomCode);
    if (!players) return null; // Room doesn't exist

    // Max 8 players
    if (players.length >= 8) return null;

    // Don't double-add the same socket
    if (players.some(p => p.socketId === socketId)) {
      return players;
    }

    players.push({ socketId, uid, displayName, isHost: false });
    this.socketToRoom.set(socketId, roomCode);
    return players;
  }

  /**
   * Remove a player by their socket ID (called on disconnect).
   * Returns { roomCode, players } so the caller can broadcast the update,
   * or null if the socket wasn't in any room.
   */
  leaveRoom(socketId) {
    const roomCode = this.socketToRoom.get(socketId);
    if (!roomCode) return null;

    this.socketToRoom.delete(socketId);

    const players = this.rooms.get(roomCode);
    if (!players) return null;

    const idx = players.findIndex(p => p.socketId === socketId);
    if (idx === -1) return null;

    const wasHost = players[idx].isHost;
    players.splice(idx, 1);

    // If the room is now empty, destroy it
    if (players.length === 0) {
      this.rooms.delete(roomCode);
      return { roomCode, players: [] };
    }

    // If the host left, promote the next player
    if (wasHost && players.length > 0) {
      players[0].isHost = true;
    }

    return { roomCode, players };
  }

  /**
   * Get the current player list for a room.
   */
  getPlayers(roomCode) {
    return this.rooms.get(roomCode) || [];
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
