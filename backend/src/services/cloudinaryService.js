const cloudinary = require('../config/cloudinary');

/**
 * Generates Cloudinary signed upload parameters.
 * Assets are organized strictly under rooms/{roomId}/ so they can be
 * systematically eradicated during the permanent wipe.
 */
function generateUploadSignature({ roomId, resourceType = 'auto' }) {
  if (!roomId) {
    throw new Error('roomId is required for signed upload');
  }

  const timestamp = Math.round(new Date().getTime() / 1000);
  const folder = `rooms/${roomId}`;

  const paramsToSign = {
    folder,
    timestamp,
  };

  const signature = cloudinary.utils.api_sign_request(
    paramsToSign,
    process.env.CLOUDINARY_API_SECRET || 'dev_secret'
  );

  return {
    signature,
    timestamp,
    folder,
    apiKey: process.env.CLOUDINARY_API_KEY || 'dev_key',
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || 'dev_cloud',
    resourceType,
  };
}

module.exports = {
  generateUploadSignature,
};

