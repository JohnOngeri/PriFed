/**
 * JWT Token Utilities
 * Generate and verify JWT tokens
 */

import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { logger } from './logger.js';

const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-change-in-production';
const JWT_ACCESS_EXPIRY = process.env.JWT_ACCESS_EXPIRY || '15m';
const JWT_REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || '7d';

/**
 * Generate access token
 */
export const generateAccessToken = (payload) => {
  try {
    return jwt.sign(
      {
        userId: payload.userId,
        email: payload.email,
        role: payload.role,
        bankId: payload.bankId
      },
      JWT_SECRET,
      {
        expiresIn: JWT_ACCESS_EXPIRY,
        issuer: 'privfed-api',
        audience: 'privfed-mobile'
      }
    );
  } catch (error) {
    logger.error('Error generating access token:', error);
    throw new Error('Failed to generate access token');
  }
};

/**
 * Generate refresh token
 */
export const generateRefreshToken = (payload) => {
  try {
    return jwt.sign(
      {
        userId: payload.userId,
        tokenVersion: payload.tokenVersion || 0
      },
      JWT_REFRESH_SECRET,
      {
        expiresIn: JWT_REFRESH_EXPIRY,
        issuer: 'privfed-api',
        audience: 'privfed-mobile'
      }
    );
  } catch (error) {
    logger.error('Error generating refresh token:', error);
    throw new Error('Failed to generate refresh token');
  }
};

/**
 * Verify access token
 */
export const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET, {
      issuer: 'privfed-api',
      audience: 'privfed-mobile'
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token expired');
    }
    if (error.name === 'JsonWebTokenError') {
      throw new Error('Invalid token');
    }
    throw error;
  }
};

/**
 * Verify refresh token
 */
export const verifyRefreshToken = (token) => {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET, {
      issuer: 'privfed-api',
      audience: 'privfed-mobile'
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Refresh token expired');
    }
    if (error.name === 'JsonWebTokenError') {
      throw new Error('Invalid refresh token');
    }
    throw error;
  }
};

/**
 * Generate password reset token
 */
export const generatePasswordResetToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

/**
 * Hash password reset token for storage
 */
export const hashPasswordResetToken = (token) => {
  return crypto.createHash('sha256').update(token).digest('hex');
};
