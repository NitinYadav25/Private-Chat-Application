const { rateLimit } = require('express-rate-limit');

// Store for failed room join attempts: { [userOrIpKey]: { count: number, lockedUntil: number } }
const failedAttempts = new Map();

const MAX_WRONG_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

/**
 * Checks whether user/IP is currently locked out from entering room codes.
 */
function checkJoinLockout(key) {
  const record = failedAttempts.get(key);
  if (!record) return { isLocked: false };

  const now = Date.now();
  if (record.lockedUntil && now < record.lockedUntil) {
    const remainingMs = record.lockedUntil - now;
    return {
      isLocked: true,
      remainingMinutes: Math.ceil(remainingMs / (60 * 1000)),
      remainingMs,
    };
  }

  // Lockout expired, reset
  if (record.lockedUntil && now >= record.lockedUntil) {
    failedAttempts.delete(key);
  }

  return { isLocked: false };
}

/**
 * Registers a failed join code attempt.
 * If 5 failed attempts occur, triggers a 15-minute lock.
 */
function recordFailedAttempt(key) {
  const now = Date.now();
  let record = failedAttempts.get(key);

  if (!record) {
    record = { count: 1, lockedUntil: null };
    failedAttempts.set(key, record);
    return { attemptsLeft: MAX_WRONG_ATTEMPTS - 1, isLocked: false };
  }

  record.count += 1;

  if (record.count >= MAX_WRONG_ATTEMPTS) {
    record.lockedUntil = now + LOCKOUT_DURATION_MS;
    return {
      attemptsLeft: 0,
      isLocked: true,
      remainingMinutes: 15,
      remainingMs: LOCKOUT_DURATION_MS,
    };
  }

  return {
    attemptsLeft: MAX_WRONG_ATTEMPTS - record.count,
    isLocked: false,
  };
}

/**
 * Clears failed attempts upon successful room join.
 */
function resetFailedAttempts(key) {
  failedAttempts.delete(key);
}

// Global API rate limiter (protecting free tier hosting)
const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'TooManyRequests',
    message: 'Too many requests from this IP, please try again later.',
  },
});

module.exports = {
  checkJoinLockout,
  recordFailedAttempt,
  resetFailedAttempts,
  apiRateLimiter,
  MAX_WRONG_ATTEMPTS,
  LOCKOUT_DURATION_MS,
};

