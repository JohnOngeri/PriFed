/**
 * Authentication Middleware
 * Verifies JWT tokens and attaches user to request
 */

import jwt from 'jsonwebtoken';
import { logger } from '../utils/logger.js';
import prisma from '../utils/prisma.js';

/**
 * Verify JWT Access Token
 */
export const authenticate = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'No token provided',
        timestamp: new Date().toISOString()
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Get user from database
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: {
        bank: true
      }
    });

    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'User not found or inactive',
        timestamp: new Date().toISOString()
      });
    }

    // Attach user to request
    req.user = {
      id: user.id,
      email: user.email,
      federationId: user.federationId,
      role: user.role,
      bankId: user.bankId,
      bank: user.bank
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Token expired',
        timestamp: new Date().toISOString()
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid token',
        timestamp: new Date().toISOString()
      });
    }

    logger.error('Authentication error:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Authentication failed',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Optional authentication - attaches user if token is valid, but doesn't fail if missing
 */
export const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        include: { bank: true }
      });

      if (user && user.isActive) {
        req.user = {
          id: user.id,
          email: user.email,
          federationId: user.federationId,
          role: user.role,
          bankId: user.bankId,
          bank: user.bank
        };
      }
    }
    
    next();
  } catch (error) {
    // Silently fail for optional auth
    next();
  }
};

/**
 * Require specific role
 */
export const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
        timestamp: new Date().toISOString()
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Insufficient permissions',
        timestamp: new Date().toISOString()
      });
    }

    next();
  };
};

/**
 * Require admin role
 */
export const requireAdmin = requireRole('ADMIN');

/**
 * Require bank admin or admin
 */
export const requireBankAdmin = requireRole('ADMIN', 'BANK_ADMIN');
