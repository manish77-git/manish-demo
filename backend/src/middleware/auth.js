import { getAuth } from '../config/firebase.js';
import logger from '../utils/logger.js';

/**
 * Firebase Authentication middleware.
 * Verifies the Firebase ID token from the Authorization header.
 * Attaches decoded user info to req.user on success.
 */
export async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: { message: 'Missing or invalid Authorization header. Expected: Bearer <token>' },
    });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      displayName: decodedToken.name || decodedToken.email?.split('@')[0] || 'Anonymous',
      photoUrl: decodedToken.picture || null,
    };
    next();
  } catch (error) {
    logger.warn(`Auth failed: ${error.message}`);
    return res.status(401).json({
      success: false,
      error: { message: 'Invalid or expired authentication token' },
    });
  }
}

/**
 * Optional auth middleware — sets req.user if valid token exists, but doesn't block.
 */
export async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    req.user = null;
    return next();
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      displayName: decodedToken.name || decodedToken.email?.split('@')[0] || 'Anonymous',
      photoUrl: decodedToken.picture || null,
    };
  } catch {
    req.user = null;
  }

  next();
}
