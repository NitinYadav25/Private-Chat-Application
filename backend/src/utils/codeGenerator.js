const crypto = require('crypto');

// Crockford Base32 alphabet excluding confusing characters (I, L, O, 1, 0)
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 8;

/**
 * Generates an 8-character cryptographically secure room code.
 * Format example: "K7M29QXP"
 */
function generateRoomCode() {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    const randomIndex = crypto.randomInt(0, ALPHABET.length);
    code += ALPHABET[randomIndex];
  }
  return code;
}

/**
 * Formats an 8-character code with a hyphen: "XXXX-XXXX"
 */
function formatCode(code) {
  if (!code || code.length !== 8) return code;
  return `${code.slice(0, 4)}-${code.slice(4)}`;
}

/**
 * Sanitizes input code by stripping spaces, hyphens, and converting to uppercase.
 */
function sanitizeCode(input) {
  if (!input) return '';
  return input
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .slice(0, 8);
}

module.exports = {
  ALPHABET,
  CODE_LENGTH,
  generateRoomCode,
  formatCode,
  sanitizeCode,
};

