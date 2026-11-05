function errorHandler(err, req, res, next) {
  console.error('Unhandled Application Error:', err);

  const status = err.status || 500;
  const message = err.message || 'An unexpected internal error occurred';

  res.status(status).json({
    error: err.name || 'InternalServerError',
    message,
    ...(process.env.NODE_ENV === 'development' ? { stack: err.stack } : {}),
  });
}

module.exports = {
  errorHandler,
};

