const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const {
  checkJoinLockout,
  recordFailedAttempt,
  resetFailedAttempts,
} = require('../middleware/rateLimiter');
const { createRoom, joinRoom } = require('../services/roomService');
const { wipeRoom } = require('../services/wipeService');

/**
 * POST /rooms
 * Creates a temporary room and generates an 8-character single-use security code.
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const creatorId = req.user.uid;
    const { name } = req.body;

    const result = await createRoom(creatorId, name);
    return res.status(201).json(result);
  } catch (error) {
    console.error('Error creating room:', error);
    return res.status(500).json({
      error: 'CreateRoomFailed',
      message: error.message || 'Failed to create room',
    });
  }
});

/**
 * POST /rooms/join
 * Enters an 8-character code to pair into a room.
 * Rate-limited: max 5 wrong attempts per user/IP then 15-minute lock.
 */
router.post('/join', requireAuth, async (req, res) => {
  const userId = req.user.uid;
  const lockoutKey = `${userId}_${req.ip}`;

  // 1. Check if user is currently locked out
  const lockout = checkJoinLockout(lockoutKey);
  if (lockout.isLocked) {
    return res.status(429).json({
      error: 'LockedOut',
      message: `Too many wrong code attempts. Locked out for ${lockout.remainingMinutes} minutes.`,
      remainingMinutes: lockout.remainingMinutes,
      remainingMs: lockout.remainingMs,
    });
  }

  const { code } = req.body;
  if (!code) {
    return res.status(400).json({
      error: 'MissingCode',
      message: 'Please provide the 8-character security code.',
    });
  }

  try {
    const result = await joinRoom(userId, code);
    // Success: clear previous failed attempts
    resetFailedAttempts(lockoutKey);
    return res.status(200).json(result);
  } catch (error) {
    const status = error.status || 500;

    // If invalid or wrong code, increment failed attempts counter
    if (status === 404 || status === 400) {
      const attemptResult = recordFailedAttempt(lockoutKey);
      if (attemptResult.isLocked) {
        return res.status(429).json({
          error: 'LockedOut',
          message: 'Maximum 5 wrong attempts reached. Account locked from joining for 15 minutes.',
          remainingMinutes: 15,
        });
      }
      return res.status(status).json({
        error: 'InvalidCode',
        message: error.message || 'Invalid room code.',
        attemptsLeft: attemptResult.attemptsLeft,
      });
    }

    return res.status(status).json({
      error: 'JoinRoomFailed',
      message: error.message || 'Failed to join room.',
    });
  }
});

/**
 * DELETE /rooms/:id
 * Permanent Wipe endpoint: Irreversibly purges room, Cloudinary assets, and Firestore messages.
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const roomId = req.params.id;
    const userId = req.user.uid;

    const result = await wipeRoom(roomId, userId);
    return res.status(200).json(result);
  } catch (error) {
    console.error(`Error wiping room ${req.params.id}:`, error);
    return res.status(error.message.includes('Unauthorized') ? 403 : 500).json({
      error: 'WipeFailed',
      message: error.message || 'Failed to wipe room data',
    });
  }
});

module.exports = router;

