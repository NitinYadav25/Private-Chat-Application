const { db } = require('../config/firebase');
const cloudinary = require('../config/cloudinary');

/**
 * Irreversible Wipe Pipeline:
 * 1. Mark room status as 'ended' so clients immediately show "Chat ended".
 * 2. Delete all Cloudinary assets under folder rooms/{roomId}/.
 * 3. Delete all Firestore messages in batches of 400.
 * 4. Delete the room document itself.
 */
async function wipeRoom(roomId, requestingUserId) {
  const roomRef = db.collection('rooms').doc(roomId);
  const roomDoc = await roomRef.get();

  if (!roomDoc.exists) {
    throw new Error('Room not found');
  }

  const roomData = roomDoc.data();
  const participants = roomData.participants || [];

  if (!participants.includes(requestingUserId)) {
    throw new Error('Unauthorized: only room participants can end and wipe this room');
  }

  console.log(`[WIPE] Starting permanent eradication for room ${roomId} by user ${requestingUserId}`);

  // Step 1: Set status 'ended' so real-time clients instantly react
  await roomRef.update({
    status: 'ended',
    endedAt: new Date(),
    endedBy: requestingUserId,
  });

  // Step 2: Delete every Cloudinary asset under rooms/{roomId}/
  try {
    const folderPath = `rooms/${roomId}`;
    // Delete all resources in the room folder
    await cloudinary.api.delete_resources_by_prefix(`${folderPath}/`);
    // Delete the empty folder itself
    await cloudinary.api.delete_folder(folderPath).catch(() => {});
    console.log(`[WIPE] Cloudinary assets purged for ${folderPath}`);
  } catch (cloudErr) {
    console.warn(`[WIPE] Cloudinary purge non-fatal error: ${cloudErr.message}`);
  }

  // Step 3: Delete all Firestore messages in subcollection in batches of 400
  const messagesCollection = roomRef.collection('messages');
  let deletedCount = 0;

  while (true) {
    const snapshot = await messagesCollection.limit(400).get();
    if (snapshot.empty) break;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    deletedCount += snapshot.size;
  }

  console.log(`[WIPE] Deleted ${deletedCount} messages from room ${roomId}`);

  // Step 4: Delete the room document permanently
  await roomRef.delete();
  console.log(`[WIPE] Room document ${roomId} permanently deleted`);

  return {
    success: true,
    roomId,
    messagesDeleted: deletedCount,
  };
}

module.exports = {
  wipeRoom,
};

