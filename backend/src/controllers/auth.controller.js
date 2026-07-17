import { getFirestore } from '../config/firebase.js';
import logger from '../utils/logger.js';

/**
 * Auth controller — handles user profile creation and retrieval.
 * Actual authentication is handled by Firebase Auth on the client side.
 * The backend verifies tokens via the auth middleware.
 */

/**
 * POST /api/auth/profile — Create or update user profile after first login.
 */
export async function createProfile(req, res, next) {
  try {
    const { uid, email, displayName, photoUrl } = req.user;
    const { displayName: customName } = req.body;

    const db = getFirestore();
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      // Update existing profile
      const updates = {};
      if (customName) updates.displayName = customName;
      if (photoUrl) updates.photoUrl = photoUrl;
      updates.lastLoginAt = new Date().toISOString();

      await userRef.update(updates);
      const updated = (await userRef.get()).data();

      return res.json({
        success: true,
        data: { user: updated, isNew: false },
      });
    }

    // Create new profile
    const newUser = {
      uid,
      email,
      displayName: customName || displayName,
      photoUrl: photoUrl || null,
      totalScore: 0,
      gamesPlayed: 0,
      gamesWon: 0,
      averageScore: 0,
      createdAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
    };

    await userRef.set(newUser);
    logger.info(`New user profile created: ${newUser.displayName} (${uid})`);

    res.status(201).json({
      success: true,
      data: { user: newUser, isNew: true },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/auth/profile — Get current user's profile.
 */
export async function getProfile(req, res, next) {
  try {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: { message: 'User profile not found. Please create one first.' },
      });
    }

    res.json({
      success: true,
      data: { user: userDoc.data() },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/auth/profile/:userId — Get any user's public profile.
 */
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
    // Return only public fields
    res.json({
      success: true,
      data: {
        user: {
          uid: data.uid,
          displayName: data.displayName,
          photoUrl: data.photoUrl,
          totalScore: data.totalScore,
          gamesPlayed: data.gamesPlayed,
          gamesWon: data.gamesWon,
          averageScore: data.averageScore,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}
