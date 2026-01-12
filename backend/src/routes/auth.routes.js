/**
 * Authentication Routes
 * Handles login, signup, password reset, token refresh
 */

import express from 'express';
import { authLimiter, passwordResetLimiter } from '../middleware/rateLimiter.js';
import { authenticate } from '../middleware/auth.middleware.js';
import * as authController from '../controllers/auth.controller.js';
import { validate } from '../validators/validator.js';
import { loginSchema, signupSchema, forgotPasswordSchema, resetPasswordSchema, refreshTokenSchema, changePasswordSchema } from '../validators/auth.validator.js';

const router = express.Router();

/**
 * @route   POST /api/auth/signup
 * @desc    Register a new user (join federation)
 * @access  Public
 */
router.post('/signup', 
  authLimiter,
  validate(signupSchema),
  authController.signup
);

/**
 * @route   POST /api/auth/login
 * @desc    Login with federation ID and passcode
 * @access  Public
 */
router.post('/login',
  authLimiter,
  validate(loginSchema),
  authController.login
);

/**
 * @route   POST /api/auth/refresh
 * @desc    Refresh access token using refresh token
 * @access  Public
 */
router.post('/refresh',
  validate(refreshTokenSchema),
  authController.refreshToken
);

/**
 * @route   POST /api/auth/logout
 * @desc    Logout and revoke refresh token
 * @access  Private
 */
router.post('/logout',
  authenticate,
  authController.logout
);

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Request password reset email
 * @access  Public
 */
router.post('/forgot-password',
  passwordResetLimiter,
  validate(forgotPasswordSchema),
  authController.forgotPassword
);

/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password using reset token
 * @access  Public
 */
router.post('/reset-password',
  passwordResetLimiter,
  validate(resetPasswordSchema),
  authController.resetPassword
);

/**
 * @route   POST /api/auth/change-password
 * @desc    Change password (requires current password)
 * @access  Private
 */
router.post('/change-password',
  authenticate,
  validate(changePasswordSchema),
  authController.changePassword
);

/**
 * @route   GET /api/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me',
  authenticate,
  authController.getCurrentUser
);

/**
 * @route   POST /api/auth/verify-token
 * @desc    Verify if access token is valid
 * @access  Public (but requires token)
 */
router.post('/verify-token',
  authenticate,
  authController.verifyToken
);

export default router;
