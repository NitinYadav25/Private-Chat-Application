const { db } = require('../config/firebase');
const { generateRoomCode, sanitizeCode } = require('../utils/codeGenerator');
const { hashCode } = require('../utils/hash');

const EXPIRY_HOURS = 24;

/**
 * Creates a temporary chat room.
 * Generates an 8-character code, computes its SHA-256 hash, and stores ONLY the hash.
 */
async function createRoom(creatorId, name = null) {
  let uniqueCode = '';
  let codeHash = '';
  let isUnique = false;

  // Ensure collision-free code
  for (let attempt = 0; attempt < 5; attempt++) {
    uniqueCode = generateRoomCode();
    codeHash = hashCode(uniqueCode);

    const existing = await db
      .collection('rooms')
      .where('codeHash', '==', codeHash)
      .where('status', '==', 'waiting')
      .limit(1)
      .get();

    if (existing.empty) {
      isUnique = true;
      break;
    }
  }

  if (!isUnique) {
    throw new Error('Failed to generate unique room code. Please try again.');
  }

  const now = new Date();
  const expiresAt = new Date(now.getTime() + EXPIRY_HOURS * 60 * 60 * 1000);

  const roomRef = db.collection('rooms').doc();
  const roomId = roomRef.id;

  const roomData = {
    roomId,
    codeHash, // Raw code is NEVER stored
    creatorId,
    name: name ? name.trim() : null,
    participants: [creatorId],
    status: 'waiting',
    createdAt: now,
    expiresAt,
  };

  await roomRef.set(roomData);

  return {
    roomId,
    code: uniqueCode, // Return plaintext code to creator ONCE
    name: roomData.name,
    expiresAt,
    status: 'waiting',
  };
}

/**
 * Validates and pairs a user into a temporary chat room using an 8-character code.
 */
async function joinRoom(userId, rawCode) {
  const cleanCode = sanitizeCode(rawCode);

  if (!cleanCode || cleanCode.length !== 8) {
    throw { status: 400, message: 'Security code must be exactly 8 characters.' };
  }

  const codeHash = hashCode(cleanCode);

  const snapshot = await db
    .collection('rooms')
    .where('codeHash', '==', codeHash)
    .where('status', '==', 'waiting')
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw { status: 404, message: 'Invalid or expired room security code.' };
  }

  const roomDoc = snapshot.docs[0];
  const room = roomDoc.data();
  const roomId = roomDoc.id;

  // Check expiration
  const expiresAt = room.expiresAt ? room.expiresAt.toDate() : null;
  if (expiresAt && new Date() > expiresAt) {
    throw { status: 410, message: 'This room code has expired (24 hours exceeded).' };
  }

  // Prevent duplicate join by creator
  if (room.creatorId === userId) {
    return {
      roomId,
      name: room.name,
      status: room.status,
      isCreator: true,
      message: 'You are already in this room as creator.',
    };
  }

  // Check participant limit (exactly 2 participants max)
  if (room.participants.length >= 2) {
    throw { status: 409, message: 'This room is already full.' };
  }

  // Pair room: set status to 'active', add participant, and DESTROY codeHash so code is single-use!
  await roomDoc.ref.update({
    participants: [...room.participants, userId],
    status: 'active',
    codeHash: null, // Single-use enforcement: code is dead immediately
    pairedAt: new Date(),
  });

  return {
    roomId,
    name: room.name,
    status: 'active',
    partnerId: room.creatorId,
  };
}

module.exports = {
  createRoom,
  joinRoom,
};

