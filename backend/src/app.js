require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const { apiRateLimiter } = require('./middleware/rateLimiter');
const { errorHandler } = require('./middleware/errorHandler');

const healthRoutes = require('./routes/health');
const roomsRoutes = require('./routes/rooms');
const mediaRoutes = require('./routes/media');

const app = express();
const PORT = process.env.PORT || 5000;

// Security & Header Middlewares
app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '1mb' }));

// Apply rate limiting across all incoming requests
app.use(apiRateLimiter);

// Mount API routes
app.use('/health', healthRoutes);
app.use('/rooms', roomsRoutes);
app.use('/media', mediaRoutes);

// Root Welcome Endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'GhostConv API',
    description: 'Ephemeral 1-to-1 private chat room engine',
    status: 'running',
    version: '1.0.0',
  });
});

// 404 Route Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'NotFound',
    message: `Cannot ${req.method} ${req.originalUrl}`,
  });
});

// Central Error Handler
app.use(errorHandler);

// Start server if run directly
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`GhostConv backend server running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
  });
}

module.exports = app;

