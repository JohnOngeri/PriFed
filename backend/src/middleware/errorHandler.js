/**
 * Global Error Handler Middleware
 * Handles all errors and formats responses for mobile clients
 */

import { logger } from '../utils/logger.js';

export const errorHandler = (err, req, res, next) => {
  // Log error
  logger.error('Error occurred:', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    ip: req.ip
  });

  // Default error
  let statusCode = err.statusCode || err.status || 500;
  let message = err.message || 'Internal Server Error';
  let details = null;

  // Validation errors
  if (err.name === 'ValidationError' || err.name === 'ZodError') {
    statusCode = 400;
    message = 'Validation Error';
    details = err.errors || err.issues || err.message;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token';
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expired';
  }

  // Prisma errors
  if (err.code === 'P2002') {
    statusCode = 409;
    message = 'Duplicate entry - record already exists';
  }

  if (err.code === 'P2025') {
    statusCode = 404;
    message = 'Record not found';
  }

  // Rate limit errors
  if (err.statusCode === 429) {
    message = 'Too many requests - please try again later';
  }

  // Send error response
  const errorResponse = {
    error: err.name || 'Error',
    message,
    ...(details && { details }),
    timestamp: new Date().toISOString(),
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  };

  res.status(statusCode).json(errorResponse);
};
