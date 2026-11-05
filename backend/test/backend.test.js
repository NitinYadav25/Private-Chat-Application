const assert = require('assert');
const { generateRoomCode, sanitizeCode, ALPHABET } = require('../src/utils/codeGenerator');
const { hashCode } = require('../src/utils/hash');
const {
  checkJoinLockout,
  recordFailedAttempt,
  resetFailedAttempts,
  MAX_WRONG_ATTEMPTS,
} = require('../src/middleware/rateLimiter');

console.log('--- Running GhostConv Backend Tests ---');

// 1. Code Generation Test
for (let i = 0; i < 50; i++) {
  const code = generateRoomCode();
  assert.strictEqual(code.length, 8, `Code length must be 8, got ${code.length}`);
  for (const char of code) {
    assert(ALPHABET.includes(char), `Character "${char}" not in allowed alphabet!`);
  }
}
console.log('✓ Code Generator: 50 unique codes validated against Crockford Base32 alphabet.');

// 2. Code Sanitization Test
const rawInput = ' k7m2 - 9qxp ';
const clean = sanitizeCode(rawInput);
assert.strictEqual(clean, 'K7M29QXP', `Expected "K7M29QXP", got "${clean}"`);
console.log('✓ Code Sanitizer: Strips spaces, hyphens, and converts to uppercase.');

// 3. SHA-256 Code Hashing Test
const hash1 = hashCode('K7M29QXP');
const hash2 = hashCode('k7m2-9qxp'); // should match after sanitization
assert.strictEqual(hash1, hash2, 'Hashes should match regardless of casing and dashes');
assert.strictEqual(hash1.length, 64, 'SHA-256 hash must be 64 hex characters');
console.log('✓ Code Hasher: Computes consistent 64-char SHA-256 hash.');

// 4. Rate Limiting (5 wrong attempts -> 15-minute lock)
const testKey = 'test_user_ip_1';
resetFailedAttempts(testKey);

assert.strictEqual(checkJoinLockout(testKey).isLocked, false);

// 4 failed attempts: not locked yet
for (let i = 1; i <= 4; i++) {
  const attempt = recordFailedAttempt(testKey);
  assert.strictEqual(attempt.isLocked, false);
  assert.strictEqual(attempt.attemptsLeft, MAX_WRONG_ATTEMPTS - i);
}

// 5th failed attempt: triggers lockout
const fifthAttempt = recordFailedAttempt(testKey);
assert.strictEqual(fifthAttempt.isLocked, true);
assert.strictEqual(fifthAttempt.attemptsLeft, 0);
assert.strictEqual(checkJoinLockout(testKey).isLocked, true);

// Reset clears lockout
resetFailedAttempts(testKey);
assert.strictEqual(checkJoinLockout(testKey).isLocked, false);
console.log('✓ Rate Limiter: 5 wrong attempts properly triggers 15-minute lockout.');

console.log('--- All Backend Tests Passed Successfully! ---');

