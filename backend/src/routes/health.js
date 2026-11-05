const express = require('express');
const router = express.Router();

/**
 * GET /health
 * Quick health-check endpoint for client warm-up and monitoring.
 */
router.get('/', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'GhostConv Backend',
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;

