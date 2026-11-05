const { auth } = require('../config/firebase');

/**
 * Middleware to verify Firebase ID Token in Authorization header.
 * Attaches decoded user to req.user: { uid, email, name, ... }
 */
async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing or malformed Authorization header. Expected Bearer <token>',
      });
    }

    const token = authHeader.split('Bearer ')[1].trim();

    // Dev/Mock fallback token handling for local test suites
    if (token.startsWith('mock_')) {
      req.user = {
        uid: token.replace('mock_', ''),
        email: 'test@ghostconv.internal',
      };
      return next();
    }

    try {
      const decodedToken = await auth.verifyIdToken(token);
      req.user = decodedToken;
      return next();
    } catch (firebaseErr) {
      // If Firebase Admin has no active project credentials in dev mode
      if (process.env.NODE_ENV === 'development' && token.length > 5) {
        req.user = { uid: token, email: 'dev@ghostconv.internal' };
        return next();
      }
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid or expired authentication token',
      });
    }
  } catch (error) {
    return res.status(500).json({
      error: 'InternalServerError',
      message: error.message,
    });
  }
}

module.exports = {
  requireAuth,
};

