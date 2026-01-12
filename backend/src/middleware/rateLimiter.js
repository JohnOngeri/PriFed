/**
 * Rate Limiting Middleware
 * Prevents brute-force attacks and API abuse
 */

import rateLimit from 'express-rate-limit';
import { logger } from '../utils/logger.js';

/**
 * General API rate limiter
 */
export const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
  message: {
    error: 'Too Many Requests',
    message: 'Too many requests from this IP, please try again later',
    timestamp: new Date().toISOString()
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn('Rate limit exceeded', {
      ip: req.ip,
      path: req.path,
      method: req.method
    });
    res.status(429).json({
      error: 'Too Many Requests',
      message: 'Too many requests from this IP, please try again later',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * Strict rate limiter for authentication endpoints
 */
export const authLimiter = rateLimit({
  windowMs: parseInt(process.env.AUTH_RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
  max: parseInt(process.env.AUTH_RATE_LIMIT_MAX_REQUESTS || '5'), // 5 attempts per 15 minutes
  message: {
    error: 'Too Many Requests',
    message: 'Too many authentication attempts, please try again later',
    timestamp: new Date().toISOString()
  },
  skipSuccessfulRequests: true, // Don't count successful requests
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn('Auth rate limit exceeded', {
      ip: req.ip,
      path: req.path,
      method: req.method
    });
    res.status(429).json({
      error: 'Too Many Requests',
      message: 'Too many authentication attempts, please try again later',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * Password reset rate limiter
 */
export const passwordResetLimiter = rateLimit({
  windowMs: 3600000, // 1 hour
  max: 3, // 3 attempts per hour
  message: {
    error: 'Too Many Requests',
    message: 'Too many password reset attempts, please try again later',
    timestamp: new Date().toISOString()
  },
  standardHeaders: true,
  legacyHeaders: false
});
