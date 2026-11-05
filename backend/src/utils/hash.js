const crypto = require('crypto');
const { sanitizeCode } = require('./codeGenerator');

/**
 * Computes SHA-256 hash of a sanitized 8-character room code.
 * The raw code is never stored on the server or in Firestore.
 */
function hashCode(rawCode) {
  const clean = sanitizeCode(rawCode);
  return crypto.createHash('sha256').update(clean).digest('hex');
}

module.exports = {
  hashCode,
};

