/**
 * Authentication Controller
 * Handles all authentication-related operations
 */

import prisma from '../utils/prisma.js';
import { hashPassword, comparePassword } from '../utils/password.js';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken, generatePasswordResetToken, hashPasswordResetToken } from '../utils/jwt.js';
import { sendPasswordResetEmail, sendWelcomeEmail } from '../utils/email.js';
import { logger } from '../utils/logger.js';
import { generateUniqueFederationId, normalizeFederationId } from '../utils/federationId.js';
import crypto from 'crypto';

/**
 * Sign up new user
 * Federation ID is auto-generated and must be unique
 */
export const signup = async (req, res) => {
  try {
    const { email, passcode, bankName, bankId } = req.body;

    // Check if user already exists by email
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'Email already registered',
        timestamp: new Date().toISOString()
      });
    }

    // Generate unique Federation ID
    const federationId = await generateUniqueFederationId(async (id) => {
      const exists = await prisma.user.findUnique({
        where: { federationId: id }
      });
      return !!exists;
    });

    // Hash password
    const passwordHash = await hashPassword(passcode);

    // Create user
    const user = await prisma.user.create({
      data: {
        email,
        federationId,
        passwordHash,
        role: 'PUBLIC',
        bankId: bankId || null,
        isActive: true
      },
      include: {
        bank: true
      }
    });

    // Generate tokens
    const accessToken = generateAccessToken({
      userId: user.id,
      email: user.email,
      role: user.role,
      bankId: user.bankId
    });

    const refreshToken = generateRefreshToken({
      userId: user.id,
      tokenVersion: 0
    });

    // Store refresh token
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
      }
    });

    // Send welcome email (critical - must send Federation ID)
    try {
      await sendWelcomeEmail(email, federationId);
    } catch (emailError) {
      // Log error but don't fail signup - Federation ID is in response
      logger.error('Failed to send welcome email:', emailError);
    }

    logger.info('User signed up successfully', { userId: user.id, federationId });

    res.status(201).json({
      message: 'Account created successfully. Your Federation ID is CRITICAL. Save it securely - it cannot be recovered.',
      federationId: user.federationId,
      user: {
        id: user.id,
        email: user.email,
        federationId: user.federationId,
        role: user.role,
        bankId: user.bankId
      },
      tokens: {
        accessToken,
        refreshToken,
        tokenType: 'Bearer',
        expiresIn: '15m'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Signup error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create user account',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Login user
 */
export const login = async (req, res) => {
  try {
    const { federationId, passcode } = req.body;

    // Find user by federation ID or email
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { federationId },
          { email: federationId } // Allow login with email too
        ]
      },
      include: {
        bank: true
      }
    });

    if (!user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid Federation ID or passcode',
        timestamp: new Date().toISOString()
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Account is inactive',
        timestamp: new Date().toISOString()
      });
    }

    // Verify password
    const isValidPassword = await comparePassword(passcode, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid Federation ID or passcode',
        timestamp: new Date().toISOString()
      });
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() }
    });

    // Generate tokens
    const accessToken = generateAccessToken({
      userId: user.id,
      email: user.email,
      role: user.role,
      bankId: user.bankId
    });

    const refreshToken = generateRefreshToken({
      userId: user.id,
      tokenVersion: 0
    });

    // Store refresh token
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        deviceId: req.headers['x-device-id'] || null,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
      }
    });

    logger.info('User logged in successfully', { userId: user.id, federationId });

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        federationId: user.federationId,
        role: user.role,
        bankId: user.bankId,
        bank: user.bank ? {
          id: user.bank.id,
          bankId: user.bank.bankId,
          name: user.bank.name
        } : null
      },
      tokens: {
        accessToken,
        refreshToken,
        tokenType: 'Bearer',
        expiresIn: '15m'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to authenticate user',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Refresh access token
 */
export const refreshToken = async (req, res) => {
  try {
    const { refreshToken: token } = req.body;

    // Verify refresh token
    const decoded = verifyRefreshToken(token);

    // Check if refresh token exists in database
    const storedToken = await prisma.refreshToken.findUnique({
      where: { token },
      include: { user: true }
    });

    if (!storedToken || storedToken.revokedAt || storedToken.expiresAt < new Date()) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid or expired refresh token',
        timestamp: new Date().toISOString()
      });
    }

    if (!storedToken.user.isActive) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'User account is inactive',
        timestamp: new Date().toISOString()
      });
    }

    // Generate new access token
    const accessToken = generateAccessToken({
      userId: storedToken.user.id,
      email: storedToken.user.email,
      role: storedToken.user.role,
      bankId: storedToken.user.bankId
    });

    res.json({
      accessToken,
      tokenType: 'Bearer',
      expiresIn: '15m',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Refresh token error:', error);
    res.status(401).json({
      error: 'Unauthorized',
      message: error.message || 'Invalid refresh token',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Logout user
 */
export const logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (refreshToken) {
      // Revoke refresh token
      await prisma.refreshToken.updateMany({
        where: {
          token: refreshToken,
          userId: req.user.id
        },
        data: {
          revokedAt: new Date()
        }
      });
    } else {
      // Revoke all refresh tokens for user
      await prisma.refreshToken.updateMany({
        where: {
          userId: req.user.id,
          revokedAt: null
        },
        data: {
          revokedAt: new Date()
        }
      });
    }

    logger.info('User logged out', { userId: req.user.id });

    res.json({
      message: 'Logout successful',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to logout',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Forgot password
 */
export const forgotPassword = async (req, res) => {
  try {
    const { federationId, email } = req.body;

    // Find user
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          federationId ? { federationId } : null,
          email ? { email } : null
        ].filter(Boolean)
      }
    });

    // Always return success to prevent user enumeration
    if (!user) {
      return res.json({
        message: 'If an account exists with that email or Federation ID, a password reset link has been sent',
        timestamp: new Date().toISOString()
      });
    }

    // Generate reset token
    const resetToken = generatePasswordResetToken();
    const hashedToken = hashPasswordResetToken(resetToken);
    const expiresAt = new Date(Date.now() + parseInt(process.env.PASSWORD_RESET_EXPIRY || '3600000')); // 1 hour

    // Delete existing reset tokens for this user
    await prisma.passwordResetToken.deleteMany({
      where: { userId: user.id }
    });

    // Store reset token
    await prisma.passwordResetToken.create({
      data: {
        token: hashedToken,
        userId: user.id,
        expiresAt
      }
    });

    // Send reset email (non-blocking)
    sendPasswordResetEmail(user.email, resetToken, user.federationId).catch(err => {
      logger.error('Failed to send password reset email:', err);
    });

    logger.info('Password reset requested', { userId: user.id });

    res.json({
      message: 'If an account exists with that email or Federation ID, a password reset link has been sent',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Forgot password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to process password reset request',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Reset password
 */
export const resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    // Hash token to compare
    const hashedToken = hashPasswordResetToken(token);

    // Find valid reset token
    const resetToken = await prisma.passwordResetToken.findFirst({
      where: {
        token: hashedToken,
        expiresAt: { gt: new Date() },
        usedAt: null
      },
      include: { user: true }
    });

    if (!resetToken) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid or expired reset token',
        timestamp: new Date().toISOString()
      });
    }

    // Hash new password
    const passwordHash = await hashPassword(newPassword);

    // Update user password
    await prisma.user.update({
      where: { id: resetToken.userId },
      data: { passwordHash }
    });

    // Mark token as used
    await prisma.passwordResetToken.update({
      where: { id: resetToken.id },
      data: { usedAt: new Date() }
    });

    // Revoke all refresh tokens for security
    await prisma.refreshToken.updateMany({
      where: { userId: resetToken.userId },
      data: { revokedAt: new Date() }
    });

    logger.info('Password reset successful', { userId: resetToken.userId });

    res.json({
      message: 'Password reset successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Reset password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to reset password',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Change password (requires current password)
 */
export const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Get user with password hash
    const user = await prisma.user.findUnique({
      where: { id: req.user.id }
    });

    // Verify current password
    const isValidPassword = await comparePassword(currentPassword, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Current password is incorrect',
        timestamp: new Date().toISOString()
      });
    }

    // Hash new password
    const passwordHash = await hashPassword(newPassword);

    // Update password
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash }
    });

    // Revoke all refresh tokens except current session
    await prisma.refreshToken.updateMany({
      where: {
        userId: user.id,
        revokedAt: null
      },
      data: { revokedAt: new Date() }
    });

    logger.info('Password changed successfully', { userId: user.id });

    res.json({
      message: 'Password changed successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Change password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to change password',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Get current user
 */
export const getCurrentUser = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: {
        bank: true
      }
    });

    res.json({
      user: {
        id: user.id,
        email: user.email,
        federationId: user.federationId,
        role: user.role,
        bankId: user.bankId,
        bank: user.bank ? {
          id: user.bank.id,
          bankId: user.bank.bankId,
          name: user.bank.name,
          subtitle: user.bank.subtitle,
          color: user.bank.color,
          icon: user.bank.icon
        } : null,
        lastLoginAt: user.lastLoginAt,
        createdAt: user.createdAt
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Get current user error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve user information',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Verify token
 */
export const verifyToken = async (req, res) => {
  res.json({
    valid: true,
    user: req.user,
    timestamp: new Date().toISOString()
  });
};
