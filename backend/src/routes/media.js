const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { generateUploadSignature } = require('../services/cloudinaryService');

/**
 * POST /media/sign
 * Returns a signed upload signature for Cloudinary.
 * Secrets never leave the backend.
 */
router.post('/sign', requireAuth, (req, res) => {
  try {
    const { roomId, resourceType } = req.body;

    if (!roomId) {
      return res.status(400).json({
        error: 'MissingRoomId',
        message: 'roomId is required to generate media upload signature',
      });
    }

    const signatureData = generateUploadSignature({ roomId, resourceType });
    return res.status(200).json(signatureData);
  } catch (error) {
    console.error('Error signing media upload:', error);
    return res.status(500).json({
      error: 'MediaSignFailed',
      message: error.message || 'Failed to sign media upload',
    });
  }
});

module.exports = router;

